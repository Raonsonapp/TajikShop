package handlers

import "testing"

// Зинаҳои намунавии яклухт:
//   1–9 дона   → 100 сом. (нархи чакана)
//   10–49 дона →  90 сом.
//   50+ дона   →  80 сом.
func sampleTiers() []priceTier {
	return []priceTier{
		{MinQty: 10, Price: 9000},
		{MinQty: 50, Price: 8000},
	}
}

func TestPriceForQty(t *testing.T) {
	const base int64 = 10000 // 100 сом.
	tiers := sampleTiers()

	cases := []struct {
		qty  int
		want int64
		why  string
	}{
		{1, 10000, "як дона — нархи чакана"},
		{9, 10000, "9 дона — ҳанӯз чакана"},
		{10, 9000, "маҳз 10 — зинаи яклухт сар мешавад"},
		{11, 9000, "11 дона"},
		{49, 9000, "49 — ҳанӯз зинаи дуюм"},
		{50, 8000, "маҳз 50 — зинаи сеюм"},
		{1000, 8000, "хеле зиёд — зинаи охирин"},
		{0, 10000, "сифр — нархи чакана"},
	}
	for _, c := range cases {
		if got := priceForQty(tiers, base, c.qty); got != c.want {
			t.Errorf("%s: priceForQty(%d) = %d, мехостам %d", c.why, c.qty, got, c.want)
		}
	}
}

// Бе зина — ҳамеша нархи асосӣ. Бе ин маҳсулоти оддӣ метавонист нархи
// бегона гирад.
func TestPriceForQtyNoTiers(t *testing.T) {
	if got := priceForQty(nil, 5000, 100); got != 5000 {
		t.Errorf("бе зина = %d, мехостам 5000", got)
	}
	if got := priceForQty([]priceTier{}, 5000, 1); got != 5000 {
		t.Errorf("зинаи холӣ = %d, мехостам 5000", got)
	}
}

// Зинаи вайрон (шумораи сифр ё нархи манфӣ) набояд истифода шавад —
// вагарна як сатри нодуруст дар база маҳсулотро ройгон мекунад.
func TestPriceForQtyIgnoresBrokenTiers(t *testing.T) {
	tiers := []priceTier{
		{MinQty: 0, Price: 1},      // шумораи сифр — нодида
		{MinQty: -5, Price: 1},     // манфӣ — нодида
		{MinQty: 10, Price: 0},     // нархи сифр — нодида
		{MinQty: 10, Price: -9000}, // манфӣ — нодида
		{MinQty: 20, Price: 9000},  // ин дуруст
	}
	if got := priceForQty(tiers, 10000, 5); got != 10000 {
		t.Errorf("5 дона = %d, мехостам 10000 (зинаҳои вайрон нодида)", got)
	}
	if got := priceForQty(tiers, 10000, 25); got != 9000 {
		t.Errorf("25 дона = %d, мехостам 9000", got)
	}
}

// Тартиби зинаҳо дар база метавонад ҳар хел бошад — натиҷа набояд
// тағйир ёбад.
func TestPriceForQtyOrderIndependent(t *testing.T) {
	a := []priceTier{{MinQty: 10, Price: 9000}, {MinQty: 50, Price: 8000}}
	b := []priceTier{{MinQty: 50, Price: 8000}, {MinQty: 10, Price: 9000}}
	for _, qty := range []int{1, 10, 30, 50, 100} {
		if priceForQty(a, 10000, qty) != priceForQty(b, 10000, qty) {
			t.Errorf("шумораи %d: тартиб натиҷаро иваз мекунад", qty)
		}
	}
}

// ── Санҷиши зинаҳои фурӯшанда ────────────────────────────────────────────

func TestValidateTiersOK(t *testing.T) {
	clean, msg := validateTiers([]priceTier{
		{MinQty: 50, Price: 8000},
		{MinQty: 10, Price: 9000},
	}, 10000)
	if msg != "" {
		t.Fatalf("хатои ғайричашмдошт: %s", msg)
	}
	// Бояд тартиб дода шаванд.
	if len(clean) != 2 || clean[0].MinQty != 10 || clean[1].MinQty != 50 {
		t.Fatalf("тартиб нодуруст: %+v", clean)
	}
}

// Ин қоида аз мантиқи савдо меояд: харидори ЯКЛУХТ набояд БЕШТАР
// пардозад. Зинаи «50+ = 120 сом.» дар ҳоле ки «10+ = 90 сом.» қариб
// ҳамеша хатои хаттии фурӯшанда аст — ва бе санҷиш он ба харидор
// мерасад.
func TestValidateTiersRejectsIncreasingPrice(t *testing.T) {
	_, msg := validateTiers([]priceTier{
		{MinQty: 10, Price: 9000},
		{MinQty: 50, Price: 9500}, // гаронтар аз зинаи хурдтар
	}, 10000)
	if msg == "" {
		t.Fatal("зинаи гаронтар қабул шуд — бояд рад шавад")
	}
}

func TestValidateTiersRejectsBadInput(t *testing.T) {
	cases := []struct {
		name  string
		tiers []priceTier
		base  int64
	}{
		{"шумораи 1", []priceTier{{MinQty: 1, Price: 9000}}, 10000},
		{"шумораи сифр", []priceTier{{MinQty: 0, Price: 9000}}, 10000},
		{"шумораи манфӣ", []priceTier{{MinQty: -10, Price: 9000}}, 10000},
		{"нархи сифр", []priceTier{{MinQty: 10, Price: 0}}, 10000},
		{"нархи манфӣ", []priceTier{{MinQty: 10, Price: -1}}, 10000},
		{"аз чакана гарон", []priceTier{{MinQty: 10, Price: 11000}}, 10000},
		{"ба чакана баробар", []priceTier{{MinQty: 10, Price: 10000}}, 10000},
		{"ду зинаи якхела", []priceTier{
			{MinQty: 10, Price: 9000}, {MinQty: 10, Price: 8000},
		}, 10000},
	}
	for _, c := range cases {
		if _, msg := validateTiers(c.tiers, c.base); msg == "" {
			t.Errorf("%s: қабул шуд, бояд рад шавад", c.name)
		}
	}
}

// Зиёда аз 10 зина — ин аллакай хато ё кӯшиши пур кардани база аст.
func TestValidateTiersLimit(t *testing.T) {
	var many []priceTier
	for i := 0; i < 11; i++ {
		many = append(many, priceTier{MinQty: (i + 1) * 10, Price: int64(9000 - i)})
	}
	if _, msg := validateTiers(many, 10000); msg == "" {
		t.Fatal("11 зина қабул шуд — бояд рад шавад")
	}
}

func TestValidateTiersEmptyIsFine(t *testing.T) {
	// Фурӯшанда метавонад зинаҳоро тамоман бардорад.
	clean, msg := validateTiers(nil, 10000)
	if msg != "" {
		t.Fatalf("рӯйхати холӣ рад шуд: %s", msg)
	}
	if len(clean) != 0 {
		t.Fatalf("мехостам 0 зина, гирифтам %d", len(clean))
	}
}

// Зинаҳо бо ҳисоби ҷамъ якҷоя кор кунанд.
func TestTiersWithTotals(t *testing.T) {
	base := int64(10000)
	tiers := sampleTiers()

	// 20 дона × 90 сом. = 1800 сом., + 20 расонидан = 1820 сом.
	unit := priceForQty(tiers, base, 20)
	lines := []checkoutLine{{
		ProductID: "p", SellerID: "s", Qty: 20, UnitPrice: unit,
		Stock: 100, MinQty: 1, Active: true,
	}}
	tot := computeTotals(lines, deliveryFeeDirams, 0)
	if tot.Items != 180000 {
		t.Fatalf("ҷамъи мол = %d, мехостам 180000 (20 × 90 сом.)", tot.Items)
	}
	if tot.Final != 182000 {
		t.Fatalf("ҷамъи ниҳоӣ = %d, мехостам 182000", tot.Final)
	}
}
