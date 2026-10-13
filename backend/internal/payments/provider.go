// Package payments — интерфейси пардохт, мустақил аз провайдер.
//
// ЧАРО ИН ҲОЛО СОХТА МЕШАВАД, ҲОЛ ОН КИ ПРОВАЙДЕРИ ВОҚЕӢ НЕСТ:
//
// Пардохти воқеӣ маълумоти merchant-и Алиф ё Корти Миллӣ талаб мекунад,
// ва он аз мо вобаста нест. Вале се чизи аз ҳама хатарноки пардохт ба
// провайдер ҲЕҶ РАБТЕ НАДОРАНД:
//
//  1. такрори webhook (провайдер ҳамон рӯйдодро чанд бор мефиристад —
//     ин меъёри кор аст, на хато);
//  2. имзои webhook (бе он ҳар кас метавонад «пардохт шуд» фиристад);
//  3. тартиби ҳолатҳо (пардохти бекоршуда набояд ба «пардохтшуда»
//     баргардад).
//
// Ҳар се ҳоло сохта ва САНҶИДА мешаванд. Вақте маълумоти merchant
// омад, танҳо як adapter навишта мешавад — мантиқи хатарнок аллакай
// кор мекунад ва тест дорад.
//
// Ин ҷо ягон «провайдери қалбакӣ, ки худаш мегӯяд пардохт шуд» нест:
// `Sandbox` ошкоро барои ТЕСТ аст ва дар лог худашро ҳамчун sandbox
// меномад.
package payments

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"strings"
)

// Status — ҳолати пардохт.
//
// Ин ҳолатҳои МО ҳастанд, на провайдер. Ҳар adapter ҳолати худашро ба
// инҳо табдил медиҳад — вагарна коди мо ба номҳои провайдери мушаххас
// вобаста мешуд ва иваз кардани провайдер бознависии ҳама чизро талаб
// мекард.
type Status string

const (
	StatusPending  Status = "pending"
	StatusPaid     Status = "paid"
	StatusFailed   Status = "failed"
	StatusCanceled Status = "canceled"
	StatusRefunded Status = "refunded"
)

// statusRank — тартиби ҳолатҳо.
//
// Пардохт ақиб намеравад. Агар провайдер баъди «paid» рӯйдоди
// «pending»-ро фиристад (ва онҳо мефиристанд — рӯйдодҳо метавонанд бо
// тартиби вайрон расанд), мо онро НАДИДА мегузаронем.
var statusRank = map[Status]int{
	StatusPending:  0,
	StatusFailed:   1,
	StatusCanceled: 1,
	StatusPaid:     2,
	StatusRefunded: 3,
}

// CanTransition — оё аз `from` ба `to` гузаштан мумкин аст?
func CanTransition(from, to Status) bool {
	f, okF := statusRank[from]
	t, okT := statusRank[to]
	if !okT {
		return false // ҳолати нашинохта
	}
	if !okF {
		return true // ҳолати аввал
	}
	// Ҳамон ҳолат — тағйир нест, вале хато ҳам нест (такрори webhook).
	if from == to {
		return false
	}
	// Пардохти бекоршуда/афтода метавонад баъд муваффақ шавад (корбар
	// аз нав кӯшиш мекунад дар ҳамон интент) — вале «paid» ба «failed»
	// баргардонидан мумкин нест.
	return t > f
}

// InitiateRequest — он чизе, ки мо ба провайдер медиҳем.
type InitiateRequest struct {
	OrderID string
	UserID  string
	// Дирам (int64), на `float64`. Сабаб дар `money.go` шарҳ дода шуда:
	// `float64` барои пул рақами дақиқ нигоҳ намедорад.
	AmountDirams int64
	Currency     string // "TJS"
	Description  string
	ReturnURL    string
	// IdempotencyKey — то дархости такрорӣ дар тарафи ПРОВАЙДЕР ҳам
	// пардохти дуюм насозад.
	IdempotencyKey string
}

// InitiateResponse — он чизе, ки провайдер бармегардонад.
type InitiateResponse struct {
	// ProviderRef — шиносаи пардохт дар тарафи провайдер. Маҳз ӯ баъд
	// дар webhook меояд.
	ProviderRef string
	// PayURL — ҷое, ки корбарро мефиристем (саҳифаи банк).
	PayURL string
	Status Status
}

// RefundRequest — баргардонидани пул.
type RefundRequest struct {
	ProviderRef    string
	AmountDirams   int64 // 0 = пурра
	Reason         string
	IdempotencyKey string
}

type RefundResponse struct {
	RefundRef string
	Status    Status
}

// Event — рӯйдоди webhook, аллакай тасдиқшуда ва ба шакли мо оварда.
type Event struct {
	// EventID — шиносаи ЯГОНАИ рӯйдод дар тарафи провайдер.
	//
	// Маҳз ӯ такрорро бас мекунад. Бе он мо наметавонем фарқ кунем:
	// «пардохти дуюм» ё «ҳамон пардохт, бори дуюм фиристода шуд».
	EventID      string
	ProviderRef  string
	Status       Status
	AmountDirams int64
	Raw          string
}

// Provider — он чизе, ки ҳар провайдери пардохт бояд дошта бошад.
type Provider interface {
	Name() string
	Initiate(ctx context.Context, req InitiateRequest) (InitiateResponse, error)
	// Status — ҳолати ҳозира аз рӯи провайдер.
	//
	// Ин барои ҲИСОББАРОБАРКУНӢ лозим аст: webhook метавонад гум шавад
	// (шабака, сервери хоб), ва он гоҳ фармоиш абадӣ «интизори пардохт»
	// мемонад, ҳол он ки пул аллакай гирифта шудааст.
	Status(ctx context.Context, providerRef string) (Status, error)
	// VerifyWebhook — имзоро месанҷад ва рӯйдодро мегардонад.
	//
	// Агар имзо нодуруст бошад, ХАТО бармегардад ва рӯйдод НАДИДА
	// мемонад. Бе ин ҳар кас метавонад «пардохт шуд» фиристад.
	VerifyWebhook(headers map[string]string, body []byte) (Event, error)
	Refund(ctx context.Context, req RefundRequest) (RefundResponse, error)
}

var (
	ErrBadSignature  = errors.New("имзои webhook нодуруст")
	ErrNotConfigured = errors.New("провайдери пардохт танзим нашудааст")
	ErrNoEventID     = errors.New("рӯйдод шиносаи ягона надорад")
)

// VerifyHMAC — имзои HMAC-SHA256.
//
// `hmac.Equal` ҳатмист, на `==`: муқоисаи оддии сатрҳо дар аввалин
// байти нодуруст бас мекунад, ва аз рӯи ВАҚТИ ҷавоб имзоро байт ба байт
// тахмин кардан мумкин аст (timing attack). `hmac.Equal` ҳамеша тамоми
// дарозиро месанҷад.
func VerifyHMAC(secret string, body []byte, gotSignature string) bool {
	if secret == "" || gotSignature == "" {
		return false
	}
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write(body)
	want := hex.EncodeToString(mac.Sum(nil))
	got := strings.ToLower(strings.TrimSpace(gotSignature))
	// Баъзе провайдерҳо пешванд мегузоранд: «sha256=...»
	if i := strings.IndexByte(got, '='); i > 0 && i < 12 {
		got = got[i+1:]
	}
	return hmac.Equal([]byte(want), []byte(got))
}

// SignHMAC — ҳамон имзо, барои тест ва adapter-ҳое, ки дархостро имзо
// мекунанд.
func SignHMAC(secret string, body []byte) string {
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write(body)
	return hex.EncodeToString(mac.Sum(nil))
}
