package handlers

import (
	"strings"
	"time"
)

// ═══════════════════════════════════════════════════════════════════════════
//  RFQ — мантиқи тоза (бе база)
// ═══════════════════════════════════════════════════════════════════════════
//
// Ҳамаи қоидаҳо ин ҷо, бе `db.DB` — пас онҳоро воқеан санҷидан мумкин аст.
// Handler-ҳо дар `rfq.go` танҳо дархост ва транзаксия доранд.

// Ҳолатҳои дархост.
const (
	rfqOpen      = "open"      // фурӯшандагон пешниҳод дода метавонанд
	rfqClosed    = "closed"    // мӯҳлат гузашт ё харидор пӯшид
	rfqAwarded   = "awarded"   // пешниҳод қабул шуд, фармоиш сохта шуд
	rfqCancelled = "cancelled" // харидор бекор кард
)

// Ҳолатҳои пешниҳод.
const (
	quoteActive    = "active"
	quoteRevised   = "revised"   // нусхаи нав дода шуд
	quoteWithdrawn = "withdrawn" // фурӯшанда гирифт
	quoteAccepted  = "accepted"
	quoteRejected  = "rejected"
)

// Маҳдудиятҳо. Онҳо аз мантиқи корӣ меоянд, на аз ҳавои дил.
const (
	// Дархост бояд ҳадди ақал як соат кушода бошад — вагарна фурӯшанда
	// ҳатто фурсати хондан надорад.
	rfqMinOpenHours = 1
	// Ва на бештар аз 90 рӯз: дархости кӯҳна нархи кӯҳна дорад ва
	// рӯйхатро ифлос мекунад.
	rfqMaxOpenDays = 90
	// Шумора: аз 1 то 10 миллион. Ҳадди боло барои он, ки ҳисоби ҷамъ аз
	// `int64` берун наравад.
	rfqMaxQuantity = 10_000_000
	rfqMaxTitle    = 200
	rfqMaxDesc     = 4000
	rfqMaxNote     = 2000
	// Фурӯшанда метавонад пешниҳодашро то 10 бор ислоҳ кунад. Бештар аз
	// он аллакай нишонаи кӯшиши пур кардани база аст.
	quoteMaxVersions = 10
)

// ── Сохтани дархост ──────────────────────────────────────────────────────

type rfqInput struct {
	Title       string
	Description string
	Quantity    int
	Unit        string
	TargetPrice int64 // дирам, 0 = нишон дода нашуд
	Destination string
	ClosesAt    time.Time
	NeededBy    *time.Time
}

// validateRFQ — дархостро месанҷад ва тоза мекунад.
//
// Хатои аввалро бармегардонад — рӯйхати пурра ин ҷо лозим нест, чунки
// форма майдонҳои кам дорад ва корбар якбора мебинад.
func validateRFQ(in rfqInput, now time.Time) (rfqInput, string) {
	in.Title = strings.TrimSpace(in.Title)
	in.Description = strings.TrimSpace(in.Description)
	in.Destination = strings.TrimSpace(in.Destination)
	in.Unit = normalizeUnit(in.Unit)

	if len([]rune(in.Title)) < 3 {
		return in, "Номи дархост хеле кӯтоҳ аст"
	}
	if len([]rune(in.Title)) > rfqMaxTitle {
		in.Title = string([]rune(in.Title)[:rfqMaxTitle])
	}
	if len([]rune(in.Description)) > rfqMaxDesc {
		in.Description = string([]rune(in.Description)[:rfqMaxDesc])
	}
	if in.Quantity < 1 {
		return in, "Шумораро нишон диҳед"
	}
	if in.Quantity > rfqMaxQuantity {
		return in, "Шумора хеле зиёд аст"
	}
	if in.TargetPrice < 0 {
		return in, "Нархи дилхоҳ манфӣ буда наметавонад"
	}
	if in.ClosesAt.Before(now.Add(rfqMinOpenHours * time.Hour)) {
		return in, "Мӯҳлат бояд ҳадди ақал 1 соат баъдтар бошад"
	}
	if in.ClosesAt.After(now.AddDate(0, 0, rfqMaxOpenDays)) {
		return in, "Мӯҳлат аз 90 рӯз зиёд буда наметавонад"
	}
	// Санаи лозимӣ пеш аз пӯшидани дархост маъно надорад: фурӯшанда
	// ҳатто фурсати фиристодан надорад.
	if in.NeededBy != nil && in.NeededBy.Before(in.ClosesAt) {
		return in, "Санаи лозимӣ пеш аз мӯҳлати пешниҳодҳо аст"
	}
	return in, ""
}

// canQuote — оё фурӯшанда ҳоло пешниҳод дода метавонад?
func canQuote(status string, closesAt, now time.Time) bool {
	return strings.TrimSpace(strings.ToLower(status)) == rfqOpen &&
		closesAt.After(now)
}

// effectiveRFQStatus — ҳолати ВОҚЕӢ бо назардошти мӯҳлат.
//
// Дар база `status` метавонад ҳамчунон 'open' бошад, вале мӯҳлат
// гузашта — чунки ягон sweeper ҳар сония кор намекунад. Пас ҳолати
// намоишшаванда ҳисоб мешавад.
func effectiveRFQStatus(status string, closesAt, now time.Time) string {
	s := strings.TrimSpace(strings.ToLower(status))
	if s == rfqOpen && !closesAt.After(now) {
		return rfqClosed
	}
	if s == "" {
		return rfqOpen
	}
	return s
}

// ── Пешниҳод ─────────────────────────────────────────────────────────────

type quoteInput struct {
	UnitPrice    int64 // дирам
	MinQty       int
	ShippingCost int64 // дирам
	LeadDays     int
	PaymentTerms string
	Note         string
	ValidUntil   *time.Time
}

func validateQuote(in quoteInput, rfqQty int, now time.Time) (quoteInput, string) {
	in.PaymentTerms = strings.TrimSpace(in.PaymentTerms)
	in.Note = strings.TrimSpace(in.Note)
	if len([]rune(in.Note)) > rfqMaxNote {
		in.Note = string([]rune(in.Note)[:rfqMaxNote])
	}
	if len([]rune(in.PaymentTerms)) > 200 {
		in.PaymentTerms = string([]rune(in.PaymentTerms)[:200])
	}

	if in.UnitPrice <= 0 {
		return in, "Нархи як донаро нишон диҳед"
	}
	if in.ShippingCost < 0 {
		return in, "Арзиши расонидан манфӣ буда наметавонад"
	}
	if in.MinQty < 1 {
		in.MinQty = 1
	}
	// Ҳадди ақали фурӯшанда аз шумораи дархост зиёд бошад — пешниҳод
	// барои ин харидор бефоида аст. Беҳтар аст, ки фурӯшанда инро фавран
	// бидонад, на баъди интизори ҷавоб.
	if in.MinQty > rfqQty {
		return in, "Ҳадди ақали шумо аз шумораи дархост зиёд аст"
	}
	if in.LeadDays < 0 {
		return in, "Мӯҳлати омодагӣ манфӣ буда наметавонад"
	}
	if in.LeadDays > 365 {
		return in, "Мӯҳлати омодагӣ аз як сол зиёд аст"
	}
	// Пешниҳоди аллакай мӯҳлаташ гузашта маъно надорад.
	if in.ValidUntil != nil && !in.ValidUntil.After(now) {
		return in, "Мӯҳлати эътибори пешниҳод аллакай гузаштааст"
	}
	return in, ""
}

// quoteUsable — оё харидор ин пешниҳодро ҳоло қабул карда метавонад?
//
// Мӯҳлат ҳатмист: бе он фурӯшанда абадӣ ба нархи шашмоҳа
// пешниҳодкардааш баста мемонад, ва харидор метавонад баъди ним сол
// «қабул» занад.
func quoteUsable(status string, validUntil *time.Time, now time.Time) bool {
	if strings.TrimSpace(strings.ToLower(status)) != quoteActive {
		return false
	}
	if validUntil != nil && !validUntil.After(now) {
		return false
	}
	return true
}

// quoteTotal — ҷамъи пешниҳод барои ҳамин шумора (дирам).
//
// Шумора ин ҷо аз ДАРХОСТ меояд, на аз фурӯшанда — фурӯшанда нархи як
// дона ва арзиши расониданро медиҳад.
func quoteTotal(unitPrice int64, qty int, shipping int64) int64 {
	if unitPrice <= 0 || qty <= 0 || qty > rfqMaxQuantity {
		return 0
	}
	if shipping < 0 {
		shipping = 0
	}
	return unitPrice*int64(qty) + shipping
}

// cheapestQuote — индекси пешниҳоди аз ҳама арзон (аз рӯи ҶАМЪ, на аз
// рӯи нархи як дона).
//
// Маҳз ҷамъ муҳим аст: пешниҳоди «10 сом. донааш + 5000 расонидан»
// метавонад аз «12 сом. донааш + ройгон» гаронтар афтад. Нархи як дона
// худаш танҳо нимаи ҳақиқат аст.
//
// `-1` агар ягон пешниҳоди коршоям набошад.
func cheapestQuote(totals []int64) int {
	best := -1
	for i, t := range totals {
		if t <= 0 {
			continue
		}
		if best == -1 || t < totals[best] {
			best = i
		}
	}
	return best
}
