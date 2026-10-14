package handlers

// Барнома бояд БИДОНАД, ки мол «бо фармоиш» аст — вагарна экран
// «Тамом шуд» менависад, дар ҳоле ки дӯзанда ҳар вақт медӯзад.
//
// Пештар сервер `track_stock`-ро умуман намефиристод: он танҳо дар дохили
// checkout истифода мешуд.

import (
	"testing"

	"tajikshop/internal/db"
	"tajikshop/internal/middleware"
	"tajikshop/internal/storage"

	"github.com/gin-gonic/gin"
)

func mtoRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	middleware.SetSecret(testSecret)
	r := gin.New()
	ph := NewProductHandler((*storage.R2Client)(nil))
	api := r.Group("/api/v1")
	api.GET("/products", ph.List)
	api.GET("/products/:id", ph.GetByID)
	return r
}

func TestMadeToOrderReachesClient(t *testing.T) {
	needDB(t)
	r := mtoRouter()
	_, normal := newTestSeller(t, 100, 5, 1)
	_, onDemand := newTestSeller(t, 100, 5, 1)
	if _, err := db.DB.Exec(`UPDATE products SET track_stock=false WHERE id=$1`,
		onDemand); err != nil {
		t.Fatalf("track_stock гузошта нашуд: %v", err)
	}

	// ── Экрани маҳсулот ──
	for _, c := range []struct {
		pid  string
		want bool
		name string
	}{
		{normal, false, "моли оддӣ"},
		{onDemand, true, "моли бо фармоиш"},
	} {
		res := call(t, r, "GET", "/api/v1/products/"+c.pid, nil, nil)
		if res.Status != 200 {
			t.Fatalf("%s: %d %s", c.name, res.Status, res.Error)
		}
		got, ok := res.Data["made_to_order"]
		if !ok {
			t.Fatalf("%s: майдони `made_to_order` умуман нест — барнома "+
				"«Тамом шуд» менависад", c.name)
		}
		if got != c.want {
			t.Errorf("%s: made_to_order=%v, мехостам %v", c.name, got, c.want)
		}
	}

	// ── Рӯйхат (корти мол) ──
	//
	// Нишона бояд дар каталог ҳам бошад: харидор пеш аз зер кардан
	// бидонад, ки мол бо фармоиш сохта мешавад.
	res := call(t, r, "GET", "/api/v1/products?limit=200", nil, nil)
	if res.Status != 200 {
		t.Fatalf("рӯйхат: %d %s", res.Status, res.Error)
	}
	raw, _ := res.Data["products"].([]any)
	seen := map[string]bool{}
	for _, e := range raw {
		row, _ := e.(map[string]any)
		id, _ := row["id"].(string)
		if id == normal || id == onDemand {
			seen[id] = true
			want := id == onDemand
			if row["made_to_order"] != want {
				t.Errorf("рӯйхат, %s: made_to_order=%v, мехостам %v",
					id, row["made_to_order"], want)
			}
		}
	}
	if !seen[normal] || !seen[onDemand] {
		t.Skip("молҳои тест дар саҳифаи аввал нашуданд")
	}
}
