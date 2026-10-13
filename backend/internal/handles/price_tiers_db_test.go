package handlers

// Зинаҳои нархи яклухт бо Postgres-и воқеӣ.
//
// Муҳимтарин санҷиш ин ҷо: нархи зина бояд ВОҚЕАН дар checkout гирифта
// шавад. Агар экран нархи яклухтро нишон диҳад ва сервер нархи чаканаро
// гирад, харидор бештар мепардозад — ва ин навъи хатоест, ки боварии ӯро
// мешиканад.

import (
	"testing"

	"tajikshop/internal/db"
	"tajikshop/internal/middleware"
	"tajikshop/internal/storage"

	"github.com/gin-gonic/gin"
)

func tiersRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	middleware.SetSecret(testSecret)
	r := gin.New()
	uh := NewUserHandler(testSecret, nil)
	oh := NewOrderHandler((*storage.R2Client)(nil))
	ph := NewProductHandler((*storage.R2Client)(nil))
	api := r.Group("/api/v1")
	api.POST("/auth/login", uh.Login)
	api.GET("/products/:id/tiers", ph.GetTiers)
	api.PUT("/products/:id/tiers", middleware.Auth(), ph.SetTiers)
	api.POST("/cart", middleware.Auth(), oh.AddToCart)
	api.GET("/cart", middleware.Auth(), oh.GetCart)
	api.POST("/orders/checkout", middleware.Auth(), oh.Checkout)
	return r
}

// Сабад ва checkout бояд ЯК рақам диҳанд.
//
// Бе ин сабад нархи чаканаро нишон медод, вале checkout нархи яклухтро
// мегирифт — ду рақами гуногун дар як амал. Ҳатто агар фарқият ба фоидаи
// харидор бошад, ин боварии ӯро мешиканад.
func TestCartAndCheckoutAgreeOnTierPrice(t *testing.T) {
	needDB(t)
	r := tiersRouter()
	_, pid := newTestSeller(t, 100, 1000, 1)
	setTiers(t, pid, [2]float64{10, 90}, [2]float64{50, 80})
	_, tok := newBuyer(t, r, 0)

	call(t, r, "POST", "/api/v1/cart",
		map[string]any{"product_id": pid, "quantity": 60}, bearer(tok))

	// Сабад чиро нишон медиҳад?
	code, cart := callList(t, r, "/api/v1/cart", bearer(tok))
	if code != 200 {
		t.Fatalf("сабад: %d", code)
	}
	if len(cart) != 1 {
		t.Fatalf("%d мол дар сабад, мехостам 1", len(cart))
	}
	cartPrice, _ := cart[0]["price"].(float64)
	retail, _ := cart[0]["retail_price"].(float64)
	if cartPrice != 80 {
		t.Fatalf("нархи сабад = %v, мехостам 80 (зинаи 50+)", cart[0]["price"])
	}
	if retail != 100 {
		t.Fatalf("нархи чакана = %v, мехостам 100", cart[0]["retail_price"])
	}
	if cart[0]["wholesale"] != true {
		t.Error("нишонаи «яклухт» гузошта нашуд")
	}

	// Checkout чиро мегирад?
	res := call(t, r, "POST", "/api/v1/orders/checkout",
		map[string]any{"payment_method": "cod"}, bearer(tok))
	if res.Status != 201 {
		t.Fatalf("фармоиш: %d %s", res.Status, res.Error)
	}
	itemsTotal, _ := res.Data["items_total"].(float64)
	want := cartPrice * 60
	if itemsTotal != want {
		t.Fatalf("сабад %v × 60 = %v, вале checkout %v гирифт — ин фарқият "+
			"маҳз ҳамон хатоест, ки боварии харидорро мешиканад",
			cartPrice, want, itemsTotal)
	}
}

func setTiers(t *testing.T, pid string, tiers ...[2]float64) {
	t.Helper()
	db.DB.Exec(`DELETE FROM product_price_tiers WHERE product_id=$1`, pid)
	for _, tr := range tiers {
		if _, err := db.DB.Exec(`INSERT INTO product_price_tiers(id,product_id,min_qty,price)
			VALUES(uuid_generate_v4(),$1,$2,$3)`, pid, int(tr[0]), tr[1]); err != nil {
			t.Fatalf("зина сохта нашуд: %v", err)
		}
	}
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM product_price_tiers WHERE product_id=$1`, pid)
	})
}

// Маҳз ин он чизест, ки зинаҳоро аз «матн дар экран» ба хусусияти воқеӣ
// табдил медиҳад.
func TestCheckoutUsesWholesaleTier(t *testing.T) {
	needDB(t)
	r := tiersRouter()
	_, pid := newTestSeller(t, 100, 1000, 1) // нархи чакана 100 сом.
	setTiers(t, pid, [2]float64{10, 90}, [2]float64{50, 80})
	_, tok := newBuyer(t, r, 0)

	// 20 дона → зинаи 10+ → 90 сом. ҳар дона.
	// 20 × 90 = 1800; + 20 расонидан = 1820.
	call(t, r, "POST", "/api/v1/cart",
		map[string]any{"product_id": pid, "quantity": 20}, bearer(tok))
	res := call(t, r, "POST", "/api/v1/orders/checkout",
		map[string]any{"payment_method": "cod"}, bearer(tok))
	if res.Status != 201 {
		t.Fatalf("фармоиш: %d %s", res.Status, res.Error)
	}
	if got, _ := res.Data["items_total"].(float64); got != 1800 {
		t.Fatalf("ҷамъи мол = %v, мехостам 1800 (20 × 90 сом.) — "+
			"нархи зина гирифта нашуд", res.Data["items_total"])
	}
	if got, _ := res.Data["total"].(float64); got != 1820 {
		t.Fatalf("ҷамъи ниҳоӣ = %v, мехостам 1820", res.Data["total"])
	}

	// Нархи сабтшуда дар `order_items` низ бояд нархи зина бошад — вагарна
	// таърихи фармоиш рақами дигарро нишон медиҳад.
	var saved float64
	db.DB.QueryRow(`SELECT price FROM order_items WHERE product_id=$1
		ORDER BY created_at DESC LIMIT 1`, pid).Scan(&saved)
	if saved != 90 {
		t.Fatalf("нархи сабтшуда = %v, мехостам 90", saved)
	}
}

// Шумораи кам → нархи чакана, на яклухт.
func TestCheckoutRetailBelowTier(t *testing.T) {
	needDB(t)
	r := tiersRouter()
	_, pid := newTestSeller(t, 100, 1000, 1)
	setTiers(t, pid, [2]float64{10, 90})
	_, tok := newBuyer(t, r, 0)

	call(t, r, "POST", "/api/v1/cart",
		map[string]any{"product_id": pid, "quantity": 5}, bearer(tok))
	res := call(t, r, "POST", "/api/v1/orders/checkout",
		map[string]any{"payment_method": "cod"}, bearer(tok))
	if res.Status != 201 {
		t.Fatalf("фармоиш: %d %s", res.Status, res.Error)
	}
	// 5 × 100 = 500
	if got, _ := res.Data["items_total"].(float64); got != 500 {
		t.Fatalf("ҷамъи мол = %v, мехостам 500 (нархи чакана)", res.Data["items_total"])
	}
}

// Зинаи сеюм — шумораи калон.
func TestCheckoutUsesHighestMatchingTier(t *testing.T) {
	needDB(t)
	r := tiersRouter()
	_, pid := newTestSeller(t, 100, 1000, 1)
	setTiers(t, pid, [2]float64{10, 90}, [2]float64{50, 80})
	_, tok := newBuyer(t, r, 0)

	call(t, r, "POST", "/api/v1/cart",
		map[string]any{"product_id": pid, "quantity": 60}, bearer(tok))
	res := call(t, r, "POST", "/api/v1/orders/checkout",
		map[string]any{"payment_method": "cod"}, bearer(tok))
	if res.Status != 201 {
		t.Fatalf("фармоиш: %d %s", res.Status, res.Error)
	}
	// 60 × 80 = 4800
	if got, _ := res.Data["items_total"].(float64); got != 4800 {
		t.Fatalf("ҷамъи мол = %v, мехостам 4800 (60 × 80 сом.)", res.Data["items_total"])
	}
}

// ── Гузоштани зинаҳо аз ҷониби фурӯшанда ─────────────────────────────────

func TestSetTiersBySeller(t *testing.T) {
	needDB(t)
	r := tiersRouter()
	sellerID, pid := newTestSeller(t, 100, 100, 1)
	tok := sellerToken(t, r, sellerID)
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM product_price_tiers WHERE product_id=$1`, pid)
	})

	res := call(t, r, "PUT", "/api/v1/products/"+pid+"/tiers", map[string]any{
		"tiers": []map[string]any{
			{"min_qty": 50, "price": 80},
			{"min_qty": 10, "price": 90},
		},
	}, bearer(tok))
	if res.Status != 200 {
		t.Fatalf("гузоштани зинаҳо: %d %s", res.Status, res.Error)
	}
	if n, _ := res.Data["count"].(float64); int(n) != 2 {
		t.Fatalf("шумораи зинаҳо = %v, мехостам 2", res.Data["count"])
	}

	// Хондани оммавӣ.
	code, list := callList(t, r, "/api/v1/products/"+pid+"/tiers", nil)
	if code != 200 {
		t.Fatalf("хондани зинаҳо: %d", code)
	}
	if len(list) != 2 {
		t.Fatalf("%d зина, мехостам 2", len(list))
	}
	// Бояд тартиб дода шаванд: аввал 10, баъд 50.
	if q, _ := list[0]["min_qty"].(float64); int(q) != 10 {
		t.Errorf("зинаи аввал = %v, мехостам 10", list[0]["min_qty"])
	}
	if p, _ := list[1]["price"].(float64); p != 80 {
		t.Errorf("нархи зинаи дуюм = %v, мехостам 80", list[1]["price"])
	}
}

// Фурӯшандаи бегона набояд зинаҳои моли дигареро иваз кунад.
func TestSetTiersForeignProduct(t *testing.T) {
	needDB(t)
	r := tiersRouter()
	_, pid := newTestSeller(t, 100, 100, 1)
	otherID, _ := newTestSeller(t, 50, 10, 1)
	tok := sellerToken(t, r, otherID)

	res := call(t, r, "PUT", "/api/v1/products/"+pid+"/tiers", map[string]any{
		"tiers": []map[string]any{{"min_qty": 10, "price": 1}},
	}, bearer(tok))
	if res.Status != 403 {
		t.Fatalf("мехостам 403, гирифтам %d %s", res.Status, res.Error)
	}
	var n int
	db.DB.QueryRow(`SELECT COUNT(*) FROM product_price_tiers WHERE product_id=$1`, pid).Scan(&n)
	if n != 0 {
		t.Fatalf("%d зина сохта шуд — бегона набояд иваз кунад", n)
	}
}

// Зинаи гаронтар аз чакана бояд рад шавад.
func TestSetTiersRejectsAboveRetail(t *testing.T) {
	needDB(t)
	r := tiersRouter()
	sellerID, pid := newTestSeller(t, 100, 100, 1)
	tok := sellerToken(t, r, sellerID)

	res := call(t, r, "PUT", "/api/v1/products/"+pid+"/tiers", map[string]any{
		"tiers": []map[string]any{{"min_qty": 10, "price": 150}},
	}, bearer(tok))
	if res.Status != 400 {
		t.Fatalf("мехостам 400, гирифтам %d %s", res.Status, res.Error)
	}
}

// Гузоштани зинаҳои нав зинаҳои кӯҳнаро пурра иваз мекунад — ҳолати
// нимкора набояд монад.
func TestSetTiersReplacesAll(t *testing.T) {
	needDB(t)
	r := tiersRouter()
	sellerID, pid := newTestSeller(t, 100, 100, 1)
	tok := sellerToken(t, r, sellerID)
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM product_price_tiers WHERE product_id=$1`, pid)
	})

	call(t, r, "PUT", "/api/v1/products/"+pid+"/tiers", map[string]any{
		"tiers": []map[string]any{
			{"min_qty": 10, "price": 90}, {"min_qty": 50, "price": 80},
		},
	}, bearer(tok))

	// Акнун як зина мегузорем.
	res := call(t, r, "PUT", "/api/v1/products/"+pid+"/tiers", map[string]any{
		"tiers": []map[string]any{{"min_qty": 20, "price": 85}},
	}, bearer(tok))
	if res.Status != 200 {
		t.Fatalf("иваз кардан: %d %s", res.Status, res.Error)
	}

	var n, minQty int
	db.DB.QueryRow(`SELECT COUNT(*), COALESCE(MIN(min_qty),0)
		FROM product_price_tiers WHERE product_id=$1`, pid).Scan(&n, &minQty)
	if n != 1 || minQty != 20 {
		t.Fatalf("%d зина бо min_qty=%d, мехостам 1 зинаи 20", n, minQty)
	}
}

// Зинаҳоро пурра бардоштан мумкин бошад.
func TestSetTiersCanClear(t *testing.T) {
	needDB(t)
	r := tiersRouter()
	sellerID, pid := newTestSeller(t, 100, 100, 1)
	tok := sellerToken(t, r, sellerID)

	call(t, r, "PUT", "/api/v1/products/"+pid+"/tiers", map[string]any{
		"tiers": []map[string]any{{"min_qty": 10, "price": 90}},
	}, bearer(tok))
	res := call(t, r, "PUT", "/api/v1/products/"+pid+"/tiers",
		map[string]any{"tiers": []map[string]any{}}, bearer(tok))
	if res.Status != 200 {
		t.Fatalf("бардоштани зинаҳо: %d %s", res.Status, res.Error)
	}
	var n int
	db.DB.QueryRow(`SELECT COUNT(*) FROM product_price_tiers WHERE product_id=$1`, pid).Scan(&n)
	if n != 0 {
		t.Fatalf("%d зина монд, мехостам 0", n)
	}
}
