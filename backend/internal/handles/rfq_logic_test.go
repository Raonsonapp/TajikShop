package handlers

import (
	"testing"
	"time"
)

var rfqNow = time.Date(2026, 10, 13, 12, 0, 0, 0, time.UTC)

func goodRFQ() rfqInput {
	return rfqInput{
		Title:       "500 кг орди навъи аввал",
		Description: "Барои нонвойхона",
		Quantity:    500,
		Unit:        "кг",
		TargetPrice: 450, // 4.50 сом.
		Destination: "Душанбе",
		ClosesAt:    rfqNow.AddDate(0, 0, 7),
	}
}

func TestValidateRFQOK(t *testing.T) {
	out, msg := validateRFQ(goodRFQ(), rfqNow)
	if msg != "" {
		t.Fatalf("хатои ғайричашмдошт: %s", msg)
	}
	if out.Unit != "кг" {
		t.Errorf("воҳид = %q, мехостам «кг»", out.Unit)
	}
}

func TestValidateRFQRejects(t *testing.T) {
	cases := []struct {
		name string
		edit func(*rfqInput)
	}{
		{"номи кӯтоҳ", func(r *rfqInput) { r.Title = "аб" }},
		{"номи холӣ", func(r *rfqInput) { r.Title = "   " }},
		{"шумораи сифр", func(r *rfqInput) { r.Quantity = 0 }},
		{"шумораи манфӣ", func(r *rfqInput) { r.Quantity = -5 }},
		{"шумораи бениҳоят", func(r *rfqInput) { r.Quantity = 999_999_999 }},
		{"нархи манфӣ", func(r *rfqInput) { r.TargetPrice = -1 }},
		// Мӯҳлати хеле наздик: фурӯшанда ҳатто фурсати хондан надорад.
		{"мӯҳлат баъди 10 дақиқа", func(r *rfqInput) {
			r.ClosesAt = rfqNow.Add(10 * time.Minute)
		}},
		{"мӯҳлат дар гузашта", func(r *rfqInput) {
			r.ClosesAt = rfqNow.AddDate(0, 0, -1)
		}},
		{"мӯҳлати 100 рӯз", func(r *rfqInput) {
			r.ClosesAt = rfqNow.AddDate(0, 0, 100)
		}},
	}
	for _, c := range cases {
		r := goodRFQ()
		c.edit(&r)
		if _, msg := validateRFQ(r, rfqNow); msg == "" {
			t.Errorf("%s: қабул шуд, бояд рад шавад", c.name)
		}
	}
}

// Санаи лозимӣ пеш аз пӯшидани дархост маъно надорад: фурӯшанда ҳатто
// фурсати фиристодан надорад.
func TestValidateRFQNeededBeforeClose(t *testing.T) {
	r := goodRFQ()
	early := r.ClosesAt.AddDate(0, 0, -2)
	r.NeededBy = &early
	if _, msg := validateRFQ(r, rfqNow); msg == "" {
		t.Fatal("санаи лозимии пеш аз мӯҳлат қабул шуд")
	}

	late := r.ClosesAt.AddDate(0, 0, 5)
	r.NeededBy = &late
	if _, msg := validateRFQ(r, rfqNow); msg != "" {
		t.Fatalf("санаи дуруст рад шуд: %s", msg)
	}
}

// Матни хеле дароз набояд дархостро рад кунад — кӯтоҳ карда мешавад.
func TestValidateRFQTrimsLongText(t *testing.T) {
	r := goodRFQ()
	r.Title = ""
	for i := 0; i < 500; i++ {
		r.Title += "а"
	}
	for i := 0; i < 9000; i++ {
		r.Description += "б"
	}
	out, msg := validateRFQ(r, rfqNow)
	if msg != "" {
		t.Fatalf("рад шуд: %s", msg)
	}
	if len([]rune(out.Title)) != rfqMaxTitle {
		t.Errorf("ном = %d ҳарф, мехостам %d", len([]rune(out.Title)), rfqMaxTitle)
	}
	if len([]rune(out.Description)) != rfqMaxDesc {
		t.Errorf("тавзеҳ = %d ҳарф, мехостам %d",
			len([]rune(out.Description)), rfqMaxDesc)
	}
}

// ── Иҷозати пешниҳод ─────────────────────────────────────────────────────

func TestCanQuote(t *testing.T) {
	future := rfqNow.AddDate(0, 0, 3)
	past := rfqNow.AddDate(0, 0, -1)

	if !canQuote(rfqOpen, future, rfqNow) {
		t.Error("дархости кушода бо мӯҳлати оянда — бояд мумкин бошад")
	}
	// Мӯҳлат гузашт — ҳатто агар дар база ҳамчунон 'open' бошад.
	if canQuote(rfqOpen, past, rfqNow) {
		t.Error("мӯҳлат гузашт — пешниҳод набояд мумкин бошад")
	}
	for _, s := range []string{rfqClosed, rfqAwarded, rfqCancelled, "", "хххх"} {
		if canQuote(s, future, rfqNow) {
			t.Errorf("ҳолати «%s» — пешниҳод набояд мумкин бошад", s)
		}
	}
	// Ҳарфи калон набояд муҳим бошад.
	if !canQuote("OPEN", future, rfqNow) {
		t.Error("«OPEN» бояд кор кунад")
	}
}

// Ҳолати намоишшаванда бояд мӯҳлатро ба назар гирад: дар база 'open'
// мемонад, вале корбар «пӯшида» бинад.
func TestEffectiveRFQStatus(t *testing.T) {
	future := rfqNow.AddDate(0, 0, 3)
	past := rfqNow.Add(-time.Minute)

	if got := effectiveRFQStatus(rfqOpen, future, rfqNow); got != rfqOpen {
		t.Errorf("= %q, мехостам open", got)
	}
	if got := effectiveRFQStatus(rfqOpen, past, rfqNow); got != rfqClosed {
		t.Errorf("= %q, мехостам closed (мӯҳлат гузашт)", got)
	}
	// Ҳолати қабулшуда бо мӯҳлати гузашта ҳам 'awarded' мемонад —
	// вагарна таърих вайрон мешавад.
	if got := effectiveRFQStatus(rfqAwarded, past, rfqNow); got != rfqAwarded {
		t.Errorf("= %q, мехостам awarded", got)
	}
	if got := effectiveRFQStatus("", future, rfqNow); got != rfqOpen {
		t.Errorf("ҳолати холӣ = %q, мехостам open", got)
	}
}

// ── Пешниҳод ─────────────────────────────────────────────────────────────

func goodQuote() quoteInput {
	v := rfqNow.AddDate(0, 0, 5)
	return quoteInput{
		UnitPrice:    460, // 4.60 сом.
		MinQty:       100,
		ShippingCost: 15000,
		LeadDays:     3,
		PaymentTerms: "50% пешпардохт",
		ValidUntil:   &v,
	}
}

func TestValidateQuoteOK(t *testing.T) {
	if _, msg := validateQuote(goodQuote(), 500, rfqNow); msg != "" {
		t.Fatalf("хатои ғайричашмдошт: %s", msg)
	}
}

func TestValidateQuoteRejects(t *testing.T) {
	cases := []struct {
		name string
		edit func(*quoteInput)
	}{
		{"нархи сифр", func(q *quoteInput) { q.UnitPrice = 0 }},
		{"нархи манфӣ", func(q *quoteInput) { q.UnitPrice = -1 }},
		{"расонидани манфӣ", func(q *quoteInput) { q.ShippingCost = -1 }},
		{"мӯҳлати омодагии манфӣ", func(q *quoteInput) { q.LeadDays = -1 }},
		{"мӯҳлати омодагии 2 сол", func(q *quoteInput) { q.LeadDays = 800 }},
		// Ҳадди ақали фурӯшанда аз шумораи дархост зиёд — пешниҳод барои
		// ин харидор бефоида аст, ва беҳтар аст, ки фурӯшанда фавран
		// бидонад.
		{"ҳадди ақал аз дархост зиёд", func(q *quoteInput) { q.MinQty = 1000 }},
		{"мӯҳлати эътибор дар гузашта", func(q *quoteInput) {
			p := rfqNow.AddDate(0, 0, -1)
			q.ValidUntil = &p
		}},
	}
	for _, c := range cases {
		q := goodQuote()
		c.edit(&q)
		if _, msg := validateQuote(q, 500, rfqNow); msg == "" {
			t.Errorf("%s: қабул шуд, бояд рад шавад", c.name)
		}
	}
}

func TestValidateQuoteFixesMinQty(t *testing.T) {
	q := goodQuote()
	q.MinQty = 0
	out, msg := validateQuote(q, 500, rfqNow)
	if msg != "" {
		t.Fatalf("рад шуд: %s", msg)
	}
	if out.MinQty != 1 {
		t.Errorf("ҳадди ақал = %d, мехостам 1", out.MinQty)
	}
}

// Пешниҳод бе мӯҳлат мумкин аст (фурӯшанда онро нишон надод).
func TestValidateQuoteNoValidUntil(t *testing.T) {
	q := goodQuote()
	q.ValidUntil = nil
	if _, msg := validateQuote(q, 500, rfqNow); msg != "" {
		t.Fatalf("пешниҳоди бе мӯҳлат рад шуд: %s", msg)
	}
}

// ── Қобилияти қабул ──────────────────────────────────────────────────────

func TestQuoteUsable(t *testing.T) {
	future := rfqNow.AddDate(0, 0, 3)
	past := rfqNow.Add(-time.Second)

	if !quoteUsable(quoteActive, &future, rfqNow) {
		t.Error("пешниҳоди фаъол бо мӯҳлати оянда — бояд коршоям бошад")
	}
	// Бе ин фурӯшанда абадӣ ба нархи шашмоҳа пешниҳодкардааш баста
	// мемонад.
	if quoteUsable(quoteActive, &past, rfqNow) {
		t.Error("мӯҳлати пешниҳод гузашт — набояд қабул шавад")
	}
	if !quoteUsable(quoteActive, nil, rfqNow) {
		t.Error("пешниҳоди бе мӯҳлат бояд коршоям бошад")
	}
	for _, s := range []string{quoteRevised, quoteWithdrawn, quoteAccepted,
		quoteRejected, "", "хххх"} {
		if quoteUsable(s, &future, rfqNow) {
			t.Errorf("ҳолати «%s» набояд коршоям бошад", s)
		}
	}
}

// ── Ҷамъ ва муқоиса ──────────────────────────────────────────────────────

func TestQuoteTotal(t *testing.T) {
	// 4.60 сом. × 500 = 2300 сом. + 150 расонидан = 2450 сом.
	if got := quoteTotal(460, 500, 15000); got != 245000 {
		t.Errorf("= %d, мехостам 245000", got)
	}
	// Бе расонидан.
	if got := quoteTotal(460, 500, 0); got != 230000 {
		t.Errorf("= %d, мехостам 230000", got)
	}
	// Маълумоти вайрон → 0, на рақами бофташуда.
	for _, c := range [][3]int64{
		{0, 500, 0}, {-1, 500, 0}, {460, 0, 0}, {460, -5, 0},
		{460, 999_999_999, 0},
	} {
		if got := quoteTotal(c[0], int(c[1]), c[2]); got != 0 {
			t.Errorf("quoteTotal(%v) = %d, мехостам 0", c, got)
		}
	}
	// Расонидани манфӣ ҳамчун сифр.
	if got := quoteTotal(100, 10, -500); got != 1000 {
		t.Errorf("= %d, мехостам 1000", got)
	}
}

// Маҳз ҷамъ муҳим аст, на нархи як дона.
//
// Пешниҳоди «10 сом. донааш + 5000 расонидан» метавонад аз «12 сом.
// донааш + ройгон» ГАРОНТАР афтад. Агар муқоиса аз рӯи нархи як дона
// бошад, харидор пешниҳоди гаронтарро интихоб мекунад.
func TestCheapestQuoteUsesTotal(t *testing.T) {
	qty := 100
	// A: 10 сом. донааш + 50 сом. расонидан = 1050 сом.
	a := quoteTotal(1000, qty, 5000)
	// B: 12 сом. донааш + ройгон = 1200 сом.
	b := quoteTotal(1200, qty, 0)
	// C: 10.20 сом. донааш + 10 сом. расонидан = 1030 сом. ← арзонтарин
	c := quoteTotal(1020, qty, 1000)

	if got := cheapestQuote([]int64{a, b, c}); got != 2 {
		t.Fatalf("арзонтарин = %d, мехостам 2 (C). Ҷамъҳо: %d, %d, %d",
			got, a, b, c)
	}
	// Назорат: аз рӯи нархи як дона A арзонтарин менамуд.
	if 1000 >= 1020 {
		t.Fatal("шарти санҷиш нодуруст")
	}
}

func TestCheapestQuoteEdgeCases(t *testing.T) {
	if got := cheapestQuote(nil); got != -1 {
		t.Errorf("рӯйхати холӣ = %d, мехостам -1", got)
	}
	if got := cheapestQuote([]int64{0, 0, 0}); got != -1 {
		t.Errorf("ҳама сифр = %d, мехостам -1", got)
	}
	// Сатрҳои вайрон нодида мегузаранд.
	if got := cheapestQuote([]int64{0, 500, -100, 300}); got != 3 {
		t.Errorf("= %d, мехостам 3", got)
	}
	// Ҳангоми баробарӣ аввалин.
	if got := cheapestQuote([]int64{500, 500}); got != 0 {
		t.Errorf("= %d, мехостам 0", got)
	}
}
