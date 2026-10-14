package handlers

// Нест кардани ҳисоб бо Postgres-и воқеӣ.
//
// ЧАРО ИН ТЕСТ ҲОЛО НАВИШТА МЕШАВАД:
//
// Тести эмулятор қадами охиринашро чунин тамом кард:
//
//     → DELETE /users/me  auth:✓
//     ✗ 500 /users/me: Хатои сервер. Баъдтар кӯшиш кунед
//        ⚠ тозакунӣ нашуд
//
// Тест сабз монд (тозакунӣ хаторо намепартояд), вале НЕСТ КАРДАНИ ҲИСОБ
// КОР НАМЕКУНАД. Ин ду масъала аст:
//
//  1. Google Play нест кардани ҳисобро ҲАТМӢ талаб мекунад. Бе он
//     барнома аз мағоза бароварда мешавад.
//  2. Ҳисобҳои санҷишӣ дар базаи production ҷамъ мешаванд.
//
// Ин масир тест НАДОШТ. Ҳоло дорад.

import (
	"strings"
	"testing"

	"tajikshop/internal/db"
	"tajikshop/internal/middleware"
	"tajikshop/internal/storage"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func deleteAccountRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	middleware.SetSecret(testSecret)
	r := gin.New()
	uh := NewUserHandler(testSecret, nil)
	oh := NewOrderHandler((*storage.R2Client)(nil))
	rh := NewRFQHandler()
	api := r.Group("/api/v1")
	api.POST("/auth/login", uh.Login)
	api.DELETE("/users/me", middleware.Auth(), uh.DeleteAccount)
	api.POST("/cart", middleware.Auth(), oh.AddToCart)
	api.POST("/orders/checkout", middleware.Auth(), oh.Checkout)
	api.POST("/rfqs", middleware.Auth(), rh.Create)
	return r
}

// Ҳисоби тоза — бе ягон маълумот.
func TestDeleteAccountEmpty(t *testing.T) {
	needDB(t)
	r := deleteAccountRouter()
	uid, email := newTestUser(t)
	tok, _ := login(t, r, email)

	res := call(t, r, "DELETE", "/api/v1/users/me", nil, bearer(tok))
	if res.Status != 200 {
		t.Fatalf("нест кардан: %d %s", res.Status, res.Error)
	}
	var deleted, banned bool
	db.DB.QueryRow(`SELECT COALESCE(is_deleted,false), COALESCE(is_banned,false)
		FROM users WHERE id=$1`, uid).Scan(&deleted, &banned)
	if !deleted || !banned {
		t.Fatalf("is_deleted=%v is_banned=%v, мехостам ҳарду true", deleted, banned)
	}
}

// Маҳз ҳолати тести эмулятор: корбар дархости нарх сохт, баъд ҳисобро
// нест мекунад.
//
// Дар CI ин 500 дод.
func TestDeleteAccountWithRFQ(t *testing.T) {
	needDB(t)
	r := deleteAccountRouter()
	uid, email := newTestUser(t)
	tok, _ := login(t, r, email)

	rfq := call(t, r, "POST", "/api/v1/rfqs", map[string]any{
		"title": "CI: 500 кг орд", "quantity": 500, "unit": "кг", "days": 7,
	}, bearer(tok))
	if rfq.Status != 201 {
		t.Fatalf("дархост сохта нашуд: %d %s", rfq.Status, rfq.Error)
	}
	rfqID := str(rfq.Data, "id")
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM rfq_quotes WHERE rfq_id=$1`, rfqID)
		db.DB.Exec(`DELETE FROM rfqs WHERE id=$1`, rfqID)
	})

	res := call(t, r, "DELETE", "/api/v1/users/me", nil, bearer(tok))
	if res.Status != 200 {
		t.Fatalf("нест кардан бо дархости нарх: %d %s", res.Status, res.Error)
	}
	var deleted bool
	db.DB.QueryRow(`SELECT COALESCE(is_deleted,false) FROM users WHERE id=$1`,
		uid).Scan(&deleted)
	if !deleted {
		t.Fatal("ҳисоб нест карда нашуд")
	}
}

// Корбари фармоишдошта: фармоиш бояд МОНАД (таърихи фурӯшанда), вале
// ҳисоб нест шавад.
func TestDeleteAccountWithOrder(t *testing.T) {
	needDB(t)
	r := deleteAccountRouter()
	_, pid := newTestSeller(t, 100, 10, 1)
	uid, email := newTestUser(t)
	tok, _ := login(t, r, email)

	call(t, r, "POST", "/api/v1/cart",
		map[string]any{"product_id": pid, "quantity": 1}, bearer(tok))
	ord := call(t, r, "POST", "/api/v1/orders/checkout",
		map[string]any{"payment_method": "cod"}, bearer(tok))
	if ord.Status != 201 {
		t.Fatalf("фармоиш: %d %s", ord.Status, ord.Error)
	}
	oid := str(ord.Data, "order_id")
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM order_sellers WHERE order_id=$1`, oid)
		db.DB.Exec(`DELETE FROM order_items WHERE order_id=$1`, oid)
		db.DB.Exec(`DELETE FROM checkout_keys WHERE order_id=$1`, oid)
		db.DB.Exec(`DELETE FROM orders WHERE id=$1`, oid)
	})

	res := call(t, r, "DELETE", "/api/v1/users/me", nil, bearer(tok))
	if res.Status != 200 {
		t.Fatalf("нест кардан бо фармоиш: %d %s", res.Status, res.Error)
	}

	// Фармоиш бояд монад — вагарна таърихи фурӯшанда ва ҳисоботи пулӣ
	// вайрон мешавад.
	var exists bool
	db.DB.QueryRow(`SELECT EXISTS(SELECT 1 FROM orders WHERE id=$1)`, oid).
		Scan(&exists)
	if !exists {
		t.Error("фармоиш нест шуд — таърихи фурӯшанда гум мешавад")
	}
	// Вале маълумоти шахсӣ бояд нест шуда бошад.
	var name, em string
	db.DB.QueryRow(`SELECT name, COALESCE(email,'') FROM users WHERE id=$1`,
		uid).Scan(&name, &em)
	if !strings.Contains(em, "deleted") {
		t.Errorf("почта нест нашуд: %q", em)
	}
	if strings.Contains(name, "Тест") {
		t.Errorf("ном нест нашуд: %q", name)
	}
}

// Фурӯшандаи моли фурӯхташуда: мол бояд пинҳон шавад, вале нест нашавад
// (таърихи фармоиш ба он ишора мекунад).
func TestDeleteAccountSellerWithSoldProduct(t *testing.T) {
	needDB(t)
	r := deleteAccountRouter()
	sellerID, pid := newTestSeller(t, 100, 10, 1)
	buyerID, _ := newTestUser(t)

	// Фармоиши дастӣ бо моли ин фурӯшанда.
	oid := uuid.NewString()
	db.DB.Exec(`INSERT INTO orders(id,user_id,total,status) VALUES($1,$2,100,'pending')`,
		oid, buyerID)
	db.DB.Exec(`INSERT INTO order_items(id,order_id,product_id,seller_id,title,quantity,price)
		VALUES($1,$2,$3,$4,'Моли фурӯхташуда',1,100)`,
		uuid.NewString(), oid, pid, sellerID)
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM order_items WHERE order_id=$1`, oid)
		db.DB.Exec(`DELETE FROM orders WHERE id=$1`, oid)
	})

	var email string
	db.DB.QueryRow(`SELECT email FROM users WHERE id=$1`, sellerID).Scan(&email)
	tok, _ := login(t, r, email)

	res := call(t, r, "DELETE", "/api/v1/users/me", nil, bearer(tok))
	if res.Status != 200 {
		t.Fatalf("нест кардани фурӯшанда: %d %s", res.Status, res.Error)
	}

	var active bool
	var stock int
	var exists bool
	db.DB.QueryRow(`SELECT EXISTS(SELECT 1 FROM products WHERE id=$1)`, pid).
		Scan(&exists)
	if !exists {
		t.Fatal("моли фурӯхташуда нест шуд — таърихи фармоиш вайрон мешавад")
	}
	db.DB.QueryRow(`SELECT COALESCE(is_active,true), stock FROM products WHERE id=$1`,
		pid).Scan(&active, &stock)
	if active || stock != 0 {
		t.Errorf("мол пинҳон нашуд: is_active=%v stock=%d", active, stock)
	}
}

// Такрори нест кардан — 200, на хато.
//
// Барнома метавонад дархостро такрор кунад (интернет), ва корбар набояд
// «хато» бинад.
func TestDeleteAccountIsIdempotent(t *testing.T) {
	needDB(t)
	r := deleteAccountRouter()
	_, email := newTestUser(t)
	tok, _ := login(t, r, email)

	for i := 0; i < 3; i++ {
		res := call(t, r, "DELETE", "/api/v1/users/me", nil, bearer(tok))
		if res.Status != 200 {
			t.Fatalf("кӯшиши %d: %d %s", i+1, res.Status, res.Error)
		}
	}
}

// Ҳисоби бо ҲАМА намуди маълумот.
//
// Ин тести «ҳама якҷоя» аст: ҳар ҷадвали нав, ки ба `users` ишора
// мекунад, метавонад нест карданро шиканад. Бе чунин тест камбудӣ танҳо
// дар эмулятор ё — бадтар — дар телефони корбар пайдо мешавад.
func TestDeleteAccountWithEverything(t *testing.T) {
	needDB(t)
	r := deleteAccountRouter()
	uid, email := newTestUser(t)
	tok, _ := login(t, r, email)
	_, pid := newTestSeller(t, 100, 10, 1)

	// Сабад + фармоиш.
	call(t, r, "POST", "/api/v1/cart",
		map[string]any{"product_id": pid, "quantity": 1}, bearer(tok))
	ord := call(t, r, "POST", "/api/v1/orders/checkout",
		map[string]any{"payment_method": "cod"}, bearer(tok))
	oid := str(ord.Data, "order_id")

	// Дархости нарх.
	rfq := call(t, r, "POST", "/api/v1/rfqs", map[string]any{
		"title": "CI ҳама", "quantity": 10, "days": 3}, bearer(tok))
	rfqID := str(rfq.Data, "id")

	// Маълумоти дигар, ки ба `users` ишора мекунад.
	db.DB.Exec(`INSERT INTO notifications(id,user_id,type,title) VALUES($1,$2,'test','х')`,
		uuid.NewString(), uid)
	db.DB.Exec(`INSERT INTO addresses(id,user_id,city,street) VALUES($1,$2,'Душанбе','х')`,
		uuid.NewString(), uid)
	db.DB.Exec(`INSERT INTO wallet_transactions(id,user_id,amount,type,status)
		VALUES($1,$2,10,'topup','completed')`, uuid.NewString(), uid)
	db.DB.Exec(`INSERT INTO payment_intents(id,order_id,user_id,provider,provider_ref,amount)
		VALUES($1,$2,$3,'sandbox',$4,100)`,
		uuid.NewString(), oid, uid, "sbx_"+uuid.NewString())

	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM payment_intents WHERE user_id=$1`, uid)
		db.DB.Exec(`DELETE FROM wallet_transactions WHERE user_id=$1`, uid)
		db.DB.Exec(`DELETE FROM rfq_quotes WHERE rfq_id=$1`, rfqID)
		db.DB.Exec(`DELETE FROM rfqs WHERE id=$1`, rfqID)
		db.DB.Exec(`DELETE FROM order_sellers WHERE order_id=$1`, oid)
		db.DB.Exec(`DELETE FROM order_items WHERE order_id=$1`, oid)
		db.DB.Exec(`DELETE FROM checkout_keys WHERE order_id=$1`, oid)
		db.DB.Exec(`DELETE FROM orders WHERE id=$1`, oid)
	})

	res := call(t, r, "DELETE", "/api/v1/users/me", nil, bearer(tok))
	if res.Status != 200 {
		t.Fatalf("нест кардан бо ҳама намуди маълумот: %d %s",
			res.Status, res.Error)
	}

	// Маълумоти шахсӣ бояд нест шуда бошад.
	var addrs, notifs int
	db.DB.QueryRow(`SELECT COUNT(*) FROM addresses WHERE user_id=$1`, uid).Scan(&addrs)
	db.DB.QueryRow(`SELECT COUNT(*) FROM notifications WHERE user_id=$1`, uid).Scan(&notifs)
	if addrs != 0 {
		t.Errorf("%d суроға монд — маълумоти шахсӣ бояд нест шавад", addrs)
	}
	if notifs != 0 {
		t.Errorf("%d огоҳӣ монд", notifs)
	}
}

// МАҲЗ ҳолати production: сутуне дар ҷадвали `users` НЕСТ.
//
// Дар тести эмулятор `DELETE /users/me` дар production **500** дод, ҳол
// он ки дар базаи маҳаллии ТОЗА ҳамаи тестҳо сабз буданд. Фарқ дар он
// аст, ки базаи production кӯҳна аст ва тавассути `ALTER TABLE` рушд
// кардааст — ва `execEach` хатои ҳар амрро ба лог менависад ва
// МЕГУЗАРАД. Як `ALTER TABLE`-и солҳо пеш афтода = сутуни нестбуда.
//
// Ин тест сутунро ВОҚЕАН мепартояд ва месанҷад, ки нест кардан
// ҳамчунон кор мекунад — ва муҳимтар: маълумоти ҳассос нест мешавад.
func TestDeleteAccountSurvivesMissingColumn(t *testing.T) {
	needDB(t)
	r := deleteAccountRouter()

	// `bio` сутуни ихтиёрӣ аст — онро муваққатан мепартоем.
	var hasBio bool
	db.DB.QueryRow(`SELECT EXISTS(SELECT 1 FROM information_schema.columns
		WHERE table_name='users' AND column_name='bio')`).Scan(&hasBio)
	if !hasBio {
		t.Skip("сутуни `bio` дар ин база нест — тест маъно надорад")
	}
	if _, err := db.DB.Exec(`ALTER TABLE users DROP COLUMN bio`); err != nil {
		t.Skipf("сутун партофта нашуд: %v", err)
	}
	t.Cleanup(func() {
		db.DB.Exec(`ALTER TABLE users ADD COLUMN IF NOT EXISTS bio TEXT DEFAULT ''`)
	})

	uid, email := newTestUser(t)
	tok, _ := login(t, r, email)

	res := call(t, r, "DELETE", "/api/v1/users/me", nil, bearer(tok))
	if res.Status != 200 {
		t.Fatalf("бе сутуни `bio`: %d %s — нест кардан набояд афтад",
			res.Status, res.Error)
	}

	// Ва маълумоти ҲАССОС бояд дар ҳар ҳол нест шуда бошад.
	var name, em, pw string
	var banned bool
	db.DB.QueryRow(`SELECT name, COALESCE(email,''), COALESCE(password_hash,''),
			COALESCE(is_banned,false)
		FROM users WHERE id=$1`, uid).Scan(&name, &em, &pw, &banned)
	if !strings.Contains(em, "deleted") {
		t.Errorf("почта нест нашуд: %q", em)
	}
	if pw != "" {
		t.Error("парол нест нашуд — ҳисоб ҳамчунон кушода мешавад")
	}
	if !banned {
		t.Error("ҳисоб баста нашуд")
	}
}
