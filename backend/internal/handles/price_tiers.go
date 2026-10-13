package handlers

import (
	"database/sql"
	"net/http"
	"sort"
	"tajikshop/internal/db"
	"tajikshop/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/lib/pq"
)

// ═══════════════════════════════════════════════════════════════════════════
//  Зинаҳои нархи яклухт
// ═══════════════════════════════════════════════════════════════════════════
//
// Пештар маҳсулот ЯК `wholesale_price` дошт — як рақам, бе ҳеҷ шарт. Он
// на дар сабад, на дар checkout истифода намешуд, пас амалан танҳо
// ҳамчун матн дар экран мемонд.
//
// Савдои яклухти воқеӣ бо ЗИНАҲО кор мекунад:
//
//     1–9 дона    → 100 сом.
//     10–49 дона  →  90 сом.
//     50+ дона    →  80 сом.
//
// Фурӯшанда зинаҳои худро мегузорад. Ҳамин ки харидор шумораро зиёд
// мекунад, нархи як дона худкор кам мешавад — ва ҳамон нарх дар checkout
// гирифта мешавад, на нархи чакана.
//
// Маҳз ин ҷо нуқтаи хатар аст: агар экран як нархро нишон диҳад ва
// сервер нархи дигарро гирад, харидор пулашро гумшуда меҳисобад. Пас
// ҳисоби нарх ЯК ҶОЙ аст — `priceForQty` — ва ҳам экран, ҳам checkout
// ҳамонро истифода мебаранд.

// priceTier — як зинаи нарх.
type priceTier struct {
	MinQty int   `json:"min_qty"`
	Price  int64 `json:"-"`     // дирам, дарунӣ
	Somoni float64 `json:"price"` // барои JSON
}

// priceForQty — нархи як дона барои ҳамин шумора.
//
// Зинаи мувофиқ он аст, ки `min_qty`-и КАЛОНТАРИН дорад ва аз шумора
// зиёд нест. Агар ягон зина мувофиқ наояд (шумора аз ҳамаи зинаҳо
// камтар), нархи чаканаи асосӣ бармегардад.
//
// Функсия тоза аст — бе база — пас онро воқеан санҷидан мумкин аст.
func priceForQty(tiers []priceTier, basePrice int64, qty int) int64 {
	best := basePrice
	bestMin := 0
	for _, t := range tiers {
		if t.MinQty <= 0 || t.Price <= 0 {
			continue // зинаи вайрон — нодида
		}
		if qty >= t.MinQty && t.MinQty >= bestMin {
			best, bestMin = t.Price, t.MinQty
		}
	}
	return best
}

// validateTiers — зинаҳои фурӯшандаро месанҷад ва тартиб медиҳад.
//
// Ду қоида, ва ҳардуяш аз мантиқи савдо меоянд:
//
//  1. `min_qty` набояд такрор шавад — вагарна маълум нест, кадом нарх
//     амал мекунад.
//  2. ҳар чи шумора зиёдтар, нарх бояд КАМТАР (ё баробар) бошад.
//     Зинаи «50+ дона = 120 сом.» дар ҳоле ки «10+ дона = 90 сом.»
//     маъно надорад: харидори яклухт бештар мепардозад. Ин қариб ҳамеша
//     хатои хаттӣ аст, ва бе санҷиш он ба харидор мерасад.
func validateTiers(tiers []priceTier, basePrice int64) ([]priceTier, string) {
	clean := []priceTier{}
	seen := map[int]bool{}
	for _, t := range tiers {
		if t.MinQty < 2 {
			return nil, "Зина бояд аз 2 дона боло бошад"
		}
		if t.Price <= 0 {
			return nil, "Нархи зина бояд аз сифр зиёд бошад"
		}
		if t.Price >= basePrice {
			return nil, "Нархи яклухт бояд аз нархи чакана камтар бошад"
		}
		if seen[t.MinQty] {
			return nil, "Ду зина бо ҳамон шумора"
		}
		seen[t.MinQty] = true
		clean = append(clean, t)
	}
	if len(clean) > 10 {
		return nil, "Зиёда аз 10 зина мумкин нест"
	}
	sort.Slice(clean, func(i, j int) bool { return clean[i].MinQty < clean[j].MinQty })
	for i := 1; i < len(clean); i++ {
		if clean[i].Price > clean[i-1].Price {
			return nil, "Зинаи калонтар бояд нархи камтар дошта бошад"
		}
	}
	return clean, ""
}

// loadTiers — зинаҳои маҳсулот.
func loadTiers(q interface {
	Query(string, ...interface{}) (*sql.Rows, error)
}, productID string) []priceTier {
	rows, err := q.Query(`SELECT min_qty, price FROM product_price_tiers
		WHERE product_id=$1 ORDER BY min_qty`, productID)
	out := []priceTier{}
	if err != nil || rows == nil {
		return out
	}
	defer rows.Close()
	for rows.Next() {
		var t priceTier
		var p float64
		if e := rows.Scan(&t.MinQty, &p); e != nil {
			continue
		}
		t.Price = toDirams(p)
		t.Somoni = p
		out = append(out, t)
	}
	return out
}

// loadTiersForDB — ҳамон `loadTiersFor`, вале берун аз транзаксия.
func loadTiersForDB(productIDs []string) map[string][]priceTier {
	return collectTiers(db.DB.Query, productIDs)
}

// loadTiersFor — зинаҳои ЧАНД маҳсулот бо ЯК дархост.
//
// Дар checkout ин ҳатмист. Бо дархости ҷудогона барои ҳар сатри сабад
// мо масъалаи классикии N+1 мегирифтем: сабади 30-мол = 31 дархост ба
// база, дар дохили транзаксияи кушода.
func loadTiersFor(tx *sql.Tx, productIDs []string) map[string][]priceTier {
	return collectTiers(tx.Query, productIDs)
}

// collectTiers — мантиқи умумии ҳарду: як дархост барои ҳамаи молҳо.
//
// `ANY($1)` ин ҷо ҳатмист. Бо дархости ҷудогона барои ҳар сатри сабад мо
// масъалаи классикии N+1 мегирифтем: сабади 30-мол = 31 дархост ба база,
// ва дар checkout ин дар дохили транзаксияи кушода мешуд.
func collectTiers(query func(string, ...interface{}) (*sql.Rows, error),
	productIDs []string) map[string][]priceTier {
	out := map[string][]priceTier{}
	if len(productIDs) == 0 {
		return out
	}
	rows, err := query(`SELECT product_id, min_qty, price
		FROM product_price_tiers WHERE product_id = ANY($1)
		ORDER BY product_id, min_qty`, pq.Array(productIDs))
	if err != nil || rows == nil {
		return out
	}
	defer rows.Close()
	for rows.Next() {
		var pid string
		var t priceTier
		var p float64
		if e := rows.Scan(&pid, &t.MinQty, &p); e != nil {
			continue
		}
		t.Price = toDirams(p)
		t.Somoni = p
		out[pid] = append(out[pid], t)
	}
	return out
}

// ── HTTP ─────────────────────────────────────────────────────────────────

// GetTiers — GET /products/:id/tiers  (оммавӣ)
func (h *ProductHandler) GetTiers(c *gin.Context) {
	tiers := loadTiers(db.DB, c.Param("id"))
	utils.OK(c, tiers)
}

// SetTiers — PUT /products/:id/tiers  (фурӯшанда)
//
// Ҳамаи зинаҳоро якбора иваз мекунад — ин аз «илова/нест кун»-и
// ҷудогона содатар ва бехатартар аст: ҳолати нимкора пайдо намешавад.
func (h *ProductHandler) SetTiers(c *gin.Context) {
	uid := utils.UserID(c)
	pid := c.Param("id")

	var in struct {
		Tiers []struct {
			MinQty int     `json:"min_qty"`
			Price  float64 `json:"price"`
		} `json:"tiers"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, "Зинаҳо хонда нашуданд")
		return
	}

	// Маҳсулот бояд аз ҳамин фурӯшанда бошад.
	var basePrice float64
	err := db.DB.QueryRow(`SELECT price FROM products WHERE id=$1 AND seller_id=$2`,
		pid, uid).Scan(&basePrice)
	if err != nil {
		utils.Err(c, http.StatusForbidden, "Ин маҳсулоти шумо нест")
		return
	}

	raw := make([]priceTier, 0, len(in.Tiers))
	for _, t := range in.Tiers {
		raw = append(raw, priceTier{MinQty: t.MinQty, Price: toDirams(t.Price), Somoni: t.Price})
	}
	clean, msg := validateTiers(raw, toDirams(basePrice))
	if msg != "" {
		utils.Err(c, http.StatusBadRequest, msg)
		return
	}

	tx, txErr := db.DB.Begin()
	if txErr != nil {
		utils.Err(c, http.StatusInternalServerError, "Зинаҳо нигоҳ дошта нашуданд")
		return
	}
	if _, e := tx.Exec(`DELETE FROM product_price_tiers WHERE product_id=$1`, pid); e != nil {
		tx.Rollback()
		utils.Err(c, http.StatusInternalServerError, "Зинаҳои кӯҳна нест нашуданд")
		return
	}
	for _, t := range clean {
		if _, e := tx.Exec(`INSERT INTO product_price_tiers(id,product_id,min_qty,price)
			VALUES($1,$2,$3,$4)`, uuid.NewString(), pid, t.MinQty, toSomoni(t.Price)); e != nil {
			tx.Rollback()
			utils.Err(c, http.StatusInternalServerError, "Зина нигоҳ дошта нашуд")
			return
		}
	}
	if e := tx.Commit(); e != nil {
		utils.Err(c, http.StatusInternalServerError, "Зинаҳо нигоҳ дошта нашуданд")
		return
	}
	utils.OK(c, gin.H{"tiers": clean, "count": len(clean)})
}
