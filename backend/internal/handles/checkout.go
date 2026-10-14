package handlers

import (
	"database/sql"
	"net/http"
	"strings"
	"tajikshop/internal/db"
	"tajikshop/internal/utils"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// ═══════════════════════════════════════════════════════════════════════════
//  Checkout — сохтани фармоиш
// ═══════════════════════════════════════════════════════════════════════════
//
// Ин қисми аз ҳама ҳассоси тамоми барнома аст: ин ҷо пул ва анбор якҷоя
// тағйир меёбанд. Нусхаи пештара чор камбудии ҷиддӣ дошт, ва ҳар чор
// камбудӣ дар фурӯши воқеӣ зарари воқеӣ мерасонд:
//
//  1. АНБОР ТАМОМАН САНҶИДА НАМЕШУД. `UPDATE products SET
//     stock=GREATEST(stock-$1,0)` ҳар шуморро қабул мекард. Дар анбор 3
//     дона буд, харидор 100 дона мефармуд — фармоиш қабул мешуд, анбор 0
//     мешуд, ва фурӯшанда бо харидор рӯ ба рӯ мемонд.
//
//  2. РОҲИ ҒАЙРИ-ҲАМЁН ТРАНЗАКСИЯ НАДОШТ. Фармоиш, молҳо, анбор ва тоза
//     кардани сабад чор амри ҷудогона буданд. Агар сервер дар байни онҳо
//     афтад — фармоиши бе мол, ё анбори камшуда бе фармоиш мемонд.
//
//  3. IDEMPOTENCY НАБУД. Ду зеркунии тугма ё такрори шабака = ду фармоиш
//     ва ду бор пул аз ҳамён.
//
//  4. ПУЛИ РАСОНИДАН АЗ МУШТАРӢ МЕОМАД. Сервер танҳо бо 200 маҳдуд
//     мекард, пас `{"delivery_fee": 0}` расониданро ройгон мекард.
//
// Ҳоло ҳамааш дар ЯК транзаксия аст, сатрҳои маҳсулот бо `FOR UPDATE`
// қулф мешаванд (бо тартиби муайян, то deadlock нашавад), ва ҳар рақам
// дар сервер бо дирами бутун ҳисоб мешавад.

// checkoutRequest — он чизе, ки барнома мефиристад.
//
// `delivery_fee` ва `total` дидаву дониста ҚАБУЛ НАМЕШАВАНД: ҳардуро
// сервер худаш ҳисоб мекунад.
type checkoutRequest struct {
	AddressID      string `json:"address_id"`
	Note           string `json:"note"`
	PaymentMethod  string `json:"payment_method"` // dc | cod | wallet
	CouponCode     string `json:"coupon_code"`
	Fulfilment     string `json:"fulfilment"` // delivery | pickup
	DeliveryASAP   *bool  `json:"delivery_asap"`
	DeliverySlot   string `json:"delivery_slot"` // "HH:MM"
	IdempotencyKey string `json:"idempotency_key"`
}

// idempotencyKeyOf — калидро аз сарлавҳа ё бадани дархост мегирад.
//
// Сарлавҳаи `Idempotency-Key` тартиби қабулшудаи соҳа аст; майдони JSON
// барои мизоҷони кӯҳна мемонад.
func idempotencyKeyOf(c *gin.Context, in checkoutRequest) string {
	k := strings.TrimSpace(c.GetHeader("Idempotency-Key"))
	if k == "" {
		k = strings.TrimSpace(in.IdempotencyKey)
	}
	if len(k) > 120 {
		k = k[:120]
	}
	return k
}

// Checkout — POST /orders/checkout
func (h *OrderHandler) Checkout(c *gin.Context) {
	uid := utils.UserID(c)
	var in checkoutRequest
	c.ShouldBindJSON(&in)

	method := normalizePaymentMethod(in.PaymentMethod)
	fulfilment := normalizeFulfilment(in.Fulfilment)
	delivery := deliveryFeeFor(fulfilment) // дирам, аз СЕРВЕР

	slot := strings.TrimSpace(in.DeliverySlot)
	if in.DeliveryASAP != nil && *in.DeliveryASAP {
		slot = ""
	}
	if len(slot) > 5 {
		slot = slot[:5]
	}
	note := in.Note
	if len(note) > 1000 {
		note = note[:1000]
	}

	key := idempotencyKeyOf(c, in)

	// Калид аллакай истифода шуд? Ҳамон фармоишро бармегардонем — на
	// фармоиши нав ва на хато. Барои барнома ин маънои «ҳамааш хуб
	// гузашт»-ро дорад, ҳатто агар ҷавоби аввал дар роҳ гум шуда бошад.
	if key != "" {
		if prev, total, ok := existingCheckout(uid, key); ok {
			utils.Created(c, gin.H{
				"order_id": prev, "total": total, "repeated": true,
			})
			return
		}
	}

	tx, err := db.DB.Begin()
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, "Фармоиш сохта нашуд, аз нав кӯшиш кунед")
		return
	}
	// `defer` барои ҳолатҳои ғайричашмдошт; роҳи дурусти корӣ худаш
	// `Commit` мекунад ва баъд ин `Rollback` ҳеҷ кор намекунад.
	committed := false
	defer func() {
		if !committed {
			tx.Rollback()
		}
	}()

	lines, lerr := loadAndLockCart(tx, uid)
	if lerr != nil {
		utils.Err(c, http.StatusInternalServerError, "Сабад хонда нашуд")
		return
	}
	if len(lines) == 0 {
		utils.Err(c, http.StatusBadRequest, "Сабад холӣ аст")
		return
	}

	// Санҷиши анбор, ҳадди ақал ва фаъол будан — ПЕШ аз сохтани фармоиш.
	if issues := validateLines(lines); len(issues) > 0 {
		utils.Fail(c, http.StatusConflict, gin.H{
			"message": "Баъзе маҳсулот тағйир ёфт — сабадро аз нав бинед",
			"issues":  issues,
		})
		return
	}

	// Купон дар дохили транзаксия санҷида мешавад, то ду дархости
	// ҳамзамон ҳардуяш тахфиф нагиранд.
	discountPct, couponCode := checkCouponInTx(tx, uid, in.CouponCode)

	tot := computeTotals(lines, delivery, discountPct)

	var addr interface{}
	if strings.TrimSpace(in.AddressID) != "" {
		addr = strings.TrimSpace(in.AddressID)
	}

	// Ҳамён: тавозунро қулф мекунем ва месанҷем.
	status := "pending"
	if method == "wallet" {
		var bal float64
		if e := tx.QueryRow(`SELECT COALESCE(wallet_balance,0) FROM users WHERE id=$1 FOR UPDATE`, uid).
			Scan(&bal); e != nil {
			utils.Err(c, http.StatusInternalServerError, "Ҳамён хонда нашуд")
			return
		}
		if toDirams(bal) < tot.Final {
			utils.Err(c, http.StatusBadRequest, "Тавозуни ҳамён нокифоя аст")
			return
		}
		status = "paid"
	}

	orderID := uuid.NewString()
	if _, e := tx.Exec(`INSERT INTO orders
		(id,user_id,address_id,total,note,payment_method,discount,fulfilment,delivery_fee,delivery_slot,status)
		VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)`,
		orderID, uid, addr, toSomoni(tot.Final), note, method,
		toSomoni(tot.Discount), fulfilment, toSomoni(tot.Delivery), slot, status); e != nil {
		utils.Err(c, http.StatusInternalServerError, "Фармоиш сохта нашуд")
		return
	}

	// Молҳо + кам кардани анбор.
	//
	// `WHERE stock >= $1` дуюмин қулф аст: `FOR UPDATE` аллакай кафолат
	// медиҳад, вале агар рӯзе касе ин ҷоро иваз кунад ва қулфро гум
	// кунад, ин шарт фурӯши зиёдатиро боз ҳам бас мекунад.
	for _, l := range lines {
		if _, e := tx.Exec(`INSERT INTO order_items
			(id,order_id,product_id,seller_id,title,quantity,price)
			VALUES($1,$2,$3,$4,$5,$6,$7)`,
			uuid.NewString(), orderID, l.ProductID, l.SellerID, l.Title,
			l.Qty, toSomoni(l.UnitPrice)); e != nil {
			utils.Err(c, http.StatusInternalServerError, "Моли фармоиш сабт нашуд")
			return
		}
		// Моли бешумор (`track_stock=false`) захира надорад — онро кам
		// кардан маъно надорад ва молро бардурӯғ «тамом» мекард.
		if l.Unlimited {
			continue
		}
		res, e := tx.Exec(`UPDATE products SET stock = stock - $1, updated_at = NOW()
			WHERE id = $2 AND stock >= $1`, l.Qty, l.ProductID)
		if e != nil {
			utils.Err(c, http.StatusInternalServerError, "Анбор нав нашуд")
			return
		}
		if n, _ := res.RowsAffected(); n != 1 {
			utils.Fail(c, http.StatusConflict, gin.H{
				"message": "«" + l.Title + "» ҳоло тамом шуд",
				"issues": []lineIssue{{
					ProductID: l.ProductID, Title: l.Title,
					Code: issueNotEnough, Available: l.Stock, MinQty: l.MinQty,
				}},
			})
			return
		}
	}

	// Зер-фармоиш барои ҳар фурӯшанда.
	for sellerID, sub := range sellerSubtotals(lines) {
		if _, e := tx.Exec(`INSERT INTO order_sellers(id,order_id,seller_id,status,subtotal)
			VALUES($1,$2,$3,$4,$5) ON CONFLICT (order_id,seller_id) DO NOTHING`,
			uuid.NewString(), orderID, sellerID, status, toSomoni(sub)); e != nil {
			utils.Err(c, http.StatusInternalServerError, "Зер-фармоиш сохта нашуд")
			return
		}
	}

	// Пардохт аз ҳамён.
	if method == "wallet" {
		if _, e := tx.Exec(`UPDATE users SET wallet_balance = wallet_balance - $1 WHERE id=$2`,
			toSomoni(tot.Final), uid); e != nil {
			utils.Err(c, http.StatusInternalServerError, "Пардохт нашуд")
			return
		}
		if _, e := tx.Exec(`INSERT INTO wallet_transactions(id,user_id,amount,type,status,note)
			VALUES($1,$2,$3,'purchase','completed',$4)`,
			uuid.NewString(), uid, -toSomoni(tot.Final), "Харид #"+shortID(orderID)); e != nil {
			utils.Err(c, http.StatusInternalServerError, "Амалиёти ҳамён сабт нашуд")
			return
		}
	}

	// Купонро сабт мекунем — дар ҳамон транзаксия, то такрор нашавад.
	if couponCode != "" {
		if _, e := tx.Exec(`INSERT INTO coupon_redemptions(id,code,user_id,order_id)
			VALUES($1,$2,$3,$4)`, uuid.NewString(), couponCode, uid, orderID); e != nil {
			utils.Err(c, http.StatusInternalServerError, "Купон сабт нашуд")
			return
		}
		tx.Exec(`UPDATE coupons SET used_count = used_count + 1 WHERE UPPER(code)=$1`, couponCode)
	}

	// Калиди idempotency — ҳам дар ҳамин транзаксия.
	//
	// Агар ду дархости ҳамзамон бо ҳамон калид оянд, дуюмаш ба UNIQUE
	// бархӯрд мекунад ва тамоми транзаксияаш бекор мешавад — яъне
	// фармоиши дуюм умуман сохта намешавад.
	if key != "" {
		if _, e := tx.Exec(`INSERT INTO checkout_keys(key,user_id,order_id) VALUES($1,$2,$3)`,
			key, uid, orderID); e != nil {
			tx.Rollback()
			committed = true // `defer`-ро хомӯш мекунем, аллакай бекор шуд
			if prev, total, ok := existingCheckout(uid, key); ok {
				utils.Created(c, gin.H{"order_id": prev, "total": total, "repeated": true})
				return
			}
			utils.Err(c, http.StatusConflict, "Ин фармоиш аллакай фиристода шуд")
			return
		}
	}

	if _, e := tx.Exec(`DELETE FROM cart_items WHERE user_id=$1`, uid); e != nil {
		utils.Err(c, http.StatusInternalServerError, "Сабад тоза нашуд")
		return
	}

	if e := tx.Commit(); e != nil {
		utils.Err(c, http.StatusInternalServerError, "Фармоиш нигоҳ дошта нашуд")
		return
	}
	committed = true

	// Аз ин ҷо ба поён ҳамааш «баъди фурӯш» аст: огоҳиҳо. Агар яктааш
	// афтад, фармоиш бояд дар ҳар ҳол дуруст монад — пас онҳо берун аз
	// транзаксия ҳастанд.
	afterCheckout(orderID, uid, lines, method, tot)

	utils.Created(c, gin.H{
		"order_id":     orderID,
		"total":        toSomoni(tot.Final),
		"items_total":  toSomoni(tot.Items),
		"delivery_fee": toSomoni(tot.Delivery),
		"discount":     toSomoni(tot.Discount),
		"status":       status,
	})
}

// loadAndLockCart — сабадро мехонад ва сатрҳои маҳсулотро қулф мекунад.
//
// `ORDER BY ci.product_id` ҳатмист: бе он ду харидор, ки ҳамон ду молро
// бо тартиби гуногун мефармоянд, якдигарро қулф мекунанд (deadlock).
// Бо тартиби муайян ҳарду ҳамон молро аввал мегиранд, пас яктааш танҳо
// интизор мешавад.
func loadAndLockCart(tx *sql.Tx, uid string) ([]checkoutLine, error) {
	rows, err := tx.Query(`SELECT ci.product_id, ci.quantity,
			p.price, p.stock, COALESCE(p.min_order_qty,1),
			COALESCE(p.is_active,true), p.seller_id, COALESCE(p.title,''),
			COALESCE(p.track_stock,true)
		FROM cart_items ci
		JOIN products p ON p.id = ci.product_id
		WHERE ci.user_id = $1
		ORDER BY ci.product_id
		FOR UPDATE OF p`, uid)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []checkoutLine
	var ids []string
	for rows.Next() {
		var l checkoutLine
		var price float64
		var trackStock bool
		// Хатои `Scan`-ро НАДИДА НАМЕГУЗАРОНЕМ. Агар сутуни NULL ба
		// `string` афтад, `Scan` хато медиҳад ва тамоми сатр сифр мемонад
		// — он гоҳ маҳсулот бо нархи 0 ба фармоиш мегузашт.
		if e := rows.Scan(&l.ProductID, &l.Qty, &price, &l.Stock, &l.MinQty,
			&l.Active, &l.SellerID, &l.Title, &trackStock); e != nil {
			return nil, e
		}
		l.UnitPrice = toDirams(price)
		l.Unlimited = !trackStock
		out = append(out, l)
		ids = append(ids, l.ProductID)
	}
	if e := rows.Err(); e != nil {
		return nil, e
	}

	// Зинаҳои нархи яклухт. Бо ЯК дархост барои ҳамаи молҳо — вагарна
	// сабади 30-мол 31 дархост дар дохили транзаксияи кушода медод.
	//
	// Нархи зина бояд маҳз ин ҷо гирифта шавад. Агар экран нархи яклухтро
	// нишон диҳад ва сервер нархи чаканаро гирад, харидор бештар
	// мепардозад — ва ин ҳамон навъи хатоест, ки боварии ӯро мешиканад.
	tiers := loadTiersFor(tx, ids)
	for i := range out {
		if t := tiers[out[i].ProductID]; len(t) > 0 {
			out[i].UnitPrice = priceForQty(t, out[i].UnitPrice, out[i].Qty)
		}
	}
	return out, nil
}

// existingCheckout — фармоиши пештараи ҳамин калид.
func existingCheckout(uid, key string) (string, float64, bool) {
	var oid string
	var total float64
	err := db.DB.QueryRow(`SELECT k.order_id, o.total FROM checkout_keys k
		JOIN orders o ON o.id = k.order_id
		WHERE k.key=$1 AND k.user_id=$2`, key, uid).Scan(&oid, &total)
	if err != nil {
		return "", 0, false
	}
	return oid, total, true
}

// checkCouponInTx — купонро дар дохили транзаксия месанҷад.
//
// Маҳдудияти ҳар корбар нав аст: пештар танҳо `used_count`-и умумӣ буд,
// пас як корбар метавонист ҳамон купонро бефосила истифода кунад.
func checkCouponInTx(tx *sql.Tx, uid, raw string) (int, string) {
	code := strings.ToUpper(strings.TrimSpace(raw))
	if code == "" {
		return 0, ""
	}
	var disc, maxUses, used, perUser int
	var active bool
	var expires sql.NullTime
	err := tx.QueryRow(`SELECT discount_percent, max_uses, used_count, is_active,
			expires_at, COALESCE(per_user_limit,1)
		FROM coupons WHERE UPPER(code)=$1 FOR UPDATE`, code).
		Scan(&disc, &maxUses, &used, &active, &expires, &perUser)
	if err != nil || !active {
		return 0, ""
	}
	if expires.Valid && expires.Time.Before(time.Now()) {
		return 0, ""
	}
	if maxUses > 0 && used >= maxUses {
		return 0, ""
	}
	if perUser > 0 {
		var mine int
		tx.QueryRow(`SELECT COUNT(*) FROM coupon_redemptions WHERE code=$1 AND user_id=$2`,
			code, uid).Scan(&mine)
		if mine >= perUser {
			return 0, ""
		}
	}
	if disc < 0 {
		disc = 0
	}
	if disc > 100 {
		disc = 100
	}
	return disc, code
}

// afterCheckout — огоҳиҳои баъди фармоиш.
func afterCheckout(orderID, uid string, lines []checkoutLine, method string, tot checkoutTotals) {
	short := shortID(orderID)
	title := "Фармоиш қабул шуд"
	body := "Фармоиши #" + short + " қабул шуд"
	if method == "wallet" {
		body = "Фармоиши #" + short + " бо ҳамён пардохт шуд"
	}
	db.DB.Exec(`INSERT INTO notifications(id,user_id,type,title,body,ref_id)
		VALUES($1,$2,'order',$3,$4,$5)`, uuid.NewString(), uid, title, body, orderID)
	pushToUser(uid, title, body)

	notifySellersOfNewOrder(orderID)

	// Моле, ки бо ҳамин фармоиш тамом шуд — аз фурӯшанда мепурсем «боз ҳаст?».
	for _, l := range lines {
		if shouldAskSoldOut(!l.Unlimited, l.Stock-l.Qty) {
			notifySoldOut(l.ProductID)
		}
	}
}
