package handlers

import (
	"database/sql"
	"strings"
	"time"
)

// ═══════════════════════════════════════════════════════════════════════════
//  Ҳолати фармоиш ҳангоми чанд фурӯшанда
// ═══════════════════════════════════════════════════════════════════════════
//
// Камбудии аслӣ: дар сабад моли ду фурӯшанда буд, вале `orders` ЯК сатр
// буд ва ЯК `status` дошт. `SellerUpdateOrderStatus` соҳибиятро месанҷид
// («фармоиш моли ман дорад?») ва баъд `UPDATE orders SET status=...`
// мекард — яъне ҳолати ТАМОМИ фармоишро.
//
// Натиҷа: фурӯшандаи A «фиристодам» мезад, ва моли ҳанӯз нафиристодаи
// фурӯшандаи B ҳам «фиристода шуд» мешуд. Боз бадтар: `protect_until`
// барои ҳар ду сар мешуд, пас мӯҳлати шикояти харидор барои моли ҳанӯз
// нагирифта мегузашт.
//
// Ҳал: ҳар фурӯшанда сатри худро дар `order_sellers` дорад ва танҳо
// ҳамонро иваз мекунад. Ҳолати умумии `orders` АЗ ОНҲО ҲИСОБ мешавад.
//
// Чаро `orders.status` боқӣ мемонад, на нест мешавад: тамоми барнома,
// админка, огоҳиҳо ва ҳисоботҳо онро мехонанд. Иваз кардани ҳамаи он
// якбора хатари хеле калон аст. Пас `orders.status` мемонад, вале ҳоло
// ҳисобшуда аст — на он чизе, ки охирин фурӯшанда навишт.

// Дараҷаи пешрафт. Ҳолати умумӣ = КАМТАРИН дараҷа дар байни
// фурӯшандагон: агар яке ҳанӯз нафиристода бошад, фармоиш «фиристода
// шуд» нест.
var statusRank = map[string]int{
	"pending":    0,
	"paid":       1,
	"processing": 2,
	"shipped":    3,
	"delivered":  4,
	"completed":  5,
}

// aggregateOrderStatus — ҳолати умумӣ аз ҳолати фурӯшандагон.
//
// Қоидаҳо:
//   - фурӯшандаи бекоркарда ҳисоб намешавад (моли ӯ дигар нест);
//   - агар ҲАМА бекор шуда бошанд → фармоиш бекор аст;
//   - вагарна камтарин дараҷа;
//   - ҳолати нофаҳмо (аз версияи кӯҳна ё админ) ҳамчун «pending» —
//     яъне дараҷаи сифр, то фармоиш ҳеҷ гоҳ «тайёр» дар назар нарасад.
func aggregateOrderStatus(sellerStatuses []string) string {
	if len(sellerStatuses) == 0 {
		return ""
	}
	best := ""
	bestRank := 999
	active := 0
	for _, raw := range sellerStatuses {
		s := strings.TrimSpace(strings.ToLower(raw))
		if s == "cancelled" {
			continue
		}
		active++
		r, ok := statusRank[s]
		if !ok {
			s, r = "pending", 0
		}
		if r < bestRank {
			bestRank, best = r, s
		}
	}
	if active == 0 {
		return "cancelled"
	}
	return best
}

// nextSellerStatuses — қадамҳои иҷозатдодашуда аз ҳолати ҳозира.
//
// Ин ҳамон ҷадвали `sellerStatusFlow` аст, вале ҳоло аз рӯи ҳолати ХУДИ
// ФУРӮШАНДА санҷида мешавад, на аз рӯи ҳолати умумии фармоиш. Фарқ
// амалӣ аст: пештар, агар фурӯшандаи B фармоишро «processing» карда
// бошад, ҳолати умумӣ «processing» мешуд ва фурӯшандаи A метавонист
// фавран «shipped» занад — бе он ки худаш фармоишро қабул карда бошад.
func nextSellerStatuses(cur string) []string {
	return sellerStatusFlow[strings.TrimSpace(strings.ToLower(cur))]
}

// sellerCanMoveTo — оё ин қадам аз ҳолати ҳозира мумкин аст?
func sellerCanMoveTo(cur, next string) bool {
	next = strings.TrimSpace(strings.ToLower(next))
	for _, s := range nextSellerStatuses(cur) {
		if s == next {
			return true
		}
	}
	return false
}

// ── Бо база ──────────────────────────────────────────────────────────────

// recomputeOrderStatus — ҳолати умумии фармоишро аз зер-фармоишҳо ҳисоб
// карда менависад.
//
// Вақтҳо (`shipped_at`, `delivered_at`, `protect_until`) ТАНҲО вақте
// гузошта мешаванд, ки ҲАМА фурӯшандагон ба он қадам расида бошанд.
//
// Маҳз ин ҷои муҳим аст: мӯҳлати ҳимояи харидор (`protect_until`) бояд
// аз лаҳзаи супоридани ОХИРИН мол сар шавад. Агар он аз аввалин мол сар
// шавад, харидор метавонад мӯҳлати шикоятро барои моле, ки ҳанӯз
// нагирифтааст, гум кунад.
func recomputeOrderStatus(tx *sql.Tx, orderID string, now time.Time) (string, error) {
	rows, err := tx.Query(`SELECT status FROM order_sellers WHERE order_id=$1`, orderID)
	if err != nil {
		return "", err
	}
	var all []string
	for rows.Next() {
		var s string
		if e := rows.Scan(&s); e != nil {
			rows.Close()
			return "", e
		}
		all = append(all, s)
	}
	rows.Close()
	if e := rows.Err(); e != nil {
		return "", e
	}

	parent := aggregateOrderStatus(all)
	if parent == "" {
		// Зер-фармоиш нест — чизе иваз намекунем, то ҳолати ҳозираи
		// фармоишро тасодуфан нашӯем.
		var cur string
		tx.QueryRow(`SELECT status FROM orders WHERE id=$1`, orderID).Scan(&cur)
		return cur, nil
	}

	switch parent {
	case "shipped":
		// Вақти фиристодан = вақти ОХИРИН фурӯшанда.
		_, err = tx.Exec(`UPDATE orders SET status=$1, updated_at=$2,
			shipped_at = COALESCE((SELECT MAX(shipped_at) FROM order_sellers
				WHERE order_id=$3 AND status <> 'cancelled'), $2),
			tracking_code = COALESCE((SELECT tracking_code FROM order_sellers
				WHERE order_id=$3 AND COALESCE(tracking_code,'') <> ''
				ORDER BY shipped_at DESC LIMIT 1), orders.tracking_code)
			WHERE id=$3`, parent, now, orderID)
	case "delivered":
		until := now.AddDate(0, 0, protectionDays)
		_, err = tx.Exec(`UPDATE orders SET status=$1, updated_at=$2,
			delivered_at  = COALESCE((SELECT MAX(delivered_at) FROM order_sellers
				WHERE order_id=$3 AND status <> 'cancelled'), $2),
			protect_until = COALESCE(orders.protect_until, $4)
			WHERE id=$3`, parent, now, orderID, until)
	default:
		// Фармоиши аллакай анҷомёфта ё бекоршударо ақиб намебарем —
		// вагарна пули аллакай додашуда аз нав «дар escrow» мешавад.
		_, err = tx.Exec(`UPDATE orders SET status=$1, updated_at=$2
			WHERE id=$3 AND status NOT IN ('completed')`, parent, now, orderID)
	}
	return parent, err
}

// backfillOrderSeller — зер-фармоишро барои фармоиши КӮҲНА месозад.
//
// Фармоишҳое, ки пеш аз ин тағйирот сохта шудаанд, сатри `order_sellers`
// надоранд. Бе ин фурӯшанда дар онҳо ҳеҷ коре карда наметавонист —
// яъне таърихи кории худро гум мекард.
//
// `false` бармегардонад, агар фурӯшанда дар ин фармоиш воқеан моле
// надошта бошад — он гоҳ ин кӯшиши дастрасии бегона аст.
func backfillOrderSeller(tx *sql.Tx, orderID, sellerID string) bool {
	res, err := tx.Exec(`INSERT INTO order_sellers(order_id,seller_id,status,subtotal)
		SELECT $1, $2, o.status, COALESCE(SUM(oi.price*oi.quantity),0)
		FROM orders o
		JOIN order_items oi ON oi.order_id = o.id
		LEFT JOIN products p ON p.id = oi.product_id
		WHERE o.id=$1 AND COALESCE(oi.seller_id, p.seller_id) = $2
		GROUP BY o.status
		ON CONFLICT (order_id,seller_id) DO NOTHING`, orderID, sellerID)
	if err != nil {
		return false
	}
	n, _ := res.RowsAffected()
	return n > 0
}
