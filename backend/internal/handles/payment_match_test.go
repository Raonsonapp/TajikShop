package handlers

import "testing"

// Парсери SMS мантиқи пул аст — пас онро воқеан месанҷем.
func TestParseBankSMS(t *testing.T) {
	cases := []struct {
		name    string
		text    string
		wantAmt float64
		wantTail string
		wantOK  bool
	}{
		{
			name:    "лотинӣ бо корт",
			text:    "Popolnenie 250.00 TJS. Karta *7344. Ostatok 1200.00 TJS",
			wantAmt: 250, wantTail: "7344", wantOK: true,
		},
		{
			name:    "русӣ бо вергул",
			text:    "Пополнение 1 250,50 TJS на карту **** 7344",
			wantAmt: 1250.50, wantTail: "7344", wantOK: true,
		},
		{
			name:    "тоҷикӣ",
			text:    "Ба ҳисоби шумо 80 сомонӣ ворид шуд",
			wantAmt: 80, wantTail: "", wantOK: true,
		},
		{
			name:    "смн бе корт",
			text:    "Зачисление 99.90 смн",
			wantAmt: 99.90, wantTail: "", wantOK: true,
		},
		{
			// SMS-и ХАРОҶОТ набояд ҳамчун воридот қабул шавад — вагарна
			// фармоиш бе гирифтани пул тасдиқ мешуд.
			name: "хароҷот рад мешавад",
			text: "Spisanie 250.00 TJS. Karta *7344",
			wantOK: false,
		},
		{
			name:   "матни бемаъно",
			text:   "Салом, чӣ хел?",
			wantOK: false,
		},
		{
			name:   "воридот вале бе маблағ",
			text:   "Пополнение прошло успешно",
			wantOK: false,
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			amt, tail, ok := parseBankSMS(tc.text)
			if ok != tc.wantOK {
				t.Fatalf("ok = %v, мехостем %v", ok, tc.wantOK)
			}
			if !tc.wantOK {
				return
			}
			if amt != tc.wantAmt {
				t.Errorf("маблағ = %v, мехостем %v", amt, tc.wantAmt)
			}
			if tail != tc.wantTail {
				t.Errorf("корт = %q, мехостем %q", tail, tc.wantTail)
			}
		})
	}
}

func TestOnlyDigits(t *testing.T) {
	if got := onlyDigits("9762 0001 9975 7344"); got != "9762000199757344" {
		t.Errorf("onlyDigits = %q", got)
	}
}
