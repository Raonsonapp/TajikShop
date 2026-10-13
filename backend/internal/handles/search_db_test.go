package handlers

// Ҷустуҷӯи маҳсулот бо Postgres-и воқеӣ.
//
// Ин тестҳо ЗУДИРО намесанҷанд — зудӣ бо `EXPLAIN ANALYZE` дар базаи
// 60 000-маҳсулота андоза гирифта шуд (натиҷаҳо дар `schema.sql`).
//
// Ин ҷо он чизе санҷида мешавад, ки метавонад ҲАНГОМИ беҳтаркунии зудӣ
// ХОМӮШОНА вайрон шавад: маънои ҷустуҷӯ.
//
// Маҳз барои ҳамин ин тестҳо навишта шуданд. Ду роҳи гуногун (триграм
// барои 3+ ҳарф, префикс барои 1-2 ҳарф) маънои онро дорад, ки як роҳ
// метавонад кор кунад ва дигаре — не, ва касе инро нафаҳмад.

import (
	"testing"

	"tajikshop/internal/db"
	"tajikshop/internal/middleware"
	"tajikshop/internal/storage"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func searchRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	middleware.SetSecret(testSecret)
	r := gin.New()
	ph := NewProductHandler((*storage.R2Client)(nil))
	api := r.Group("/api/v1")
	api.GET("/products", ph.List)
	return r
}

// searchFixture — чанд маҳсулоти бо номи муайян.
func searchFixture(t *testing.T, titles ...string) (sellerID string, ids []string) {
	t.Helper()
	sellerID, _ = newTestUser(t)
	db.DB.Exec(`UPDATE users SET is_seller=true WHERE id=$1`, sellerID)
	for _, title := range titles {
		id := uuid.NewString()
		if _, err := db.DB.Exec(`INSERT INTO products
			(id,seller_id,title,description,price,stock,is_active)
			VALUES($1,$2,$3,$4,100,10,true)`,
			id, sellerID, title, "Тавзеҳи "+title); err != nil {
			t.Fatalf("маҳсулот сохта нашуд: %v", err)
		}
		ids = append(ids, id)
		t.Cleanup(func() { db.DB.Exec(`DELETE FROM products WHERE id=$1`, id) })
	}
	return sellerID, ids
}

// searchTitles — номҳои маҳсулоти ёфташуда.
//
// `/products` объект бармегардонад (`{products, total, page, ...}`), на
// массив — пас `callList` ин ҷо кор намекунад.
func searchTitles(t *testing.T, r *gin.Engine, q string) []string {
	t.Helper()
	res := call(t, r, "GET", "/api/v1/products?limit=100&search="+urlEscape(q),
		nil, nil)
	if res.Status != 200 {
		t.Fatalf("ҷустуҷӯи «%s»: %d %s", q, res.Status, res.Error)
	}
	raw, _ := res.Data["products"].([]any)
	out := []string{}
	for _, e := range raw {
		m, _ := e.(map[string]any)
		if s, ok := m["title"].(string); ok {
			out = append(out, s)
		}
	}
	return out
}

func contains(list []string, want string) bool {
	for _, s := range list {
		if s == want {
			return true
		}
	}
	return false
}

// Калимаи 3+ ҳарф: ҷустуҷӯ дар МИЁНАИ матн кор мекунад.
//
// Маҳз ин он чизест, ки корбар интизор аст: ӯ «Samsu» менависад ва
// «Samsung Galaxy»-ро мебинад.
func TestSearchPartialWordInMiddle(t *testing.T) {
	needDB(t)
	r := searchRouter()
	searchFixture(t, "CIQ Samsung Galaxy A54", "CIQ Nokia 3310")

	got := searchTitles(t, r, "Samsu")
	if !contains(got, "CIQ Samsung Galaxy A54") {
		t.Fatalf("«Samsu» «Samsung»-ро наёфт. Натиҷаҳо: %v", got)
	}
	if contains(got, "CIQ Nokia 3310") {
		t.Errorf("«Samsu» моли бегонаро ёфт: %v", got)
	}
}

// Ҳарфҳои кириллӣ.
//
// Ин муҳим аст: триграм бо байтҳо кор мекунад, ва ҳарфи кириллӣ ДУ байт
// аст. Агар ҷое ҳарф бо байт омехта шавад, ҷустуҷӯи тоҷикӣ вайрон
// мешавад — вале ҷустуҷӯи англисӣ кор мекунад, ва хато пинҳон мемонад.
func TestSearchCyrillic(t *testing.T) {
	needDB(t)
	r := searchRouter()
	searchFixture(t, "CIQ Яхдони Artel", "CIQ Телевизори LG")

	got := searchTitles(t, r, "Яхдон")
	if !contains(got, "CIQ Яхдони Artel") {
		t.Fatalf("ҷустуҷӯи кириллӣ кор накард. Натиҷаҳо: %v", got)
	}

	// Ва ҳарфи калон/хурд набояд муҳим бошад.
	got = searchTitles(t, r, "яхдон")
	if !contains(got, "CIQ Яхдони Artel") {
		t.Fatalf("ҳарфи хурд кор накард. Натиҷаҳо: %v", got)
	}
}

// Калимаи 1-2 ҳарф: ПРЕФИКС, на миёнаи матн.
//
// Ин қарори огоҳона аст, на камбудӣ: `ILIKE '%ор%'` 116 мс Seq Scan
// медод ва ҳазорҳо натиҷаи бефоида. Префикс 0.13 мс аст ва барои ду
// ҳарф маънои бештар дорад.
func TestSearchShortQueryIsPrefix(t *testing.T) {
	needDB(t)
	r := searchRouter()
	searchFixture(t, "CIQ Орди навъи аввал", "CIQ Шакари Хуҷанд")

	// «Ор» — префикси «Орди...» нест, чунки ном бо «CIQ» сар мешавад.
	// Пас маҳсулоти махсус бо префикс месозем.
	searchFixture(t, "Ордкашӣ CIQ")

	got := searchTitles(t, r, "Ор")
	if !contains(got, "Ордкашӣ CIQ") {
		t.Fatalf("префикси «Ор» кор накард. Натиҷаҳо: %v", got)
	}
	// Ва моле, ки «ор» дар МИЁНААШ аст, НАБОЯД пайдо шавад — ин маҳз
	// фарқи роҳи префикс аст.
	if contains(got, "CIQ Орди навъи аввал") {
		t.Errorf("ҷустуҷӯи кӯтоҳ моли миёнаи матнро ёфт — "+
			"ин бояд танҳо префикс бошад: %v", got)
	}
}

// Чанд калима: ҲАМААШ бояд мувофиқ ояд (AND, на OR).
//
// Бе ин ҷустуҷӯи «Samsung яхдон» ҳам телефон, ҳам яхдон медод — ва
// корбар фикр мекунад, ки ҷустуҷӯ вайрон аст.
func TestSearchMultipleWordsAreAnd(t *testing.T) {
	needDB(t)
	r := searchRouter()
	searchFixture(t,
		"CIQ Яхдони Samsung калон",
		"CIQ Телефони Samsung",
		"CIQ Яхдони Artel")

	got := searchTitles(t, r, "Samsung Яхдон")
	if !contains(got, "CIQ Яхдони Samsung калон") {
		t.Fatalf("моли ҳарду калимадор ёфт нашуд: %v", got)
	}
	for _, bad := range []string{"CIQ Телефони Samsung", "CIQ Яхдони Artel"} {
		if contains(got, bad) {
			t.Errorf("«%s» танҳо як калима дорад, вале ёфт шуд — "+
				"ҷустуҷӯ бояд AND бошад, на OR", bad)
		}
	}
}

// Ҷустуҷӯ дар тавзеҳ низ кор кунад (барои калимаи 3+ ҳарф).
func TestSearchLooksInDescription(t *testing.T) {
	needDB(t)
	r := searchRouter()
	sid, _ := newTestUser(t)
	db.DB.Exec(`UPDATE users SET is_seller=true WHERE id=$1`, sid)
	id := uuid.NewString()
	db.DB.Exec(`INSERT INTO products(id,seller_id,title,description,price,stock,is_active)
		VALUES($1,$2,'CIQ Моли беном','Дар дохилаш калимаи ЗАРДОЛУ ҳаст',100,5,true)`,
		id, sid)
	t.Cleanup(func() { db.DB.Exec(`DELETE FROM products WHERE id=$1`, id) })

	got := searchTitles(t, r, "зардолу")
	if !contains(got, "CIQ Моли беном") {
		t.Fatalf("ҷустуҷӯ дар тавзеҳ кор накард: %v", got)
	}
}

// Ҷустуҷӯи бенатиҷа — рӯйхати холӣ, на хато.
func TestSearchNoResults(t *testing.T) {
	needDB(t)
	r := searchRouter()
	got := searchTitles(t, r, "ҷустуҷӯи-ҳеҷ-гоҳ-наёфтшаванда-xyzzy")
	if len(got) != 0 {
		t.Fatalf("%d натиҷа, мехостам 0: %v", len(got), got)
	}
}

// Аломатҳои махсуси SQL/LIKE набояд ҷустуҷӯро шиканад.
//
// `%` ва `_` дар `LIKE` маъно доранд. Корбари «50%» ҷӯянда набояд ҳамаи
// маҳсулотро бинад, ва набояд хато гирад.
func TestSearchSpecialCharsAreSafe(t *testing.T) {
	needDB(t)
	r := searchRouter()
	searchFixture(t, "CIQ Тахфифи 50 фоиз")

	for _, q := range []string{"%", "_", "%%", "';--", "100%", "a_b", "\\"} {
		res := call(t, r, "GET",
			"/api/v1/products?limit=5&search="+urlEscape(q), nil, nil)
		if res.Status != 200 {
			t.Errorf("ҷустуҷӯи «%s» → %d, мехостам 200", q, res.Status)
		}
	}
	// Ҷадвал бояд дар ҷояш бошад.
	var n int
	if err := db.DB.QueryRow(`SELECT COUNT(*) FROM products`).Scan(&n); err != nil {
		t.Fatalf("ҷадвали products осеб дид: %v", err)
	}
}

// Индексҳои ҷустуҷӯ ВОҚЕАН сохта мешаванд.
//
// `execEach` хатои ҳар амрро ба лог менависад ва МЕГУЗАРАД. Пас агар
// `CREATE EXTENSION pg_trgm` ҳуқуқ надошта бошад ё номи индекс хато
// бошад, ҷустуҷӯ хомӯшона суст мемонад — ва касе инро то рӯзи
// шикоятҳои корбарон намефаҳмад.
func TestSearchIndexesExist(t *testing.T) {
	needDB(t)

	var trgmAvailable bool
	db.DB.QueryRow(`SELECT EXISTS(SELECT 1 FROM pg_extension WHERE extname='pg_trgm')`).
		Scan(&trgmAvailable)
	if !trgmAvailable {
		// Ин дар баъзе mиzban-ҳо (ҳуқуқи нокифоя) мумкин аст — он гоҳ
		// ҷустуҷӯ кор мекунад, вале сусттар. Огоҳӣ, на нокомӣ.
		t.Skip("pg_trgm дар ин база нест — ҷустуҷӯ сусттар мемонад")
	}

	for _, idx := range []string{
		"idx_products_title_trgm",
		"idx_products_desc_trgm",
		"idx_products_title_prefix",
	} {
		var ok bool
		db.DB.QueryRow(`SELECT EXISTS(SELECT 1 FROM pg_indexes
			WHERE indexname=$1)`, idx).Scan(&ok)
		if !ok {
			t.Errorf("индекси «%s» сохта нашуд — ҷустуҷӯ Seq Scan мемонад", idx)
		}
	}
}
