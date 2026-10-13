package handlers

// Пардохт тавассути провайдер, бо Postgres-и воқеӣ.
//
// Провайдери воқеӣ ҳанӯз нест (маълумоти merchant лозим), вале се чизи
// аз ҳама хатарноки пардохт ба провайдер ҲЕҶ РАБТЕ НАДОРАНД, ва маҳз
// онҳо ин ҷо санҷида мешаванд:
//
//  1. такрори webhook — провайдер ҳамон рӯйдодро чанд бор мефиристад,
//     ва ин МЕЪЁРИ КОР аст;
//  2. имзо — бе он ҳар кас «пардохт шуд» фиристода метавонад ва моли
//     ройгон мегирад;
//  3. тартиби ҳолатҳо — рӯйдодҳо метавонанд бо тартиби вайрон расанд.

import (
	"encoding/json"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"

	"tajikshop/internal/db"
	"tajikshop/internal/middleware"
	"tajikshop/internal/payments"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

const payTestSecret = "pay-webhook-secret"

func payRouter(t *testing.T) (*gin.Engine, *payments.Sandbox) {
	t.Helper()
	gin.SetMode(gin.TestMode)
	middleware.SetSecret(testSecret)
	sb := payments.NewSandbox(payTestSecret)
	r := gin.New()
	uh := NewUserHandler(testSecret, nil)
	pay := NewPaymentHandler(sb)
	api := r.Group("/api/v1")
	api.POST("/auth/login", uh.Login)
	api.POST("/payments/start", middleware.Auth(), pay.Start)
	api.GET("/payments/:order_id/status", middleware.Auth(), pay.Status)
	api.POST("/payments/webhook/:provider", pay.Webhook)
	api.POST("/admin/payments/reconcile",
		middleware.Auth(), middleware.AdminOnly(), pay.Reconcile)
	return r, sb
}

// payOrder — фармоиши интизори пардохт.
func payOrder(t *testing.T, buyerID string, total float64) string {
	t.Helper()
	oid := uuid.NewString()
	if _, err := db.DB.Exec(`INSERT INTO orders(id,user_id,total,status,payment_method)
		VALUES($1,$2,$3,'pending','dc')`, oid, buyerID, total); err != nil {
		t.Fatalf("фармоиш сохта нашуд: %v", err)
	}
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM payment_events WHERE provider_ref IN
			(SELECT provider_ref FROM payment_intents WHERE order_id=$1)`, oid)
		db.DB.Exec(`DELETE FROM payment_intents WHERE order_id=$1`, oid)
		db.DB.Exec(`DELETE FROM order_events WHERE order_id=$1`, oid)
		db.DB.Exec(`DELETE FROM notifications WHERE ref_id=$1`, oid)
		db.DB.Exec(`DELETE FROM orders WHERE id=$1`, oid)
	})
	return oid
}

// postWebhook — webhook бо имзои дуруст (ё нодуруст).
func postWebhook(t *testing.T, r *gin.Engine, body []byte, sig string) int {
	t.Helper()
	req := httptest.NewRequest("POST", "/api/v1/payments/webhook/sandbox",
		strings.NewReader(string(body)))
	req.Header.Set("Content-Type", "application/json")
	if sig != "" {
		req.Header.Set("X-Signature", sig)
	}
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	return w.Code
}

func payBody(eventID, ref, status string, amountDirams int64) []byte {
	b, _ := json.Marshal(map[string]any{
		"event_id": eventID, "ref": ref,
		"status": status, "amount": amountDirams,
	})
	return b
}

func orderStatusOf(t *testing.T, oid string) string {
	t.Helper()
	var s string
	db.DB.QueryRow(`SELECT status FROM orders WHERE id=$1`, oid).Scan(&s)
	return s
}

// ── Роҳи муваффақ ────────────────────────────────────────────────────────

func TestPaymentStartAndWebhook(t *testing.T) {
	needDB(t)
	r, _ := payRouter(t)
	buyerID, tok := newBuyer(t, r, 0)
	oid := payOrder(t, buyerID, 250)

	res := call(t, r, "POST", "/api/v1/payments/start",
		map[string]any{"order_id": oid}, bearer(tok))
	if res.Status != 200 {
		t.Fatalf("оғози пардохт: %d %s", res.Status, res.Error)
	}
	ref := str(res.Data, "provider_ref")
	if ref == "" {
		t.Fatal("provider_ref холӣ аст")
	}
	// Суроға бояд ошкоро sandbox будани худро гӯяд.
	if !strings.Contains(str(res.Data, "pay_url"), "sandbox") {
		t.Errorf("pay_url = %q — бояд ошкоро sandbox бошад",
			str(res.Data, "pay_url"))
	}

	body := payBody("ev-1", ref, "paid", 25000)
	if code := postWebhook(t, r, body,
		payments.SignHMAC(payTestSecret, body)); code != 200 {
		t.Fatalf("webhook: %d", code)
	}

	if got := orderStatusOf(t, oid); got != "paid" {
		t.Fatalf("ҳолати фармоиш = %q, мехостам paid", got)
	}
	var intentStatus string
	db.DB.QueryRow(`SELECT status FROM payment_intents WHERE order_id=$1`,
		oid).Scan(&intentStatus)
	if intentStatus != "paid" {
		t.Errorf("ҳолати интент = %q, мехостам paid", intentStatus)
	}
}

// ── Имзо ─────────────────────────────────────────────────────────────────

// Бе ин ҳар кас метавонад моли ройгон гирад.
func TestPaymentWebhookRejectsUnsigned(t *testing.T) {
	needDB(t)
	r, _ := payRouter(t)
	buyerID, tok := newBuyer(t, r, 0)
	oid := payOrder(t, buyerID, 250)
	res := call(t, r, "POST", "/api/v1/payments/start",
		map[string]any{"order_id": oid}, bearer(tok))
	ref := str(res.Data, "provider_ref")

	body := payBody("ev-1", ref, "paid", 25000)
	for _, sig := range []string{"", "deadbeef", payments.SignHMAC("калиди-дигар", body)} {
		if code := postWebhook(t, r, body, sig); code != 401 {
			t.Errorf("имзои «%s»: %d, мехостам 401", sig, code)
		}
	}
	// Ва фармоиш бояд ҳамчунон интизори пардохт бошад.
	if got := orderStatusOf(t, oid); got != "pending" {
		t.Fatalf("ҳолати фармоиш = %q — webhook-и беимзо фармоишро "+
			"пардохтшуда кард", got)
	}
	// Ҳеҷ рӯйдод сабт нашуда бошад.
	var n int
	db.DB.QueryRow(`SELECT COUNT(*) FROM payment_events WHERE provider_ref=$1`,
		ref).Scan(&n)
	if n != 0 {
		t.Fatalf("%d рӯйдод сабт шуд, мехостам 0", n)
	}
}

// ── Такрори webhook ──────────────────────────────────────────────────────

// Провайдер ҳамон рӯйдодро чанд бор мефиристад — ин МЕЪЁРИ КОР аст.
func TestPaymentWebhookIsIdempotent(t *testing.T) {
	needDB(t)
	r, _ := payRouter(t)
	buyerID, tok := newBuyer(t, r, 0)
	oid := payOrder(t, buyerID, 250)
	res := call(t, r, "POST", "/api/v1/payments/start",
		map[string]any{"order_id": oid}, bearer(tok))
	ref := str(res.Data, "provider_ref")

	body := payBody("ev-same", ref, "paid", 25000)
	sig := payments.SignHMAC(payTestSecret, body)
	for i := 0; i < 5; i++ {
		if code := postWebhook(t, r, body, sig); code != 200 {
			t.Fatalf("webhook %d: %d", i+1, code)
		}
	}

	var n int
	db.DB.QueryRow(`SELECT COUNT(*) FROM payment_events
		WHERE provider_ref=$1 AND event_id='ev-same'`, ref).Scan(&n)
	if n != 1 {
		t.Fatalf("%d рӯйдод сабт шуд, мехостам 1", n)
	}
	// Ва огоҳӣ бояд ЯК бор фиристода шуда бошад.
	db.DB.QueryRow(`SELECT COUNT(*) FROM notifications WHERE ref_id=$1`,
		oid).Scan(&n)
	if n != 1 {
		t.Fatalf("%d огоҳӣ, мехостам 1 — харидор набояд панҷ хабар гирад", n)
	}
}

// Webhook-ҳои ҲАМЗАМОН бо ҳамон рӯйдод.
//
// Маҳз ин ҷо санҷиши кодӣ («оё аллакай ҳаст?») кифоя нест: ду дархост
// метавонанд ҳарду онро гузаранд. `UNIQUE(provider, event_id)` дар БАЗА
// ин корро мекунад.
func TestPaymentWebhookConcurrentDuplicates(t *testing.T) {
	needDB(t)
	r, _ := payRouter(t)
	buyerID, tok := newBuyer(t, r, 0)
	oid := payOrder(t, buyerID, 250)
	res := call(t, r, "POST", "/api/v1/payments/start",
		map[string]any{"order_id": oid}, bearer(tok))
	ref := str(res.Data, "provider_ref")

	body := payBody("ev-race", ref, "paid", 25000)
	sig := payments.SignHMAC(payTestSecret, body)

	var wg sync.WaitGroup
	for i := 0; i < 10; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			postWebhook(t, r, body, sig)
		}()
	}
	wg.Wait()

	var n int
	db.DB.QueryRow(`SELECT COUNT(*) FROM payment_events
		WHERE provider_ref=$1 AND event_id='ev-race'`, ref).Scan(&n)
	if n != 1 {
		t.Fatalf("%d рӯйдод, мехостам 1 — `UNIQUE` такрорро бас накард", n)
	}
	db.DB.QueryRow(`SELECT COUNT(*) FROM notifications WHERE ref_id=$1`,
		oid).Scan(&n)
	if n != 1 {
		t.Fatalf("%d огоҳӣ, мехостам 1", n)
	}
}

// ── Тартиби ҳолатҳо ──────────────────────────────────────────────────────

// Рӯйдоди баъд аз «paid» фармоишро ақиб намебарад.
//
// Бе ин фармоиши пардохтшуда ба «интизори пардохт» бармегашт, ва
// фурӯшанда молро намефиристод.
func TestPaymentWebhookDoesNotUnpayOrder(t *testing.T) {
	needDB(t)
	r, _ := payRouter(t)
	buyerID, tok := newBuyer(t, r, 0)
	oid := payOrder(t, buyerID, 250)
	res := call(t, r, "POST", "/api/v1/payments/start",
		map[string]any{"order_id": oid}, bearer(tok))
	ref := str(res.Data, "provider_ref")

	for i, st := range []string{"paid", "pending", "failed", "canceled"} {
		body := payBody("ev-"+st, ref, st, 25000)
		if code := postWebhook(t, r, body,
			payments.SignHMAC(payTestSecret, body)); code != 200 {
			t.Fatalf("рӯйдоди %d («%s»): %d", i, st, code)
		}
	}

	if got := orderStatusOf(t, oid); got != "paid" {
		t.Fatalf("ҳолати фармоиш = %q, мехостам paid", got)
	}
	// Рӯйдодҳои ақибрафт сабт шудаанд, вале `applied=false`.
	var applied, notApplied int
	db.DB.QueryRow(`SELECT COUNT(*) FROM payment_events
		WHERE provider_ref=$1 AND applied=true`, ref).Scan(&applied)
	db.DB.QueryRow(`SELECT COUNT(*) FROM payment_events
		WHERE provider_ref=$1 AND applied=false`, ref).Scan(&notApplied)
	if applied != 1 {
		t.Errorf("%d рӯйдоди татбиқшуда, мехостам 1", applied)
	}
	if notApplied != 3 {
		t.Errorf("%d рӯйдоди татбиқнашуда, мехостам 3 — онҳо бояд САБТ "+
			"шаванд, то админ бубинад", notApplied)
	}
}

// ── Иҷозатҳо ва ҳолатҳои канорӣ ──────────────────────────────────────────

// Фармоиши каси ДИГАР пардохт карда намешавад.
func TestPaymentStartForeignOrder(t *testing.T) {
	needDB(t)
	r, _ := payRouter(t)
	otherID, _ := newTestUser(t)
	oid := payOrder(t, otherID, 250)
	_, tok := newBuyer(t, r, 0)

	res := call(t, r, "POST", "/api/v1/payments/start",
		map[string]any{"order_id": oid}, bearer(tok))
	if res.Status != 404 {
		t.Fatalf("мехостам 404, гирифтам %d %s", res.Status, res.Error)
	}
}

// Фармоиши аллакай пардохтшуда дубора пардохт намешавад.
func TestPaymentStartRejectsPaidOrder(t *testing.T) {
	needDB(t)
	r, _ := payRouter(t)
	buyerID, tok := newBuyer(t, r, 0)
	oid := payOrder(t, buyerID, 250)
	db.DB.Exec(`UPDATE orders SET status='paid' WHERE id=$1`, oid)

	res := call(t, r, "POST", "/api/v1/payments/start",
		map[string]any{"order_id": oid}, bearer(tok))
	if res.Status != 409 {
		t.Fatalf("мехостам 409, гирифтам %d %s", res.Status, res.Error)
	}
}

// Ду зеркунии тугма ЯК интент месозад.
func TestPaymentStartIsIdempotent(t *testing.T) {
	needDB(t)
	r, _ := payRouter(t)
	buyerID, tok := newBuyer(t, r, 0)
	oid := payOrder(t, buyerID, 250)

	h := bearer(tok)
	h["Idempotency-Key"] = "pay-" + uuid.NewString()
	a := call(t, r, "POST", "/api/v1/payments/start",
		map[string]any{"order_id": oid}, h)
	b := call(t, r, "POST", "/api/v1/payments/start",
		map[string]any{"order_id": oid}, h)
	if a.Status != 200 || b.Status != 200 {
		t.Fatalf("ҳолатҳо: %d ва %d", a.Status, b.Status)
	}
	if str(a.Data, "provider_ref") != str(b.Data, "provider_ref") {
		t.Fatalf("ду интенти гуногун: %q ва %q",
			str(a.Data, "provider_ref"), str(b.Data, "provider_ref"))
	}
	var n int
	db.DB.QueryRow(`SELECT COUNT(*) FROM payment_intents WHERE order_id=$1`,
		oid).Scan(&n)
	if n != 1 {
		t.Fatalf("%d интент, мехостам 1", n)
	}
}

// Рӯйдоди интенти НОШИНОС сабт мешавад, вале ба ягон фармоиш татбиқ
// намешавад.
//
// Ин метавонад пардохти берун аз барнома бошад — он набояд гум шавад,
// вале набояд ҳам фармоиши тасодуфиро пардохтшуда кунад.
func TestPaymentWebhookUnknownIntent(t *testing.T) {
	needDB(t)
	r, _ := payRouter(t)
	ref := "sbx_" + uuid.NewString()
	body := payBody("ev-orphan", ref, "paid", 999)
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM payment_events WHERE provider_ref=$1`, ref)
	})

	if code := postWebhook(t, r, body,
		payments.SignHMAC(payTestSecret, body)); code != 200 {
		t.Fatalf("webhook: %d", code)
	}
	var applied bool
	var found bool
	db.DB.QueryRow(`SELECT EXISTS(SELECT 1 FROM payment_events
		WHERE provider_ref=$1)`, ref).Scan(&found)
	if !found {
		t.Fatal("рӯйдоди ношинос сабт нашуд — он бояд дар дафтар монад")
	}
	db.DB.QueryRow(`SELECT COALESCE(applied,false) FROM payment_events
		WHERE provider_ref=$1`, ref).Scan(&applied)
	if applied {
		t.Error("рӯйдоди ношинос татбиқшуда қайд шуд")
	}
}

// Бадани вайрон — на panic, на 500.
func TestPaymentWebhookBadBody(t *testing.T) {
	needDB(t)
	r, _ := payRouter(t)
	for _, raw := range []string{"", "{", "ин JSON нест", "[]", "null"} {
		body := []byte(raw)
		code := postWebhook(t, r, body, payments.SignHMAC(payTestSecret, body))
		if code != 401 && code != 400 {
			t.Errorf("бадани «%s» → %d, мехостам 400 ё 401", raw, code)
		}
	}
}

// ── Ҳисоббаробаркунӣ ─────────────────────────────────────────────────────

// Webhook метавонад ГУМ шавад: шабака, сервери хоб, HF Space аз нав
// оғозшуда. Он гоҳ фармоиш абадӣ «интизори пардохт» мемонад, ҳол он ки
// пул аллакай гирифта шудааст.
func TestPaymentReconcileCatchesLostWebhook(t *testing.T) {
	needDB(t)
	r, sb := payRouter(t)
	buyerID, tok := newBuyer(t, r, 0)
	adminID, adminTok := newAdmin(t, r)
	_ = adminID
	oid := payOrder(t, buyerID, 250)

	res := call(t, r, "POST", "/api/v1/payments/start",
		map[string]any{"order_id": oid}, bearer(tok))
	ref := str(res.Data, "provider_ref")

	// Провайдер пардохтро қабул кард, вале webhook НАРАСИД: мо
	// мустақиман ҳолати провайдерро иваз мекунем, бе webhook.
	body := payBody("ev-lost", ref, "paid", 25000)
	sb.VerifyWebhook(map[string]string{
		"X-Signature": payments.SignHMAC(payTestSecret, body)}, body)

	// Фармоиш ҳамчунон интизори пардохт аст.
	if got := orderStatusOf(t, oid); got != "pending" {
		t.Fatalf("шарти санҷиш вайрон: ҳолат = %q", got)
	}

	// Интентро «кӯҳна» мекунем — ҳисоббаробаркунӣ танҳо интентҳои аз 10
	// дақиқа кӯҳнатарро мегирад.
	db.DB.Exec(`UPDATE payment_intents SET created_at = NOW() - INTERVAL '1 hour'
		WHERE provider_ref=$1`, ref)

	rec := call(t, r, "POST", "/api/v1/admin/payments/reconcile", nil,
		bearer(adminTok))
	if rec.Status != 200 {
		t.Fatalf("ҳисоббаробаркунӣ: %d %s", rec.Status, rec.Error)
	}
	if got := orderStatusOf(t, oid); got != "paid" {
		t.Fatalf("ҳолати фармоиш = %q, мехостам paid — ҳисоббаробаркунӣ "+
			"пардохти гумшударо надошт", got)
	}
}

// Ҳисоббаробаркунии такрорӣ набояд дубора татбиқ кунад.
func TestPaymentReconcileIsIdempotent(t *testing.T) {
	needDB(t)
	r, sb := payRouter(t)
	buyerID, tok := newBuyer(t, r, 0)
	_, adminTok := newAdmin(t, r)
	oid := payOrder(t, buyerID, 250)

	res := call(t, r, "POST", "/api/v1/payments/start",
		map[string]any{"order_id": oid}, bearer(tok))
	ref := str(res.Data, "provider_ref")
	body := payBody("ev-lost2", ref, "paid", 25000)
	sb.VerifyWebhook(map[string]string{
		"X-Signature": payments.SignHMAC(payTestSecret, body)}, body)
	db.DB.Exec(`UPDATE payment_intents SET created_at = NOW() - INTERVAL '1 hour'
		WHERE provider_ref=$1`, ref)

	for i := 0; i < 3; i++ {
		call(t, r, "POST", "/api/v1/admin/payments/reconcile", nil,
			bearer(adminTok))
	}
	var n int
	db.DB.QueryRow(`SELECT COUNT(*) FROM notifications WHERE ref_id=$1`,
		oid).Scan(&n)
	if n != 1 {
		t.Fatalf("%d огоҳӣ, мехостам 1", n)
	}
}

// Корбари оддӣ ҳисоббаробаркунӣ карда наметавонад.
func TestPaymentReconcileAdminOnly(t *testing.T) {
	needDB(t)
	r, _ := payRouter(t)
	_, tok := newBuyer(t, r, 0)
	res := call(t, r, "POST", "/api/v1/admin/payments/reconcile", nil, bearer(tok))
	if res.Status != 403 {
		t.Fatalf("мехостам 403, гирифтам %d", res.Status)
	}
}

// ── Провайдер танзим нашуда ──────────────────────────────────────────────

// Агар провайдер набошад, масирҳо 503 медиҳанд — НА «пардохт шуд».
//
// Ин аз «провайдери қалбакӣ, ки ҳамеша мегӯяд пардохт шуд» беҳтар аст:
// чунин провайдер дар production моли ройгон медод.
func TestPaymentWithoutProvider(t *testing.T) {
	needDB(t)
	gin.SetMode(gin.TestMode)
	middleware.SetSecret(testSecret)
	r := gin.New()
	uh := NewUserHandler(testSecret, nil)
	pay := NewPaymentHandler(nil) // провайдер нест
	api := r.Group("/api/v1")
	api.POST("/auth/login", uh.Login)
	api.POST("/payments/start", middleware.Auth(), pay.Start)
	api.POST("/payments/webhook/:provider", pay.Webhook)

	buyerID, tok := newBuyer(t, r, 0)
	oid := payOrder(t, buyerID, 250)

	res := call(t, r, "POST", "/api/v1/payments/start",
		map[string]any{"order_id": oid}, bearer(tok))
	if res.Status != 503 {
		t.Fatalf("мехостам 503, гирифтам %d %s", res.Status, res.Error)
	}
	if got := orderStatusOf(t, oid); got != "pending" {
		t.Fatalf("ҳолат = %q, мехостам pending", got)
	}

	// Webhook 200 медиҳад (то провайдер такрор накунад), вале чизе
	// намекунад.
	body := payBody("ev-1", "ref", "paid", 100)
	if code := postWebhook(t, r, body,
		payments.SignHMAC(payTestSecret, body)); code != 200 {
		t.Errorf("webhook бе провайдер → %d, мехостам 200", code)
	}
	if got := orderStatusOf(t, oid); got != "pending" {
		t.Fatalf("ҳолат = %q — webhook бе провайдер фармоишро иваз кард", got)
	}
}
