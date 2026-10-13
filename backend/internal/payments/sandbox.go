package payments

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"sync"
)

// Sandbox — провайдери ТЕСТӢ.
//
// Ин провайдери «қалбакӣ, ки худаш мегӯяд пардохт шуд» НЕСТ. Он ошкоро
// `sandbox` ном дорад, дар лог ҳамчун sandbox менамояд, ва дар
// production танҳо он гоҳ фаъол мешавад, ки `PAYMENT_PROVIDER=sandbox`
// дидаву дониста гузошта шавад.
//
// Вазифаи ӯ: мантиқи ХАТАРНОКИ пардохт (такрори webhook, имзо, тартиби
// ҳолатҳо) бе маълумоти merchant санҷида шавад. Вақте Алиф ё Корти
// Миллӣ пайваст шавад, танҳо `Initiate`/`Status`/`VerifyWebhook`-и он
// навишта мешавад — мантиқи гирду атроф аллакай тест дорад.
type Sandbox struct {
	Secret string

	mu    sync.RWMutex
	state map[string]Status // providerRef → ҳолат
}

func NewSandbox(secret string) *Sandbox {
	return &Sandbox{Secret: secret, state: map[string]Status{}}
}

func (s *Sandbox) Name() string { return "sandbox" }

func (s *Sandbox) Initiate(_ context.Context, req InitiateRequest) (InitiateResponse, error) {
	if req.AmountDirams <= 0 {
		return InitiateResponse{}, errors.New("маблағ бояд аз сифр зиёд бошад")
	}
	if req.OrderID == "" {
		return InitiateResponse{}, errors.New("фармоиш нишон дода нашуд")
	}
	// Калиди idempotency ҳамчун шиносаи провайдер: дархости такрорӣ
	// ҲАМОН пардохтро бармегардонад, на пардохти нав. Провайдери воқеӣ
	// ҳамин тавр кор мекунад.
	ref := "sbx_" + req.IdempotencyKey
	if req.IdempotencyKey == "" {
		ref = "sbx_" + req.OrderID
	}

	s.mu.Lock()
	if _, seen := s.state[ref]; !seen {
		s.state[ref] = StatusPending
	}
	cur := s.state[ref]
	s.mu.Unlock()

	return InitiateResponse{
		ProviderRef: ref,
		// Дар sandbox «саҳифаи банк» нест — ба ҷояш суроғаи дохилӣ, ки
		// ошкоро sandbox будани худро мегӯяд.
		PayURL: "sandbox://pay/" + ref,
		Status: cur,
	}, nil
}

func (s *Sandbox) Status(_ context.Context, ref string) (Status, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	st, ok := s.state[ref]
	if !ok {
		return "", errors.New("пардохт ёфт нашуд")
	}
	return st, nil
}

// VerifyWebhook — ҳамон санҷиши имзо, ки провайдери воқеӣ талаб мекунад.
//
// Шакли бадан:
//
//	{"event_id":"...","ref":"...","status":"paid","amount":12345}
func (s *Sandbox) VerifyWebhook(headers map[string]string, body []byte) (Event, error) {
	sig := ""
	for k, v := range headers {
		if strings.EqualFold(k, "X-Signature") ||
			strings.EqualFold(k, "X-Payment-Signature") {
			sig = v
			break
		}
	}
	if !VerifyHMAC(s.Secret, body, sig) {
		return Event{}, ErrBadSignature
	}

	var in struct {
		EventID string `json:"event_id"`
		Ref     string `json:"ref"`
		Status  string `json:"status"`
		Amount  int64  `json:"amount"`
	}
	if err := json.Unmarshal(body, &in); err != nil {
		return Event{}, errors.New("бадани webhook хонда нашуд")
	}
	if strings.TrimSpace(in.EventID) == "" {
		// Бе шиносаи ягона такрорро фарқ кардан номумкин аст — пас
		// чунин рӯйдод қабул намешавад.
		return Event{}, ErrNoEventID
	}

	st := Status(strings.ToLower(strings.TrimSpace(in.Status)))
	if _, ok := statusRank[st]; !ok {
		return Event{}, errors.New("ҳолати нашинохта: " + in.Status)
	}

	s.mu.Lock()
	if cur, ok := s.state[in.Ref]; !ok || CanTransition(cur, st) {
		s.state[in.Ref] = st
	}
	s.mu.Unlock()

	return Event{
		EventID: in.EventID, ProviderRef: in.Ref,
		Status: st, AmountDirams: in.Amount, Raw: string(body),
	}, nil
}

func (s *Sandbox) Refund(_ context.Context, req RefundRequest) (RefundResponse, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	cur, ok := s.state[req.ProviderRef]
	if !ok {
		return RefundResponse{}, errors.New("пардохт ёфт нашуд")
	}
	if cur != StatusPaid {
		// Пардохти напардохташударо баргардонидан мумкин нест. Бе ин
		// санҷиш «баргардонидани» пардохти афтода пулро аз ҳеҷ ҷо
		// месохт.
		return RefundResponse{}, errors.New(
			"танҳо пардохти анҷомёфта баргардонида мешавад")
	}
	s.state[req.ProviderRef] = StatusRefunded
	return RefundResponse{
		RefundRef: "rfd_" + req.ProviderRef,
		Status:    StatusRefunded,
	}, nil
}
