package handlers

import "testing"

// Маҳз ин қоида камбудии аслиро бас мекунад: агар як фурӯшанда ҳанӯз
// нафиристода бошад, фармоиш «фиристода шуд» НЕСТ.
func TestAggregateOrderStatus(t *testing.T) {
	cases := []struct {
		name string
		in   []string
		want string
	}{
		{"як фурӯшанда", []string{"processing"}, "processing"},
		{"ҳарду фиристоданд", []string{"shipped", "shipped"}, "shipped"},

		// Камбудии аслӣ: пештар ин «shipped» мешуд.
		{"яке фиристод, дигаре не", []string{"shipped", "processing"}, "processing"},
		{"яке супорид, дигаре дар роҳ", []string{"delivered", "shipped"}, "shipped"},
		{"яке ҳанӯз қабул накард", []string{"delivered", "pending"}, "pending"},

		// Фурӯшандаи бекоркарда ҳисоб намешавад — моли ӯ дигар нест, ва
		// фармоиш набояд абадӣ дар «бекор» бимонад.
		{"яке бекор кард, дигаре фиристод", []string{"cancelled", "shipped"}, "shipped"},
		{"ҳама бекор карданд", []string{"cancelled", "cancelled"}, "cancelled"},

		{"ҳама анҷом ёфт", []string{"completed", "completed"}, "completed"},
		{"ҳолати нофаҳмо = pending", []string{"ягон-чизи-нодуруст", "shipped"}, "pending"},
		{"холӣ", []string{}, ""},

		// Ҳарфи калон ва фосила набояд муҳим бошад.
		{"ҳарфи калон", []string{"SHIPPED", " shipped "}, "shipped"},
	}
	for _, c := range cases {
		if got := aggregateOrderStatus(c.in); got != c.want {
			t.Errorf("%s: aggregateOrderStatus(%v) = %q, мехостам %q",
				c.name, c.in, got, c.want)
		}
	}
}

// Қадамҳо бояд аз ҳолати ХУДИ ФУРӮШАНДА санҷида шаванд.
//
// Пештар онҳо аз ҳолати умумии фармоиш санҷида мешуданд: агар
// фурӯшандаи B фармоишро «processing» карда бошад, фурӯшандаи A
// метавонист фавран «shipped» занад — бе он ки худаш фармоишро қабул
// карда бошад.
func TestSellerCanMoveTo(t *testing.T) {
	ok := [][2]string{
		{"pending", "processing"},
		{"pending", "cancelled"},
		{"paid", "processing"},
		{"processing", "shipped"},
		{"processing", "cancelled"},
		{"shipped", "delivered"},
	}
	for _, c := range ok {
		if !sellerCanMoveTo(c[0], c[1]) {
			t.Errorf("«%s» → «%s» бояд мумкин бошад", c[0], c[1])
		}
	}

	bad := [][2]string{
		{"pending", "shipped"},    // бе қабул кардан фиристодан мумкин нест
		{"pending", "delivered"},  // ва якбора супоридан ҳам
		{"processing", "delivered"},
		{"shipped", "cancelled"},  // моли дар роҳ бекор карда намешавад
		{"delivered", "shipped"},  // ақиб рафтан мумкин нест
		{"completed", "shipped"},
		{"cancelled", "processing"},
		{"", "shipped"},
	}
	for _, c := range bad {
		if sellerCanMoveTo(c[0], c[1]) {
			t.Errorf("«%s» → «%s» бояд МУМКИН НАБОШАД", c[0], c[1])
		}
	}
}

// Ҳолати умумӣ бояд ҳамеша яке аз ҳолатҳои воқеӣ бошад — на сатри
// бофташуда, вагарна барнома ва админка онро намешиносанд.
func TestAggregateReturnsKnownStatus(t *testing.T) {
	known := map[string]bool{"cancelled": true, "": true}
	for s := range statusRank {
		known[s] = true
	}
	inputs := [][]string{
		{"pending"}, {"paid", "shipped"}, {"cancelled", "delivered"},
		{"ҳеҷ", "чиз"}, {"completed", "cancelled"},
	}
	for _, in := range inputs {
		got := aggregateOrderStatus(in)
		if !known[got] {
			t.Errorf("aggregateOrderStatus(%v) = %q — ҳолати нашинохта", in, got)
		}
	}
}
