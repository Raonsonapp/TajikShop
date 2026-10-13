package handlers

// Тестҳои фармоиши бисёрфурӯшанда бо Postgres-и воқеӣ.
//
// Камбудии аслӣ: фурӯшандаи A «фиристодам» мезад ва моли ҳанӯз
// нафиристодаи фурӯшандаи B ҳам «фиристода шуд» мешуд. Боз бадтар:
// мӯҳлати шикояти харидор (`protect_until`) барои моли нагирифта сар
// мешуд.

import (
	"encoding/json"
	"net/http/httptest"
	"testing"
	"time"

	"tajikshop/internal/db"
	"tajikshop/internal/middleware"
	"tajikshop/internal/storage"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func multiSellerRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	middleware.SetSecret(testSecret)
	r := gin.New()
	uh := NewUserHandler(testSecret, nil)
	oh := NewOrderHandler((*storage.R2Client)(nil))
	api := r.Group("/api/v1")
	api.POST("/auth/login", uh.Login)
	api.POST("/cart", middleware.Auth(), oh.AddToCart)
	api.POST("/orders/checkout", middleware.Auth(), oh.Checkout)
	api.POST("/seller/orders/:id/status", middleware.Auth(), oh.SellerUpdateOrderStatus)
	api.GET("/orders/:id/timeline", middleware.Auth(), oh.OrderTimeline)
	api.GET("/seller/orders", middleware.Auth(), uh.SellerOrders)
	return r
}

func sellerToken(t *testing.T, r *gin.Engine, sellerID string) string {
	t.Helper()
	var email string
	if err := db.DB.QueryRow(`SELECT email FROM users WHERE id=$1`, sellerID).Scan(&email); err != nil {
		t.Fatalf("почтаи фурӯшанда ёфт нашуд: %v", err)
	}
	tok, _ := login(t, r, email)
	return tok
}

func orderStatus(t *testing.T, oid string) string {
	t.Helper()
	var s string
	if err := db.DB.QueryRow(`SELECT status FROM orders WHERE id=$1`, oid).Scan(&s); err != nil {
		t.Fatalf("ҳолати фармоиш хонда нашуд: %v", err)
	}
	return s
}

func sellerRowStatus(t *testing.T, oid, sid string) string {
	t.Helper()
	var s string
	if err := db.DB.QueryRow(`SELECT status FROM order_sellers
		WHERE order_id=$1 AND seller_id=$2`, oid, sid).Scan(&s); err != nil {
		t.Fatalf("ҳолати зер-фармоиш хонда нашуд: %v", err)
	}
	return s
}

// twoSellerOrder — фармоиш бо моли ду фурӯшандаи гуногун.
func twoSellerOrder(t *testing.T, r *gin.Engine) (oid, s1, s2, t1, t2, buyerTok string) {
	t.Helper()
	var p1, p2 string
	s1, p1 = newTestSeller(t, 100, 10, 1)
	s2, p2 = newTestSeller(t, 200, 10, 1)
	_, buyerTok = newBuyer(t, r, 0)
	call(t, r, "POST", "/api/v1/cart", map[string]any{"product_id": p1, "quantity": 1}, bearer(buyerTok))
	call(t, r, "POST", "/api/v1/cart", map[string]any{"product_id": p2, "quantity": 1}, bearer(buyerTok))
	res := call(t, r, "POST", "/api/v1/orders/checkout",
		map[string]any{"payment_method": "cod"}, bearer(buyerTok))
	if res.Status != 201 {
		t.Fatalf("фармоиш сохта нашуд: %d %s", res.Status, res.Error)
	}
	oid = str(res.Data, "order_id")
	return oid, s1, s2, sellerToken(t, r, s1), sellerToken(t, r, s2), buyerTok
}

// ── Маҳз камбудии аслӣ ───────────────────────────────────────────────────

func TestSellerCannotShipAnotherSellersGoods(t *testing.T) {
	needDB(t)
	r := multiSellerRouter()
	oid, s1, s2, t1, _, _ := twoSellerOrder(t, r)

	// Фурӯшандаи 1: қабул → фиристод.
	for _, st := range []string{"processing", "shipped"} {
		res := call(t, r, "POST", "/api/v1/seller/orders/"+oid+"/status",
			map[string]any{"status": st}, bearer(t1))
		if res.Status != 200 {
			t.Fatalf("фурӯшандаи 1 → %s: %d %s", st, res.Status, res.Error)
		}
	}

	// Фурӯшандаи 1 воқеан фиристод.
	if got := sellerRowStatus(t, oid, s1); got != "shipped" {
		t.Fatalf("фурӯшандаи 1 = %q, мехостам shipped", got)
	}

	// Фурӯшандаи 2 бояд ТАҒЙИР НАЁБАД — маҳз ин камбудии аслӣ буд.
	if got := sellerRowStatus(t, oid, s2); got != "pending" {
		t.Fatalf("фурӯшандаи 2 = %q, мехостам pending — "+
			"фурӯшандаи 1 набояд ба моли ӯ таъсир расонад", got)
	}

	// Ҳолати умумии фармоиш бояд ҳамон «pending» бошад: як фурӯшанда
	// ҳанӯз ҳатто фармоишро қабул накардааст.
	if got := orderStatus(t, oid); got != "pending" {
		t.Fatalf("ҳолати умумӣ = %q, мехостам pending", got)
	}
}

// Фармоиш «фиристода шуд» мешавад ТАНҲО вақте, ки ҳар ду фиристоданд.
func TestOrderShippedOnlyWhenAllSellersShipped(t *testing.T) {
	needDB(t)
	r := multiSellerRouter()
	oid, _, _, t1, t2, _ := twoSellerOrder(t, r)

	ship := func(tok string) {
		for _, st := range []string{"processing", "shipped"} {
			res := call(t, r, "POST", "/api/v1/seller/orders/"+oid+"/status",
				map[string]any{"status": st}, bearer(tok))
			if res.Status != 200 {
				t.Fatalf("→ %s: %d %s", st, res.Status, res.Error)
			}
		}
	}

	ship(t1)
	if got := orderStatus(t, oid); got == "shipped" {
		t.Fatal("фармоиш «shipped» шуд, ҳол он ки фурӯшандаи 2 ҳанӯз нафиристодааст")
	}

	ship(t2)
	if got := orderStatus(t, oid); got != "shipped" {
		t.Fatalf("ҳолати умумӣ = %q, мехостам shipped (ҳар ду фиристоданд)", got)
	}
}

// Мӯҳлати ҳимояи харидор бояд аз лаҳзаи супоридани ОХИРИН мол сар шавад.
//
// Пештар он аз аввалин мол сар мешуд — яъне харидор метавонист мӯҳлати
// шикоятро барои моле, ки ҳанӯз нагирифтааст, гум кунад.
func TestProtectionStartsAfterLastDelivery(t *testing.T) {
	needDB(t)
	r := multiSellerRouter()
	oid, _, _, t1, t2, _ := twoSellerOrder(t, r)

	deliver := func(tok string) {
		for _, st := range []string{"processing", "shipped", "delivered"} {
			res := call(t, r, "POST", "/api/v1/seller/orders/"+oid+"/status",
				map[string]any{"status": st}, bearer(tok))
			if res.Status != 200 {
				t.Fatalf("→ %s: %d %s", st, res.Status, res.Error)
			}
		}
	}

	deliver(t1)
	var pu interface{}
	db.DB.QueryRow(`SELECT protect_until FROM orders WHERE id=$1`, oid).Scan(&pu)
	if _, ok := pu.(time.Time); ok {
		t.Fatal("protect_until гузошта шуд, ҳол он ки фурӯшандаи 2 ҳанӯз насупоридааст")
	}

	deliver(t2)
	db.DB.QueryRow(`SELECT protect_until FROM orders WHERE id=$1`, oid).Scan(&pu)
	if _, ok := pu.(time.Time); !ok {
		t.Fatal("protect_until баъди супоридани ҳар ду гузошта нашуд")
	}
	if got := orderStatus(t, oid); got != "delivered" {
		t.Fatalf("ҳолати умумӣ = %q, мехостам delivered", got)
	}
}

// Қадамҳо аз ҳолати ХУДИ ФУРӮШАНДА санҷида мешаванд.
//
// Пештар онҳо аз ҳолати умумӣ санҷида мешуданд: агар фурӯшандаи B
// фармоишро «processing» карда бошад, фурӯшандаи A метавонист фавран
// «shipped» занад — бе он ки худаш фармоишро қабул карда бошад.
func TestSellerCannotSkipOwnSteps(t *testing.T) {
	needDB(t)
	r := multiSellerRouter()
	oid, _, _, t1, t2, _ := twoSellerOrder(t, r)

	// Фурӯшандаи 2 фармоишро қабул мекунад.
	res := call(t, r, "POST", "/api/v1/seller/orders/"+oid+"/status",
		map[string]any{"status": "processing"}, bearer(t2))
	if res.Status != 200 {
		t.Fatalf("фурӯшандаи 2 → processing: %d %s", res.Status, res.Error)
	}

	// Фурӯшандаи 1 ҳанӯз «pending» аст — пас «shipped» мумкин нест.
	res = call(t, r, "POST", "/api/v1/seller/orders/"+oid+"/status",
		map[string]any{"status": "shipped"}, bearer(t1))
	if res.Status != 400 {
		t.Fatalf("мехостам 400, гирифтам %d — фурӯшандаи 1 бе қабул кардан "+
			"фиристода наметавонад", res.Status)
	}
}

// Бегона набояд ҳолати фармоишро иваз кунад.
func TestOutsiderCannotChangeOrderStatus(t *testing.T) {
	needDB(t)
	r := multiSellerRouter()
	oid, _, _, _, _, _ := twoSellerOrder(t, r)

	// Фурӯшандаи сеюм, ки дар ин фармоиш ҳеҷ моле надорад.
	s3, _ := newTestSeller(t, 50, 5, 1)
	t3 := sellerToken(t, r, s3)

	res := call(t, r, "POST", "/api/v1/seller/orders/"+oid+"/status",
		map[string]any{"status": "processing"}, bearer(t3))
	if res.Status != 403 {
		t.Fatalf("мехостам 403, гирифтам %d %s", res.Status, res.Error)
	}
}

// callList — ҳамон `call`, вале барои ҷавобе, ки `data`-и он РӮЙХАТ аст.
func callList(t *testing.T, r *gin.Engine, path string, headers map[string]string) (int, []map[string]any) {
	t.Helper()
	req := httptest.NewRequest("GET", path, nil)
	for k, v := range headers {
		req.Header.Set(k, v)
	}
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	var env struct {
		Data []map[string]any `json:"data"`
	}
	json.Unmarshal(w.Body.Bytes(), &env)
	return w.Code, env.Data
}

// Ҳар фурӯшанда дар рӯйхати худ ҳолати ХУДашро мебинад.
//
// Пештар ҳолати умумии фармоиш бармегашт — пас фурӯшандаи 2 «фиристода
// шуд» мебинад, ҳол он ки худаш ҳанӯз нафиристодааст.
func TestSellerOrdersShowsOwnStatus(t *testing.T) {
	needDB(t)
	r := multiSellerRouter()
	oid, _, _, t1, t2, _ := twoSellerOrder(t, r)

	// Фурӯшандаи 1 қабул мекунад ва мефиристад.
	for _, st := range []string{"processing", "shipped"} {
		res := call(t, r, "POST", "/api/v1/seller/orders/"+oid+"/status",
			map[string]any{"status": st}, bearer(t1))
		if res.Status != 200 {
			t.Fatalf("фурӯшандаи 1 → %s: %d %s", st, res.Status, res.Error)
		}
	}

	rowFor := func(tok string) map[string]any {
		code, list := callList(t, r, "/api/v1/seller/orders", bearer(tok))
		if code != 200 {
			t.Fatalf("seller/orders: %d", code)
		}
		for _, row := range list {
			if row["id"] == oid {
				return row
			}
		}
		t.Fatalf("фармоиши %s дар рӯйхат нест", oid)
		return nil
	}

	r1 := rowFor(t1)
	if r1["status"] != "shipped" {
		t.Errorf("фурӯшандаи 1 ҳолати худро %v мебинад, мехостам shipped", r1["status"])
	}

	r2 := rowFor(t2)
	if r2["status"] != "pending" {
		t.Errorf("фурӯшандаи 2 ҳолати худро %v мебинад, мехостам pending — "+
			"ӯ ҳанӯз чизе нафиристодааст", r2["status"])
	}
	// Ҳолати умумӣ низ бармегардад — то фурӯшанда бидонад, ки фармоиш
	// интизори фурӯшандаи дигар аст.
	if r2["order_status"] != "pending" {
		t.Errorf("order_status = %v, мехостам pending", r2["order_status"])
	}

	// Ҳар ду бояд ҳамон фармоишро бо ҷамъи ХУДашон бинанд.
	if s, _ := r1["subtotal"].(float64); s != 100 {
		t.Errorf("ҷамъи фурӯшандаи 1 = %v, мехостам 100", r1["subtotal"])
	}
	if s, _ := r2["subtotal"].(float64); s != 200 {
		t.Errorf("ҷамъи фурӯшандаи 2 = %v, мехостам 200", r2["subtotal"])
	}
}

// Харидор дар timeline пешрафти ҲАР ФУРӮШАНДАро мебинад.
func TestTimelineShowsPerSellerProgress(t *testing.T) {
	needDB(t)
	r := multiSellerRouter()
	oid, _, _, t1, _, buyerTok := twoSellerOrder(t, r)

	call(t, r, "POST", "/api/v1/seller/orders/"+oid+"/status",
		map[string]any{"status": "processing"}, bearer(t1))

	res := call(t, r, "GET", "/api/v1/orders/"+oid+"/timeline", nil, bearer(buyerTok))
	if res.Status != 200 {
		t.Fatalf("timeline: %d %s", res.Status, res.Error)
	}
	raw, ok := res.Data["sellers"].([]any)
	if !ok {
		t.Fatalf("`sellers` дар timeline нест: %v", res.Data["sellers"])
	}
	if len(raw) != 2 {
		t.Fatalf("%d фурӯшанда, мехостам 2", len(raw))
	}
	seen := map[string]bool{}
	for _, e := range raw {
		m, _ := e.(map[string]any)
		seen[(m["status"]).(string)] = true
		if (m["seller_name"]).(string) == "" {
			t.Error("номи фурӯшанда холӣ аст")
		}
		if n, _ := m["items"].(float64); int(n) != 1 {
			t.Errorf("шумораи мол = %v, мехостам 1", m["items"])
		}
	}
	if !seen["processing"] || !seen["pending"] {
		t.Fatalf("ҳолатҳои гуногун интизор буд, гирифтам: %v", seen)
	}
}

// Фармоиши КӮҲНА (пеш аз `order_sellers`) бояд кор кунад.
//
// Бе ин фурӯшанда дар фармоишҳои пештараи худ ҳеҷ коре карда
// наметавонист — яъне таърихи кориашро гум мекард.
func TestLegacyOrderWithoutSubordersStillWorks(t *testing.T) {
	needDB(t)
	r := multiSellerRouter()
	sid, pid := newTestSeller(t, 100, 10, 1)
	buyerID, _ := newBuyer(t, r, 0)

	// Фармоишро бо даст месозем — бе сатри `order_sellers`, мисли
	// фармоишҳои пеш аз ин тағйирот.
	oid := uuid.NewString()
	db.DB.Exec(`INSERT INTO orders(id,user_id,total,status,payment_method)
		VALUES($1,$2,100,'pending','cod')`, oid, buyerID)
	db.DB.Exec(`INSERT INTO order_items(id,order_id,product_id,seller_id,title,quantity,price)
		VALUES($1,$2,$3,$4,'Моли кӯҳна',1,100)`, uuid.NewString(), oid, pid, sid)
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM order_sellers WHERE order_id=$1`, oid)
		db.DB.Exec(`DELETE FROM order_items WHERE order_id=$1`, oid)
		db.DB.Exec(`DELETE FROM orders WHERE id=$1`, oid)
	})

	tok := sellerToken(t, r, sid)
	res := call(t, r, "POST", "/api/v1/seller/orders/"+oid+"/status",
		map[string]any{"status": "processing"}, bearer(tok))
	if res.Status != 200 {
		t.Fatalf("фармоиши кӯҳна: %d %s", res.Status, res.Error)
	}
	if got := sellerRowStatus(t, oid, sid); got != "processing" {
		t.Fatalf("зер-фармоиш = %q, мехостам processing", got)
	}
	if got := orderStatus(t, oid); got != "processing" {
		t.Fatalf("ҳолати умумӣ = %q, мехостам processing", got)
	}
}

// Агар як фурӯшанда бекор кунад, фармоиш набояд абадӣ дар «бекор»
// бимонад — моли фурӯшандаи дигар ҳамчунон меравад.
func TestOneSellerCancelDoesNotKillOrder(t *testing.T) {
	needDB(t)
	r := multiSellerRouter()
	oid, _, _, t1, t2, _ := twoSellerOrder(t, r)

	res := call(t, r, "POST", "/api/v1/seller/orders/"+oid+"/status",
		map[string]any{"status": "cancelled"}, bearer(t1))
	if res.Status != 200 {
		t.Fatalf("бекор кардан: %d %s", res.Status, res.Error)
	}

	// Фурӯшандаи 2 моли худро мефиристад.
	for _, st := range []string{"processing", "shipped"} {
		res = call(t, r, "POST", "/api/v1/seller/orders/"+oid+"/status",
			map[string]any{"status": st}, bearer(t2))
		if res.Status != 200 {
			t.Fatalf("фурӯшандаи 2 → %s: %d %s", st, res.Status, res.Error)
		}
	}
	if got := orderStatus(t, oid); got != "shipped" {
		t.Fatalf("ҳолати умумӣ = %q, мехостам shipped — "+
			"бекории як фурӯшанда набояд фармоишро бас кунад", got)
	}
}
