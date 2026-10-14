package handlers

// Моли «бо фармоиш» бо захираи СИФР бояд дар каталог бимонад.
//
// Ҳозир `normalizeStock` ба чунин мол рақами рамзӣ (1 000 000)
// мегузорад, пас филтри `stock > 0` мегузарад. Вале ин ба РАҚАМ
// вобаста аст: як `UPDATE`-и дастӣ, маълумоти кӯҳна, ё муҳоҷирате, ки
// рақамро иваз кунад, эълонро НОПАДИД мекунад — ва фурӯшанда
// намефаҳмад, чаро.
//
// Акнун ҳар филтр `OR track_stock = false` дорад.

import (
	"testing"

	"tajikshop/internal/db"
	"tajikshop/internal/middleware"
	"tajikshop/internal/storage"

	"github.com/gin-gonic/gin"
)

func listRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	middleware.SetSecret(testSecret)
	r := gin.New()
	ph := NewProductHandler((*storage.R2Client)(nil))
	api := r.Group("/api/v1")
	api.GET("/products", ph.List)
	api.GET("/products/trending", ph.Trending)
	return r
}

func idsIn(t *testing.T, r *gin.Engine, path string) map[string]bool {
	t.Helper()
	res := call(t, r, "GET", path, nil, nil)
	if res.Status != 200 {
		t.Fatalf("%s: %d %s", path, res.Status, res.Error)
	}
	raw, _ := res.Data["products"].([]any)
	out := map[string]bool{}
	for _, e := range raw {
		if m, ok := e.(map[string]any); ok {
			if id, ok := m["id"].(string); ok {
				out[id] = true
			}
		}
	}
	return out
}

func TestMadeToOrderWithZeroStockStaysInCatalog(t *testing.T) {
	needDB(t)
	r := listRouter()
	// Захираи СИФР — ҳолати «вайрон», ки филтри кӯҳна пинҳон мекард.
	_, pid := newTestSeller(t, 100, 0, 1)
	if _, err := db.DB.Exec(`UPDATE products
		SET track_stock=false, stock=0, is_active=true WHERE id=$1`, pid); err != nil {
		t.Fatalf("ҳолат гузошта нашуд: %v", err)
	}

	for _, path := range []string{
		"/api/v1/products?limit=200",
		"/api/v1/products/trending",
	} {
		if !idsIn(t, r, path)[pid] {
			t.Errorf("%s: моли «бо фармоиш» бо захираи сифр пинҳон шуд — "+
				"фурӯшанда намефаҳмад, чаро эълонаш нопадид шуд", path)
		}
	}
}

// Вале моли ОДДИИ тамомшуда бояд пинҳон монад.
//
// Бе ин санҷиш ислоҳи боло метавонист филтрро умуман хомӯш кунад.
func TestTrackedProductWithZeroStockHidden(t *testing.T) {
	needDB(t)
	r := listRouter()
	_, pid := newTestSeller(t, 100, 0, 1)
	db.DB.Exec(`UPDATE products SET track_stock=true, stock=0, is_active=true
		WHERE id=$1`, pid)

	if idsIn(t, r, "/api/v1/products/trending")[pid] {
		t.Error("моли тамомшуда дар каталог монд — харидор онро мебинад, " +
			"зер мекунад, ва харида наметавонад")
	}
}
