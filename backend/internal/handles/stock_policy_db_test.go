package handlers

// Ҷараёни пурраи моли тамомшуда, бо Postgres-и воқеӣ.
//
// Пештар мол баъди тамом шудан АБАДӢ дар бозор мемонд: фурӯшанда огоҳӣ
// мегирифт («боз ҳаст?»), вале агар ҷавоб надиҳад — ва аксаран ҷавоб
// намедиҳад — харидор моли нобударо мебинад, зер мекунад, ва харида
// наметавонад.

import (
	"testing"

	"tajikshop/internal/db"
	"tajikshop/internal/middleware"
	"tajikshop/internal/storage"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func stockRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	middleware.SetSecret(testSecret)
	r := gin.New()
	uh := NewUserHandler(testSecret, nil)
	oh := NewOrderHandler((*storage.R2Client)(nil))
	ph := NewProductHandler((*storage.R2Client)(nil))
	api := r.Group("/api/v1")
	api.POST("/auth/login", uh.Login)
	api.POST("/cart", middleware.Auth(), oh.AddToCart)
	api.POST("/orders/checkout", middleware.Auth(), oh.Checkout)
	api.POST("/products/:id/restock", middleware.Auth(), ph.Restock)
	api.GET("/seller/products/sold-out", middleware.Auth(), ph.SoldOutProducts)
	return r
}

func productState(t *testing.T, pid string) (stock int, active, asked bool) {
	t.Helper()
	var askedAt interface{}
	if err := db.DB.QueryRow(`SELECT stock, COALESCE(is_active,true), sold_out_asked_at
		FROM products WHERE id=$1`, pid).Scan(&stock, &active, &askedAt); err != nil {
		t.Fatalf("мол хонда нашуд: %v", err)
	}
	return stock, active, askedAt != nil
}

// ── Ҷараёни пурра ────────────────────────────────────────────────────────

// Харидор охирин донаро мегирад → фурӯшанда савол мегирад → ҷавоб
// намедиҳад → мол баъди мӯҳлат ХУДКОР пинҳон мешавад.
func TestSoldOutAutoHiddenWhenNoAnswer(t *testing.T) {
	needDB(t)
	r := stockRouter()
	sellerID, pid := newTestSeller(t, 100, 1, 1) // ЯК дона
	_, tok := newBuyer(t, r, 0)
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM notifications WHERE user_id=$1`, sellerID)
	})

	call(t, r, "POST", "/api/v1/cart",
		map[string]any{"product_id": pid, "quantity": 1}, bearer(tok))
	if res := call(t, r, "POST", "/api/v1/orders/checkout",
		map[string]any{"payment_method": "cod"}, bearer(tok)); res.Status != 201 {
		t.Fatalf("фармоиш: %d %s", res.Status, res.Error)
	}

	// Мол тамом шуд, савол дода шуд, вале ҳанӯз дар бозор аст.
	stock, active, asked := productState(t, pid)
	if stock != 0 {
		t.Fatalf("захира = %d, мехостам 0", stock)
	}
	if !active {
		t.Fatal("мол фавран пинҳон шуд — аввал бояд савол дода шавад")
	}
	if !asked {
		t.Fatal("`sold_out_asked_at` гузошта нашуд — бе он мӯҳлат сар намешавад")
	}
	var notifs int
	db.DB.QueryRow(`SELECT COUNT(*) FROM notifications
		WHERE user_id=$1 AND type='stock' AND ref_id=$2`, sellerID, pid).Scan(&notifs)
	if notifs != 1 {
		t.Fatalf("%d огоҳӣ, мехостам 1", notifs)
	}

	// Ҳанӯз мӯҳлат нагузашт — sweeper набояд даст расонад.
	hideUnansweredSoldOut()
	if _, active, _ = productState(t, pid); !active {
		t.Fatal("мол пеш аз мӯҳлат пинҳон шуд")
	}

	// Мӯҳлат мегузарад.
	db.DB.Exec(`UPDATE products SET sold_out_asked_at = NOW() - INTERVAL '5 days'
		WHERE id=$1`, pid)
	if n := hideUnansweredSoldOut(); n != 1 {
		t.Fatalf("sweeper %d молро пинҳон кард, мехостам 1", n)
	}

	_, active, _ = productState(t, pid)
	if active {
		t.Fatal("мол пинҳон нашуд — харидор ҳамчунон моли нобударо мебинад")
	}

	// Мол бояд МОНАД, на нест шавад: таърихи фармоиш ба он ишора
	// мекунад, ва фурӯшанда бояд онро баргардонда тавонад.
	var exists bool
	db.DB.QueryRow(`SELECT EXISTS(SELECT 1 FROM products WHERE id=$1)`, pid).Scan(&exists)
	if !exists {
		t.Fatal("мол ҲАЗФ шуд — таърихи фармоиш вайрон мешавад")
	}

	// Огоҳии дуюм: фурӯшанда бояд бидонад, ЧАРО эълонаш нопадид шуд.
	var hidden int
	db.DB.QueryRow(`SELECT COUNT(*) FROM notifications
		WHERE user_id=$1 AND ref_id=$2 AND title='Эълон пинҳон шуд'`,
		sellerID, pid).Scan(&hidden)
	if hidden != 1 {
		t.Fatalf("%d огоҳии пинҳоншавӣ, мехостам 1 — бе он фурӯшанда "+
			"намефаҳмад, чаро эълонаш нопадид шуд", hidden)
	}
}

// Агар фурӯшанда ҶАВОБ ДИҲАД, мол набояд пинҳон шавад.
func TestSoldOutNotHiddenAfterRestock(t *testing.T) {
	needDB(t)
	r := stockRouter()
	sellerID, pid := newTestSeller(t, 100, 1, 1)
	_, tok := newBuyer(t, r, 0)
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM notifications WHERE user_id=$1`, sellerID)
	})

	call(t, r, "POST", "/api/v1/cart",
		map[string]any{"product_id": pid, "quantity": 1}, bearer(tok))
	call(t, r, "POST", "/api/v1/orders/checkout",
		map[string]any{"payment_method": "cod"}, bearer(tok))

	// Фурӯшанда мегӯяд «ҳа, боз ҳаст».
	stok := sellerToken(t, r, sellerID)
	if res := call(t, r, "POST", "/api/v1/products/"+pid+"/restock",
		map[string]any{"stock": 10}, bearer(stok)); res.Status != 200 {
		t.Fatalf("restock: %d %s", res.Status, res.Error)
	}

	stock, active, asked := productState(t, pid)
	if stock != 10 || !active {
		t.Fatalf("захира=%d фаъол=%v, мехостам 10 ва true", stock, active)
	}
	if asked {
		t.Fatal("`sold_out_asked_at` тоза нашуд — sweeper молро баъди се " +
			"рӯз пинҳон мекунад, ҳол он ки он баргардонда шудааст")
	}

	// Мӯҳлат мегузарад — вале мол ҷавоб гирифтааст.
	db.DB.Exec(`UPDATE products SET updated_at = NOW() - INTERVAL '10 days' WHERE id=$1`, pid)
	hideUnansweredSoldOut()
	if _, active, _ = productState(t, pid); !active {
		t.Fatal("моли баргардондашуда пинҳон шуд")
	}
}

// ── Моли бешумор ─────────────────────────────────────────────────────────

// Фурӯшандаи бе анбор (дӯзанда, нонвой) набояд ҳеҷ гоҳ «тамом» шавад.
func TestUnlimitedProductNeverSoldOut(t *testing.T) {
	needDB(t)
	r := stockRouter()
	sellerID, pid := newTestSeller(t, 100, 5, 1)
	db.DB.Exec(`UPDATE products SET track_stock=false, stock=$2 WHERE id=$1`,
		pid, maxStock)
	_, tok := newBuyer(t, r, 0)
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM notifications WHERE user_id=$1`, sellerID)
	})

	// Шумораи калон — аз захираи аслӣ хеле зиёд.
	call(t, r, "POST", "/api/v1/cart",
		map[string]any{"product_id": pid, "quantity": 50}, bearer(tok))
	db.DB.Exec(`UPDATE cart_items SET quantity=50 WHERE product_id=$1`, pid)

	if res := call(t, r, "POST", "/api/v1/orders/checkout",
		map[string]any{"payment_method": "cod"}, bearer(tok)); res.Status != 201 {
		t.Fatalf("фармоиши моли бешумор: %d %s", res.Status, res.Error)
	}

	stock, active, asked := productState(t, pid)
	// Захира набояд кам шавад.
	if stock != maxStock {
		t.Errorf("захира = %d — моли бешумор набояд кам шавад", stock)
	}
	if !active {
		t.Error("моли бешумор пинҳон шуд")
	}
	if asked {
		t.Error("моли бешумор саволи «боз ҳаст?» гирифт — ин фурӯшандаро " +
			"безор мекунад")
	}

	// Ва sweeper набояд ба он даст расонад.
	db.DB.Exec(`UPDATE products SET sold_out_asked_at = NOW() - INTERVAL '30 days',
		stock=0 WHERE id=$1`, pid)
	hideUnansweredSoldOut()
	if _, active, _ = productState(t, pid); !active {
		t.Fatal("sweeper моли бешуморро пинҳон кард")
	}
}

// Эълони нав бе шумора: фурӯшанда «бешумор»-ро интихоб мекунад.
func TestCreateProductWithoutStock(t *testing.T) {
	needDB(t)
	sellerID, _ := newTestUser(t)
	db.DB.Exec(`UPDATE users SET is_seller=true, is_verified=true WHERE id=$1`, sellerID)

	// Мустақиман тавассути мантиқ — handler-и Create `multipart` мегирад
	// ва дар тест сохтани он арзиш надорад.
	st := normalizeStock(stockInput{TrackStock: false})
	pid := uuid.NewString()
	if _, err := db.DB.Exec(`INSERT INTO products
		(id,seller_id,title,price,stock,track_stock,is_active)
		VALUES($1,$2,'Кӯрта бо фармоиш',250,$3,$4,true)`,
		pid, sellerID, st.Stock, st.TrackStock); err != nil {
		t.Fatalf("эълон сохта нашуд: %v", err)
	}
	t.Cleanup(func() { db.DB.Exec(`DELETE FROM products WHERE id=$1`, pid) })

	stock, active, _ := productState(t, pid)
	if !active {
		t.Fatal("эълони бе шумора фаъол нест")
	}
	// Захира бояд аз сифр зиёд бошад — вагарна ҳамаи дархостҳои
	// `stock > 0` молро аз бозор пинҳон мекунанд.
	if stock <= 0 {
		t.Fatalf("захира = %d — эълони бе шумора дар бозор намоён намешавад",
			stock)
	}
}

// Рӯйхати «тамомшуда» моли бешуморро нишон надиҳад.
func TestSoldOutListExcludesUnlimited(t *testing.T) {
	needDB(t)
	r := stockRouter()
	sellerID, limited := newTestSeller(t, 100, 0, 1)
	_, unlimited := newTestSeller(t, 100, 0, 1)
	// Ҳарду ба ҳамон фурӯшанда.
	db.DB.Exec(`UPDATE products SET seller_id=$1 WHERE id=$2`, sellerID, unlimited)
	db.DB.Exec(`UPDATE products SET track_stock=false WHERE id=$1`, unlimited)

	tok := sellerToken(t, r, sellerID)
	_, list := callList(t, r, "/api/v1/seller/products/sold-out", bearer(tok))
	ids := map[string]bool{}
	for _, row := range list {
		if s, ok := row["id"].(string); ok {
			ids[s] = true
		}
	}
	if !ids[limited] {
		t.Error("моли тамомшуда дар рӯйхат нест")
	}
	if ids[unlimited] {
		t.Error("моли бешумор дар рӯйхати «тамомшуда» аст")
	}
}
