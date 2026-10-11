package handlers

// Тестҳои сессия бо Postgres-и воқеӣ.
//
// Онҳо ТАНҲО вақте иҷро мешаванд, ки TAJIKSHOP_TEST_DB_URL гузошта шавад —
// базаи алоҳидаи тестӣ (ҳеҷ гоҳ базаи production!), масалан:
//
//	createdb tajikshop_test
//	TAJIKSHOP_TEST_DB_URL='postgres://postgres:postgres@127.0.0.1:5433/tajikshop_test?sslmode=disable' \
//	  go test ./internal/handles/ -run Session -v
//
// Бе он тестҳо skip мешаванд, пас `go test ./...` дар CI бе база ҳам сабз аст.

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"sync"
	"testing"

	"tajikshop/internal/auth"
	"tajikshop/internal/db"
	"tajikshop/internal/middleware"
	"tajikshop/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

const testSecret = "test-secret-sessions"
const testPartnerKey = "test-partner-key"

var dbOnce sync.Once

func needDB(t *testing.T) {
	t.Helper()
	dsn := os.Getenv("TAJIKSHOP_TEST_DB_URL")
	if dsn == "" {
		t.Skip("TAJIKSHOP_TEST_DB_URL гузошта нашудааст — тести база skip")
	}
	dbOnce.Do(func() {
		db.Connect(dsn)
		db.Migrate()
	})
}

func testRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	middleware.SetSecret(testSecret)
	r := gin.New()
	uh := NewUserHandler(testSecret, nil)
	sso := NewSSOHandler(testSecret, testPartnerKey)
	api := r.Group("/api/v1")
	api.POST("/auth/login", uh.Login)
	api.POST("/auth/refresh", uh.RefreshToken)
	api.POST("/auth/logout", uh.Logout)
	api.PUT("/users/me/password", middleware.Auth(), uh.ChangePassword)
	api.POST("/sso/code", middleware.Auth(), sso.IssueCode)
	api.POST("/sso/exchange", sso.Exchange)
	return r
}

type apiResp struct {
	Status int
	Data   map[string]any
	Error  string
}

func call(t *testing.T, r *gin.Engine, method, path string, body any, headers map[string]string) apiResp {
	t.Helper()
	buf, _ := json.Marshal(body)
	req := httptest.NewRequest(method, path, bytes.NewReader(buf))
	req.Header.Set("Content-Type", "application/json")
	for k, v := range headers {
		req.Header.Set(k, v)
	}
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	var env struct {
		Data  map[string]any `json:"data"`
		Error string         `json:"error"`
	}
	json.Unmarshal(w.Body.Bytes(), &env)
	return apiResp{Status: w.Code, Data: env.Data, Error: env.Error}
}

func str(m map[string]any, k string) string {
	s, _ := m[k].(string)
	return s
}

// newTestUser — корбари тоза бо пароли «secret123».
func newTestUser(t *testing.T) (id, email string) {
	t.Helper()
	id = uuid.NewString()
	email = "u_" + id[:8] + "@test.local"
	hash, _ := utils.HashPassword("secret123")
	if _, err := db.DB.Exec(`INSERT INTO users(id,name,email,password_hash) VALUES($1,$2,$3,$4)`,
		id, "Тест "+id[:4], email, hash); err != nil {
		t.Fatalf("корбар сохта нашуд: %v", err)
	}
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM auth_sessions WHERE user_id=$1`, id)
		db.DB.Exec(`DELETE FROM sso_codes WHERE user_id=$1`, id)
		db.DB.Exec(`DELETE FROM users WHERE id=$1`, id)
	})
	return id, email
}

func login(t *testing.T, r *gin.Engine, email string) (access, refresh string) {
	t.Helper()
	res := call(t, r, "POST", "/api/v1/auth/login",
		map[string]string{"email": email, "password": "secret123"}, nil)
	if res.Status != 200 {
		t.Fatalf("login: %d %s", res.Status, res.Error)
	}
	return str(res.Data, "access_token"), str(res.Data, "refresh_token")
}

func refresh(t *testing.T, r *gin.Engine, tok string) apiResp {
	t.Helper()
	return call(t, r, "POST", "/api/v1/auth/refresh", map[string]string{"refresh_token": tok}, nil)
}

// raonsonExchange — ҷараёни пурраи SSO: код аз TajikShop → exchange-и Raonson.
func raonsonExchange(t *testing.T, r *gin.Engine, access string) apiResp {
	t.Helper()
	code := call(t, r, "POST", "/api/v1/sso/code", map[string]string{"target_app": "raonson"},
		map[string]string{"Authorization": "Bearer " + access})
	if code.Status != 201 {
		t.Fatalf("sso/code: %d %s", code.Status, code.Error)
	}
	ex := call(t, r, "POST", "/api/v1/sso/exchange",
		map[string]string{"code": str(code.Data, "code"), "app": "raonson"},
		map[string]string{"X-Partner-Key": testPartnerKey})
	if ex.Status != 200 {
		t.Fatalf("sso/exchange: %d %s", ex.Status, ex.Error)
	}
	return ex
}

func TestSessionRefreshRotatesPerClient(t *testing.T) {
	needDB(t)
	r := testRouter()
	uid, email := newTestUser(t)

	_, appRT := login(t, r, email)

	// Ротатсия: токени нав, фарқ аз кӯҳна.
	res := refresh(t, r, appRT)
	if res.Status != 200 {
		t.Fatalf("refresh: %d %s", res.Status, res.Error)
	}
	appRT2 := str(res.Data, "refresh_token")
	if appRT2 == "" || appRT2 == appRT {
		t.Fatal("refresh токени нав надод (ротатсия нест)")
	}
	if str(res.Data, "access_token") == "" {
		t.Fatal("access_token нест")
	}
	// Токени нав кор мекунад ва боз иваз мешавад.
	res = refresh(t, r, appRT2)
	if res.Status != 200 {
		t.Fatalf("refresh бо токени нав: %d", res.Status)
	}
	appRT3 := str(res.Data, "refresh_token")
	// Пас аз он ки мизоҷ токени навро истифода бурд, токени аввала мемирад.
	if res := refresh(t, r, appRT); res.Status != 401 {
		t.Fatalf("токени аввала пас аз ротатсия набояд кор кунад, гирифт %d", res.Status)
	}
	if res := refresh(t, r, appRT3); res.Status != 200 {
		t.Fatalf("токени охирин бояд кор кунад: %d", res.Status)
	}

	// Ҳамаи инҳо ЯК сессия аст.
	var n int
	db.DB.QueryRow(`SELECT COUNT(*) FROM auth_sessions WHERE user_id=$1`, uid).Scan(&n)
	if n != 1 {
		t.Fatalf("бояд 1 сессия бошад, ҳаст %d", n)
	}
}

// Барномаи кӯҳна токени навро нигоҳ намедорад ва ҳамеша бо ҳамон токен
// меояд — бояд кор карданро идома диҳад.
func TestSessionOldClientWithoutRotationKeepsWorking(t *testing.T) {
	needDB(t)
	r := testRouter()
	_, email := newTestUser(t)
	_, rt := login(t, r, email)
	for i := 0; i < 3; i++ {
		if res := refresh(t, r, rt); res.Status != 200 {
			t.Fatalf("такрори %d: мизоҷи кӯҳна берун шуд (%d)", i, res.Status)
		}
	}
}

func TestSessionExchangeDoesNotKillAppSession(t *testing.T) {
	needDB(t)
	r := testRouter()
	uid, email := newTestUser(t)

	access, appRT := login(t, r, email)
	ex := raonsonExchange(t, r, access)
	raonsonRT := str(ex.Data, "refresh_token")
	if raonsonRT == "" || raonsonRT == appRT {
		t.Fatal("exchange токени алоҳида надод")
	}

	// Сессияи барнома зинда аст.
	res := refresh(t, r, appRT)
	if res.Status != 200 {
		t.Fatalf("exchange сессияи барномаро кушт: %d %s", res.Status, res.Error)
	}
	// Сессияи Raonson ҳам зинда ва ротатсияи худро дорад.
	res2 := refresh(t, r, raonsonRT)
	if res2.Status != 200 {
		t.Fatalf("сессияи raonson кор намекунад: %d", res2.Status)
	}
	// Логини нав дар дастгоҳи дигар ҳарду сессияро намекушад.
	login(t, r, email)
	if res := refresh(t, r, str(res.Data, "refresh_token")); res.Status != 200 {
		t.Fatalf("логини нав сессияи барномаро кушт: %d", res.Status)
	}
	if res := refresh(t, r, str(res2.Data, "refresh_token")); res.Status != 200 {
		t.Fatalf("логини нав сессияи raonson-ро кушт: %d", res.Status)
	}

	var clients []string
	rows, _ := db.DB.Query(`SELECT client FROM auth_sessions WHERE user_id=$1 ORDER BY created_at`, uid)
	for rows.Next() {
		var c string
		rows.Scan(&c)
		clients = append(clients, c)
	}
	rows.Close()
	if len(clients) != 3 || clients[0] != "app" || clients[1] != "raonson" || clients[2] != "app" {
		t.Fatalf("сессияҳо: %v", clients)
	}
}

func TestSessionLogoutRevokesOnlyThatSession(t *testing.T) {
	needDB(t)
	r := testRouter()
	_, email := newTestUser(t)
	access, appRT := login(t, r, email)
	raonsonRT := str(raonsonExchange(t, r, access).Data, "refresh_token")

	if res := call(t, r, "POST", "/api/v1/auth/logout", map[string]string{"refresh_token": appRT}, nil); res.Status != 200 {
		t.Fatalf("logout: %d", res.Status)
	}
	if res := refresh(t, r, appRT); res.Status != 401 {
		t.Fatalf("пас аз logout токен бояд мурад: %d", res.Status)
	}
	if res := refresh(t, r, raonsonRT); res.Status != 200 {
		t.Fatalf("logout-и барнома сессияи raonson-ро кушт: %d", res.Status)
	}
}

func TestSessionPasswordChangeRevokesAll(t *testing.T) {
	needDB(t)
	r := testRouter()
	_, email := newTestUser(t)
	access, appRT := login(t, r, email)
	raonsonRT := str(raonsonExchange(t, r, access).Data, "refresh_token")
	_, otherDeviceRT := login(t, r, email)

	res := call(t, r, "PUT", "/api/v1/users/me/password",
		map[string]string{"current_password": "secret123", "new_password": "newpass456"},
		map[string]string{"Authorization": "Bearer " + access})
	if res.Status != 200 {
		t.Fatalf("ивази парол: %d %s", res.Status, res.Error)
	}
	for name, tok := range map[string]string{"app": appRT, "raonson": raonsonRT, "дастгоҳи дигар": otherDeviceRT} {
		if res := refresh(t, r, tok); res.Status != 401 {
			t.Fatalf("пас аз ивази парол сессияи %s бояд мурад: %d", name, res.Status)
		}
	}
	// Ин дастгоҳ сессияи нав гирифт.
	if res := refresh(t, r, str(res.Data, "refresh_token")); res.Status != 200 {
		t.Fatalf("сессияи нав пас аз ивази парол кор намекунад: %d", res.Status)
	}
	// Пароли нодуруст → 401, ҳеҷ чиз иваз намешавад.
	bad := call(t, r, "PUT", "/api/v1/users/me/password",
		map[string]string{"current_password": "wrong", "new_password": "x123456"},
		map[string]string{"Authorization": "Bearer " + access})
	if bad.Status != 401 {
		t.Fatalf("пароли нодуруст: %d", bad.Status)
	}
}

func TestSessionRevokeAllOnDeletionAndBan(t *testing.T) {
	needDB(t)
	r := testRouter()
	uid, email := newTestUser(t)
	_, rt := login(t, r, email)
	db.DB.Exec(`UPDATE users SET is_banned=true WHERE id=$1`, uid)
	// Ҳатто бе revokeAll: refresh-и корбари бандшуда рад мешавад.
	if res := refresh(t, r, rt); res.Status != 401 {
		t.Fatalf("корбари бандшуда токен гирифт: %d", res.Status)
	}
	var open int
	db.DB.QueryRow(`SELECT COUNT(*) FROM auth_sessions WHERE user_id=$1 AND revoked_at IS NULL`, uid).Scan(&open)
	if open != 0 {
		t.Fatalf("сессияҳои кушода монданд: %d", open)
	}
}

// Токени кӯҳна (пеш аз сессияҳо) дар users.refresh_token: бояд кор кунад,
// ба сессияи client=app гузарад ва бо exchange намирад.
func TestSessionLegacyTokenMigratesOnFirstUse(t *testing.T) {
	needDB(t)
	r := testRouter()
	uid, email := newTestUser(t)
	legacy, _ := auth.GenerateRefreshToken(uid, testSecret)
	db.DB.Exec(`UPDATE users SET refresh_token=$1 WHERE id=$2`, legacy, uid)

	// Raonson exchange — пештар маҳз ин сутунро мекушт.
	access, _ := login(t, r, email)
	raonsonExchange(t, r, access)

	res := refresh(t, r, legacy)
	if res.Status != 200 {
		t.Fatalf("токени кӯҳна кор накард: %d %s", res.Status, res.Error)
	}
	var client string
	var col string
	db.DB.QueryRow(`SELECT client FROM auth_sessions WHERE user_id=$1 AND prev_token_hash=$2`,
		uid, hashToken(legacy)).Scan(&client)
	db.DB.QueryRow(`SELECT COALESCE(refresh_token,'') FROM users WHERE id=$1`, uid).Scan(&col)
	if client != "app" {
		t.Fatalf("токени кӯҳна ба сессияи app нагузашт: %q", client)
	}
	if col != "" {
		t.Fatal("сутуни кӯҳна пок нашуд")
	}
	// Барномаи кӯҳна бо ҳамон токен боз меояд — кор мекунад.
	res = refresh(t, r, legacy)
	if res.Status != 200 {
		t.Fatalf("такрори токени кӯҳна: %d", res.Status)
	}
	// Барномаи нав токени навро истифода мебарад → токени кӯҳна мемирад.
	if res := refresh(t, r, str(res.Data, "refresh_token")); res.Status != 200 {
		t.Fatalf("токени нав: %d", res.Status)
	}
	if res := refresh(t, r, legacy); res.Status != 401 {
		t.Fatalf("токени кӯҳна пас аз ротатсияи воқеӣ бояд мурад: %d", res.Status)
	}
}

func TestSSOExchangeEmailVerifiedFalseByDefault(t *testing.T) {
	needDB(t)
	r := testRouter()
	uid, email := newTestUser(t)
	// Ҳатто фурӯшандаи тасдиқшуда (is_verified) почтаи тасдиқшуда надорад.
	db.DB.Exec(`UPDATE users SET is_verified=true WHERE id=$1`, uid)
	access, _ := login(t, r, email)
	ex := raonsonExchange(t, r, access)
	user, _ := ex.Data["user"].(map[string]any)
	ev, present := user["email_verified"]
	if !present {
		t.Fatal("email_verified дар ҷавоб нест")
	}
	if ev != false {
		t.Fatalf("email_verified бояд false бошад, гирифт %v", ev)
	}
	if user["is_verified"] != true {
		t.Fatal("is_verified (фурӯшанда) бояд алоҳида монад")
	}
	if user["email"] != email {
		t.Fatalf("email: %v", user["email"])
	}
}

// Ду дархости баробари refresh бо як токен: ҳарду ҷавоб медиҳанд ё яке
// 401 — вале ҳеҷ гоҳ ду сессия ё panic.
func TestSessionConcurrentRefresh(t *testing.T) {
	needDB(t)
	r := testRouter()
	uid, email := newTestUser(t)
	_, rt := login(t, r, email)
	var wg sync.WaitGroup
	codes := make([]int, 5)
	for i := range codes {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			codes[i] = refresh(t, r, rt).Status
		}(i)
	}
	wg.Wait()
	ok := 0
	for _, c := range codes {
		if c == http.StatusOK {
			ok++
		}
	}
	if ok == 0 {
		t.Fatalf("ҳеҷ refresh муваффақ нашуд: %v", codes)
	}
	var n int
	db.DB.QueryRow(`SELECT COUNT(*) FROM auth_sessions WHERE user_id=$1`, uid).Scan(&n)
	if n != 1 {
		t.Fatalf("сессияҳо: %d", n)
	}
}
