package handlers

// Дафтари амалҳои админ бо Postgres-и воқеӣ.
//
// Ду чизи муҳим санҷида мешавад:
//
//  1. Амали админ ҲАМЕША сабт мешавад — ҳатто агар handler худаш ҳеҷ
//     коре барои сабт накунад. Ин маҳз сабаби он аст, ки middleware
//     интихоб шуд, на даъвати дастӣ: handler-и нав метавонад фаромӯш
//     кунад, middleware не.
//
//  2. Маълумоти ҳассос ба дафтар НАМЕАФТАД. Дафтар абадӣ мемонад, пас
//     паролу токен дар он — ин худаш камбудии амният мешавад.

import (
	"strings"
	"testing"

	"tajikshop/internal/db"
	"tajikshop/internal/middleware"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func auditRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	middleware.SetSecret(testSecret)
	r := gin.New()
	uh := NewUserHandler(testSecret, nil)
	adm := NewAdminHandler()
	api := r.Group("/api/v1")
	api.POST("/auth/login", uh.Login)
	// Ҳамон занҷираи масирҳои воқеӣ.
	api.POST("/admin/users/:id/ban",
		middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), adm.BanUser)
	api.POST("/admin/users/:id/unban",
		middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), adm.UnbanUser)
	api.GET("/admin/audit",
		middleware.Auth(), middleware.AdminOnly(), adm.AuditLog)
	api.GET("/admin/users/:id/audit",
		middleware.Auth(), middleware.AdminOnly(), adm.AuditLogForUser)
	return r
}

// newAdmin — админи тестӣ бо токен.
func newAdmin(t *testing.T, r *gin.Engine) (id, token string) {
	t.Helper()
	id, email := newTestUser(t)
	db.DB.Exec(`UPDATE users SET role='admin' WHERE id=$1`, id)
	token, _ = login(t, r, email)
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM admin_actions WHERE admin_id=$1`, id)
	})
	return id, token
}

func auditRows(t *testing.T, targetID string) []map[string]any {
	t.Helper()
	rows, err := db.DB.Query(`SELECT method, path, COALESCE(payload::text,''),
			COALESCE(status,0)
		FROM admin_actions WHERE target_id=$1::uuid ORDER BY created_at`, targetID)
	if err != nil {
		t.Fatalf("дафтар хонда нашуд: %v", err)
	}
	defer rows.Close()
	out := []map[string]any{}
	for rows.Next() {
		var method, path, payload string
		var status int
		if e := rows.Scan(&method, &path, &payload, &status); e != nil {
			continue
		}
		out = append(out, map[string]any{
			"method": method, "path": path,
			"payload": payload, "status": status,
		})
	}
	return out
}

// Амали админ бояд сабт шавад, ҳарчанд handler худаш ҳеҷ чиз
// наменависад.
func TestAuditRecordsAdminAction(t *testing.T) {
	needDB(t)
	r := auditRouter()
	adminID, tok := newAdmin(t, r)
	victimID, _ := newTestUser(t)
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM admin_actions WHERE target_id=$1`, victimID)
	})

	res := call(t, r, "POST", "/api/v1/admin/users/"+victimID+"/ban",
		map[string]any{"reason": "CI тест"}, bearer(tok))
	if res.Status != 200 {
		t.Fatalf("бастан: %d %s", res.Status, res.Error)
	}

	rows := auditRows(t, victimID)
	if len(rows) != 1 {
		t.Fatalf("%d сатри дафтар, мехостам 1", len(rows))
	}
	if rows[0]["method"] != "POST" {
		t.Errorf("method = %v, мехостам POST", rows[0]["method"])
	}
	if !strings.Contains(rows[0]["path"].(string), "ban") {
		t.Errorf("path = %v, мехостам масири бастан", rows[0]["path"])
	}
	if rows[0]["status"] != 200 {
		t.Errorf("status = %v, мехостам 200", rows[0]["status"])
	}
	// Сабаб бояд сабт шуда бошад — маҳз он арзиши дафтар аст.
	if !strings.Contains(rows[0]["payload"].(string), "CI тест") {
		t.Errorf("payload сабабро надорад: %v", rows[0]["payload"])
	}
	// Ва админ маълум бошад.
	var who string
	db.DB.QueryRow(`SELECT admin_id FROM admin_actions
		WHERE target_id=$1::uuid LIMIT 1`, victimID).Scan(&who)
	if who != adminID {
		t.Errorf("admin_id = %q, мехостам %q", who, adminID)
	}
}

// МУҲИМТАРИН тест: парол ва токен ба дафтар намеафтанд.
//
// Дафтар абадӣ мемонад. Агар паролу токен дар он бошанд, он худаш ба
// камбудии амният табдил меёбад — ҷои нави дуздидани маълумот.
func TestAuditRedactsSecrets(t *testing.T) {
	needDB(t)
	r := auditRouter()
	_, tok := newAdmin(t, r)
	victimID, _ := newTestUser(t)
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM admin_actions WHERE target_id=$1`, victimID)
	})

	const leak = "ПАРОЛИ-НИҲОЯТ-МАХФӢ"
	res := call(t, r, "POST", "/api/v1/admin/users/"+victimID+"/ban",
		map[string]any{
			"reason":      "санҷиш",
			"password":    leak,
			"token":       leak,
			"secret_key":  leak,
			"card_number": leak,
			"new_pin":     leak,
		}, bearer(tok))
	if res.Status != 200 {
		t.Fatalf("бастан: %d %s", res.Status, res.Error)
	}

	rows := auditRows(t, victimID)
	if len(rows) != 1 {
		t.Fatalf("%d сатри дафтар, мехостам 1", len(rows))
	}
	payload := rows[0]["payload"].(string)
	if strings.Contains(payload, leak) {
		t.Fatalf("МАЪЛУМОТИ МАХФӢ ба дафтар афтод: %s", payload)
	}
	// Вале майдони бехатар бояд монад — вагарна дафтар бефоида аст.
	if !strings.Contains(payload, "санҷиш") {
		t.Errorf("майдони бехатар гум шуд: %s", payload)
	}
}

// Амали НОМУВАФФАҚ сабт намешавад — он рӯй надод.
func TestAuditSkipsFailedAction(t *testing.T) {
	needDB(t)
	r := auditRouter()
	_, tok := newAdmin(t, r)

	// Корбари нестбуда → handler хато медиҳад.
	missing := uuid.NewString()
	res := call(t, r, "POST", "/api/v1/admin/users/"+missing+"/ban",
		map[string]any{"reason": "х"}, bearer(tok))
	if res.Status < 400 {
		t.Skipf("handler барои корбари нестбуда %d дод — ин тест маъно надорад",
			res.Status)
	}
	if n := len(auditRows(t, missing)); n != 0 {
		t.Fatalf("%d сатри дафтар барои амали номуваффақ, мехостам 0", n)
	}
}

// Корбари оддӣ дафтарро хонда наметавонад.
func TestAuditOnlyAdminCanRead(t *testing.T) {
	needDB(t)
	r := auditRouter()
	_, email := newTestUser(t)
	tok, _ := login(t, r, email)

	code, _ := callList(t, r, "/api/v1/admin/audit", bearer(tok))
	if code != 403 {
		t.Fatalf("мехостам 403, гирифтам %d", code)
	}
}

// «Ба ин корбар кӣ чӣ кор кард?» — саволи аслии дафтар.
func TestAuditLogForUser(t *testing.T) {
	needDB(t)
	r := auditRouter()
	_, tok := newAdmin(t, r)
	victimID, _ := newTestUser(t)
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM admin_actions WHERE target_id=$1`, victimID)
	})

	call(t, r, "POST", "/api/v1/admin/users/"+victimID+"/ban",
		map[string]any{"reason": "яке"}, bearer(tok))
	call(t, r, "POST", "/api/v1/admin/users/"+victimID+"/unban", nil, bearer(tok))

	code, list := callList(t, r, "/api/v1/admin/users/"+victimID+"/audit",
		bearer(tok))
	if code != 200 {
		t.Fatalf("хондан: %d", code)
	}
	if len(list) != 2 {
		t.Fatalf("%d сатр, мехостам 2 (бастан + кушодан)", len(list))
	}
	// Номи админ бояд бошад — вагарна дафтар танҳо UUID аст ва барои
	// одам хонданашаванда.
	for _, row := range list {
		name, _ := row["admin_name"].(string)
		if name == "" {
			t.Error("номи админ холӣ аст")
		}
	}
}

// Хондани дафтар худаш сабт намешавад — вагарна ҳар кушодани саҳифа
// дафтарро пур мекунад.
func TestAuditReadIsNotLogged(t *testing.T) {
	needDB(t)
	r := auditRouter()
	adminID, tok := newAdmin(t, r)

	var before int
	db.DB.QueryRow(`SELECT COUNT(*) FROM admin_actions WHERE admin_id=$1`,
		adminID).Scan(&before)

	for i := 0; i < 3; i++ {
		callList(t, r, "/api/v1/admin/audit", bearer(tok))
	}

	var after int
	db.DB.QueryRow(`SELECT COUNT(*) FROM admin_actions WHERE admin_id=$1`,
		adminID).Scan(&after)
	if after != before {
		t.Fatalf("хондан %d сатр сохт, мехостам 0", after-before)
	}
}

// Админ бояд БИДОНАД, ки корбар ёфт нашуд.
//
// Пештар ҳамаи ин handler-ҳо натиҷаи `Exec`-ро партофта мегузаштанд ва
// ҳамеша «OK» медоданд. Яъне агар админ дар ID ҳарфе хато кунад, ӯ
// «корбар баста шуд» мебинад — вале ҳеҷ кас баста намешавад, ва ӯ ҳеҷ
// гоҳ намефаҳмад.
func TestAdminActionOnMissingUserIs404(t *testing.T) {
	needDB(t)
	r := auditRouter()
	_, tok := newAdmin(t, r)
	missing := uuid.NewString()

	for _, path := range []string{"ban", "unban"} {
		res := call(t, r, "POST", "/api/v1/admin/users/"+missing+"/"+path,
			map[string]any{"reason": "х"}, bearer(tok))
		if res.Status != 404 {
			t.Errorf("«%s» барои корбари нестбуда %d дод, мехостам 404",
				path, res.Status)
		}
	}
}

// Бастани корбари АЛЛАКАЙ бастаи такрорӣ набояд 404 диҳад.
//
// Дар Postgres `UPDATE ... SET x=true` сатрро ҳатто агар арзиш ҳамон
// бошад ҳам «тағйирдодашуда» мешуморад — пас `RowsAffected` 1 мемонад.
// Ин санҷиш муҳофизат аз он аст, ки рӯзе касе инро «беҳтар» кунад ва
// амали такрорӣ ба хато табдил ёбад.
func TestAdminBanIsIdempotent(t *testing.T) {
	needDB(t)
	r := auditRouter()
	_, tok := newAdmin(t, r)
	victimID, _ := newTestUser(t)
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM admin_actions WHERE target_id=$1`, victimID)
	})

	for i := 0; i < 2; i++ {
		res := call(t, r, "POST", "/api/v1/admin/users/"+victimID+"/ban",
			map[string]any{"reason": "такрор"}, bearer(tok))
		if res.Status != 200 {
			t.Fatalf("бастани %d-ум: %d %s", i+1, res.Status, res.Error)
		}
	}
	var banned bool
	db.DB.QueryRow(`SELECT is_banned FROM users WHERE id=$1`, victimID).Scan(&banned)
	if !banned {
		t.Fatal("корбар баста нашуд")
	}
}
