package handlers

// Ҷустуҷӯи таъминкунанда бо Postgres-и воқеӣ.
//
// Қоидаи аслӣ, ки санҷида мешавад:
//
//     РАҚАМИ БОФТАШУДА НЕСТ.
//
// Ҳар рақам аз сатрҳои воқеии база ҳисоб мешавад. Ва он чизе, ки
// фурӯшанда ХУДАШ навиштааст, аз он чизе, ки ТАСДИҚ шудааст, ҷудо
// бармегардад — вагарна харидор даъвои фурӯшандаро ҳамчун маълумоти
// тасдиқшуда мефаҳмад.

import (
	"net/url"
	"testing"

	"tajikshop/internal/db"
	"tajikshop/internal/middleware"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func suppliersRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	middleware.SetSecret(testSecret)
	r := gin.New()
	uh := NewUserHandler(testSecret, nil)
	api := r.Group("/api/v1")
	api.POST("/auth/login", uh.Login)
	api.GET("/suppliers", uh.Suppliers)
	api.GET("/suppliers/:id", uh.SupplierProfile)
	return r
}

// supplierWith — фурӯшанда бо фармоишҳои анҷомёфта/бекоршуда ва рейтинг.
func supplierWith(t *testing.T, opts struct {
	Verified  bool
	Region    string
	ShopName  string
	Done      int
	Cancelled int
	Score     int
}) string {
	t.Helper()
	sid, _ := newTestUser(t)
	db.DB.Exec(`UPDATE users SET is_seller=true, is_verified=$1,
		region=$2, shop_name=$3 WHERE id=$4`,
		opts.Verified, opts.Region, opts.ShopName, sid)

	mk := func(status string) {
		oid := uuid.NewString()
		buyer, _ := newTestUser(t)
		db.DB.Exec(`INSERT INTO orders(id,user_id,total,status) VALUES($1,$2,100,$3)`,
			oid, buyer, status)
		db.DB.Exec(`INSERT INTO order_sellers(id,order_id,seller_id,status,subtotal)
			VALUES($1,$2,$3,$4,100)`, uuid.NewString(), oid, sid, status)
		t.Cleanup(func() {
			db.DB.Exec(`DELETE FROM seller_ratings WHERE order_id=$1`, oid)
			db.DB.Exec(`DELETE FROM order_sellers WHERE order_id=$1`, oid)
			db.DB.Exec(`DELETE FROM orders WHERE id=$1`, oid)
		})
		if opts.Score > 0 && status == "completed" {
			db.DB.Exec(`INSERT INTO seller_ratings(id,order_id,seller_id,buyer_id,score)
				VALUES($1,$2,$3,$4,$5)`,
				uuid.NewString(), oid, sid, buyer, opts.Score)
		}
	}
	for i := 0; i < opts.Done; i++ {
		mk("completed")
	}
	for i := 0; i < opts.Cancelled; i++ {
		mk("cancelled")
	}
	return sid
}

type supOpts = struct {
	Verified  bool
	Region    string
	ShopName  string
	Done      int
	Cancelled int
	Score     int
}

func findSupplier(list []map[string]any, id string) map[string]any {
	for _, row := range list {
		if row["id"] == id {
			return row
		}
	}
	return nil
}

// Ҳамаи рақамҳо аз сатрҳои ВОҚЕӢ.
func TestSuppliersStatsAreReal(t *testing.T) {
	needDB(t)
	r := suppliersRouter()
	sid := supplierWith(t, supOpts{
		Verified: true, ShopName: "CI Таъминкунанда",
		Done: 7, Cancelled: 3, Score: 5,
	})

	code, list := callList(t, r, "/api/v1/suppliers?limit=200", nil)
	if code != 200 {
		t.Fatalf("suppliers: %d", code)
	}
	row := findSupplier(list, sid)
	if row == nil {
		t.Fatal("таъминкунанда дар рӯйхат нест")
	}
	ver, _ := row["verified"].(map[string]any)
	if ver == nil {
		t.Fatal("бахши `verified` нест")
	}
	if n, _ := ver["orders_completed"].(float64); int(n) != 7 {
		t.Errorf("фармоиши анҷомёфта = %v, мехостам 7", ver["orders_completed"])
	}
	if n, _ := ver["orders_cancelled"].(float64); int(n) != 3 {
		t.Errorf("фармоиши бекоршуда = %v, мехостам 3", ver["orders_cancelled"])
	}
	// 7 аз 10 = 70%
	if n, _ := ver["completion_rate"].(float64); int(n) != 70 {
		t.Errorf("фоизи анҷом = %v, мехостам 70", ver["completion_rate"])
	}
	if ver["badge"] != true {
		t.Error("галочка нишон дода нашуд")
	}
	if n, _ := ver["rating"].(float64); n != 5 {
		t.Errorf("рейтинг = %v, мехостам 5", ver["rating"])
	}
}

// Фоизи анҷом дар шумораи КАМИ фармоиш умуман нишон дода намешавад.
//
// «100% анҷом» дар 2 фармоиш маъно надорад ва харидорро фиреб медиҳад.
// Беҳтар аст, ки рақам набошад, аз он ки рақами бемаънӣ бошад.
func TestSuppliersNoCompletionRateOnTooFewOrders(t *testing.T) {
	needDB(t)
	r := suppliersRouter()
	sid := supplierWith(t, supOpts{ShopName: "CI Кам", Done: 2})

	_, list := callList(t, r, "/api/v1/suppliers?limit=200", nil)
	row := findSupplier(list, sid)
	if row == nil {
		t.Fatal("таъминкунанда нест")
	}
	ver, _ := row["verified"].(map[string]any)
	if _, has := ver["completion_rate"]; has {
		t.Fatalf("фоизи анҷом дар 2 фармоиш нишон дода шуд: %v — "+
			"ин рақам харидорро фиреб медиҳад", ver["completion_rate"])
	}
	// Вале шумораи воқеӣ бояд бошад.
	if n, _ := ver["orders_completed"].(float64); int(n) != 2 {
		t.Errorf("фармоиши анҷомёфта = %v, мехостам 2", ver["orders_completed"])
	}
}

// Даъвои фурӯшанда аз маълумоти тасдиқшуда ҶУДО бармегардад.
//
// Ин ҳамон ҷойест, ки платформаҳо одатан фиреб мекунанд: «минтақаи
// фаъолият» ҳамчун маълумоти тасдиқшуда нишон дода мешавад, ҳол он ки
// онро худи фурӯшанда навиштааст.
func TestSuppliersSeparatesSelfReportedFromVerified(t *testing.T) {
	needDB(t)
	r := suppliersRouter()
	sid := supplierWith(t, supOpts{
		Verified: false, Region: "Хатлон", ShopName: "CI Даъво", Done: 1,
	})
	db.DB.Exec(`UPDATE users SET shop_desc='Беҳтарин дар кишвар!' WHERE id=$1`, sid)

	_, list := callList(t, r, "/api/v1/suppliers?limit=200", nil)
	row := findSupplier(list, sid)
	if row == nil {
		t.Fatal("таъминкунанда нест")
	}

	self, _ := row["self_reported"].(map[string]any)
	if self == nil {
		t.Fatal("бахши `self_reported` нест")
	}
	if self["region"] != "Хатлон" {
		t.Errorf("минтақа = %v, мехостам Хатлон", self["region"])
	}
	if self["description"] != "Беҳтарин дар кишвар!" {
		t.Errorf("тавзеҳ дар `self_reported` нест")
	}

	// Ва даъво НАБОЯД дар бахши тасдиқшуда бошад.
	ver, _ := row["verified"].(map[string]any)
	for _, k := range []string{"region", "description", "business_type"} {
		if _, has := ver[k]; has {
			t.Errorf("«%s» дар бахши тасдиқшуда аст — он даъвои фурӯшанда "+
				"аст, на маълумоти тасдиқшуда", k)
		}
	}
	if ver["badge"] != false {
		t.Error("галочкаи тасдиқнашуда ҳамчун `true` омад")
	}
}

// Филтри «танҳо тасдиқшуда».
func TestSuppliersVerifiedFilter(t *testing.T) {
	needDB(t)
	r := suppliersRouter()
	ok := supplierWith(t, supOpts{Verified: true, ShopName: "CI Тасдиқ"})
	no := supplierWith(t, supOpts{Verified: false, ShopName: "CI Бетасдиқ"})

	_, list := callList(t, r, "/api/v1/suppliers?verified=1&limit=200", nil)
	if findSupplier(list, ok) == nil {
		t.Error("фурӯшандаи тасдиқшуда дар рӯйхат нест")
	}
	if findSupplier(list, no) != nil {
		t.Error("фурӯшандаи ТАСДИҚНАШУДА дар филтри «танҳо тасдиқшуда» ҳаст")
	}
}

// Филтри минтақа.
func TestSuppliersRegionFilter(t *testing.T) {
	needDB(t)
	r := suppliersRouter()
	sogd := supplierWith(t, supOpts{Region: "Суғд", ShopName: "CI Суғд"})
	khatlon := supplierWith(t, supOpts{Region: "Хатлон", ShopName: "CI Хатлон"})

	_, list := callList(t, r, "/api/v1/suppliers?region=Суғд&limit=200", nil)
	if findSupplier(list, sogd) == nil {
		t.Error("фурӯшандаи Суғд ёфт нашуд")
	}
	if findSupplier(list, khatlon) != nil {
		t.Error("фурӯшандаи Хатлон дар филтри Суғд ҳаст")
	}
}

// Фурӯшандаи бастшуда ё нестшуда дар рӯйхат набошад.
func TestSuppliersExcludesBannedAndDeleted(t *testing.T) {
	needDB(t)
	r := suppliersRouter()
	banned := supplierWith(t, supOpts{ShopName: "CI Баста"})
	deleted := supplierWith(t, supOpts{ShopName: "CI Нестшуда"})
	db.DB.Exec(`UPDATE users SET is_banned=true WHERE id=$1`, banned)
	db.DB.Exec(`UPDATE users SET is_deleted=true WHERE id=$1`, deleted)

	_, list := callList(t, r, "/api/v1/suppliers?limit=200", nil)
	if findSupplier(list, banned) != nil {
		t.Error("фурӯшандаи бастшуда дар рӯйхат аст")
	}
	if findSupplier(list, deleted) != nil {
		t.Error("фурӯшандаи нестшуда дар рӯйхат аст")
	}
}

// Тартиб аз рӯйхати САХТ интихоб мешавад — на аз сатри корбар.
//
// Бе ин `?sort=...` роҳи SQL injection мешуд.
func TestSuppliersSortIsSafe(t *testing.T) {
	needDB(t)
	r := suppliersRouter()
	supplierWith(t, supOpts{ShopName: "CI Тартиб", Done: 1})

	for _, sort := range []string{
		"rating", "products", "new", "orders",
		// Кӯшиши injection — бояд нодида монад, на хато диҳад.
		"u.id; DROP TABLE users; --",
		"'; DELETE FROM users WHERE 1=1; --",
		"",
	} {
		code, _ := callList(t, r, "/api/v1/suppliers?limit=5&sort="+
			urlEscape(sort), nil)
		if code != 200 {
			t.Fatalf("sort=%q → %d, мехостам 200", sort, code)
		}
	}
	// Ҷадвали корбарон бояд дар ҷояш бошад.
	var n int
	if err := db.DB.QueryRow(`SELECT COUNT(*) FROM users`).Scan(&n); err != nil {
		t.Fatalf("ҷадвали users осеб дид: %v", err)
	}
}

// Профили як таъминкунанда.
func TestSupplierProfile(t *testing.T) {
	needDB(t)
	r := suppliersRouter()
	sid := supplierWith(t, supOpts{
		Verified: true, Region: "Душанбе", ShopName: "CI Профил",
		Done: 6, Cancelled: 0, Score: 4,
	})

	res := call(t, r, "GET", "/api/v1/suppliers/"+sid, nil, nil)
	if res.Status != 200 {
		t.Fatalf("профил: %d %s", res.Status, res.Error)
	}
	if res.Data["name"] != "CI Профил" {
		t.Errorf("ном = %v", res.Data["name"])
	}
	ver, _ := res.Data["verified"].(map[string]any)
	if n, _ := ver["orders_completed"].(float64); int(n) != 6 {
		t.Errorf("фармоиши анҷомёфта = %v, мехостам 6", ver["orders_completed"])
	}
	if n, _ := ver["completion_rate"].(float64); int(n) != 100 {
		t.Errorf("фоизи анҷом = %v, мехостам 100 (6 аз 6)", ver["completion_rate"])
	}
	self, _ := res.Data["self_reported"].(map[string]any)
	if self["region"] != "Душанбе" {
		t.Errorf("минтақа = %v", self["region"])
	}
}

// Профили корбари ғайрифурӯшанда — 404.
func TestSupplierProfileNotASeller(t *testing.T) {
	needDB(t)
	r := suppliersRouter()
	uid, _ := newTestUser(t)
	res := call(t, r, "GET", "/api/v1/suppliers/"+uid, nil, nil)
	if res.Status != 404 {
		t.Fatalf("мехостам 404, гирифтам %d", res.Status)
	}
}

// Молҳои яклухт дар профил.
//
// Маҳз инҳо барои харидори яклухт муҳиманд: моли бе зина нархи чакана
// дорад ва ба ӯ намеарзад.
func TestSupplierProfileShowsWholesaleItems(t *testing.T) {
	needDB(t)
	r := suppliersRouter()
	sid, pid := newTestSeller(t, 100, 500, 1)
	// Моли дуюм БЕ зина — он набояд дар рӯйхати яклухт бошад.
	plain := uuid.NewString()
	db.DB.Exec(`INSERT INTO products(id,seller_id,title,price,stock,is_active)
		VALUES($1,$2,'Моли чакана',50,10,true)`, plain, sid)
	t.Cleanup(func() { db.DB.Exec(`DELETE FROM products WHERE id=$1`, plain) })
	setTiers(t, pid, [2]float64{10, 90}, [2]float64{50, 80})

	res := call(t, r, "GET", "/api/v1/suppliers/"+sid, nil, nil)
	if res.Status != 200 {
		t.Fatalf("профил: %d %s", res.Status, res.Error)
	}
	items, _ := res.Data["wholesale"].([]any)
	if len(items) != 1 {
		t.Fatalf("%d моли яклухт, мехостам 1 (моли бе зина набояд бошад)",
			len(items))
	}
	m, _ := items[0].(map[string]any)
	if m["id"] != pid {
		t.Errorf("моли нодуруст: %v", m["id"])
	}
	// Нархи аз ҳама пасти зина.
	if p, _ := m["wholesale_from"].(float64); p != 80 {
		t.Errorf("нархи яклухт аз = %v, мехостам 80", m["wholesale_from"])
	}
	if q, _ := m["wholesale_min_qty"].(float64); int(q) != 10 {
		t.Errorf("шумораи ҳадди ақал = %v, мехостам 10", m["wholesale_min_qty"])
	}
}

// urlEscape — кодкунии содда барои параметри дархост дар тест.
func urlEscape(s string) string { return url.QueryEscape(s) }
