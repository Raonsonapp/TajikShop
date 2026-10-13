package handlers

import (
	"database/sql"
	"net/http"
	"strconv"
	"strings"
	"tajikshop/internal/db"
	"tajikshop/internal/utils"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// ═══════════════════════════════════════════════════════════════════════════
//  RFQ — дархости нарх
// ═══════════════════════════════════════════════════════════════════════════
//
// Қоидаи аз ҳама муҳими амният ин ҷо:
//
//     ФУРӮШАНДА ПЕШНИҲОДИ РАҚИБОНАШРО НАМЕБИНАД.
//
// Бе ин тамоми RFQ бефоида аст: фурӯшандаи дуюм нархи аввалро мебинад ва
// як дирам камтар мегузорад. Он гоҳ ҳеҷ кас нархи ҳақиқии худро
// намедиҳад, ва гуфтушунид ба бозии «кӣ охирин менависад» табдил меёбад.
//
// Пас: харидор ҲАМА пешниҳодҳоро мебинад, фурӯшанда ТАНҲО пешниҳоди
// ХУДашро.

type RFQHandler struct{}

func NewRFQHandler() *RFQHandler { return &RFQHandler{} }

// ── Харидор: сохтани дархост ─────────────────────────────────────────────

// Create — POST /rfqs
func (h *RFQHandler) Create(c *gin.Context) {
	uid := utils.UserID(c)
	var in struct {
		Title       string  `json:"title"`
		Description string  `json:"description"`
		CategoryID  string  `json:"category_id"`
		Quantity    int     `json:"quantity"`
		Unit        string  `json:"unit"`
		TargetPrice float64 `json:"target_price"`
		Destination string  `json:"destination"`
		ClosesAt    string  `json:"closes_at"` // RFC3339
		NeededBy    string  `json:"needed_by"` // YYYY-MM-DD
		Days        int     `json:"days"`      // муқобили `closes_at`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, "Дархост хонда нашуд")
		return
	}

	now := time.Now()
	// Барнома метавонад ё санаи дақиқ, ё «чанд рӯз кушода монад» диҳад.
	// Дуюм барои корбар содатар аст.
	closes := now.AddDate(0, 0, 7)
	if s := strings.TrimSpace(in.ClosesAt); s != "" {
		if t, err := time.Parse(time.RFC3339, s); err == nil {
			closes = t
		}
	} else if in.Days > 0 {
		closes = now.AddDate(0, 0, in.Days)
	}

	var neededBy *time.Time
	if s := strings.TrimSpace(in.NeededBy); s != "" {
		if t, err := time.Parse("2006-01-02", s); err == nil {
			neededBy = &t
		}
	}

	clean, msg := validateRFQ(rfqInput{
		Title:       in.Title,
		Description: in.Description,
		Quantity:    in.Quantity,
		Unit:        in.Unit,
		TargetPrice: toDirams(in.TargetPrice),
		Destination: in.Destination,
		ClosesAt:    closes,
		NeededBy:    neededBy,
	}, now)
	if msg != "" {
		utils.Err(c, http.StatusBadRequest, msg)
		return
	}

	var cat interface{}
	if s := strings.TrimSpace(in.CategoryID); s != "" {
		cat = s
	}

	id := uuid.NewString()
	if _, err := db.DB.Exec(`INSERT INTO rfqs
		(id,buyer_id,title,description,category_id,quantity,unit,
		 target_price,destination,needed_by,closes_at,status)
		VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,'open')`,
		id, uid, clean.Title, clean.Description, cat, clean.Quantity,
		clean.Unit, toSomoni(clean.TargetPrice), clean.Destination,
		clean.NeededBy, clean.ClosesAt); err != nil {
		utils.Err(c, http.StatusInternalServerError, "Дархост сохта нашуд")
		return
	}

	utils.Created(c, gin.H{
		"id": id, "status": rfqOpen,
		"closes_at": clean.ClosesAt, "quantity": clean.Quantity,
	})
}

// MyRFQs — GET /rfqs/my  (харидор)
func (h *RFQHandler) MyRFQs(c *gin.Context) {
	uid := utils.UserID(c)
	rows, err := db.DB.Query(`SELECT r.id, r.title, r.quantity, COALESCE(r.unit,'дона'),
			r.status, r.closes_at, r.created_at,
			COALESCE(r.target_price,0), COALESCE(r.destination,''),
			(SELECT COUNT(*) FROM rfq_quotes q
				WHERE q.rfq_id=r.id AND q.status=$2)
		FROM rfqs r WHERE r.buyer_id=$1
		ORDER BY r.created_at DESC LIMIT 100`, uid, quoteActive)
	utils.OK(c, scanRFQList(rows, err))
}

// Open — GET /rfqs/open  (фурӯшанда)
//
// Танҳо дархостҳои кушода бо мӯҳлати ҳанӯз нагузашта. Шумораи
// пешниҳодҳо нишон дода НАМЕШАВАД: он ҳам маълумоти рақобат аст
// («ин ҷо 7 пешниҳод ҳаст, намеарзад»).
func (h *RFQHandler) Open(c *gin.Context) {
	uid := utils.UserID(c)
	rows, err := db.DB.Query(`SELECT r.id, r.title, r.quantity, COALESCE(r.unit,'дона'),
			r.status, r.closes_at, r.created_at,
			COALESCE(r.target_price,0), COALESCE(r.destination,''),
			(SELECT COUNT(*) FROM rfq_quotes q
				WHERE q.rfq_id=r.id AND q.seller_id=$1 AND q.status=$2)
		FROM rfqs r
		WHERE r.status='open' AND r.closes_at > NOW() AND r.buyer_id <> $1
		ORDER BY r.closes_at ASC LIMIT 100`, uid, quoteActive)
	// Сутуни охирин ин ҷо «оё МАН пешниҳод додам» аст — то фурӯшанда
	// дархости аллакай ҷавобдодаашро фарқ кунад.
	utils.OK(c, scanRFQList(rows, err))
}

func scanRFQList(rows *sql.Rows, err error) []gin.H {
	out := []gin.H{}
	if err != nil || rows == nil {
		return out
	}
	defer rows.Close()
	now := time.Now()
	for rows.Next() {
		var id, title, unit, status, dest string
		var qty, quotes int
		var target float64
		var closesAt, createdAt time.Time
		if e := rows.Scan(&id, &title, &qty, &unit, &status, &closesAt,
			&createdAt, &target, &dest, &quotes); e != nil {
			continue
		}
		row := gin.H{
			"id": id, "title": title, "quantity": qty, "unit": unit,
			"status":     effectiveRFQStatus(status, closesAt, now),
			"closes_at":  closesAt,
			"created_at": createdAt,
			"quotes":     quotes,
			"open":       canQuote(status, closesAt, now),
		}
		if target > 0 {
			row["target_price"] = target
		}
		if dest != "" {
			row["destination"] = dest
		}
		out = append(out, row)
	}
	return out
}

// Get — GET /rfqs/:id
//
// Ҷавоб ба он вобаста аст, ки КӢ мепурсад:
//   - харидор: тамоми маълумот + ҲАМА пешниҳодҳо
//   - фурӯшанда: маълумоти дархост + ТАНҲО пешниҳоди худаш
//   - дигар: 403
func (h *RFQHandler) Get(c *gin.Context) {
	uid := utils.UserID(c)
	id := c.Param("id")

	var buyerID, title, desc, unit, status, dest, catID string
	var qty int
	var target float64
	var closesAt, createdAt time.Time
	var neededBy sql.NullTime
	err := db.DB.QueryRow(`SELECT buyer_id, title, COALESCE(description,''),
			COALESCE(unit,'дона'), status, COALESCE(destination,''),
			COALESCE(category_id::text,''), quantity,
			COALESCE(target_price,0), closes_at, created_at, needed_by
		FROM rfqs WHERE id=$1`, id).
		Scan(&buyerID, &title, &desc, &unit, &status, &dest, &catID, &qty,
			&target, &closesAt, &createdAt, &neededBy)
	if err != nil {
		utils.Err(c, http.StatusNotFound, "Дархост ёфт нашуд")
		return
	}

	isBuyer := buyerID == uid
	now := time.Now()

	// Фурӯшандаи бегона дархости кушодаро мебинад (ин оммавӣ аст), вале
	// дархости пӯшидаи каси дигарро не.
	if !isBuyer && !canQuote(status, closesAt, now) {
		// Агар ӯ аллакай пешниҳод дода бошад, ҳақ дорад натиҷаро бинад.
		var mine bool
		db.DB.QueryRow(`SELECT EXISTS(SELECT 1 FROM rfq_quotes
			WHERE rfq_id=$1 AND seller_id=$2)`, id, uid).Scan(&mine)
		if !mine {
			utils.Err(c, http.StatusForbidden, "Ин дархост дастрас нест")
			return
		}
	}

	body := gin.H{
		"id": id, "title": title, "description": desc,
		"quantity": qty, "unit": unit,
		"status":     effectiveRFQStatus(status, closesAt, now),
		"closes_at":  closesAt,
		"created_at": createdAt,
		"open":       canQuote(status, closesAt, now),
		"is_buyer":   isBuyer,
	}
	if target > 0 {
		body["target_price"] = target
	}
	if dest != "" {
		body["destination"] = dest
	}
	if catID != "" {
		body["category_id"] = catID
	}
	if neededBy.Valid {
		body["needed_by"] = neededBy.Time.Format("2006-01-02")
	}

	if isBuyer {
		body["quotes"] = h.quotesForBuyer(id, qty)
		body["buyer_name"] = ""
	} else {
		body["quotes"] = h.quotesForSeller(id, uid, qty)
	}
	utils.OK(c, body)
}

// quotesForBuyer — ҳамаи пешниҳодҳои фаъол, аз арзонтарин.
//
// Тартиб аз рӯи ҶАМЪ аст, на аз рӯи нархи як дона. Пешниҳоди «10 сом.
// донааш + 5000 расонидан» метавонад аз «12 сом. донааш + ройгон»
// гаронтар афтад — нархи як дона худаш танҳо нимаи ҳақиқат аст.
func (h *RFQHandler) quotesForBuyer(rfqID string, qty int) []gin.H {
	rows, err := db.DB.Query(`SELECT q.id, q.seller_id,
			COALESCE(NULLIF(u.shop_name,''), u.name, ''),
			COALESCE(u.is_verified,false),
			q.version, q.unit_price, q.min_qty, COALESCE(q.shipping_cost,0),
			COALESCE(q.lead_days,0), COALESCE(q.payment_terms,''),
			COALESCE(q.note,''), q.valid_until, q.status, q.created_at
		FROM rfq_quotes q
		LEFT JOIN users u ON u.id = q.seller_id
		WHERE q.rfq_id=$1 AND q.status IN ($2,$3)
		ORDER BY q.created_at DESC`, rfqID, quoteActive, quoteAccepted)
	return scanQuotes(rows, err, qty, true)
}

// quotesForSeller — ТАНҲО пешниҳодҳои ҳамин фурӯшанда, бо ҳамаи версияҳо.
//
// Версияҳои кӯҳна нишон дода мешаванд, то фурӯшанда бинад, чӣ пешниҳод
// карда буд.
func (h *RFQHandler) quotesForSeller(rfqID, sellerID string, qty int) []gin.H {
	rows, err := db.DB.Query(`SELECT q.id, q.seller_id,
			COALESCE(NULLIF(u.shop_name,''), u.name, ''),
			COALESCE(u.is_verified,false),
			q.version, q.unit_price, q.min_qty, COALESCE(q.shipping_cost,0),
			COALESCE(q.lead_days,0), COALESCE(q.payment_terms,''),
			COALESCE(q.note,''), q.valid_until, q.status, q.created_at
		FROM rfq_quotes q
		LEFT JOIN users u ON u.id = q.seller_id
		WHERE q.rfq_id=$1 AND q.seller_id=$2
		ORDER BY q.version DESC`, rfqID, sellerID)
	return scanQuotes(rows, err, qty, false)
}

func scanQuotes(rows *sql.Rows, err error, qty int, withSeller bool) []gin.H {
	out := []gin.H{}
	if err != nil || rows == nil {
		return out
	}
	defer rows.Close()
	now := time.Now()
	type item struct {
		row   gin.H
		total int64
	}
	var items []item
	for rows.Next() {
		var id, sellerID, sellerName, terms, note, status string
		var verified bool
		var version, minQty, leadDays int
		var unitPrice, shipping float64
		var validUntil sql.NullTime
		var createdAt time.Time
		if e := rows.Scan(&id, &sellerID, &sellerName, &verified, &version,
			&unitPrice, &minQty, &shipping, &leadDays, &terms, &note,
			&validUntil, &status, &createdAt); e != nil {
			continue
		}
		var vu *time.Time
		if validUntil.Valid {
			vu = &validUntil.Time
		}
		total := quoteTotal(toDirams(unitPrice), qty, toDirams(shipping))
		row := gin.H{
			"id": id, "version": version,
			"unit_price": unitPrice, "min_qty": minQty,
			"shipping_cost": shipping, "lead_days": leadDays,
			"payment_terms": terms, "note": note,
			"status":     status,
			"created_at": createdAt,
			"total":      toSomoni(total),
			"usable":     quoteUsable(status, vu, now),
		}
		if vu != nil {
			row["valid_until"] = *vu
		}
		if withSeller {
			row["seller_id"] = sellerID
			row["seller_name"] = sellerName
			row["seller_verified"] = verified
		}
		items = append(items, item{row, total})
	}

	// Арзонтаринро нишон мегузорем — харидор бояд онро фавран бинад.
	totals := make([]int64, len(items))
	for i, it := range items {
		if it.row["usable"] == true {
			totals[i] = it.total
		}
	}
	if best := cheapestQuote(totals); best >= 0 {
		items[best].row["cheapest"] = true
	}
	for _, it := range items {
		out = append(out, it.row)
	}
	return out
}

// Close — POST /rfqs/:id/close  (харидор)
func (h *RFQHandler) Close(c *gin.Context) {
	uid := utils.UserID(c)
	res, err := db.DB.Exec(`UPDATE rfqs SET status='closed', updated_at=NOW()
		WHERE id=$1 AND buyer_id=$2 AND status='open'`, c.Param("id"), uid)
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, "Пӯшида нашуд")
		return
	}
	if n, _ := res.RowsAffected(); n == 0 {
		utils.Err(c, http.StatusForbidden, "Ин дархости шумо нест ё аллакай пӯшида аст")
		return
	}
	utils.OK(c, gin.H{"status": rfqClosed})
}

// ── Фурӯшанда: пешниҳод ──────────────────────────────────────────────────

// Quote — POST /rfqs/:id/quotes
//
// Пешниҳоди нав ё ислоҳи пешниҳоди ҳозира. Ислоҳ сатри кӯҳнаро ИВАЗ
// НАМЕКУНАД: сатри нав бо `version+1` сохта мешавад ва кӯҳна 'revised'
// мешавад.
//
// Чаро: бе ин харидор нархи дидаашро исбот карда наметавонад. Маҳз
// ҳамин ҷойест, ки ихтилоф ба вуҷуд меояд.
func (h *RFQHandler) Quote(c *gin.Context) {
	uid := utils.UserID(c)
	rfqID := c.Param("id")

	var in struct {
		UnitPrice    float64 `json:"unit_price"`
		MinQty       int     `json:"min_qty"`
		ShippingCost float64 `json:"shipping_cost"`
		LeadDays     int     `json:"lead_days"`
		PaymentTerms string  `json:"payment_terms"`
		Note         string  `json:"note"`
		ValidDays    int     `json:"valid_days"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, "Пешниҳод хонда нашуд")
		return
	}

	tx, txErr := db.DB.Begin()
	if txErr != nil {
		utils.Err(c, http.StatusInternalServerError, "Пешниҳод сабт нашуд")
		return
	}
	committed := false
	defer func() {
		if !committed {
			tx.Rollback()
		}
	}()

	// Дархостро қулф мекунем: вагарна харидор метавонад дар ҳамон лаҳза
	// пешниҳоди дигарро қабул кунад, ва мо ба дархости аллакай
	// қабулшуда пешниҳод илова мекунем.
	var buyerID, status string
	var qty int
	var closesAt time.Time
	if e := tx.QueryRow(`SELECT buyer_id, status, quantity, closes_at
		FROM rfqs WHERE id=$1 FOR UPDATE`, rfqID).
		Scan(&buyerID, &status, &qty, &closesAt); e != nil {
		utils.Err(c, http.StatusNotFound, "Дархост ёфт нашуд")
		return
	}
	if buyerID == uid {
		utils.Err(c, http.StatusBadRequest, "Ба дархости худ пешниҳод додан мумкин нест")
		return
	}
	now := time.Now()
	if !canQuote(status, closesAt, now) {
		utils.Err(c, http.StatusConflict, "Дархост пӯшида аст")
		return
	}

	var validUntil *time.Time
	if in.ValidDays > 0 {
		t := now.AddDate(0, 0, in.ValidDays)
		validUntil = &t
	}

	clean, msg := validateQuote(quoteInput{
		UnitPrice:    toDirams(in.UnitPrice),
		MinQty:       in.MinQty,
		ShippingCost: toDirams(in.ShippingCost),
		LeadDays:     in.LeadDays,
		PaymentTerms: in.PaymentTerms,
		Note:         in.Note,
		ValidUntil:   validUntil,
	}, qty, now)
	if msg != "" {
		utils.Err(c, http.StatusBadRequest, msg)
		return
	}

	// Версияи навбатӣ.
	var maxVersion int
	tx.QueryRow(`SELECT COALESCE(MAX(version),0) FROM rfq_quotes
		WHERE rfq_id=$1 AND seller_id=$2`, rfqID, uid).Scan(&maxVersion)
	if maxVersion >= quoteMaxVersions {
		utils.Err(c, http.StatusConflict,
			"Шумо аллакай 10 бор пешниҳодро ислоҳ кардед")
		return
	}

	// Версияҳои пештара 'revised' мешаванд — вале НЕСТ намешаванд.
	if _, e := tx.Exec(`UPDATE rfq_quotes SET status=$1
		WHERE rfq_id=$2 AND seller_id=$3 AND status=$4`,
		quoteRevised, rfqID, uid, quoteActive); e != nil {
		utils.Err(c, http.StatusInternalServerError, "Пешниҳоди кӯҳна нав нашуд")
		return
	}

	qid := uuid.NewString()
	if _, e := tx.Exec(`INSERT INTO rfq_quotes
		(id,rfq_id,seller_id,version,unit_price,min_qty,shipping_cost,
		 lead_days,payment_terms,note,valid_until,status)
		VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)`,
		qid, rfqID, uid, maxVersion+1, toSomoni(clean.UnitPrice),
		clean.MinQty, toSomoni(clean.ShippingCost), clean.LeadDays,
		clean.PaymentTerms, clean.Note, clean.ValidUntil, quoteActive); e != nil {
		utils.Err(c, http.StatusInternalServerError, "Пешниҳод сабт нашуд")
		return
	}

	if e := tx.Commit(); e != nil {
		utils.Err(c, http.StatusInternalServerError, "Пешниҳод нигоҳ дошта нашуд")
		return
	}
	committed = true

	total := quoteTotal(clean.UnitPrice, qty, clean.ShippingCost)
	title := "Пешниҳоди нав"
	body := "Ба дархости шумо пешниҳод омад: " + fmtSomoni(total) + " сом."
	db.DB.Exec(`INSERT INTO notifications(id,user_id,type,title,body,ref_id)
		VALUES($1,$2,'rfq',$3,$4,$5)`,
		uuid.NewString(), buyerID, title, body, rfqID)
	pushToUser(buyerID, title, body)

	utils.Created(c, gin.H{
		"id": qid, "version": maxVersion + 1,
		"total": toSomoni(total), "status": quoteActive,
	})
}

// Withdraw — POST /quotes/:id/withdraw  (фурӯшанда)
func (h *RFQHandler) Withdraw(c *gin.Context) {
	uid := utils.UserID(c)
	// Пешниҳоди аллакай қабулшуда гирифта намешавад — фармоиш аллакай
	// сохта шудааст.
	res, err := db.DB.Exec(`UPDATE rfq_quotes SET status=$1
		WHERE id=$2 AND seller_id=$3 AND status=$4`,
		quoteWithdrawn, c.Param("id"), uid, quoteActive)
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, "Гирифта нашуд")
		return
	}
	if n, _ := res.RowsAffected(); n == 0 {
		utils.Err(c, http.StatusForbidden,
			"Ин пешниҳоди шумо нест ё аллакай қабул шудааст")
		return
	}
	utils.OK(c, gin.H{"status": quoteWithdrawn})
}

// fmtSomoni — дирамро барои матни огоҳӣ ба сомонӣ табдил медиҳад.
//
// `strconv.FormatFloat` бо `-1` шумораи ҳадди ақали рақамҳои лозимиро
// мегузорад: 2450 → «24.5», на «24.50».
func fmtSomoni(dirams int64) string {
	return strconv.FormatFloat(toSomoni(dirams), 'f', -1, 64)
}
