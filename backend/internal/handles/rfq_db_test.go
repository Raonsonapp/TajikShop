package handlers

// RFQ бо Postgres-и воқеӣ.
//
// Муҳимтарин санҷиш ин ҷо қоидаи амният аст:
//
//     ФУРӮШАНДА ПЕШНИҲОДИ РАҚИБОНАШРО НАМЕБИНАД.
//
// Бе ин тамоми RFQ бефоида аст: фурӯшандаи дуюм нархи аввалро мебинад ва
// як дирам камтар мегузорад. Он гоҳ ҳеҷ кас нархи ҳақиқии худро
// намедиҳад.

import (
	"testing"
	"time"

	"tajikshop/internal/db"
	"tajikshop/internal/middleware"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func rfqRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	middleware.SetSecret(testSecret)
	r := gin.New()
	uh := NewUserHandler(testSecret, nil)
	rh := NewRFQHandler()
	api := r.Group("/api/v1")
	api.POST("/auth/login", uh.Login)
	api.POST("/rfqs", middleware.Auth(), rh.Create)
	api.GET("/rfqs/my", middleware.Auth(), rh.MyRFQs)
	api.GET("/rfqs/open", middleware.Auth(), rh.Open)
	api.GET("/rfqs/:id", middleware.Auth(), rh.Get)
	api.POST("/rfqs/:id/close", middleware.Auth(), rh.Close)
	api.POST("/rfqs/:id/quotes", middleware.Auth(), rh.Quote)
	api.POST("/quotes/:id/withdraw", middleware.Auth(), rh.Withdraw)
	api.POST("/quotes/:id/accept", middleware.Auth(), rh.Award)
	return r
}

// newRFQ — дархости кушода аз номи харидор.
func newRFQ(t *testing.T, r *gin.Engine, tok string, qty int) string {
	t.Helper()
	res := call(t, r, "POST", "/api/v1/rfqs", map[string]any{
		"title":    "500 кг орди навъи аввал",
		"quantity": qty,
		"unit":     "кг",
		"days":     7,
	}, bearer(tok))
	if res.Status != 201 {
		t.Fatalf("дархост сохта нашуд: %d %s", res.Status, res.Error)
	}
	id := str(res.Data, "id")
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM rfq_quotes WHERE rfq_id=$1`, id)
		db.DB.Exec(`DELETE FROM rfqs WHERE id=$1`, id)
	})
	return id
}

func submitQuote(t *testing.T, r *gin.Engine, rfqID, tok string,
	unitPrice, shipping float64) string {
	t.Helper()
	res := call(t, r, "POST", "/api/v1/rfqs/"+rfqID+"/quotes", map[string]any{
		"unit_price":    unitPrice,
		"shipping_cost": shipping,
		"min_qty":       1,
		"lead_days":     3,
		"valid_days":    5,
	}, bearer(tok))
	if res.Status != 201 {
		t.Fatalf("пешниҳод нашуд: %d %s", res.Status, res.Error)
	}
	return str(res.Data, "id")
}

// ── Қоидаи амният ────────────────────────────────────────────────────────

func TestRFQSellerCannotSeeRivalQuotes(t *testing.T) {
	needDB(t)
	r := rfqRouter()
	_, buyerTok := newBuyer(t, r, 0)
	s1, _ := newTestSeller(t, 100, 10, 1)
	s2, _ := newTestSeller(t, 100, 10, 1)
	t1 := sellerToken(t, r, s1)
	t2 := sellerToken(t, r, s2)

	rfqID := newRFQ(t, r, buyerTok, 500)
	submitQuote(t, r, rfqID, t1, 4.60, 150)
	submitQuote(t, r, rfqID, t2, 4.80, 100)

	// Харидор ҲАРДУро мебинад.
	res := call(t, r, "GET", "/api/v1/rfqs/"+rfqID, nil, bearer(buyerTok))
	if res.Status != 200 {
		t.Fatalf("харидор: %d %s", res.Status, res.Error)
	}
	quotes, _ := res.Data["quotes"].([]any)
	if len(quotes) != 2 {
		t.Fatalf("харидор %d пешниҳод мебинад, мехостам 2", len(quotes))
	}

	// Фурӯшандаи 1 ТАНҲО пешниҳоди худашро мебинад.
	res = call(t, r, "GET", "/api/v1/rfqs/"+rfqID, nil, bearer(t1))
	if res.Status != 200 {
		t.Fatalf("фурӯшанда: %d %s", res.Status, res.Error)
	}
	quotes, _ = res.Data["quotes"].([]any)
	if len(quotes) != 1 {
		t.Fatalf("фурӯшанда %d пешниҳод мебинад, мехостам 1 — "+
			"ӯ набояд нархи рақибро бинад", len(quotes))
	}
	m, _ := quotes[0].(map[string]any)
	if p, _ := m["unit_price"].(float64); p != 4.60 {
		t.Fatalf("фурӯшандаи 1 нархи %v мебинад, мехостам 4.60 (нархи худаш)", p)
	}
	// Ва набояд ягон маълумот дар бораи фурӯшандаи дигар бошад.
	if _, has := m["seller_name"]; has {
		t.Error("ба фурӯшанда номи фурӯшанда фиристода шуд — маълумоти зиёдатӣ")
	}
}

// Харидор пешниҳодҳоро бо ҶАМЪ муқоиса мекунад, на бо нархи як дона.
//
// «10 сом. донааш + 5000 расонидан» метавонад аз «12 сом. донааш +
// ройгон» ГАРОНТАР афтад.
func TestRFQCheapestIsByTotal(t *testing.T) {
	needDB(t)
	r := rfqRouter()
	_, buyerTok := newBuyer(t, r, 0)
	s1, _ := newTestSeller(t, 100, 10, 1)
	s2, _ := newTestSeller(t, 100, 10, 1)
	t1 := sellerToken(t, r, s1)
	t2 := sellerToken(t, r, s2)

	rfqID := newRFQ(t, r, buyerTok, 100)
	// A: 10 сом. × 100 + 500 расонидан = 1500 сом.
	submitQuote(t, r, rfqID, t1, 10, 500)
	// B: 12 сом. × 100 + 0 = 1200 сом. ← арзонтар, гарчанде донааш гарон
	submitQuote(t, r, rfqID, t2, 12, 0)

	res := call(t, r, "GET", "/api/v1/rfqs/"+rfqID, nil, bearer(buyerTok))
	quotes, _ := res.Data["quotes"].([]any)
	if len(quotes) != 2 {
		t.Fatalf("%d пешниҳод, мехостам 2", len(quotes))
	}
	var cheapestUnit float64
	for _, q := range quotes {
		m, _ := q.(map[string]any)
		if m["cheapest"] == true {
			cheapestUnit, _ = m["unit_price"].(float64)
		}
	}
	if cheapestUnit != 12 {
		t.Fatalf("арзонтарин нархи донааш %v нишон дода шуд, мехостам 12 — "+
			"муқоиса бояд аз рӯи ҶАМЪ бошад, на нархи як дона", cheapestUnit)
	}
}

// ── Версияи пешниҳод ─────────────────────────────────────────────────────

// Ислоҳи пешниҳод сатри кӯҳнаро ИВАЗ намекунад.
//
// Бе ин харидор нархи дидаашро исбот карда наметавонад — «шумо 80 гуфта
// будед».
func TestRFQQuoteKeepsVersionHistory(t *testing.T) {
	needDB(t)
	r := rfqRouter()
	_, buyerTok := newBuyer(t, r, 0)
	sid, _ := newTestSeller(t, 100, 10, 1)
	tok := sellerToken(t, r, sid)

	rfqID := newRFQ(t, r, buyerTok, 100)
	submitQuote(t, r, rfqID, tok, 10, 0)
	submitQuote(t, r, rfqID, tok, 9, 0) // ислоҳ

	var n int
	db.DB.QueryRow(`SELECT COUNT(*) FROM rfq_quotes WHERE rfq_id=$1`, rfqID).Scan(&n)
	if n != 2 {
		t.Fatalf("%d сатри пешниҳод, мехостам 2 — версия бояд нигоҳ дошта шавад", n)
	}

	// Версияи кӯҳна 'revised' аст, нав 'active'.
	var oldStatus, newStatus string
	var oldPrice, newPrice float64
	db.DB.QueryRow(`SELECT status, unit_price FROM rfq_quotes
		WHERE rfq_id=$1 AND version=1`, rfqID).Scan(&oldStatus, &oldPrice)
	db.DB.QueryRow(`SELECT status, unit_price FROM rfq_quotes
		WHERE rfq_id=$1 AND version=2`, rfqID).Scan(&newStatus, &newPrice)
	if oldStatus != quoteRevised {
		t.Errorf("версияи 1 = %q, мехостам %q", oldStatus, quoteRevised)
	}
	if newStatus != quoteActive {
		t.Errorf("версияи 2 = %q, мехостам %q", newStatus, quoteActive)
	}
	if oldPrice != 10 || newPrice != 9 {
		t.Errorf("нархҳо: %v ва %v, мехостам 10 ва 9", oldPrice, newPrice)
	}

	// Харидор ТАНҲО версияи фаъолро мебинад — вагарна ӯ панҷ варианти
	// як фурӯшандаро мебинад ва намефаҳмад кадомаш амал мекунад.
	res := call(t, r, "GET", "/api/v1/rfqs/"+rfqID, nil, bearer(buyerTok))
	quotes, _ := res.Data["quotes"].([]any)
	if len(quotes) != 1 {
		t.Fatalf("харидор %d пешниҳод мебинад, мехостам 1 (фаъол)", len(quotes))
	}

	// Фурӯшанда ҳамаи версияҳои ХУДашро мебинад.
	res = call(t, r, "GET", "/api/v1/rfqs/"+rfqID, nil, bearer(tok))
	quotes, _ = res.Data["quotes"].([]any)
	if len(quotes) != 2 {
		t.Fatalf("фурӯшанда %d версия мебинад, мехостам 2", len(quotes))
	}
}

// ── Мӯҳлат ───────────────────────────────────────────────────────────────

func TestRFQClosedRejectsQuote(t *testing.T) {
	needDB(t)
	r := rfqRouter()
	_, buyerTok := newBuyer(t, r, 0)
	sid, _ := newTestSeller(t, 100, 10, 1)
	tok := sellerToken(t, r, sid)

	rfqID := newRFQ(t, r, buyerTok, 100)
	if res := call(t, r, "POST", "/api/v1/rfqs/"+rfqID+"/close", nil,
		bearer(buyerTok)); res.Status != 200 {
		t.Fatalf("пӯшидан: %d %s", res.Status, res.Error)
	}

	res := call(t, r, "POST", "/api/v1/rfqs/"+rfqID+"/quotes", map[string]any{
		"unit_price": 10, "min_qty": 1,
	}, bearer(tok))
	if res.Status != 409 {
		t.Fatalf("мехостам 409, гирифтам %d %s", res.Status, res.Error)
	}
}

// Мӯҳлат дар база гузашт, вале `status` ҳанӯз 'open' — пешниҳод набояд
// қабул шавад. Ин муҳим аст: ягон sweeper ҳар сония кор намекунад.
func TestRFQExpiredRejectsQuoteEvenIfStatusOpen(t *testing.T) {
	needDB(t)
	r := rfqRouter()
	_, buyerTok := newBuyer(t, r, 0)
	sid, _ := newTestSeller(t, 100, 10, 1)
	tok := sellerToken(t, r, sid)

	rfqID := newRFQ(t, r, buyerTok, 100)
	db.DB.Exec(`UPDATE rfqs SET closes_at = NOW() - INTERVAL '1 hour'
		WHERE id=$1`, rfqID)

	res := call(t, r, "POST", "/api/v1/rfqs/"+rfqID+"/quotes", map[string]any{
		"unit_price": 10, "min_qty": 1,
	}, bearer(tok))
	if res.Status != 409 {
		t.Fatalf("мехостам 409, гирифтам %d %s", res.Status, res.Error)
	}
	// Ҳолати намоишшаванда бояд «closed» бошад, гарчанде дар база 'open'.
	var dbStatus string
	db.DB.QueryRow(`SELECT status FROM rfqs WHERE id=$1`, rfqID).Scan(&dbStatus)
	if dbStatus != rfqOpen {
		t.Fatalf("шарти санҷиш вайрон: дар база %q", dbStatus)
	}
	got := call(t, r, "GET", "/api/v1/rfqs/"+rfqID, nil, bearer(buyerTok))
	if got.Data["status"] != rfqClosed {
		t.Fatalf("ҳолати намоишшаванда = %v, мехостам closed", got.Data["status"])
	}
}

// ── Иҷозатҳо ─────────────────────────────────────────────────────────────

func TestRFQBuyerCannotQuoteOwnRequest(t *testing.T) {
	needDB(t)
	r := rfqRouter()
	_, buyerTok := newBuyer(t, r, 0)
	rfqID := newRFQ(t, r, buyerTok, 100)

	res := call(t, r, "POST", "/api/v1/rfqs/"+rfqID+"/quotes", map[string]any{
		"unit_price": 10, "min_qty": 1,
	}, bearer(buyerTok))
	if res.Status != 400 {
		t.Fatalf("мехостам 400, гирифтам %d %s", res.Status, res.Error)
	}
}

func TestRFQOnlyBuyerCanAccept(t *testing.T) {
	needDB(t)
	r := rfqRouter()
	_, buyerTok := newBuyer(t, r, 0)
	s1, _ := newTestSeller(t, 100, 10, 1)
	s2, _ := newTestSeller(t, 100, 10, 1)
	t1 := sellerToken(t, r, s1)
	t2 := sellerToken(t, r, s2)

	rfqID := newRFQ(t, r, buyerTok, 100)
	qid := submitQuote(t, r, rfqID, t1, 10, 0)

	// Худи фурӯшанда пешниҳоди худашро қабул карда наметавонад.
	if res := call(t, r, "POST", "/api/v1/quotes/"+qid+"/accept", nil,
		bearer(t1)); res.Status != 403 {
		t.Errorf("фурӯшанда: мехостам 403, гирифтам %d", res.Status)
	}
	// Фурӯшандаи бегона ҳам не.
	if res := call(t, r, "POST", "/api/v1/quotes/"+qid+"/accept", nil,
		bearer(t2)); res.Status != 403 {
		t.Errorf("бегона: мехостам 403, гирифтам %d", res.Status)
	}
}

func TestRFQOnlyBuyerCanClose(t *testing.T) {
	needDB(t)
	r := rfqRouter()
	_, buyerTok := newBuyer(t, r, 0)
	sid, _ := newTestSeller(t, 100, 10, 1)
	tok := sellerToken(t, r, sid)
	rfqID := newRFQ(t, r, buyerTok, 100)

	if res := call(t, r, "POST", "/api/v1/rfqs/"+rfqID+"/close", nil,
		bearer(tok)); res.Status != 403 {
		t.Fatalf("мехостам 403, гирифтам %d %s", res.Status, res.Error)
	}
}

// ── Қабул → фармоиш ──────────────────────────────────────────────────────

// Маҳз ин он чизест, ки RFQ-ро кор мекунад: нарх АЗ ПЕШНИҲОД гирифта
// мешавад.
func TestRFQAwardCreatesOrderWithQuotePrice(t *testing.T) {
	needDB(t)
	r := rfqRouter()
	buyerID, buyerTok := newBuyer(t, r, 0)
	sid, _ := newTestSeller(t, 100, 10, 1) // нархи маҳсулоташ 100 — бефарқ
	tok := sellerToken(t, r, sid)

	rfqID := newRFQ(t, r, buyerTok, 500)
	// 4.60 сом. × 500 = 2300 + 150 расонидан = 2450 сом.
	qid := submitQuote(t, r, rfqID, tok, 4.60, 150)

	res := call(t, r, "POST", "/api/v1/quotes/"+qid+"/accept", nil, bearer(buyerTok))
	if res.Status != 201 {
		t.Fatalf("қабул: %d %s", res.Status, res.Error)
	}
	oid := str(res.Data, "order_id")
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM order_sellers WHERE order_id=$1`, oid)
		db.DB.Exec(`DELETE FROM order_items WHERE order_id=$1`, oid)
		db.DB.Exec(`DELETE FROM orders WHERE id=$1`, oid)
	})

	if total, _ := res.Data["total"].(float64); total != 2450 {
		t.Fatalf("ҷамъ = %v, мехостам 2450", res.Data["total"])
	}

	// Нархи сабтшуда дар фармоиш бояд нархи ПЕШНИҲОД бошад, на 100.
	var savedPrice float64
	var savedQty int
	var savedSeller, savedTitle string
	db.DB.QueryRow(`SELECT price, quantity, seller_id, title
		FROM order_items WHERE order_id=$1`, oid).
		Scan(&savedPrice, &savedQty, &savedSeller, &savedTitle)
	if savedPrice != 4.60 {
		t.Fatalf("нархи сабтшуда = %v, мехостам 4.60 (нархи пешниҳод)", savedPrice)
	}
	if savedQty != 500 {
		t.Fatalf("шумора = %d, мехостам 500", savedQty)
	}
	if savedSeller != sid {
		t.Fatalf("фурӯшанда нодуруст сабт шуд")
	}
	if savedTitle == "" {
		t.Error("номи мол сабт нашуд — таърихи фармоиш номафҳум мемонад")
	}

	// Зер-фармоиш ҳам бояд бошад — то фурӯшанда қадамҳоро дошта бошад.
	var osCount int
	db.DB.QueryRow(`SELECT COUNT(*) FROM order_sellers
		WHERE order_id=$1 AND seller_id=$2`, oid, sid).Scan(&osCount)
	if osCount != 1 {
		t.Fatalf("%d зер-фармоиш, мехостам 1", osCount)
	}

	// Фармоиш ба харидор тааллуқ дорад.
	var ordBuyer string
	db.DB.QueryRow(`SELECT user_id FROM orders WHERE id=$1`, oid).Scan(&ordBuyer)
	if ordBuyer != buyerID {
		t.Fatal("фармоиш ба харидори дигар сабт шуд")
	}

	// Дархост 'awarded', пешниҳод 'accepted'.
	var rStatus, qStatus string
	db.DB.QueryRow(`SELECT status FROM rfqs WHERE id=$1`, rfqID).Scan(&rStatus)
	db.DB.QueryRow(`SELECT status FROM rfq_quotes WHERE id=$1`, qid).Scan(&qStatus)
	if rStatus != rfqAwarded || qStatus != quoteAccepted {
		t.Fatalf("ҳолатҳо: %q ва %q, мехостам awarded ва accepted", rStatus, qStatus)
	}
}

// Як дархост = ЯК фармоиш. Ду зеркунии тугма ду фармоиш намесозад.
func TestRFQCannotAwardTwice(t *testing.T) {
	needDB(t)
	r := rfqRouter()
	_, buyerTok := newBuyer(t, r, 0)
	s1, _ := newTestSeller(t, 100, 10, 1)
	s2, _ := newTestSeller(t, 100, 10, 1)
	t1 := sellerToken(t, r, s1)
	t2 := sellerToken(t, r, s2)

	rfqID := newRFQ(t, r, buyerTok, 100)
	q1 := submitQuote(t, r, rfqID, t1, 10, 0)
	q2 := submitQuote(t, r, rfqID, t2, 11, 0)

	res := call(t, r, "POST", "/api/v1/quotes/"+q1+"/accept", nil, bearer(buyerTok))
	if res.Status != 201 {
		t.Fatalf("қабули аввал: %d %s", res.Status, res.Error)
	}
	oid := str(res.Data, "order_id")
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM order_sellers WHERE order_id=$1`, oid)
		db.DB.Exec(`DELETE FROM order_items WHERE order_id=$1`, oid)
		db.DB.Exec(`DELETE FROM orders WHERE id=$1`, oid)
	})

	// Ҳамон пешниҳод дубора.
	if res = call(t, r, "POST", "/api/v1/quotes/"+q1+"/accept", nil,
		bearer(buyerTok)); res.Status != 409 {
		t.Errorf("такрори ҳамон: мехостам 409, гирифтам %d", res.Status)
	}
	// Пешниҳоди рақиб — он аллакай 'rejected' аст.
	if res = call(t, r, "POST", "/api/v1/quotes/"+q2+"/accept", nil,
		bearer(buyerTok)); res.Status != 409 {
		t.Errorf("пешниҳоди дигар: мехостам 409, гирифтам %d", res.Status)
	}

	var orders int
	db.DB.QueryRow(`SELECT COUNT(*) FROM orders WHERE rfq_quote_id IN ($1,$2)`,
		q1, q2).Scan(&orders)
	if orders != 1 {
		t.Fatalf("%d фармоиш сохта шуд, мехостам 1", orders)
	}
}

// Пешниҳоди мӯҳлаташ гузашта қабул намешавад.
//
// Бе ин харидор метавонад баъди ним сол «қабул» занад ва фурӯшандаро ба
// нархи кӯҳна маҷбур кунад.
func TestRFQCannotAwardExpiredQuote(t *testing.T) {
	needDB(t)
	r := rfqRouter()
	_, buyerTok := newBuyer(t, r, 0)
	sid, _ := newTestSeller(t, 100, 10, 1)
	tok := sellerToken(t, r, sid)

	rfqID := newRFQ(t, r, buyerTok, 100)
	qid := submitQuote(t, r, rfqID, tok, 10, 0)
	db.DB.Exec(`UPDATE rfq_quotes SET valid_until = NOW() - INTERVAL '1 day'
		WHERE id=$1`, qid)

	res := call(t, r, "POST", "/api/v1/quotes/"+qid+"/accept", nil, bearer(buyerTok))
	if res.Status != 409 {
		t.Fatalf("мехостам 409, гирифтам %d %s", res.Status, res.Error)
	}
	var orders int
	db.DB.QueryRow(`SELECT COUNT(*) FROM orders WHERE rfq_quote_id=$1`, qid).Scan(&orders)
	if orders != 0 {
		t.Fatalf("%d фармоиш сохта шуд, мехостам 0", orders)
	}
}

// Пешниҳоди гирифташуда қабул намешавад.
func TestRFQCannotAwardWithdrawnQuote(t *testing.T) {
	needDB(t)
	r := rfqRouter()
	_, buyerTok := newBuyer(t, r, 0)
	sid, _ := newTestSeller(t, 100, 10, 1)
	tok := sellerToken(t, r, sid)

	rfqID := newRFQ(t, r, buyerTok, 100)
	qid := submitQuote(t, r, rfqID, tok, 10, 0)

	if res := call(t, r, "POST", "/api/v1/quotes/"+qid+"/withdraw", nil,
		bearer(tok)); res.Status != 200 {
		t.Fatalf("гирифтан: %d %s", res.Status, res.Error)
	}
	if res := call(t, r, "POST", "/api/v1/quotes/"+qid+"/accept", nil,
		bearer(buyerTok)); res.Status != 409 {
		t.Fatalf("мехостам 409, гирифтам %d", res.Status)
	}
}

// Пешниҳоди аллакай қабулшуда гирифта намешавад — фармоиш аллакай ҳаст.
func TestRFQCannotWithdrawAcceptedQuote(t *testing.T) {
	needDB(t)
	r := rfqRouter()
	_, buyerTok := newBuyer(t, r, 0)
	sid, _ := newTestSeller(t, 100, 10, 1)
	tok := sellerToken(t, r, sid)

	rfqID := newRFQ(t, r, buyerTok, 100)
	qid := submitQuote(t, r, rfqID, tok, 10, 0)
	res := call(t, r, "POST", "/api/v1/quotes/"+qid+"/accept", nil, bearer(buyerTok))
	if res.Status != 201 {
		t.Fatalf("қабул: %d %s", res.Status, res.Error)
	}
	oid := str(res.Data, "order_id")
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM order_sellers WHERE order_id=$1`, oid)
		db.DB.Exec(`DELETE FROM order_items WHERE order_id=$1`, oid)
		db.DB.Exec(`DELETE FROM orders WHERE id=$1`, oid)
	})

	if res = call(t, r, "POST", "/api/v1/quotes/"+qid+"/withdraw", nil,
		bearer(tok)); res.Status != 403 {
		t.Fatalf("мехостам 403, гирифтам %d", res.Status)
	}
}

// ── Рӯйхатҳо ─────────────────────────────────────────────────────────────

// Фурӯшанда дархости ХУДашро дар рӯйхати кушода намебинад.
func TestRFQOpenListExcludesOwn(t *testing.T) {
	needDB(t)
	r := rfqRouter()
	sid, _ := newTestSeller(t, 100, 10, 1)
	tok := sellerToken(t, r, sid)

	// Фурӯшанда худаш дархост мегузорад (ин мумкин аст — ӯ ҳам харидор аст).
	mine := newRFQ(t, r, tok, 100)
	_, otherTok := newBuyer(t, r, 0)
	theirs := newRFQ(t, r, otherTok, 100)

	_, list := callList(t, r, "/api/v1/rfqs/open", bearer(tok))
	ids := map[string]bool{}
	for _, row := range list {
		ids[row["id"].(string)] = true
	}
	if ids[mine] {
		t.Error("фурӯшанда дархости ХУДашро дар рӯйхати кушода мебинад")
	}
	if !ids[theirs] {
		t.Error("дархости каси дигар дар рӯйхат нест")
	}
}

// Шумораи пешниҳодҳои рақибон дар рӯйхати кушода нишон дода намешавад —
// он ҳам маълумоти рақобат аст («ин ҷо 7 пешниҳод ҳаст, намеарзад»).
func TestRFQOpenListShowsOnlyMyQuoteCount(t *testing.T) {
	needDB(t)
	r := rfqRouter()
	_, buyerTok := newBuyer(t, r, 0)
	s1, _ := newTestSeller(t, 100, 10, 1)
	s2, _ := newTestSeller(t, 100, 10, 1)
	t1 := sellerToken(t, r, s1)
	t2 := sellerToken(t, r, s2)

	rfqID := newRFQ(t, r, buyerTok, 100)
	submitQuote(t, r, rfqID, t1, 10, 0)
	submitQuote(t, r, rfqID, t2, 11, 0)

	// Фурӯшандаи 1: 1 (пешниҳоди худаш), на 2.
	_, list := callList(t, r, "/api/v1/rfqs/open", bearer(t1))
	for _, row := range list {
		if row["id"] == rfqID {
			if n, _ := row["quotes"].(float64); int(n) != 1 {
				t.Fatalf("фурӯшанда %v пешниҳод мебинад, мехостам 1 (худаш)",
					row["quotes"])
			}
			return
		}
	}
	t.Fatal("дархост дар рӯйхат нест")
}

// Харидор дар рӯйхати худаш шумораи ПУРРАИ пешниҳодҳоро мебинад.
func TestRFQMyListShowsAllQuoteCount(t *testing.T) {
	needDB(t)
	r := rfqRouter()
	_, buyerTok := newBuyer(t, r, 0)
	s1, _ := newTestSeller(t, 100, 10, 1)
	s2, _ := newTestSeller(t, 100, 10, 1)
	rfqID := newRFQ(t, r, buyerTok, 100)
	submitQuote(t, r, rfqID, sellerToken(t, r, s1), 10, 0)
	submitQuote(t, r, rfqID, sellerToken(t, r, s2), 11, 0)

	_, list := callList(t, r, "/api/v1/rfqs/my", bearer(buyerTok))
	for _, row := range list {
		if row["id"] == rfqID {
			if n, _ := row["quotes"].(float64); int(n) != 2 {
				t.Fatalf("харидор %v пешниҳод мебинад, мехостам 2", row["quotes"])
			}
			return
		}
	}
	t.Fatal("дархост дар рӯйхати харидор нест")
}

// Дархост бе мӯҳлати кофӣ рад мешавад.
func TestRFQRejectsBadInput(t *testing.T) {
	needDB(t)
	r := rfqRouter()
	_, tok := newBuyer(t, r, 0)

	cases := []map[string]any{
		{"title": "аб", "quantity": 10, "days": 7},
		{"title": "Номи дуруст", "quantity": 0, "days": 7},
		{"title": "Номи дуруст", "quantity": -5, "days": 7},
		{"title": "Номи дуруст", "quantity": 10, "days": 0,
			"closes_at": time.Now().Add(-time.Hour).Format(time.RFC3339)},
		{"title": "Номи дуруст", "quantity": 10,
			"closes_at": time.Now().AddDate(0, 0, 200).Format(time.RFC3339)},
	}
	for i, body := range cases {
		res := call(t, r, "POST", "/api/v1/rfqs", body, bearer(tok))
		if res.Status != 400 {
			t.Errorf("ҳолати %d: мехостам 400, гирифтам %d (%v)", i, res.Status, body)
			if res.Status == 201 {
				db.DB.Exec(`DELETE FROM rfqs WHERE id=$1`, str(res.Data, "id"))
			}
		}
	}
}

// Пешниҳоди фурӯшанда то 10 версия — баъд рад мешавад.
func TestRFQQuoteVersionLimit(t *testing.T) {
	needDB(t)
	r := rfqRouter()
	_, buyerTok := newBuyer(t, r, 0)
	sid, _ := newTestSeller(t, 100, 10, 1)
	tok := sellerToken(t, r, sid)
	rfqID := newRFQ(t, r, buyerTok, 100)

	for i := 0; i < quoteMaxVersions; i++ {
		res := call(t, r, "POST", "/api/v1/rfqs/"+rfqID+"/quotes", map[string]any{
			"unit_price": float64(100 - i), "min_qty": 1,
		}, bearer(tok))
		if res.Status != 201 {
			t.Fatalf("версияи %d: %d %s", i+1, res.Status, res.Error)
		}
	}
	res := call(t, r, "POST", "/api/v1/rfqs/"+rfqID+"/quotes", map[string]any{
		"unit_price": 50, "min_qty": 1,
	}, bearer(tok))
	if res.Status != 409 {
		t.Fatalf("версияи 11: мехостам 409, гирифтам %d", res.Status)
	}
	var n int
	db.DB.QueryRow(`SELECT COUNT(*) FROM rfq_quotes WHERE rfq_id=$1`, rfqID).Scan(&n)
	if n != quoteMaxVersions {
		t.Fatalf("%d версия, мехостам %d", n, quoteMaxVersions)
	}
}

// Фармоиши RFQ бояд дар панели фурӯшанда намоён бошад.
//
// Ин нуқтаи нозук аст: сатри `order_items` бе `product_id` аст, ва ҳамаи
// дархостҳои «моли ин фурӯшанда» пештар `JOIN products` мекарданд — пас
// бо `INNER JOIN` сатри бе маҳсулот умуман гум мешуд.
func TestRFQOrderVisibleToSeller(t *testing.T) {
	needDB(t)
	r := rfqRouter()
	uh := NewUserHandler(testSecret, nil)
	r.GET("/api/v1/seller/orders", middleware.Auth(), uh.SellerOrders)

	_, buyerTok := newBuyer(t, r, 0)
	sid, _ := newTestSeller(t, 100, 10, 1)
	tok := sellerToken(t, r, sid)

	rfqID := newRFQ(t, r, buyerTok, 200)
	qid := submitQuote(t, r, rfqID, tok, 5, 0)
	res := call(t, r, "POST", "/api/v1/quotes/"+qid+"/accept", nil, bearer(buyerTok))
	if res.Status != 201 {
		t.Fatalf("қабул: %d %s", res.Status, res.Error)
	}
	oid := str(res.Data, "order_id")
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM order_sellers WHERE order_id=$1`, oid)
		db.DB.Exec(`DELETE FROM order_items WHERE order_id=$1`, oid)
		db.DB.Exec(`DELETE FROM orders WHERE id=$1`, oid)
	})

	_, list := callList(t, r, "/api/v1/seller/orders", bearer(tok))
	for _, row := range list {
		if row["id"] == oid {
			// 5 сом. × 200 = 1000 сом.
			if s, _ := row["subtotal"].(float64); s != 1000 {
				t.Errorf("ҷамъи фурӯшанда = %v, мехостам 1000", row["subtotal"])
			}
			if n, _ := row["items"].(float64); int(n) != 1 {
				t.Errorf("шумораи мол = %v, мехостам 1", row["items"])
			}
			return
		}
	}
	t.Fatal("фармоиши RFQ дар панели фурӯшанда НЕСТ — сатри бе product_id гум шуд")
}

// Бе ин тест хато пинҳон мемонд: `product_id` NOT NULL буд.
func TestRFQOrderItemHasNoProduct(t *testing.T) {
	needDB(t)
	r := rfqRouter()
	_, buyerTok := newBuyer(t, r, 0)
	sid, _ := newTestSeller(t, 100, 10, 1)
	tok := sellerToken(t, r, sid)

	rfqID := newRFQ(t, r, buyerTok, 100)
	qid := submitQuote(t, r, rfqID, tok, 7, 0)
	res := call(t, r, "POST", "/api/v1/quotes/"+qid+"/accept", nil, bearer(buyerTok))
	if res.Status != 201 {
		t.Fatalf("қабул: %d %s", res.Status, res.Error)
	}
	oid := str(res.Data, "order_id")
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM order_sellers WHERE order_id=$1`, oid)
		db.DB.Exec(`DELETE FROM order_items WHERE order_id=$1`, oid)
		db.DB.Exec(`DELETE FROM orders WHERE id=$1`, oid)
	})

	var pid *string
	if err := db.DB.QueryRow(`SELECT product_id FROM order_items
		WHERE order_id=$1`, oid).Scan(&pid); err != nil {
		t.Fatalf("сатри мол хонда нашуд: %v", err)
	}
	if pid != nil {
		t.Fatalf("product_id = %v, мехостам NULL", *pid)
	}
}

// Фурӯшандаи радшуда огоҳӣ мегирад.
//
// Бе ин ӯ абадӣ интизори ҷавоб мемонад ва дигар ба дархостҳо ҷавоб
// намедиҳад — ва он гоҳ тамоми RFQ мемурад.
func TestRFQRejectedSellerGetsNotified(t *testing.T) {
	needDB(t)
	r := rfqRouter()
	_, buyerTok := newBuyer(t, r, 0)
	s1, _ := newTestSeller(t, 100, 10, 1)
	s2, _ := newTestSeller(t, 100, 10, 1)
	t1 := sellerToken(t, r, s1)
	t2 := sellerToken(t, r, s2)

	rfqID := newRFQ(t, r, buyerTok, 100)
	q1 := submitQuote(t, r, rfqID, t1, 10, 0)
	submitQuote(t, r, rfqID, t2, 11, 0)
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM notifications WHERE ref_id=$1`, rfqID)
	})

	res := call(t, r, "POST", "/api/v1/quotes/"+q1+"/accept", nil, bearer(buyerTok))
	if res.Status != 201 {
		t.Fatalf("қабул: %d %s", res.Status, res.Error)
	}
	oid := str(res.Data, "order_id")
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM order_sellers WHERE order_id=$1`, oid)
		db.DB.Exec(`DELETE FROM order_items WHERE order_id=$1`, oid)
		db.DB.Exec(`DELETE FROM orders WHERE id=$1`, oid)
		db.DB.Exec(`DELETE FROM notifications WHERE ref_id=$1`, oid)
	})

	var n int
	db.DB.QueryRow(`SELECT COUNT(*) FROM notifications
		WHERE user_id=$1 AND type='rfq'`, s2).Scan(&n)
	if n == 0 {
		t.Fatal("фурӯшандаи радшуда огоҳӣ нагирифт")
	}
	// Ва ғолиб огоҳии фармоиш мегирад.
	db.DB.QueryRow(`SELECT COUNT(*) FROM notifications
		WHERE user_id=$1 AND ref_id=$2`, s1, oid).Scan(&n)
	if n == 0 {
		t.Fatal("ғолиб огоҳӣ нагирифт")
	}
}

// Пешниҳод ба дархости нестшуда — 404, на panic.
func TestRFQQuoteToMissingRFQ(t *testing.T) {
	needDB(t)
	r := rfqRouter()
	sid, _ := newTestSeller(t, 100, 10, 1)
	tok := sellerToken(t, r, sid)
	res := call(t, r, "POST", "/api/v1/rfqs/"+uuid.NewString()+"/quotes",
		map[string]any{"unit_price": 10, "min_qty": 1}, bearer(tok))
	if res.Status != 404 {
		t.Fatalf("мехостам 404, гирифтам %d", res.Status)
	}
}
