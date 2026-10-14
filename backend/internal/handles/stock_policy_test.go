package handlers

import "testing"

// ⚠️ Муҳимтарин санҷиши ин файл.
//
// Дар сохтори `checkoutLine` ном маҳз МАНФӢ аст (`Unlimited`, на
// `TrackStock`), ва ин қасдан: арзиши пешфарзи `bool` дар Go `false`
// аст.
//
// Бо `TrackStock` фаромӯш кардани он молро БЕШУМОР мекард — яъне хатои
// беэътиноӣ санҷиши захираро ХОМӮШ мекард, ва фурӯши зиёдатӣ бармегашт.
// Бо `Unlimited` фаромӯшӣ ба рафтори эҳтиёткор меорад.
func TestZeroValueLineChecksStock(t *testing.T) {
	// Сатри «фаромӯшшуда»: ҳеҷ кас `Unlimited`-ро нагузоштааст.
	l := checkoutLine{
		ProductID: "p", SellerID: "s", Qty: 10, UnitPrice: 100,
		Stock: 3, MinQty: 1, Active: true,
	}
	got := validateLines([]checkoutLine{l})
	if len(got) != 1 || got[0].Code != issueNotEnough {
		t.Fatalf("сатри бе `Unlimited` санҷиши захираро гузашт: %v — "+
			"арзиши пешфарз бояд ЭҲТИЁТКОР бошад", got)
	}
}

// Моли бешумор аз рӯи захира рад намешавад.
func TestUnlimitedLineIgnoresStock(t *testing.T) {
	base := checkoutLine{
		ProductID: "p", SellerID: "s", UnitPrice: 100, MinQty: 1,
		Active: true, Unlimited: true,
	}
	for _, c := range []struct {
		name  string
		qty   int
		stock int
	}{
		{"захираи сифр", 5, 0},
		{"аз захира зиёд", 1000, 3},
		{"захираи манфӣ", 1, -5},
	} {
		l := base
		l.Qty, l.Stock = c.qty, c.stock
		if got := validateLines([]checkoutLine{l}); len(got) != 0 {
			t.Errorf("%s: моли бешумор рад шуд: %v", c.name, got)
		}
	}
}

// Вале қоидаҳои ДИГАР ба моли бешумор низ дахл доранд.
//
// «Бешумор» маънои «ҳама чиз иҷозат» -ро надорад.
func TestUnlimitedStillHasOtherRules(t *testing.T) {
	base := checkoutLine{
		ProductID: "p", SellerID: "s", UnitPrice: 100, Qty: 1,
		MinQty: 1, Active: true, Unlimited: true, Stock: 0,
	}
	cases := []struct {
		name string
		edit func(*checkoutLine)
		want string
	}{
		{"хомӯш", func(l *checkoutLine) { l.Active = false }, issueInactive},
		{"шумораи манфӣ", func(l *checkoutLine) { l.Qty = -1 }, issueInvalidQty},
		{"шумораи бениҳоят", func(l *checkoutLine) { l.Qty = 999999 }, issueInvalidQty},
		{"нархи сифр", func(l *checkoutLine) { l.UnitPrice = 0 }, issueInvalidPrice},
		{"аз ҳадди ақал камтар", func(l *checkoutLine) {
			l.MinQty, l.Qty = 10, 2
		}, issueBelowMinQty},
	}
	for _, c := range cases {
		l := base
		c.edit(&l)
		got := validateLines([]checkoutLine{l})
		if len(got) != 1 || got[0].Code != c.want {
			t.Errorf("%s: мехостам %q, гирифтам %v", c.name, c.want, got)
		}
	}
}

// ── Нормализатсия ────────────────────────────────────────────────────────

func TestNormalizeStock(t *testing.T) {
	// Бешумор: рақами рамзӣ, НА сифр.
	//
	// Сифр молро аз бозор пинҳон мекард — ҳамаи дархостҳои мавҷуд
	// `stock > 0`-ро ҳамчун «дастрас» мефаҳманд.
	out := normalizeStock(stockInput{TrackStock: false, Stock: 7})
	if out.TrackStock {
		t.Error("TrackStock бояд false монад")
	}
	if out.Stock <= 0 {
		t.Fatalf("захираи моли бешумор = %d — он бояд аз сифр зиёд бошад, "+
			"вагарна мол аз бозор пинҳон мешавад", out.Stock)
	}

	cases := []struct {
		name string
		in   stockInput
		want int
	}{
		{"оддӣ", stockInput{true, 42}, 42},
		{"сифр", stockInput{true, 0}, 0},
		{"манфӣ", stockInput{true, -5}, 0},
		{"аз ҳад зиёд", stockInput{true, 99_000_000}, maxStock},
	}
	for _, c := range cases {
		if got := normalizeStock(c.in); got.Stock != c.want {
			t.Errorf("%s: %d, мехостам %d", c.name, got.Stock, c.want)
		}
	}
}

// ── Дастрасӣ ва саволи «боз ҳаст?» ───────────────────────────────────────

func TestStockAvailable(t *testing.T) {
	cases := []struct {
		name  string
		track bool
		stock int
		want  int
		ok    bool
	}{
		{"кофӣ", true, 10, 3, true},
		{"маҳз баробар", true, 3, 3, true},
		{"нокифоя", true, 2, 3, false},
		{"холӣ", true, 0, 1, false},
		{"бешумор", false, 0, 1000, true},
		{"шумораи сифр", true, 10, 0, false},
		{"шумораи манфӣ", false, 10, -1, false},
	}
	for _, c := range cases {
		if got := stockAvailable(c.track, c.stock, c.want); got != c.ok {
			t.Errorf("%s: %v, мехостам %v", c.name, got, c.ok)
		}
	}
}

// Саволи «боз ҳаст?» танҳо ба моли пайгиришаванда.
func TestShouldAskSoldOut(t *testing.T) {
	if !shouldAskSoldOut(true, 0) {
		t.Error("моли тамомшуда бояд савол гирад")
	}
	if !shouldAskSoldOut(true, -1) {
		t.Error("захираи манфӣ низ тамом аст")
	}
	if shouldAskSoldOut(true, 5) {
		t.Error("моли мавҷуд набояд савол гирад")
	}
	// Моли бешумор ҳеҷ гоҳ тамом намешавад — савол фурӯшандаро безор
	// мекунад.
	if shouldAskSoldOut(false, 0) {
		t.Error("моли бешумор набояд савол гирад")
	}
}

// ── Матни огоҳӣ ──────────────────────────────────────────────────────────

// Номи дароз огоҳиро нохоно мекунад.
func TestNotificationTitleTrimmed(t *testing.T) {
	long := ""
	for i := 0; i < 200; i++ {
		long += "а"
	}
	for _, body := range []string{soldOutAskBody(long), soldOutHiddenBody(long)} {
		if len([]rune(body)) > 160 {
			t.Errorf("матн %d ҳарф — хеле дароз: %s", len([]rune(body)), body)
		}
		if !contains2(body, "…") {
			t.Error("номи дароз кӯтоҳ карда нашуд")
		}
	}
	// Номи кӯтоҳ бояд пурра монад.
	if !contains2(soldOutAskBody("Орд"), "Орд") {
		t.Error("номи кӯтоҳ гум шуд")
	}
}

// Огоҳии дуюм бояд САБАБ ва роҳи бозгаштро гӯяд.
//
// Бе ин фурӯшанда як рӯз мебинад, ки эълонаш нопадид шуд, ва намефаҳмад
// чаро — ва ин аз худи пинҳон кардан бадтар аст.
func TestHiddenNotificationExplainsWhy(t *testing.T) {
	b := soldOutHiddenBody("Орд")
	for _, want := range []string{"пинҳон", "тамом", "баргардонед"} {
		if !contains2(b, want) {
			t.Errorf("матн «%s»-ро надорад: %s", want, b)
		}
	}
}

// contains2 — `strings.Contains` бе import-и иловагӣ дар ин файл.
func contains2(s, sub string) bool {
	return len(s) >= len(sub) && (func() bool {
		for i := 0; i+len(sub) <= len(s); i++ {
			if s[i:i+len(sub)] == sub {
				return true
			}
		}
		return false
	})()
}
