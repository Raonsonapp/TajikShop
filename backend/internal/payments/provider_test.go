package payments

import (
	"context"
	"encoding/json"
	"strings"
	"sync"
	"testing"
)

const testSecret = "test-webhook-secret"

func sandbox(t *testing.T) *Sandbox {
	t.Helper()
	return NewSandbox(testSecret)
}

// ── Имзо ─────────────────────────────────────────────────────────────────

// Бе ин санҷиш ҲАР КАС метавонад «пардохт шуд» фиристад.
func TestVerifyHMAC(t *testing.T) {
	body := []byte(`{"event_id":"e1","ref":"r1","status":"paid"}`)
	sig := SignHMAC(testSecret, body)

	if !VerifyHMAC(testSecret, body, sig) {
		t.Fatal("имзои дуруст рад шуд")
	}
	// Пешванди «sha256=» — баъзе провайдерҳо чунин мефиристанд.
	if !VerifyHMAC(testSecret, body, "sha256="+sig) {
		t.Error("имзо бо пешванди sha256= рад шуд")
	}
	// Ҳарфи калон набояд муҳим бошад.
	if !VerifyHMAC(testSecret, body, strings.ToUpper(sig)) {
		t.Error("имзо бо ҳарфи калон рад шуд")
	}

	bad := []struct {
		name   string
		secret string
		body   []byte
		sig    string
	}{
		{"калиди нодуруст", "калиди-дигар", body, sig},
		{"бадани тағйирёфта", testSecret,
			[]byte(`{"event_id":"e1","ref":"r1","status":"paid","x":1}`), sig},
		{"имзои холӣ", testSecret, body, ""},
		{"имзои бофташуда", testSecret, body, "deadbeef"},
		{"калиди холӣ", "", body, sig},
		// Маблағ иваз шуд — имзо бояд афтад.
		{"маблағи тағйирёфта", testSecret,
			[]byte(`{"event_id":"e1","ref":"r1","status":"paid","amount":999999}`), sig},
	}
	for _, c := range bad {
		if VerifyHMAC(c.secret, c.body, c.sig) {
			t.Errorf("%s: имзо қабул шуд, бояд рад шавад", c.name)
		}
	}
}

// ── Тартиби ҳолатҳо ──────────────────────────────────────────────────────

// Пардохт АҚИБ намеравад.
//
// Рӯйдодҳои webhook метавонанд бо тартиби вайрон расанд — ин меъёри кор
// аст. Агар баъди «paid» рӯйдоди «pending» расад ва мо онро қабул кунем,
// фармоиши пардохтшуда ба «интизори пардохт» бармегардад.
func TestCanTransition(t *testing.T) {
	ok := [][2]Status{
		{StatusPending, StatusPaid},
		{StatusPending, StatusFailed},
		{StatusPending, StatusCanceled},
		{StatusFailed, StatusPaid},   // корбар аз нав кӯшиш кард
		{StatusCanceled, StatusPaid}, // ҳамчунин
		{StatusPaid, StatusRefunded},
	}
	for _, c := range ok {
		if !CanTransition(c[0], c[1]) {
			t.Errorf("«%s» → «%s» бояд мумкин бошад", c[0], c[1])
		}
	}

	bad := [][2]Status{
		{StatusPaid, StatusPending}, // ← маҳз камбудии хатарнок
		{StatusPaid, StatusFailed},
		{StatusPaid, StatusCanceled},
		{StatusRefunded, StatusPaid},
		{StatusRefunded, StatusPending},
		{StatusFailed, StatusCanceled}, // ҳамон дараҷа
		// Такрори ҳамон ҳолат — тағйир нест.
		{StatusPaid, StatusPaid},
		{StatusPending, StatusPending},
		// Ҳолати нашинохта ҳеҷ гоҳ қабул намешавад.
		{StatusPending, Status("ягон-чиз")},
		{StatusPaid, Status("")},
	}
	for _, c := range bad {
		if CanTransition(c[0], c[1]) {
			t.Errorf("«%s» → «%s» бояд МУМКИН НАБОШАД", c[0], c[1])
		}
	}

	// Ҳолати аввал (аз холӣ) — ҳар ҳолати шинохта мумкин.
	for _, to := range []Status{StatusPending, StatusPaid, StatusFailed} {
		if !CanTransition("", to) {
			t.Errorf("ҳолати аввал «%s» рад шуд", to)
		}
	}
}

// ── Sandbox ──────────────────────────────────────────────────────────────

func TestSandboxInitiate(t *testing.T) {
	s := sandbox(t)
	res, err := s.Initiate(context.Background(), InitiateRequest{
		OrderID: "o1", UserID: "u1", AmountDirams: 12345,
		Currency: "TJS", IdempotencyKey: "k1",
	})
	if err != nil {
		t.Fatalf("Initiate: %v", err)
	}
	if res.ProviderRef == "" {
		t.Fatal("ProviderRef холӣ аст")
	}
	if res.Status != StatusPending {
		t.Errorf("ҳолат = %q, мехостам pending", res.Status)
	}
	// Суроға бояд ошкоро sandbox будани худро гӯяд — вагарна касе онро
	// бо саҳифаи воқеии банк омехта мекунад.
	if !strings.HasPrefix(res.PayURL, "sandbox://") {
		t.Errorf("PayURL = %q — бояд ошкоро sandbox бошад", res.PayURL)
	}
}

// Дархости такрорӣ бо ҳамон калид ҲАМОН пардохтро бармегардонад.
//
// Бе ин зеркунии дукаратаи тугма ду пардохт месозад, ва корбар ду бор
// мепардозад.
func TestSandboxInitiateIsIdempotent(t *testing.T) {
	s := sandbox(t)
	req := InitiateRequest{
		OrderID: "o1", AmountDirams: 500, IdempotencyKey: "same-key",
	}
	a, _ := s.Initiate(context.Background(), req)
	b, _ := s.Initiate(context.Background(), req)
	if a.ProviderRef != b.ProviderRef {
		t.Fatalf("ду пардохти гуногун: %q ва %q", a.ProviderRef, b.ProviderRef)
	}
}

func TestSandboxInitiateRejectsBadInput(t *testing.T) {
	s := sandbox(t)
	for _, req := range []InitiateRequest{
		{OrderID: "o1", AmountDirams: 0},
		{OrderID: "o1", AmountDirams: -100},
		{OrderID: "", AmountDirams: 100},
	} {
		if _, err := s.Initiate(context.Background(), req); err == nil {
			t.Errorf("дархости вайрон қабул шуд: %+v", req)
		}
	}
}

func webhookBody(eventID, ref, status string, amount int64) []byte {
	b, _ := json.Marshal(map[string]any{
		"event_id": eventID, "ref": ref, "status": status, "amount": amount,
	})
	return b
}

func TestSandboxWebhookVerified(t *testing.T) {
	s := sandbox(t)
	s.Initiate(context.Background(), InitiateRequest{
		OrderID: "o1", AmountDirams: 500, IdempotencyKey: "k"})

	body := webhookBody("ev-1", "sbx_k", "paid", 500)
	ev, err := s.VerifyWebhook(
		map[string]string{"X-Signature": SignHMAC(testSecret, body)}, body)
	if err != nil {
		t.Fatalf("webhook: %v", err)
	}
	if ev.EventID != "ev-1" || ev.Status != StatusPaid {
		t.Fatalf("рӯйдод нодуруст: %+v", ev)
	}
	// Ҳолат бояд дар провайдер низ иваз шуда бошад.
	if st, _ := s.Status(context.Background(), "sbx_k"); st != StatusPaid {
		t.Errorf("ҳолати провайдер = %q, мехостам paid", st)
	}
}

func TestSandboxWebhookRejectsBadSignature(t *testing.T) {
	s := sandbox(t)
	body := webhookBody("ev-1", "sbx_k", "paid", 500)

	cases := []map[string]string{
		{"X-Signature": "deadbeef"},
		{"X-Signature": ""},
		{},                                      // имзо умуман нест
		{"X-Other": SignHMAC(testSecret, body)}, // сарлавҳаи нодуруст
	}
	for i, h := range cases {
		if _, err := s.VerifyWebhook(h, body); err != ErrBadSignature {
			t.Errorf("ҳолати %d: хато = %v, мехостам ErrBadSignature", i, err)
		}
	}
}

// Рӯйдод бе шиносаи ягона қабул намешавад.
//
// Бе `event_id` фарқ кардан номумкин аст: «пардохти дуюм» ё «ҳамон
// пардохт, бори дуюм фиристода шуд». Пас чунин рӯйдод рад мешавад, на
// «эҳтиётан қабул».
func TestSandboxWebhookRequiresEventID(t *testing.T) {
	s := sandbox(t)
	for _, id := range []string{"", "   "} {
		body := webhookBody(id, "sbx_k", "paid", 500)
		if _, err := s.VerifyWebhook(
			map[string]string{"X-Signature": SignHMAC(testSecret, body)},
			body); err != ErrNoEventID {
			t.Errorf("шиносаи «%s»: хато = %v, мехостам ErrNoEventID", id, err)
		}
	}
}

func TestSandboxWebhookRejectsUnknownStatus(t *testing.T) {
	s := sandbox(t)
	body := webhookBody("ev-1", "sbx_k", "ягон-ҳолати-нав", 500)
	if _, err := s.VerifyWebhook(
		map[string]string{"X-Signature": SignHMAC(testSecret, body)},
		body); err == nil {
		t.Fatal("ҳолати нашинохта қабул шуд")
	}
}

// Рӯйдоди баъд аз «paid» ҳолатро ақиб намебарад.
func TestSandboxWebhookDoesNotGoBackwards(t *testing.T) {
	s := sandbox(t)
	s.Initiate(context.Background(), InitiateRequest{
		OrderID: "o1", AmountDirams: 500, IdempotencyKey: "k"})

	for _, st := range []string{"paid", "pending", "failed"} {
		body := webhookBody("ev-"+st, "sbx_k", st, 500)
		s.VerifyWebhook(
			map[string]string{"X-Signature": SignHMAC(testSecret, body)}, body)
	}
	if st, _ := s.Status(context.Background(), "sbx_k"); st != StatusPaid {
		t.Fatalf("ҳолат = %q, мехостам paid — рӯйдоди баъдӣ набояд "+
			"пардохтро ақиб барад", st)
	}
}

// Webhook-ҳои ҲАМЗАМОН — провайдерҳо ҳамин тавр мефиристанд.
func TestSandboxWebhookConcurrent(t *testing.T) {
	s := sandbox(t)
	s.Initiate(context.Background(), InitiateRequest{
		OrderID: "o1", AmountDirams: 500, IdempotencyKey: "k"})

	var wg sync.WaitGroup
	for i := 0; i < 20; i++ {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			body := webhookBody("ev-1", "sbx_k", "paid", 500)
			s.VerifyWebhook(
				map[string]string{"X-Signature": SignHMAC(testSecret, body)},
				body)
		}(i)
	}
	wg.Wait()
	if st, _ := s.Status(context.Background(), "sbx_k"); st != StatusPaid {
		t.Fatalf("ҳолат = %q, мехостам paid", st)
	}
}

// ── Баргардонидани пул ───────────────────────────────────────────────────

func TestSandboxRefundOnlyPaid(t *testing.T) {
	s := sandbox(t)
	s.Initiate(context.Background(), InitiateRequest{
		OrderID: "o1", AmountDirams: 500, IdempotencyKey: "k"})

	// Ҳанӯз пардохт нашуд — баргардонидан мумкин нест.
	//
	// Бе ин санҷиш «баргардонидани» пардохти афтода пулро аз ҳеҷ ҷо
	// месохт.
	if _, err := s.Refund(context.Background(),
		RefundRequest{ProviderRef: "sbx_k"}); err == nil {
		t.Fatal("баргардонидани пардохти напардохташуда қабул шуд")
	}

	// Пардохт мешавад.
	body := webhookBody("ev-1", "sbx_k", "paid", 500)
	s.VerifyWebhook(
		map[string]string{"X-Signature": SignHMAC(testSecret, body)}, body)

	res, err := s.Refund(context.Background(),
		RefundRequest{ProviderRef: "sbx_k"})
	if err != nil {
		t.Fatalf("баргардонидан: %v", err)
	}
	if res.Status != StatusRefunded {
		t.Errorf("ҳолат = %q, мехостам refunded", res.Status)
	}

	// Баргардонидани дуюм — пардохт дигар «paid» нест.
	if _, err := s.Refund(context.Background(),
		RefundRequest{ProviderRef: "sbx_k"}); err == nil {
		t.Fatal("баргардонидани дукарата қабул шуд")
	}
}

func TestSandboxRefundUnknownRef(t *testing.T) {
	s := sandbox(t)
	if _, err := s.Refund(context.Background(),
		RefundRequest{ProviderRef: "ҳеҷ-чунин-пардохт-нест"}); err == nil {
		t.Fatal("баргардонидани пардохти нестбуда қабул шуд")
	}
}

// Sandbox бояд ОШКОРО худашро sandbox номад — то дар лог ва санадҳо
// касе онро бо провайдери воқеӣ омехта накунад.
func TestSandboxIsHonestAboutItself(t *testing.T) {
	if sandbox(t).Name() != "sandbox" {
		t.Fatal("провайдери тестӣ номи дигар дорад — ин фиребанда аст")
	}
}
