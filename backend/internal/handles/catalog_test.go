package handlers

import "testing"

// Штрих-код аз сканер метавонад фосила, дефис ё аломати дигар дошта бошад.
// Агар онро тоза накунем, ҳамон маҳсулот ду сатри гуногуни каталог месозад
// ва тамоми фоидаи каталоги умумӣ нест мешавад.
func TestNormalizeBarcode(t *testing.T) {
	cases := map[string]string{
		"5449000000996":     "5449000000996",
		" 5449000000996 ":   "5449000000996",
		"5449-0000-00996":   "5449000000996",
		"EAN 5449000000996": "5449000000996",
		"\n5449000000996\t": "5449000000996",
		"":                  "",
		"бе рақам":          "",
	}
	for in, want := range cases {
		if got := normalizeBarcode(in); got != want {
			t.Errorf("normalizeBarcode(%q)=%q, бояд %q", in, got, want)
		}
	}
}

// Воҳид: дар каталог набояд «кг», «Кг», «kg» ва «килограмм» ҳамзамон
// бошанд — вагарна ҷустуҷӯ ва ҳисоби анбор вайрон мешавад.
func TestNormalizeUnit(t *testing.T) {
	cases := map[string]string{
		"":              "дона",
		"  ":            "дона",
		"кг":            "кг",
		"КГ":            "кг",
		"kg":            "кг",
		"килограмм":     "кг",
		"л":             "литр",
		"L":             "литр",
		"литр":          "литр",
		"шт":            "дона",
		"pcs":           "дона",
		"гр":            "грамм",
		"ml":            "мл",
		"баста":         "баста",
		"чизи номаълум": "дона", // ба пешфарз бармегардад
	}
	for in, want := range cases {
		if got := normalizeUnit(in); got != want {
			t.Errorf("normalizeUnit(%q)=%q, бояд %q", in, got, want)
		}
	}
}

// Ҳамаи воҳидҳои баргардонидашуда бояд дар рӯйхати иҷозатдодашуда бошанд.
func TestNormalizeUnitAlwaysAllowed(t *testing.T) {
	for _, in := range []string{"", "кг", "KG", "ҳар чизи дигар", "литр", "qqq"} {
		if got := normalizeUnit(in); !allowedUnits[got] {
			t.Errorf("normalizeUnit(%q)=%q — дар рӯйхати иҷозатдодашуда нест", in, got)
		}
	}
}

func TestNullIfEmpty(t *testing.T) {
	if nullIfEmpty("") != nil {
		t.Error("сатри холӣ бояд NULL шавад")
	}
	if nullIfEmpty("   ") != nil {
		t.Error("сатри аз фосила бояд NULL шавад")
	}
	if nullIfEmpty("abc") == nil {
		t.Error("сатри воқеӣ набояд NULL шавад")
	}
}
