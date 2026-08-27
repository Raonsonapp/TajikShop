package handlers

import (
	"net/http"
	"strconv"
	"strings"
	"tajikshop/internal/db"
	"tajikshop/internal/utils"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// ── Ҳимояи харидор (Buyer Protection, мисли Alibaba) ────────────────────────
//
// Мушкили пештара:
//   • фурӯшанда ҳолати фармоишро иваз карда наметавонист (танҳо админ), пас
//     харидор намедонист моли ӯ фиристода шуд ё не;
//   • пул дар escrow танҳо ҳангоми пахши «Тасдиқ»-и харидор озод мешуд — агар
//     харидор фаромӯш кунад, фурӯшанда ҳеҷ гоҳ пул намегирифт.
//
// Ҳалли ин ҷо: фурӯшанда қадамҳоро қайд мекунад (қабул → фиристода шуд →
// супорида шуд), ҳар қадам ба харидор push мефиристад ва дар timeline сабт
// мешавад. Пас аз супоридан мӯҳлати ҳимоя (protectionDays) сар мешавад: дар
// ин муддат харидор метавонад шикоят/бозгашт кунад. Агар шикоят накунад, пул
// худкор ба фурӯшанда мегузарад.

// Мӯҳлати ҳимояи харидор пас аз супоридани мол.
const protectionDays = 7

// Қадамҳои иҷозатдодашуда барои фурӯшанда.
var sellerStatusFlow = map[string][]string{
	"pending":    {"processing", "cancelled"},
	"paid":       {"processing", "cancelled"},
	"processing": {"shipped", "cancelled"},
	"shipped":    {"delivered"},
}

func statusTitleTJ(s string) string {
	switch s {
	case "processing":
		return "Фармоиш қабул шуд"
	case "shipped":
		return "Мол фиристода шуд"
	case "delivered":
		return "Мол супорида шуд"
	case "cancelled":
		return "Фармоиш бекор шуд"
	default:
		return "Ҳолати фармоиш нав шуд"
	}
}

func statusBodyTJ(s string, short string) string {
	switch s {
	case "processing":
		return "Фурӯшанда фармоиши #" + short + "-ро қабул кард"
	case "shipped":
		return "Фармоиши #" + short + " дар роҳ аст"
	case "delivered":
		return "Фармоиши #" + short + " супорида шуд. Лутфан гирифтанро тасдиқ кунед"
	case "cancelled":
		return "Фармоиши #" + short + " бекор карда шуд"
	default:
		return "Фармоиши #" + short
	}
}

// logOrderEvent — қадамро ба timeline илова мекунад.
func logOrderEvent(oid, status, note string) {
	db.DB.Exec(`INSERT INTO order_events(id,order_id,status,note) VALUES($1,$2,$3,$4)`,
		uuid.NewString(), oid, status, note)
}

// SellerUpdateOrderStatus — POST /seller/orders/:id/status
// Фурӯшанда танҳо фармоишеро тағйир дода метавонад, ки маҳсулоти ӯ дар он бошад.
func (h *OrderHandler) SellerUpdateOrderStatus(c *gin.Context) {
	uid := utils.UserID(c)
	oid := c.Param("id")
	var in struct {
		Status       string `json:"status"`
		TrackingCode string `json:"tracking_code"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}
	next := strings.TrimSpace(strings.ToLower(in.Status))

	// Фармоиш бояд маҳсулоти ҳамин фурӯшандаро дошта бошад.
	var owns bool
	db.DB.QueryRow(`SELECT EXISTS(
		SELECT 1 FROM order_items oi JOIN products p ON p.id=oi.product_id
		WHERE oi.order_id=$1 AND p.seller_id=$2)`, oid, uid).Scan(&owns)
	if !owns {
		utils.Err(c, http.StatusForbidden, "Ин фармоиши шумо нест")
		return
	}

	var cur, buyer string
	if err := db.DB.QueryRow(`SELECT status,user_id FROM orders WHERE id=$1`, oid).
		Scan(&cur, &buyer); err != nil {
		utils.Err(c, http.StatusNotFound, "order not found")
		return
	}

	allowed := false
	for _, s := range sellerStatusFlow[cur] {
		if s == next {
			allowed = true
			break
		}
	}
	if !allowed {
		utils.Err(c, http.StatusBadRequest, "Ин тағйирот аз ҳолати «"+cur+"» имконнопазир аст")
		return
	}

	now := time.Now()
	switch next {
	case "shipped":
		db.DB.Exec(`UPDATE orders SET status=$1, shipped_at=$2, tracking_code=$3, updated_at=$2
			WHERE id=$4`, next, now, strings.TrimSpace(in.TrackingCode), oid)
	case "delivered":
		// Мӯҳлати ҳимояи харидор аз ҳамин лаҳза сар мешавад.
		until := now.AddDate(0, 0, protectionDays)
		db.DB.Exec(`UPDATE orders SET status=$1, delivered_at=$2, protect_until=$3, updated_at=$2
			WHERE id=$4`, next, now, until, oid)
	default:
		db.DB.Exec(`UPDATE orders SET status=$1, updated_at=$2 WHERE id=$3`, next, now, oid)
	}

	short := shortID(oid)
	logOrderEvent(oid, next, strings.TrimSpace(in.TrackingCode))
	db.DB.Exec(`INSERT INTO notifications(id,user_id,type,title,body,ref_id)
		VALUES($1,$2,'order',$3,$4,$5)`,
		uuid.NewString(), buyer, statusTitleTJ(next), statusBodyTJ(next, short), oid)
	pushToUser(buyer, statusTitleTJ(next), statusBodyTJ(next, short))

	utils.OK(c, gin.H{"status": next})
}

// OrderTimeline — GET /orders/:id/timeline
// Харидор (ё фурӯшандаи ҳамон фармоиш) қадамҳоро мебинад.
func (h *OrderHandler) OrderTimeline(c *gin.Context) {
	uid := utils.UserID(c)
	oid := c.Param("id")

	var allowed bool
	db.DB.QueryRow(`SELECT EXISTS(
		SELECT 1 FROM orders o WHERE o.id=$1 AND (
			o.user_id=$2 OR EXISTS(
				SELECT 1 FROM order_items oi JOIN products p ON p.id=oi.product_id
				WHERE oi.order_id=o.id AND p.seller_id=$2)))`, oid, uid).Scan(&allowed)
	if !allowed {
		utils.Err(c, http.StatusForbidden, "no access")
		return
	}

	type event struct {
		Status    string    `json:"status"`
		Note      string    `json:"note"`
		CreatedAt time.Time `json:"created_at"`
	}
	rows, _ := db.DB.Query(`SELECT status,COALESCE(note,''),created_at
		FROM order_events WHERE order_id=$1 ORDER BY created_at`, oid)
	events := []event{}
	if rows != nil {
		defer rows.Close()
		for rows.Next() {
			var e event
			rows.Scan(&e.Status, &e.Note, &e.CreatedAt)
			events = append(events, e)
		}
	}

	var protectUntil *time.Time
	var tracking string
	var status string
	var pu, da interface{}
	db.DB.QueryRow(`SELECT status,COALESCE(tracking_code,''),protect_until,delivered_at
		FROM orders WHERE id=$1`, oid).Scan(&status, &tracking, &pu, &da)
	if t, ok := pu.(time.Time); ok {
		protectUntil = &t
	}

	daysLeft := 0
	if protectUntil != nil {
		if d := int(time.Until(*protectUntil).Hours() / 24); d > 0 {
			daysLeft = d
		}
	}

	utils.OK(c, gin.H{
		"status":           status,
		"events":           events,
		"tracking_code":    tracking,
		"protect_until":    protectUntil,
		"protection_days":  protectionDays,
		"days_left":        daysLeft,
		"protection_active": protectUntil != nil && time.Now().Before(*protectUntil),
	})
}

// releaseExpiredEscrow — фармоишҳоеро, ки мӯҳлати ҳимояашон гузашт ва харидор
// шикоят накард, ба «completed» мебарад ва пулро ба фурӯшанда(он) медиҳад.
//
// Бе ин, пул дар escrow абадӣ мемонд, агар харидор «Тасдиқ»-ро напахшад.
func releaseExpiredEscrow() {
	rows, err := db.DB.Query(`SELECT id,user_id,total,COALESCE(payment_method,'dc')
		FROM orders
		WHERE status='delivered'
		  AND protect_until IS NOT NULL
		  AND protect_until < NOW()
		  AND COALESCE(auto_released,false)=false
		LIMIT 200`)
	if err != nil || rows == nil {
		return
	}
	type ord struct {
		id, buyer, method string
		total             float64
	}
	var list []ord
	for rows.Next() {
		var o ord
		rows.Scan(&o.id, &o.buyer, &o.total, &o.method)
		list = append(list, o)
	}
	rows.Close()

	for _, o := range list {
		// Агар бозгашти ҳалнашуда бошад, пулро озод намекунем — ихтилоф аввал ҳал шавад.
		var openReturn bool
		db.DB.QueryRow(`SELECT EXISTS(SELECT 1 FROM returns
			WHERE order_id=$1 AND status IN ('pending','approved'))`, o.id).Scan(&openReturn)
		if openReturn {
			continue
		}
		settleOrder(o.id, o.buyer, o.total, o.method, true)
	}
}

// StartEscrowSweeper — ҳар соат escrow-и мӯҳлаташ гузаштаро озод мекунад.
func StartEscrowSweeper() {
	go func() {
		// Каме сабр — то пойгоҳи додаҳо тайёр шавад.
		time.Sleep(30 * time.Second)
		releaseExpiredEscrow()
		t := time.NewTicker(time.Hour)
		defer t.Stop()
		for range t.C {
			releaseExpiredEscrow()
		}
	}()
}

// settleOrder — фармоишро анҷом медиҳад: cashback ба харидор ва озод кардани
// маблағ аз escrow ба фурӯшанда(он).
//
// Ҳам «Тасдиқи харидор» ва ҳам озодкунии худкор аз ҳамин ҷо мегузаранд, то
// мантиқи пул дар ду ҷо такрор нашавад ва фарқ накунад.
func settleOrder(oid, buyer string, total float64, method string, auto bool) {
	tx, err := db.DB.Begin()
	if err != nil {
		return
	}
	// Танҳо агар ҳанӯз анҷом наёфта бошад (муҳофизат аз пардохти дукарата).
	res, err := tx.Exec(`UPDATE orders SET status='completed', auto_released=$1, updated_at=$2
		WHERE id=$3 AND status NOT IN ('completed','cancelled')`, auto, time.Now(), oid)
	if err != nil {
		tx.Rollback()
		return
	}
	if n, _ := res.RowsAffected(); n == 0 {
		tx.Rollback()
		return
	}

	// 💸 Cashback ба харидор.
	if cb := total * (cashbackPercent() + float64(loyaltyBonusPercent(buyer))) / 100; cb > 0 {
		tx.Exec(`UPDATE users SET wallet_balance=COALESCE(wallet_balance,0)+$1 WHERE id=$2`, cb, buyer)
		tx.Exec(`INSERT INTO wallet_transactions(id,user_id,amount,type,status,note)
			VALUES($1,$2,$3,'cashback','completed','💸 Cashback аз харид')`,
			uuid.NewString(), buyer, cb)
	}

	// Маблағро мутаносибан ба фурӯшандагон медиҳем (танҳо барои пардохти ҳамён,
	// чунки танҳо он дар escrow нигоҳ дошта мешавад).
	if method == "wallet" {
		rows, _ := tx.Query(`SELECT p.seller_id, SUM(oi.price*oi.quantity)
			FROM order_items oi JOIN products p ON p.id=oi.product_id
			WHERE oi.order_id=$1 GROUP BY p.seller_id`, oid)
		type pay struct {
			seller string
			amount float64
		}
		var pays []pay
		var sum float64
		if rows != nil {
			for rows.Next() {
				var s string
				var a float64
				rows.Scan(&s, &a)
				pays = append(pays, pay{s, a})
				sum += a
			}
			rows.Close()
		}
		for _, p := range pays {
			if p.seller == "" || sum <= 0 {
				continue
			}
			credit := total * (p.amount / sum)
			tx.Exec(`UPDATE users SET wallet_balance=COALESCE(wallet_balance,0)+$1 WHERE id=$2`, credit, p.seller)
			tx.Exec(`INSERT INTO wallet_transactions(id,user_id,amount,type,status,note)
				VALUES($1,$2,$3,'sale','completed',$4)`,
				uuid.NewString(), p.seller, credit, "Фурӯш #"+shortID(oid))
			tx.Exec(`INSERT INTO notifications(id,user_id,type,title,body)
				VALUES($1,$2,'order','Фурӯш анҷом ёфт','Маблағ ба ҳамёни шумо илова шуд')`,
				uuid.NewString(), p.seller)
		}
		if err := tx.Commit(); err != nil {
			return
		}
		// Push танҳо пас аз commit — то паёми дурӯғ нафиристем.
		for _, p := range pays {
			if p.seller != "" {
				pushToUser(p.seller, "Фурӯш анҷом ёфт", "Маблағ ба ҳамёни шумо илова шуд")
			}
		}
	} else {
		if err := tx.Commit(); err != nil {
			return
		}
	}

	logOrderEvent(oid, "completed", map[bool]string{true: "Мӯҳлати ҳимоя гузашт — худкор", false: ""}[auto])
}

// CartSellers — GET /cart/sellers
//
// Фурӯшанда(гон)-и маҳсулоти сабади ҳозира бо корти пардохт ва id-и онҳо.
// Пештар дар экрани пардохт рақами қалбакии «+992 XX XXX XXXX» навишта
// мешуд — харидор ба куҷо пул фиристоданашро намедонист. Ҳоло корти воқеӣ
// нишон дода мешавад ва харидор метавонад бо фурӯшанда чат кунад.
//
// Танҳо фурӯшандагоне бармегарданд, ки маҳсулоташон дар сабади ҳамин
// корбар ҳастанд — рӯйхати умумии кортҳо кушода намешавад.
func (h *OrderHandler) CartSellers(c *gin.Context) {
	uid := utils.UserID(c)
	rows, err := db.DB.Query(`
		SELECT DISTINCT u.id, u.name, COALESCE(u.shop_name,''),
			COALESCE(u.card_number,''), COALESCE(u.card_holder,''),
			COALESCE(u.shop_phone,'')
		FROM cart_items ci
		JOIN products p ON p.id = ci.product_id
		JOIN users u    ON u.id = p.seller_id
		WHERE ci.user_id = $1`, uid)
	if err != nil || rows == nil {
		utils.OK(c, []gin.H{})
		return
	}
	defer rows.Close()

	out := []gin.H{}
	for rows.Next() {
		var id, name, shop, card, holder, phone string
		rows.Scan(&id, &name, &shop, &card, &holder, &phone)
		out = append(out, gin.H{
			"seller_id":   id,
			"name":        name,
			"shop_name":   shop,
			"card_number": card,
			"card_holder": holder,
			"phone":       phone,
			"has_card":    strings.TrimSpace(card) != "",
		})
	}
	utils.OK(c, out)
}

// notifySellersOfNewOrder — ба ҳар фурӯшандаи фармоиш хабар медиҳад, ки
// харидор маҳсулот ва маблағро интихоб кард.
//
// Бе ин фурӯшанда то он даме ки худаш барномаро накушояд, аз фармоиш
// бехабар мемонад.
func notifySellersOfNewOrder(orderID string) {
	rows, err := db.DB.Query(`
		SELECT p.seller_id, COUNT(*), COALESCE(SUM(oi.price*oi.quantity),0)
		FROM order_items oi JOIN products p ON p.id = oi.product_id
		WHERE oi.order_id = $1
		GROUP BY p.seller_id`, orderID)
	if err != nil || rows == nil {
		return
	}
	type row struct {
		seller string
		items  int
		sum    float64
	}
	var list []row
	for rows.Next() {
		var r row
		rows.Scan(&r.seller, &r.items, &r.sum)
		list = append(list, r)
	}
	rows.Close()

	short := shortID(orderID)
	for _, r := range list {
		if r.seller == "" {
			continue
		}
		title := "Фармоиши нав 🛒"
		body := "Фармоиши #" + short + ": " +
			strconv.Itoa(r.items) + " ашё, " +
			strconv.FormatFloat(r.sum, 'f', 0, 64) + " сом."
		db.DB.Exec(`INSERT INTO notifications(id,user_id,type,title,body,ref_id)
			VALUES($1,$2,'order',$3,$4,$5)`,
			uuid.NewString(), r.seller, title, body, orderID)
		pushToUser(r.seller, title, body)
	}
}

// RateSeller — POST /orders/:id/rate-seller
// Харидор пас аз гирифтани мол ба фурӯшанда аз 1 то 10 баҳо медиҳад.
func (h *OrderHandler) RateSeller(c *gin.Context) {
	uid := utils.UserID(c)
	oid := c.Param("id")
	var in struct {
		Score   int    `json:"score"`
		Comment string `json:"comment"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}
	if in.Score < 1 || in.Score > 10 {
		utils.Err(c, http.StatusBadRequest, "Баҳо бояд аз 1 то 10 бошад")
		return
	}

	// Фармоиш бояд аз ҳамин харидор бошад ва мол супорида шуда бошад —
	// то касе бе харид баҳо нагузорад.
	var status string
	if err := db.DB.QueryRow(`SELECT status FROM orders WHERE id=$1 AND user_id=$2`,
		oid, uid).Scan(&status); err != nil {
		utils.Err(c, http.StatusNotFound, "order not found")
		return
	}
	if status != "delivered" && status != "completed" {
		utils.Err(c, http.StatusBadRequest, "Баъд аз гирифтани мол баҳо гузошта мешавад")
		return
	}

	rows, err := db.DB.Query(`SELECT DISTINCT p.seller_id
		FROM order_items oi JOIN products p ON p.id=oi.product_id
		WHERE oi.order_id=$1`, oid)
	if err != nil || rows == nil {
		utils.Err(c, http.StatusInternalServerError, "sellers not found")
		return
	}
	var sellers []string
	for rows.Next() {
		var s string
		rows.Scan(&s)
		if s != "" {
			sellers = append(sellers, s)
		}
	}
	rows.Close()

	for _, s := range sellers {
		db.DB.Exec(`INSERT INTO seller_ratings(id,seller_id,buyer_id,order_id,score,comment)
			VALUES($1,$2,$3,$4,$5,$6)
			ON CONFLICT (seller_id,buyer_id,order_id)
			DO UPDATE SET score=EXCLUDED.score, comment=EXCLUDED.comment`,
			uuid.NewString(), s, uid, oid, in.Score, strings.TrimSpace(in.Comment))
	}
	utils.OK(c, gin.H{"rated": true, "score": in.Score})
}

// SellerRating — GET /users/:id/rating
// Баҳои миёна ва шумораи баҳоҳои фурӯшанда (оммавӣ — нишони эътимод).
func (h *OrderHandler) SellerRating(c *gin.Context) {
	sid := c.Param("id")
	var avg float64
	var count int
	db.DB.QueryRow(`SELECT COALESCE(AVG(score),0), COUNT(*)
		FROM seller_ratings WHERE seller_id=$1`, sid).Scan(&avg, &count)

	// Шарҳҳои охирин — фурӯшанда бояд бубинад, ки чаро баҳо чунин аст.
	reviews := []gin.H{}
	rows, _ := db.DB.Query(`SELECT r.score,COALESCE(r.comment,''),r.created_at,
		COALESCE(u.name,''),COALESCE(u.avatar_url,'')
		FROM seller_ratings r LEFT JOIN users u ON u.id=r.buyer_id
		WHERE r.seller_id=$1 ORDER BY r.created_at DESC LIMIT 20`, sid)
	if rows != nil {
		defer rows.Close()
		for rows.Next() {
			var score int
			var comment, name, avatar string
			var created time.Time
			rows.Scan(&score, &comment, &created, &name, &avatar)
			reviews = append(reviews, gin.H{
				"score": score, "comment": comment, "created_at": created,
				"buyer_name": name, "buyer_avatar": avatar,
			})
		}
	}

	utils.OK(c, gin.H{
		"seller_id": sid,
		"average":   avg,
		"count":     count,
		"reviews":   reviews,
	})
}
