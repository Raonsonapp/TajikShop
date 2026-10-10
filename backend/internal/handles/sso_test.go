package handlers

import (
	"strings"
	"testing"
)

// Коди SSO як бор кор мекунад ва дар база ҲЭШИ он мемонад. Ин тестҳо маҳз
// ҳамон ҷойҳоеро месанҷанд, ки хатогиашон сессияи каси дигарро медиҳад.

func TestNewSSOCodeIsRandomAndHashed(t *testing.T) {
	seen := map[string]bool{}
	for i := 0; i < 200; i++ {
		code, hash, err := newSSOCode()
		if err != nil {
			t.Fatalf("код сохта нашуд: %v", err)
		}
		if len(code) < 40 {
			t.Fatalf("код хеле кӯтоҳ аст (%d аломат) — тахмин кардан мумкин", len(code))
		}
		if seen[code] {
			t.Fatal("коди такрорӣ сохта шуд — тасодуфӣ нест")
		}
		seen[code] = true

		// Дар база код набояд ҳамчун матни кушод монад.
		if hash == code || strings.Contains(hash, code) {
			t.Fatal("ҳэш худи кодро дар бар мегирад")
		}
		if len(hash) != 64 { // sha256 дар hex
			t.Fatalf("дарозии ҳэш %d, бояд 64 бошад", len(hash))
		}
	}
}

func TestHashSSOCodeIsStable(t *testing.T) {
	const code = "abc123_XYZ"
	if hashSSOCode(code) != hashSSOCode(code) {
		t.Fatal("як код ду ҳэши гуногун дод")
	}
	if hashSSOCode(code) == hashSSOCode(code+"x") {
		t.Fatal("кодҳои гуногун як ҳэш доданд")
	}
	// Фосилаҳои тасодуфии атроф набояд кодро вайрон кунанд: барнома
	// метавонад онро аз URL бо фосила бигирад.
	if hashSSOCode(" "+code+"\n") != hashSSOCode(code) {
		t.Fatal("фосилаҳои атроф ҳэшро тағйир доданд")
	}
}

func TestFindSSOApp(t *testing.T) {
	// Мантиқи тоза — бе база, пас тест дар CI бе PostgreSQL кор мекунад.
	apps := parseSSOApps(defaultSSOApps)
	findSSOApp := func(id string) (ssoApp, bool) { return findSSOAppIn(apps, id) }

	if _, ok := findSSOApp("raonson"); !ok {
		t.Fatal("Raonson дар рӯйхати пешфарз нест")
	}
	if _, ok := findSSOApp("tajikshop"); !ok {
		t.Fatal("TajikShop дар рӯйхати пешфарз нест")
	}
	// Ҳарфҳои калон ва фосила набояд монеъ шаванд.
	if _, ok := findSSOApp("  RaonSon "); !ok {
		t.Fatal("номи барнома бояд ба ҳарфи калон/хурд вобаста набошад")
	}
	// Барномаи бегона набояд қабул шавад — вагарна коди мо ба ҳар ҷо меравад.
	if _, ok := findSSOApp("evil-app"); ok {
		t.Fatal("барномаи номаълум қабул шуд")
	}
	if _, ok := findSSOApp(""); ok {
		t.Fatal("номи холӣ қабул шуд")
	}
}

func TestDefaultSSOAppsAreUsable(t *testing.T) {
	apps := parseSSOApps(defaultSSOApps)
	// Танзими вайрон набояд SSO-ро хомӯш кунад — ба пешфарз бармегардад.
	if len(parseSSOApps("{вайрон}")) < 2 {
		t.Fatal("танзими вайрон SSO-ро хомӯш кард")
	}
	if len(apps) < 2 {
		t.Fatalf("бояд ҳадди ақал ду барнома бошад, ҳаст: %d", len(apps))
	}
	for _, a := range apps {
		if a.ID == "" || a.Name == "" || a.Scheme == "" {
			t.Fatalf("барномаи нопурра: %+v", a)
		}
		// Бе fallback корбаре, ки барномаро насб накардааст, ба девор мехӯрад.
		if a.Fallback == "" {
			t.Fatalf("барномаи «%s» fallback надорад", a.ID)
		}
	}
}
