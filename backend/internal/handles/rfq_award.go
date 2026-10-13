package handlers

import (
	"net/http"
	"tajikshop/internal/db"
	"tajikshop/internal/utils"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// ═══════════════════════════════════════════════════════════════════════════
//  Қабули пешниҳод → фармоиш
// ═══════════════════════════════════════════════════════════════════════════
//
// Ин ҷои аз ҳама ҳассоси RFQ аст: ин ҷо гуфтушунид ба уҳдадории пулӣ
// табдил меёбад. Се қоида, ва ҳар сеяш аз сабаб меоянд:
//
//  1. НАРХ АЗ ПЕШНИҲОД гирифта мешавад, на аз `products.price`.
//     Маҳз барои ҳамин тамоми RFQ вуҷуд дорад. Агар нарх аз маҳсулот
//     гирифта шавад, гуфтушунид маъно надорад.
//
//  2. ПЕШНИҲОД БОЯД КОРШОЯМ БОШАД. Мӯҳлати он гузашта бошад — рад
//     мешавад. Бе ин харидор метавонад баъди ним сол «қабул» занад ва
//     фурӯшандаро ба нархи кӯҳна маҷбур кунад.
//
//  3. ЯК ДАРХОСТ = ЯК ФАРМОИШ. Қабул дар транзаксия бо қулфи дархост
//     мешавад, ва ҳолати он ба 'awarded' мегузарад. Ду зеркунии тугма
//     ду фармоиш намесозад.
//
// Фармоиш БЕ МАҲСУЛОТ сохта мешавад: дар RFQ харидор моли мушаххасро
// интихоб намекардааст — ӯ «500 кг орд» хостааст. Пас `order_items`
// сатри маҳсулот надорад, вале `order_sellers` ҳаст, ва фурӯшанда
// фармоишро дар панели худаш бо ҳамон қадамҳо мебинад.

// Award — POST /quotes/:id/accept  (харидор)
func (h *RFQHandler) Award(c *gin.Context) {
	uid := utils.UserID(c)
	quoteID := c.Param("id")

	var in struct {
		AddressID string `json:"address_id"`
		Note      string `json:"note"`
	}
	c.ShouldBindJSON(&in)

	tx, err := db.DB.Begin()
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, "Қабул нашуд")
		return
	}
	committed := false
	defer func() {
		if !committed {
			tx.Rollback()
		}
	}()

	// Пешниҳод + дархост бо як дархост, ва ҳарду қулф мешаванд.
	var rfqID, sellerID, qStatus, rStatus, buyerID, title, unit string
	var unitPrice, shipping float64
	var minQty, qty, leadDays int
	var validUntil, closesAt time.Time
	var validSet bool
	var vu interface{}
	errRow := tx.QueryRow(`SELECT q.rfq_id, q.seller_id, q.status,
			q.unit_price, COALESCE(q.shipping_cost,0), COALESCE(q.min_qty,1),
			COALESCE(q.lead_days,0), q.valid_until,
			r.status, r.buyer_id, r.title, r.quantity, COALESCE(r.unit,'дона'),
			r.closes_at
		FROM rfq_quotes q
		JOIN rfqs r ON r.id = q.rfq_id
		WHERE q.id=$1
		FOR UPDATE OF q, r`, quoteID).
		Scan(&rfqID, &sellerID, &qStatus, &unitPrice, &shipping, &minQty,
			&leadDays, &vu, &rStatus, &buyerID, &title, &qty, &unit, &closesAt)
	if errRow != nil {
		utils.Err(c, http.StatusNotFound, "Пешниҳод ёфт нашуд")
		return
	}
	if t, ok := vu.(time.Time); ok {
		validUntil, validSet = t, true
	}

	// Танҳо харидори ҳамин дархост қабул карда метавонад.
	if buyerID != uid {
		utils.Err(c, http.StatusForbidden, "Ин дархости шумо нест")
		return
	}
	if rStatus == rfqAwarded {
		utils.Err(c, http.StatusConflict, "Ин дархост аллакай қабулшуда дорад")
		return
	}
	if rStatus == rfqCancelled {
		utils.Err(c, http.StatusConflict, "Дархост бекор шудааст")
		return
	}

	now := time.Now()
	var vuPtr *time.Time
	if validSet {
		vuPtr = &validUntil
	}
	if !quoteUsable(qStatus, vuPtr, now) {
		utils.Err(c, http.StatusConflict,
			"Мӯҳлати ин пешниҳод гузаштааст ё он гирифта шудааст")
		return
	}
	// Ҳадди ақали фурӯшанда аз шумораи дархост зиёд набошад. Ин ҳангоми
	// додани пешниҳод санҷида шуд, вале харидор метавонад баъд
	// шумораро... — ҳоло наметавонад, вале санҷиш арзон аст ва рӯзе
	// таҳрири дархост илова мешавад.
	if minQty > qty {
		utils.Err(c, http.StatusConflict,
			"Ҳадди ақали фурӯшанда аз шумораи дархост зиёд аст")
		return
	}

	unitDirams := toDirams(unitPrice)
	shipDirams := toDirams(shipping)
	total := quoteTotal(unitDirams, qty, shipDirams)
	if total <= 0 {
		utils.Err(c, http.StatusConflict, "Ҷамъи пешниҳод ҳисоб нашуд")
		return
	}

	var addr interface{}
	if in.AddressID != "" {
		addr = in.AddressID
	}
	note := in.Note
	if len(note) > 1000 {
		note = note[:1000]
	}
	if note == "" {
		note = "Аз дархости нарх: " + title
	}

	orderID := uuid.NewString()
	if _, e := tx.Exec(`INSERT INTO orders
		(id,user_id,address_id,total,note,payment_method,discount,
		 fulfilment,delivery_fee,status,rfq_quote_id)
		VALUES($1,$2,$3,$4,$5,'dc',0,'delivery',$6,'pending',$7)`,
		orderID, uid, addr, toSomoni(total), note,
		toSomoni(shipDirams), quoteID); e != nil {
		utils.Err(c, http.StatusInternalServerError, "Фармоиш сохта нашуд")
		return
	}

	// Зер-фармоиши фурӯшанда — то ӯ ҳамон қадамҳоро дошта бошад
	// (қабул → фиристодам → супоридам) ва ҳимояи харидор кор кунад.
	if _, e := tx.Exec(`INSERT INTO order_sellers(id,order_id,seller_id,status,subtotal)
		VALUES($1,$2,$3,'pending',$4)`,
		uuid.NewString(), orderID, sellerID,
		toSomoni(unitDirams*int64(qty))); e != nil {
		utils.Err(c, http.StatusInternalServerError, "Зер-фармоиш сохта нашуд")
		return
	}

	// Сатри мол бе `product_id`: дар RFQ харидор моли мушаххасро
	// интихоб накардааст. Ном ва нарх ҳамчун СУРАТ нигоҳ дошта мешаванд.
	if _, e := tx.Exec(`INSERT INTO order_items
		(id,order_id,product_id,seller_id,title,unit,quantity,price)
		VALUES($1,$2,NULL,$3,$4,$5,$6,$7)`,
		uuid.NewString(), orderID, sellerID, title, unit, qty,
		toSomoni(unitDirams)); e != nil {
		utils.Err(c, http.StatusInternalServerError, "Моли фармоиш сабт нашуд")
		return
	}

	// Пешниҳоди қабулшуда ва рақибон.
	if _, e := tx.Exec(`UPDATE rfq_quotes SET status=$1 WHERE id=$2`,
		quoteAccepted, quoteID); e != nil {
		utils.Err(c, http.StatusInternalServerError, "Пешниҳод нав нашуд")
		return
	}
	if _, e := tx.Exec(`UPDATE rfq_quotes SET status=$1
		WHERE rfq_id=$2 AND id <> $3 AND status=$4`,
		quoteRejected, rfqID, quoteID, quoteActive); e != nil {
		utils.Err(c, http.StatusInternalServerError, "Пешниҳодҳои дигар нав нашуданд")
		return
	}
	if _, e := tx.Exec(`UPDATE rfqs SET status=$1, awarded_quote_id=$2,
		updated_at=NOW() WHERE id=$3`, rfqAwarded, quoteID, rfqID); e != nil {
		utils.Err(c, http.StatusInternalServerError, "Дархост нав нашуд")
		return
	}

	if e := tx.Commit(); e != nil {
		utils.Err(c, http.StatusInternalServerError, "Қабул нигоҳ дошта нашуд")
		return
	}
	committed = true

	// Огоҳиҳо берун аз транзаксия: агар яктааш афтад, фармоиш бояд дуруст монад.
	short := shortID(orderID)
	logOrderEvent(orderID, "pending", "Аз дархости нарх")

	winTitle := "Пешниҳоди шумо қабул шуд 🎉"
	winBody := "Фармоиши #" + short + " сохта шуд: " + title
	db.DB.Exec(`INSERT INTO notifications(id,user_id,type,title,body,ref_id)
		VALUES($1,$2,'order',$3,$4,$5)`,
		uuid.NewString(), sellerID, winTitle, winBody, orderID)
	pushToUser(sellerID, winTitle, winBody)

	// Фурӯшандагони радшуда низ бояд бидонанд — вагарна онҳо абадӣ
	// интизори ҷавоб мемонанд.
	notifyRejectedSellers(rfqID, sellerID, title)

	utils.Created(c, gin.H{
		"order_id":   orderID,
		"rfq_id":     rfqID,
		"quote_id":   quoteID,
		"seller_id":  sellerID,
		"total":      toSomoni(total),
		"unit_price": unitPrice,
		"quantity":   qty,
		"lead_days":  leadDays,
	})
}

// notifyRejectedSellers — фурӯшандагоне, ки пешниҳодашон қабул нашуд.
//
// Бе ин онҳо абадӣ интизори ҷавоб мемонанд ва дигар ба дархостҳо
// ҷавоб намедиҳанд — ва он гоҳ тамоми RFQ мемурад.
func notifyRejectedSellers(rfqID, winnerID, title string) {
	rows, err := db.DB.Query(`SELECT DISTINCT seller_id FROM rfq_quotes
		WHERE rfq_id=$1 AND seller_id <> $2 AND status=$3`,
		rfqID, winnerID, quoteRejected)
	if err != nil || rows == nil {
		return
	}
	var ids []string
	for rows.Next() {
		var id string
		if e := rows.Scan(&id); e == nil && id != "" {
			ids = append(ids, id)
		}
	}
	rows.Close()

	t := "Дархост баста шуд"
	b := "«" + title + "» — ин бор пешниҳоди дигар интихоб шуд"
	for _, id := range ids {
		db.DB.Exec(`INSERT INTO notifications(id,user_id,type,title,body,ref_id)
			VALUES($1,$2,'rfq',$3,$4,$5)`, uuid.NewString(), id, t, b, rfqID)
		pushToUser(id, t, b)
	}
}

// StartRFQSweeper — дархостҳои мӯҳлаташ гузаштаро мепӯшад.
//
// Ин барои ТОЗАГИИ МАЪЛУМОТ аст, на барои дурустӣ: `canQuote` ва
// `effectiveRFQStatus` мӯҳлатро ҳамеша худашон ба назар мегиранд, пас
// ҳатто агар sweeper умуман кор накунад, ягон пешниҳод ба дархости
// мӯҳлаташ гузашта намеравад.
func StartRFQSweeper() {
	go func() {
		time.Sleep(3 * time.Minute)
		for {
			db.DB.Exec(`UPDATE rfqs SET status='closed', updated_at=NOW()
				WHERE status='open' AND closes_at < NOW()`)
			// Пешниҳодҳои мӯҳлаташон гузашта низ.
			db.DB.Exec(`UPDATE rfq_quotes SET status=$1
				WHERE status=$2 AND valid_until IS NOT NULL
				  AND valid_until < NOW()`, quoteWithdrawn, quoteActive)
			time.Sleep(time.Hour)
		}
	}()
}
