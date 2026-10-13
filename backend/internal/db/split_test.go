package db

import (
	"strings"
	"testing"
)

// Ин тест барои як камбудии ВОҚЕӢ навишта шуд, ки дар CI афтод.
//
// Нусхаи кӯҳнаи `execEach` схемаро оддӣ `strings.Split(schema, ";")`
// мекард. Шарҳи зер онро шикаст:
//
//	-- АНДОЗАГИРӢ: ILIKE = 116 мс Seq Scan; префикси ор% бо ин
//	-- индекс = 0.13 мс
//	CREATE INDEX IF NOT EXISTS idx_products_title_prefix ...
//
// Нуқтавергул дар ШАРҲ амрро ба ду пора бурид, ва пораи дуюм бо
// «префикси ор% бо ин» сар мешуд. Postgres хато медод, `execEach` онро
// ба лог менавишт ва МЕГУЗАШТ — ва `CREATE INDEX` ҳеҷ гоҳ иҷро
// намешуд. Ҷустуҷӯ дар production хомӯшона суст мемонд.
func TestSplitStatementsIgnoresSemicolonInComment(t *testing.T) {
	schema := `
-- АНДОЗАГИРӢ: ILIKE = 116 мс Seq Scan; префикси ор% бо ин
-- индекс = 0.13 мс, ва ҳолати бенатиҷа = 0.09 мс.
CREATE INDEX IF NOT EXISTS idx_a ON products (lower(title));
-- шарҳи дигар; боз нуқтавергул; ва боз яке
CREATE INDEX IF NOT EXISTS idx_b ON products (price);
`
	got := splitStatements(schema)
	if len(got) != 2 {
		t.Fatalf("%d амр, мехостам 2:\n%s", len(got), strings.Join(got, "\n---\n"))
	}
	for i, want := range []string{"idx_a", "idx_b"} {
		if !strings.Contains(got[i], want) {
			t.Errorf("амри %d «%s»-ро надорад: %s", i, want, got[i])
		}
		if !strings.HasPrefix(got[i], "CREATE INDEX") {
			t.Errorf("амри %d бо «CREATE INDEX» сар намешавад: %q", i, got[i])
		}
	}
}

// `--` дар дохили сатри матнӣ шарҳ НЕСТ.
//
// Бе ин ҳолат амри `DEFAULT '--'` нимкора бурида мешуд.
func TestSplitStatementsKeepsDashesInsideString(t *testing.T) {
	schema := `ALTER TABLE t ADD COLUMN c TEXT DEFAULT '-- ин шарҳ нест';`
	got := splitStatements(schema)
	if len(got) != 1 {
		t.Fatalf("%d амр, мехостам 1: %v", len(got), got)
	}
	if !strings.Contains(got[0], "'-- ин шарҳ нест'") {
		t.Fatalf("сатри матнӣ бурида шуд: %s", got[0])
	}
}

func TestSplitStatementsBasics(t *testing.T) {
	cases := []struct {
		name   string
		schema string
		want   int
	}{
		{"холӣ", "", 0},
		{"танҳо шарҳ", "-- ҳеҷ чиз\n-- боз ҳеҷ чиз", 0},
		{"танҳо нуқтавергулҳо", ";;;\n;", 0},
		{"як амр бе нуқтавергул", "SELECT 1", 1},
		{"як амр бо нуқтавергул", "SELECT 1;", 1},
		{"се амр", "SELECT 1; SELECT 2; SELECT 3;", 3},
		{"сатрҳои холӣ дар байн", "SELECT 1;\n\n\n;\nSELECT 2;", 2},
		{"шарҳ дар охири амр", "SELECT 1; -- ин шарҳ\nSELECT 2;", 2},
	}
	for _, c := range cases {
		if got := splitStatements(c.schema); len(got) != c.want {
			t.Errorf("%s: %d амр, мехостам %d: %v",
				c.name, len(got), c.want, got)
		}
	}
}

// Амри бисёрсатрӣ набояд шикаста шавад.
func TestSplitStatementsKeepsMultilineStatement(t *testing.T) {
	schema := `
CREATE TABLE IF NOT EXISTS t (
	id UUID PRIMARY KEY,
	-- шарҳи дохилӣ; бо нуқтавергул
	name TEXT DEFAULT ''
);
`
	got := splitStatements(schema)
	if len(got) != 1 {
		t.Fatalf("%d амр, мехостам 1:\n%s", len(got), strings.Join(got, "\n---\n"))
	}
	for _, want := range []string{"CREATE TABLE", "id UUID", "name TEXT"} {
		if !strings.Contains(got[0], want) {
			t.Errorf("амр «%s»-ро надорад: %s", want, got[0])
		}
	}
	if strings.Contains(got[0], "шарҳи дохилӣ") {
		t.Error("шарҳ дар амр монд — он бояд бароварда шавад")
	}
}

// Схемаи ВОҚЕИИ барнома бояд бе амри вайрон ҷудо шавад.
//
// Ин муҳофизат аз он аст, ки касе (аз ҷумла ман) боз шарҳи бо
// нуқтавергул нависад: ҳар амр бояд бо калимаи калидии SQL сар шавад.
func TestSplitRealSchemaHasNoBrokenStatements(t *testing.T) {
	stmts := splitStatements(schemaSQL)
	if len(stmts) < 50 {
		t.Fatalf("%d амр — схема хеле кӯтоҳ аст, эҳтимол `go:embed` кор накард",
			len(stmts))
	}
	// Калимаҳои калидие, ки амри схема бо онҳо сар мешавад.
	starts := []string{
		"CREATE", "ALTER", "INSERT", "UPDATE", "DROP", "DELETE", "DO",
		"COMMENT", "GRANT", "SET", "SELECT", "WITH", "TRUNCATE",
	}
	for i, s := range stmts {
		upper := strings.ToUpper(s)
		ok := false
		for _, k := range starts {
			if strings.HasPrefix(upper, k) {
				ok = true
				break
			}
		}
		if !ok {
			// Аввалин 80 ҳарф — то маълум шавад, кадом шарҳ вайрон кард.
			head := s
			if len(head) > 80 {
				head = head[:80]
			}
			t.Errorf("амри %d бо калимаи калидии SQL сар намешавад — "+
				"эҳтимол шарҳи бо нуқтавергул онро бурид:\n%s", i, head)
		}
	}
}
