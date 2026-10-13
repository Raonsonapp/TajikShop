package handlers

import "testing"

// Табдили сомонӣ → дирам. Ҳолати муҳим 19.99 аст: дар `float64` он каме
// камтар аз 19.99 аст, ва бе мудаввар кардан як дирам гум мешавад.
func TestToDirams(t *testing.T) {
	cases := []struct {
		in   float64
		want int64
	}{
		{0, 0},
		{1, 100},
		{19.99, 1999},
		{0.01, 1},
		{0.1, 10},
		{1234.56, 123456},
		{99.999, 10000}, // мудаввар мешавад
		{-5.5, -550},
	}
	for _, c := range cases {
		if got := toDirams(c.in); got != c.want {
			t.Errorf("toDirams(%v) = %d, мехостам %d", c.in, got, c.want)
		}
	}
}

// Сабаби аслии ин файл: бо `float64` ҷамъи 0.1+0.2 ба 0.30000000000000004
// баробар мешавад. Бо дирам ин ҳеҷ гоҳ рӯй намедиҳад.
func TestNoFloatDrift(t *testing.T) {
	// 3 маҳсулоти 0.1 сомонӣ
	lines := []checkoutLine{
		{ProductID: "a", SellerID: "s", Qty: 1, UnitPrice: toDirams(0.1), Stock: 5, MinQty: 1, Active: true},
		{ProductID: "b", SellerID: "s", Qty: 1, UnitPrice: toDirams(0.1), Stock: 5, MinQty: 1, Active: true},
		{ProductID: "c", SellerID: "s", Qty: 1, UnitPrice: toDirams(0.1), Stock: 5, MinQty: 1, Active: true},
	}
	tot := computeTotals(lines, 0, 0)
	if tot.Items != 30 {
		t.Fatalf("ҷамъ = %d дирам, мехостам 30", tot.Items)
	}
	if toSomoni(tot.Items) != 0.3 {
		t.Fatalf("ба сомонӣ = %v, мехостам 0.3", toSomoni(tot.Items))
	}
}

func TestComputeTotals(t *testing.T) {
	lines := []checkoutLine{
		{ProductID: "a", SellerID: "s1", Qty: 2, UnitPrice: 10000, Stock: 9, MinQty: 1, Active: true}, // 200 сом.
		{ProductID: "b", SellerID: "s2", Qty: 3, UnitPrice: 5050, Stock: 9, MinQty: 1, Active: true},  // 151.50 сом.
	}
	// 200 + 151.50 = 351.50; + 20 расонидан = 371.50
	tot := computeTotals(lines, deliveryFeeDirams, 0)
	if tot.Items != 35150 {
		t.Fatalf("Items = %d, мехостам 35150", tot.Items)
	}
	if tot.Final != 37150 {
		t.Fatalf("Final = %d, мехостам 37150", tot.Final)
	}

	// Бо тахфифи 10%: 37150 * 10% = 3715
	tot = computeTotals(lines, deliveryFeeDirams, 10)
	if tot.Discount != 3715 || tot.Final != 33435 {
		t.Fatalf("бо 10%%: discount=%d final=%d, мехостам 3715/33435", tot.Discount, tot.Final)
	}
}

// Тахфиф набояд аз ҷамъ зиёд шавад ва ҷамъи охирин набояд манфӣ гардад —
// вагарна платформа ба харидор пул қарздор мешавад.
func TestDiscountNeverNegative(t *testing.T) {
	lines := []checkoutLine{{ProductID: "a", SellerID: "s", Qty: 1, UnitPrice: 1000, Stock: 5, MinQty: 1, Active: true}}
	for _, pct := range []int{100, 150, 1000, -50} {
		tot := computeTotals(lines, 0, pct)
		if tot.Final < 0 {
			t.Fatalf("pct=%d → final=%d (манфӣ)", pct, tot.Final)
		}
		if tot.Discount > tot.Items+tot.Delivery {
			t.Fatalf("pct=%d → тахфиф аз ҷамъ зиёд: %d > %d", pct, tot.Discount, tot.Items)
		}
	}
}

// Мудаввар кардани «ними боло»: бе `+50` ҳар тахфиф ба фоидаи платформа
// мудаввар мешуд.
func TestDiscountRounding(t *testing.T) {
	lines := []checkoutLine{{ProductID: "a", SellerID: "s", Qty: 1, UnitPrice: 1005, Stock: 5, MinQty: 1, Active: true}}
	// 1005 * 5% = 50.25 дирам → 50
	if got := computeTotals(lines, 0, 5).Discount; got != 50 {
		t.Errorf("тахфифи 5%% аз 1005 = %d, мехостам 50", got)
	}
	// 1010 * 5% = 50.5 дирам → 51 (ними боло)
	lines[0].UnitPrice = 1010
	if got := computeTotals(lines, 0, 5).Discount; got != 51 {
		t.Errorf("тахфифи 5%% аз 1010 = %d, мехостам 51", got)
	}
}

// Маҳз ҳамин санҷиш фурӯши зиёдатиро бас мекунад.
func TestValidateLinesStock(t *testing.T) {
	cases := []struct {
		name string
		line checkoutLine
		want string
	}{
		{"дуруст", checkoutLine{Qty: 2, UnitPrice: 100, Stock: 5, MinQty: 1, Active: true}, ""},
		{"аз анбор зиёд", checkoutLine{Qty: 100, UnitPrice: 100, Stock: 3, MinQty: 1, Active: true}, issueNotEnough},
		{"анбор холӣ", checkoutLine{Qty: 1, UnitPrice: 100, Stock: 0, MinQty: 1, Active: true}, issueOutOfStock},
		{"хомӯш", checkoutLine{Qty: 1, UnitPrice: 100, Stock: 5, MinQty: 1, Active: false}, issueInactive},
		{"шумораи манфӣ", checkoutLine{Qty: -1, UnitPrice: 100, Stock: 5, MinQty: 1, Active: true}, issueInvalidQty},
		{"шумораи бениҳоят", checkoutLine{Qty: 999999, UnitPrice: 100, Stock: 5, MinQty: 1, Active: true}, issueInvalidQty},
		{"нархи сифр", checkoutLine{Qty: 1, UnitPrice: 0, Stock: 5, MinQty: 1, Active: true}, issueInvalidPrice},
		{"аз ҳадди ақал камтар", checkoutLine{Qty: 2, UnitPrice: 100, Stock: 50, MinQty: 10, Active: true}, issueBelowMinQty},
		{"баробари ҳадди ақал", checkoutLine{Qty: 10, UnitPrice: 100, Stock: 50, MinQty: 10, Active: true}, ""},
		{"ҳамаи анбор", checkoutLine{Qty: 5, UnitPrice: 100, Stock: 5, MinQty: 1, Active: true}, ""},
	}
	for _, c := range cases {
		c.line.ProductID = "p"
		got := validateLines([]checkoutLine{c.line})
		if c.want == "" {
			if len(got) != 0 {
				t.Errorf("%s: мехостам тоза, гирифтам %q", c.name, got[0].Code)
			}
			continue
		}
		if len(got) != 1 || got[0].Code != c.want {
			t.Errorf("%s: мехостам %q, гирифтам %v", c.name, c.want, got)
		}
	}
}

// Сатри хато ҳисоби ҷамъро вайрон накунад — вагарна як сатри вайрон
// метавонад ҷамъи тамоми фармоишро ба `int64` берун барад.
func TestComputeTotalsIgnoresBadLines(t *testing.T) {
	lines := []checkoutLine{
		{ProductID: "ok", SellerID: "s", Qty: 1, UnitPrice: 1000, Stock: 5, MinQty: 1, Active: true},
		{ProductID: "bad", SellerID: "s", Qty: 999999999, UnitPrice: 1000, Stock: 5, MinQty: 1, Active: true},
	}
	if got := computeTotals(lines, 0, 0).Items; got != 1000 {
		t.Fatalf("Items = %d, мехостам 1000 (сатри вайрон бояд ҳисоб нашавад)", got)
	}
}

func TestSellerSubtotals(t *testing.T) {
	lines := []checkoutLine{
		{ProductID: "a", SellerID: "s1", Qty: 2, UnitPrice: 1000, Active: true},
		{ProductID: "b", SellerID: "s1", Qty: 1, UnitPrice: 500, Active: true},
		{ProductID: "c", SellerID: "s2", Qty: 3, UnitPrice: 200, Active: true},
	}
	got := sellerSubtotals(lines)
	if got["s1"] != 2500 {
		t.Errorf("s1 = %d, мехостам 2500", got["s1"])
	}
	if got["s2"] != 600 {
		t.Errorf("s2 = %d, мехостам 600", got["s2"])
	}
	if len(got) != 2 {
		t.Errorf("шумораи фурӯшандагон = %d, мехостам 2", len(got))
	}
}

func TestDeliveryFeeFor(t *testing.T) {
	if deliveryFeeFor("pickup") != 0 {
		t.Error("«аз мағоза гирифтан» бояд ройгон бошад")
	}
	if deliveryFeeFor("delivery") != 2000 {
		t.Error("расонидан бояд 20 сомонӣ бошад")
	}
	// Ҳар чизи нофаҳмо = расонидан, на ройгон.
	if deliveryFeeFor("") != 2000 || deliveryFeeFor("хххх") != 2000 {
		t.Error("тарзи нофаҳмо набояд расониданро ройгон кунад")
	}
	if deliveryFeeFor("PICKUP") != 0 {
		t.Error("тарзи гирифтан бояд бе назар ба ҳарфи калон кор кунад")
	}
}

func TestNormalizePaymentMethod(t *testing.T) {
	for in, want := range map[string]string{
		"cod": "cod", "wallet": "wallet", "dc": "dc",
		"": "dc", "хххх": "dc", "WALLET": "wallet", " cod ": "cod",
	} {
		if got := normalizePaymentMethod(in); got != want {
			t.Errorf("normalizePaymentMethod(%q) = %q, мехостам %q", in, got, want)
		}
	}
}
