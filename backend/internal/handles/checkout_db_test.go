package handlers

// Тестҳои сохтани фармоиш бо Postgres-и воқеӣ.
//
// Ин тестҳо мантиқи тоза (`money_test.go`) НАМЕсанҷанд — он ҷо қоидаҳо
// санҷида мешаванд. Ин ҷо он чизе санҷида мешавад, ки танҳо бо базаи
// воқеӣ маълум мешавад: транзаксия, қулфи сатр, UNIQUE ва рафтор ҳангоми
// дархостҳои ҲАМЗАМОН.
//
// Маҳз ҳамзамонӣ он ҷойест, ки фурӯши зиёдатӣ рӯй медиҳад: ду харидор
// дар як лаҳза охирин молро мегиранд, ҳардуяш анборро «1» мебинанд, ва
// бе қулф ҳарду фармоиш мегузарад.
//
//	TAJIKSHOP_TEST_DB_URL='postgres://postgres@127.0.0.1:55432/tajikshop_test?sslmode=disable' \
//	  go test ./internal/handles/ -run Checkout -v

import (
	"fmt"
	"sync"
	"testing"

	"tajikshop/internal/db"
	"tajikshop/internal/middleware"
	"tajikshop/internal/storage"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func checkoutRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	middleware.SetSecret(testSecret)
	r := gin.New()
	uh := NewUserHandler(testSecret, nil)
	oh := NewOrderHandler((*storage.R2Client)(nil))
	api := r.Group("/api/v1")
	api.POST("/auth/login", uh.Login)
	api.POST("/cart", middleware.Auth(), oh.AddToCart)
	api.PATCH("/cart/:id", middleware.Auth(), oh.UpdateCartItem)
	api.GET("/cart", middleware.Auth(), oh.GetCart)
	api.POST("/orders/checkout", middleware.Auth(), oh.Checkout)
	return r
}

// newTestSeller — фурӯшанда бо як маҳсулот.
func newTestSeller(t *testing.T, price float64, stock, minQty int) (sellerID, productID string) {
	t.Helper()
	sellerID, _ = newTestUser(t)
	db.DB.Exec(`UPDATE users SET is_seller=true WHERE id=$1`, sellerID)
	productID = uuid.NewString()
	if _, err := db.DB.Exec(`INSERT INTO products
		(id,seller_id,title,price,stock,is_active,min_order_qty)
		VALUES($1,$2,$3,$4,$5,true,$6)`,
		productID, sellerID, "Моли тестӣ "+productID[:6], price, stock, minQty); err != nil {
		t.Fatalf("маҳсулот сохта нашуд: %v", err)
	}
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM order_items WHERE product_id=$1`, productID)
		db.DB.Exec(`DELETE FROM cart_items WHERE product_id=$1`, productID)
		db.DB.Exec(`DELETE FROM products WHERE id=$1`, productID)
	})
	return sellerID, productID
}

func newBuyer(t *testing.T, r *gin.Engine, balance float64) (id, token string) {
	t.Helper()
	id, email := newTestUser(t)
	if balance > 0 {
		db.DB.Exec(`UPDATE users SET wallet_balance=$1 WHERE id=$2`, balance, id)
	}
	token, _ = login(t, r, email)
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM checkout_keys WHERE user_id=$1`, id)
		db.DB.Exec(`DELETE FROM coupon_redemptions WHERE user_id=$1`, id)
		db.DB.Exec(`DELETE FROM wallet_transactions WHERE user_id=$1`, id)
		db.DB.Exec(`DELETE FROM order_sellers WHERE order_id IN (SELECT id FROM orders WHERE user_id=$1)`, id)
		db.DB.Exec(`DELETE FROM order_items WHERE order_id IN (SELECT id FROM orders WHERE user_id=$1)`, id)
		db.DB.Exec(`DELETE FROM orders WHERE user_id=$1`, id)
		db.DB.Exec(`DELETE FROM cart_items WHERE user_id=$1`, id)
	})
	return id, token
}

func bearer(tok string) map[string]string {
	return map[string]string{"Authorization": "Bearer " + tok}
}

func stockOf(t *testing.T, pid string) int {
	t.Helper()
	var n int
	if err := db.DB.QueryRow(`SELECT stock FROM products WHERE id=$1`, pid).Scan(&n); err != nil {
		t.Fatalf("анбор хонда нашуд: %v", err)
	}
	return n
}

// ── Фурӯши зиёдатӣ ───────────────────────────────────────────────────────

// Камбудии аслӣ: `UPDATE products SET stock=GREATEST(stock-$1,0)` ҳар
// шуморро қабул мекард. Дар анбор 3 дона, фармоиш 10 дона → қабул мешуд.
func TestCheckoutRejectsMoreThanStock(t *testing.T) {
	needDB(t)
	r := checkoutRouter()
	_, pid := newTestSeller(t, 100, 3, 1)
	_, tok := newBuyer(t, r, 0)

	// Сервер худаш то анбор маҳдуд мекунад — 10 дона илова намешавад.
	add := call(t, r, "POST", "/api/v1/cart",
		map[string]any{"product_id": pid, "quantity": 10}, bearer(tok))
	if add.Status != 200 {
		t.Fatalf("илова: %d %s", add.Status, add.Error)
	}
	if q, _ := add.Data["quantity"].(float64); int(q) != 3 {
		t.Fatalf("шумора дар сабад = %v, мехостам 3 (ҳадди анбор)", add.Data["quantity"])
	}

	// Акнун мустақиман дар база шуморро зиёд мекунем — гӯё мизоҷи кӯҳна
	// ё касе, ки API-ро дасткорӣ мекунад.
	db.DB.Exec(`UPDATE cart_items SET quantity=10 WHERE product_id=$1`, pid)

	res := call(t, r, "POST", "/api/v1/orders/checkout",
		map[string]any{"payment_method": "cod"}, bearer(tok))
	if res.Status != 409 {
		t.Fatalf("мехостам 409 (фармоиш рад шавад), гирифтам %d %s", res.Status, res.Error)
	}
	if got := stockOf(t, pid); got != 3 {
		t.Fatalf("анбор = %d, мехостам 3 — фармоиши радшуда набояд анборро кам кунад", got)
	}
	var orders int
	db.DB.QueryRow(`SELECT COUNT(*) FROM order_items WHERE product_id=$1`, pid).Scan(&orders)
	if orders != 0 {
		t.Fatalf("%d моли фармоиш сохта шуд — мехостам 0", orders)
	}
}

// Санҷиши аз ҳама муҳим: ду харидор дар ЯК ЛАҲЗА охирин молро мегиранд.
//
// Бе `FOR UPDATE` ҳарду анборро «1» мебинанд ва ҳарду фармоиш мегузарад
// — фурӯшанда як молро ба ду нафар мефурӯшад.
func TestCheckoutConcurrentLastItem(t *testing.T) {
	needDB(t)
	r := checkoutRouter()
	_, pid := newTestSeller(t, 100, 1, 1) // ЯК дона дар анбор

	const buyers = 8
	toks := make([]string, buyers)
	for i := 0; i < buyers; i++ {
		_, toks[i] = newBuyer(t, r, 0)
		db.DB.Exec(`INSERT INTO cart_items(id,user_id,product_id,quantity)
			SELECT $1,u.id,$2,1 FROM users u WHERE u.id=(
				SELECT user_id FROM auth_sessions ORDER BY created_at DESC LIMIT 0)`,
			uuid.NewString(), pid)
		add := call(t, r, "POST", "/api/v1/cart",
			map[string]any{"product_id": pid, "quantity": 1}, bearer(toks[i]))
		if add.Status != 200 {
			t.Fatalf("харидори %d илова накард: %d %s", i, add.Status, add.Error)
		}
	}

	var wg sync.WaitGroup
	results := make([]int, buyers)
	for i := 0; i < buyers; i++ {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			res := call(t, r, "POST", "/api/v1/orders/checkout",
				map[string]any{"payment_method": "cod"}, bearer(toks[i]))
			results[i] = res.Status
		}(i)
	}
	wg.Wait()

	ok := 0
	for _, s := range results {
		if s == 201 {
			ok++
		}
	}
	if ok != 1 {
		t.Fatalf("%d фармоиш гузашт, мехостам ТАНҲО 1 (дар анбор 1 дона буд). Ҳолатҳо: %v", ok, results)
	}
	if got := stockOf(t, pid); got != 0 {
		t.Fatalf("анбор = %d, мехостам 0", got)
	}
	var sold int
	db.DB.QueryRow(`SELECT COALESCE(SUM(quantity),0) FROM order_items WHERE product_id=$1`, pid).Scan(&sold)
	if sold != 1 {
		t.Fatalf("%d дона фурӯхта шуд, мехостам 1", sold)
	}
}

// ── Idempotency ──────────────────────────────────────────────────────────

// Ду зеркунии тугма ё такрори шабака набояд ду фармоиш созад.
func TestCheckoutIdempotency(t *testing.T) {
	needDB(t)
	r := checkoutRouter()
	_, pid := newTestSeller(t, 50, 10, 1)
	_, tok := newBuyer(t, r, 0)
	call(t, r, "POST", "/api/v1/cart", map[string]any{"product_id": pid, "quantity": 2}, bearer(tok))

	h := bearer(tok)
	h["Idempotency-Key"] = "test-key-" + uuid.NewString()

	first := call(t, r, "POST", "/api/v1/orders/checkout", map[string]any{"payment_method": "cod"}, h)
	if first.Status != 201 {
		t.Fatalf("фармоиши аввал: %d %s", first.Status, first.Error)
	}
	// Такрор бо ҳамон калид — сабад аллакай холӣ аст, пас бе idempotency
	// ин «сабад холӣ аст» мегирифт. Бо он ҳамон фармоиш бармегардад.
	second := call(t, r, "POST", "/api/v1/orders/checkout", map[string]any{"payment_method": "cod"}, h)
	if second.Status != 201 {
		t.Fatalf("такрор: %d %s — мехостам 201 бо ҳамон фармоиш", second.Status, second.Error)
	}
	if str(first.Data, "order_id") != str(second.Data, "order_id") {
		t.Fatalf("фармоишҳои гуногун: %s != %s", str(first.Data, "order_id"), str(second.Data, "order_id"))
	}
	if second.Data["repeated"] != true {
		t.Errorf("такрор бояд `repeated: true` дошта бошад, дорад: %v", second.Data["repeated"])
	}
	if got := stockOf(t, pid); got != 8 {
		t.Fatalf("анбор = %d, мехостам 8 — анбор бояд ЯК бор кам шавад", got)
	}
}

// Ҳамон калид дар ҳашт дархости ҳамзамон — боз ҳам як фармоиш.
func TestCheckoutIdempotencyConcurrent(t *testing.T) {
	needDB(t)
	r := checkoutRouter()
	_, pid := newTestSeller(t, 50, 100, 1)
	_, tok := newBuyer(t, r, 0)
	call(t, r, "POST", "/api/v1/cart", map[string]any{"product_id": pid, "quantity": 2}, bearer(tok))

	key := "concurrent-" + uuid.NewString()
	var wg sync.WaitGroup
	ids := make([]string, 8)
	codes := make([]int, 8)
	for i := 0; i < 8; i++ {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			h := bearer(tok)
			h["Idempotency-Key"] = key
			res := call(t, r, "POST", "/api/v1/orders/checkout",
				map[string]any{"payment_method": "cod"}, h)
			codes[i] = res.Status
			ids[i] = str(res.Data, "order_id")
		}(i)
	}
	wg.Wait()

	uniq := map[string]bool{}
	for _, id := range ids {
		if id != "" {
			uniq[id] = true
		}
	}
	if len(uniq) != 1 {
		t.Fatalf("%d фармоиши гуногун сохта шуд, мехостам 1. Ҳолатҳо: %v", len(uniq), codes)
	}
	if got := stockOf(t, pid); got != 98 {
		t.Fatalf("анбор = %d, мехостам 98 — ҳашт дархост бояд як бор кам кунанд", got)
	}
}

// ── Транзаксия ───────────────────────────────────────────────────────────

// Фармоиши радшуда набояд ҳеҷ осоре гузорад: на сатри фармоиш, на
// камшавии анбор, на тоза шудани сабад.
func TestCheckoutFailureLeavesNothing(t *testing.T) {
	needDB(t)
	r := checkoutRouter()
	_, pid := newTestSeller(t, 100, 5, 1)
	buyerID, tok := newBuyer(t, r, 0)
	call(t, r, "POST", "/api/v1/cart", map[string]any{"product_id": pid, "quantity": 2}, bearer(tok))

	// Маҳсулотро хомӯш мекунем — checkout бояд афтад.
	db.DB.Exec(`UPDATE products SET is_active=false WHERE id=$1`, pid)

	res := call(t, r, "POST", "/api/v1/orders/checkout",
		map[string]any{"payment_method": "cod"}, bearer(tok))
	if res.Status != 409 {
		t.Fatalf("мехостам 409, гирифтам %d", res.Status)
	}

	var orders, cart int
	db.DB.QueryRow(`SELECT COUNT(*) FROM orders WHERE user_id=$1`, buyerID).Scan(&orders)
	db.DB.QueryRow(`SELECT COUNT(*) FROM cart_items WHERE user_id=$1`, buyerID).Scan(&cart)
	if orders != 0 {
		t.Errorf("%d фармоиш монд — мехостам 0", orders)
	}
	if cart != 1 {
		t.Errorf("сабад %d мол дорад — мехостам 1 (сабад набояд тоза шавад)", cart)
	}
	if got := stockOf(t, pid); got != 5 {
		t.Errorf("анбор = %d, мехостам 5", got)
	}
}

// Пардохти ҳамён: тавозун камтар аз ҷамъ → фармоиш нашавад ва пул наравад.
func TestCheckoutWalletInsufficient(t *testing.T) {
	needDB(t)
	r := checkoutRouter()
	_, pid := newTestSeller(t, 1000, 5, 1)
	buyerID, tok := newBuyer(t, r, 50) // 50 сом., лозим 1000+20
	call(t, r, "POST", "/api/v1/cart", map[string]any{"product_id": pid, "quantity": 1}, bearer(tok))

	res := call(t, r, "POST", "/api/v1/orders/checkout",
		map[string]any{"payment_method": "wallet"}, bearer(tok))
	if res.Status != 400 {
		t.Fatalf("мехостам 400, гирифтам %d %s", res.Status, res.Error)
	}
	var bal float64
	db.DB.QueryRow(`SELECT wallet_balance FROM users WHERE id=$1`, buyerID).Scan(&bal)
	if bal != 50 {
		t.Fatalf("тавозун = %v, мехостам 50 — пул набояд равад", bal)
	}
	if got := stockOf(t, pid); got != 5 {
		t.Fatalf("анбор = %d, мехостам 5", got)
	}
}

// Пардохти ҳамён бо тавозуни кофӣ: ҷамъи дуруст аз ҳамён меравад.
func TestCheckoutWalletExactTotal(t *testing.T) {
	needDB(t)
	r := checkoutRouter()
	_, pid := newTestSeller(t, 19.99, 5, 1)
	buyerID, tok := newBuyer(t, r, 100)
	call(t, r, "POST", "/api/v1/cart", map[string]any{"product_id": pid, "quantity": 3}, bearer(tok))

	// 19.99 * 3 = 59.97; + 20 расонидан = 79.97
	res := call(t, r, "POST", "/api/v1/orders/checkout",
		map[string]any{"payment_method": "wallet"}, bearer(tok))
	if res.Status != 201 {
		t.Fatalf("фармоиш: %d %s", res.Status, res.Error)
	}
	if total, _ := res.Data["total"].(float64); fmt.Sprintf("%.2f", total) != "79.97" {
		t.Fatalf("ҷамъ = %v, мехостам 79.97", res.Data["total"])
	}
	var bal float64
	db.DB.QueryRow(`SELECT wallet_balance FROM users WHERE id=$1`, buyerID).Scan(&bal)
	if fmt.Sprintf("%.2f", bal) != "20.03" {
		t.Fatalf("тавозун = %v, мехостам 20.03", bal)
	}
}

// Пули расонидан бояд дар СЕРВЕР ҳисоб шавад.
//
// Пештар он аз муштарӣ меомад, пас `{"delivery_fee": 0}` расониданро
// ройгон мекард.
func TestCheckoutIgnoresClientDeliveryFee(t *testing.T) {
	needDB(t)
	r := checkoutRouter()
	_, pid := newTestSeller(t, 100, 5, 1)
	_, tok := newBuyer(t, r, 0)
	call(t, r, "POST", "/api/v1/cart", map[string]any{"product_id": pid, "quantity": 1}, bearer(tok))

	res := call(t, r, "POST", "/api/v1/orders/checkout",
		map[string]any{"payment_method": "cod", "delivery_fee": 0, "total": 1}, bearer(tok))
	if res.Status != 201 {
		t.Fatalf("фармоиш: %d %s", res.Status, res.Error)
	}
	if fee, _ := res.Data["delivery_fee"].(float64); fee != 20 {
		t.Fatalf("расонидан = %v, мехостам 20 — рақами муштарӣ бояд нодида монад", res.Data["delivery_fee"])
	}
	if total, _ := res.Data["total"].(float64); total != 120 {
		t.Fatalf("ҷамъ = %v, мехостам 120", res.Data["total"])
	}
}

// «Аз мағоза мегирам» → расонидан ройгон.
func TestCheckoutPickupIsFree(t *testing.T) {
	needDB(t)
	r := checkoutRouter()
	_, pid := newTestSeller(t, 100, 5, 1)
	_, tok := newBuyer(t, r, 0)
	call(t, r, "POST", "/api/v1/cart", map[string]any{"product_id": pid, "quantity": 1}, bearer(tok))

	res := call(t, r, "POST", "/api/v1/orders/checkout",
		map[string]any{"payment_method": "cod", "fulfilment": "pickup"}, bearer(tok))
	if res.Status != 201 {
		t.Fatalf("фармоиш: %d %s", res.Status, res.Error)
	}
	if total, _ := res.Data["total"].(float64); total != 100 {
		t.Fatalf("ҷамъ = %v, мехостам 100", res.Data["total"])
	}
}

// ── Зер-фармоиши фурӯшандагон ────────────────────────────────────────────

// Сабад бо моли ду фурӯшанда → ду сатри `order_sellers` бо ҷамъи худашон.
func TestCheckoutSplitsPerSeller(t *testing.T) {
	needDB(t)
	r := checkoutRouter()
	s1, p1 := newTestSeller(t, 100, 10, 1)
	s2, p2 := newTestSeller(t, 250, 10, 1)
	_, tok := newBuyer(t, r, 0)
	call(t, r, "POST", "/api/v1/cart", map[string]any{"product_id": p1, "quantity": 2}, bearer(tok))
	call(t, r, "POST", "/api/v1/cart", map[string]any{"product_id": p2, "quantity": 1}, bearer(tok))

	res := call(t, r, "POST", "/api/v1/orders/checkout",
		map[string]any{"payment_method": "cod"}, bearer(tok))
	if res.Status != 201 {
		t.Fatalf("фармоиш: %d %s", res.Status, res.Error)
	}
	oid := str(res.Data, "order_id")

	subs := map[string]float64{}
	rows, err := db.DB.Query(`SELECT seller_id, subtotal FROM order_sellers WHERE order_id=$1`, oid)
	if err != nil {
		t.Fatalf("order_sellers хонда нашуд: %v", err)
	}
	defer rows.Close()
	for rows.Next() {
		var sid string
		var sub float64
		rows.Scan(&sid, &sub)
		subs[sid] = sub
	}
	if len(subs) != 2 {
		t.Fatalf("%d зер-фармоиш, мехостам 2: %v", len(subs), subs)
	}
	if subs[s1] != 200 {
		t.Errorf("фурӯшандаи 1 = %v, мехостам 200", subs[s1])
	}
	if subs[s2] != 250 {
		t.Errorf("фурӯшандаи 2 = %v, мехостам 250", subs[s2])
	}
	// Пули расонидан ба зер-фармоиш дохил намешавад — он ба тамоми
	// фармоиш тааллуқ дорад.
	if subs[s1]+subs[s2] != 450 {
		t.Errorf("ҷамъи зер-фармоишҳо = %v, мехостам 450 (бе расонидан)", subs[s1]+subs[s2])
	}
}

// ── Купон ────────────────────────────────────────────────────────────────

// Пештар танҳо `used_count`-и умумӣ буд, пас як корбар метавонист ҳамон
// купонро бефосила истифода кунад.
func TestCheckoutCouponOncePerUser(t *testing.T) {
	needDB(t)
	r := checkoutRouter()
	_, pid := newTestSeller(t, 100, 100, 1)
	_, tok := newBuyer(t, r, 0)

	code := "TEST" + uuid.NewString()[:8]
	db.DB.Exec(`INSERT INTO coupons(id,code,discount_percent,is_active,per_user_limit)
		VALUES($1,$2,10,true,1)`, uuid.NewString(), code)
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM coupon_redemptions WHERE code=$1`, code)
		db.DB.Exec(`DELETE FROM coupons WHERE code=$1`, code)
	})

	// Фармоиши аввал — тахфиф кор мекунад. 100 + 20 = 120; 10% = 12.
	call(t, r, "POST", "/api/v1/cart", map[string]any{"product_id": pid, "quantity": 1}, bearer(tok))
	first := call(t, r, "POST", "/api/v1/orders/checkout",
		map[string]any{"payment_method": "cod", "coupon_code": code}, bearer(tok))
	if first.Status != 201 {
		t.Fatalf("фармоиши аввал: %d %s", first.Status, first.Error)
	}
	if d, _ := first.Data["discount"].(float64); d != 12 {
		t.Fatalf("тахфифи аввал = %v, мехостам 12", first.Data["discount"])
	}

	// Фармоиши дуюм бо ҲАМОН купон — тахфиф набояд дода шавад.
	call(t, r, "POST", "/api/v1/cart", map[string]any{"product_id": pid, "quantity": 1}, bearer(tok))
	second := call(t, r, "POST", "/api/v1/orders/checkout",
		map[string]any{"payment_method": "cod", "coupon_code": code}, bearer(tok))
	if second.Status != 201 {
		t.Fatalf("фармоиши дуюм: %d %s", second.Status, second.Error)
	}
	if d, _ := second.Data["discount"].(float64); d != 0 {
		t.Fatalf("тахфифи дуюм = %v, мехостам 0 — купон як бор барои ҳар корбар", second.Data["discount"])
	}
}

// ── Ҳадди ақали фурӯшанда (MOQ) ──────────────────────────────────────────

func TestCheckoutEnforcesMinOrderQty(t *testing.T) {
	needDB(t)
	r := checkoutRouter()
	_, pid := newTestSeller(t, 10, 100, 12) // ҳадди ақал 12 дона
	_, tok := newBuyer(t, r, 0)

	// Иловаи 1 дона → сервер худаш ба 12 мебардорад.
	add := call(t, r, "POST", "/api/v1/cart",
		map[string]any{"product_id": pid, "quantity": 1}, bearer(tok))
	if q, _ := add.Data["quantity"].(float64); int(q) != 12 {
		t.Fatalf("шумора = %v, мехостам 12 (ҳадди ақали фурӯшанда)", add.Data["quantity"])
	}

	// Агар касе мустақиман камтар гузорад — checkout рад мекунад.
	db.DB.Exec(`UPDATE cart_items SET quantity=2 WHERE product_id=$1`, pid)
	res := call(t, r, "POST", "/api/v1/orders/checkout",
		map[string]any{"payment_method": "cod"}, bearer(tok))
	if res.Status != 409 {
		t.Fatalf("мехостам 409, гирифтам %d %s", res.Status, res.Error)
	}
}

// Фурӯшанда моли худашро нахарад — вагарна ҳисоби фурӯш ва рейтинг
// вайрон мешавад.
func TestCheckoutSellerCannotBuyOwnProduct(t *testing.T) {
	needDB(t)
	r := checkoutRouter()
	sellerID, pid := newTestSeller(t, 100, 10, 1)
	var email string
	db.DB.QueryRow(`SELECT email FROM users WHERE id=$1`, sellerID).Scan(&email)
	tok, _ := login(t, r, email)

	res := call(t, r, "POST", "/api/v1/cart",
		map[string]any{"product_id": pid, "quantity": 1}, bearer(tok))
	if res.Status != 400 {
		t.Fatalf("мехостам 400, гирифтам %d %s", res.Status, res.Error)
	}
}
