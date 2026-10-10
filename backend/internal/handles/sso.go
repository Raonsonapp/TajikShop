package handlers

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"net/http"
	"strings"
	"tajikshop/internal/auth"
	"tajikshop/internal/db"
	"tajikshop/internal/models"
	"tajikshop/internal/utils"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// ═══════════════════════════════════════════════════════════════════════════
//  SSO — як ҳисоб барои ҳамаи барномаҳои Raonson
// ═══════════════════════════════════════════════════════════════════════════
//
// Корбар дар TajikShop ворид шуда, бе паролу бақайдгирии нав ба Raonson
// мегузарад ва баръакс — мисли Instagram/Facebook/WhatsApp, ки як ҳисоб
// доранд.
//
// Чӣ тавр кор мекунад (ҷараёни «handoff code»):
//
//  1. Барномаи A (корбар дар он вориде аст):
//         POST /sso/code  {target_app:"raonson"}
//     → {code, deep_link, expires_in}
//
//  2. Барномаи A барномаи B-ро мекушояд: `raonson://sso?code=…`
//
//  3. Барномаи B кодро иваз мекунад:
//         POST /sso/exchange  {code, app:"raonson"}
//     → {access_token, refresh_token, user}
//
// Чаро код, на худи токен:
//   • токени воқеӣ ҳеҷ гоҳ ба сатри URL намеафтад (URL дар логи система,
//     таърихи браузер ва «recent apps» намоён мешавад);
//   • код ЯК БОР кор мекунад ва пас аз 2 дақиқа мемирад;
//   • код ба барномаи мақсаднок баста аст — коди Raonson дар ҷои дигар
//     кор намекунад;
//   • дар база худи код не, балки ҳэши он нигоҳ дошта мешавад, пас
//     дастрасӣ ба база ба касе сессия намедиҳад.

const (
	ssoCodeTTL   = 2 * time.Minute
	ssoCodeBytes = 32
)

type SSOHandler struct{ secret string }

func NewSSOHandler(secret string) *SSOHandler { return &SSOHandler{secret: secret} }

// ── Барномаҳои шарик ───────────────────────────────────────────────────────

type ssoApp struct {
	ID       string `json:"id"`
	Name     string `json:"name"`
	Scheme   string `json:"scheme"`   // raonson://
	Package  string `json:"package"`  // барои Google Play
	Fallback string `json:"fallback"` // агар барнома насб нашуда бошад
}

// Рӯйхат дар `settings` нигоҳ дошта мешавад, пас барномаи навро бе релизи
// нав илова кардан мумкин аст.
const defaultSSOApps = `[
  {"id":"raonson","name":"Raonson","scheme":"raonson","package":"com.raonson.app",
   "fallback":"https://play.google.com/store/apps/details?id=com.raonson.app"},
  {"id":"tajikshop","name":"TajikShop","scheme":"tajikshop","package":"com.tajikshop.app",
   "fallback":"https://play.google.com/store/apps/details?id=com.tajikshop.app"}
]`

// parseSSOApps — мантиқи тоза, бе база: пас тестшаванда аст.
func parseSSOApps(raw string) []ssoApp {
	var apps []ssoApp
	if err := json.Unmarshal([]byte(raw), &apps); err != nil || len(apps) == 0 {
		// Танзими вайрон набояд SSO-ро тамоман хомӯш кунад.
		json.Unmarshal([]byte(defaultSSOApps), &apps)
	}
	return apps
}

func findSSOAppIn(apps []ssoApp, id string) (ssoApp, bool) {
	id = strings.ToLower(strings.TrimSpace(id))
	if id == "" {
		return ssoApp{}, false
	}
	for _, a := range apps {
		if strings.ToLower(a.ID) == id {
			return a, true
		}
	}
	return ssoApp{}, false
}

func ssoApps() []ssoApp { return parseSSOApps(settingStr("sso_apps", defaultSSOApps)) }

func findSSOApp(id string) (ssoApp, bool) { return findSSOAppIn(ssoApps(), id) }

// Apps — GET /sso/apps  (оммавӣ)
// Барнома аз ин ҷо мефаҳмад, ки ба кадом барномаҳо гузаштан мумкин аст.
func (h *SSOHandler) Apps(c *gin.Context) {
	utils.OK(c, ssoApps())
}

// ── Қадами 1: гирифтани код ────────────────────────────────────────────────

// IssueCode — POST /sso/code  {target_app}   (бо ворид)
func (h *SSOHandler) IssueCode(c *gin.Context) {
	uid := utils.UserID(c)

	var in struct {
		TargetApp string `json:"target_app"`
	}
	c.ShouldBindJSON(&in)

	app, ok := findSSOApp(in.TargetApp)
	if !ok {
		utils.Err(c, http.StatusBadRequest, "Барномаи номаълум")
		return
	}

	code, hash, err := newSSOCode()
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, "код сохта нашуд")
		return
	}

	// Коди қаблии ҳамин корбар барои ҳамин барнома дигар лозим нест —
	// вагарна чанд коди зинда якбора мемонанд.
	db.DB.Exec(`DELETE FROM sso_codes WHERE user_id=$1 AND target_app=$2 AND used_at IS NULL`,
		uid, app.ID)

	if _, e := db.DB.Exec(`INSERT INTO sso_codes(id,user_id,target_app,code_hash,expires_at)
		VALUES($1,$2,$3,$4,$5)`,
		uuid.NewString(), uid, app.ID, hash, time.Now().Add(ssoCodeTTL)); e != nil {
		utils.Err(c, http.StatusInternalServerError, e.Error())
		return
	}

	utils.Created(c, gin.H{
		"code":       code,
		"expires_in": int(ssoCodeTTL.Seconds()),
		"deep_link":  app.Scheme + "://sso?code=" + code,
		"fallback":   app.Fallback,
		"app":        app,
	})
}

// ── Қадами 2: иваз кардани код ба сессия ───────────────────────────────────

// Exchange — POST /sso/exchange  {code, app}   (оммавӣ: корбар ҳанӯз ворид нест)
func (h *SSOHandler) Exchange(c *gin.Context) {
	var in struct {
		Code string `json:"code" binding:"required"`
		App  string `json:"app"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}
	app, ok := findSSOApp(in.App)
	if !ok {
		utils.Err(c, http.StatusBadRequest, "Барномаи номаълум")
		return
	}

	hash := hashSSOCode(in.Code)

	// Як бор кор мекунад: `used_at IS NULL` дар худи UPDATE аст, пас ду
	// дархости баробар наметавонанд ҳарду сессия гиранд.
	var uid string
	err := db.DB.QueryRow(`UPDATE sso_codes SET used_at=NOW()
		WHERE code_hash=$1 AND target_app=$2 AND used_at IS NULL AND expires_at > NOW()
		RETURNING user_id`, hash, app.ID).Scan(&uid)
	if err != nil || uid == "" {
		utils.Err(c, http.StatusUnauthorized, "Код нодуруст ё мӯҳлаташ гузашт")
		return
	}

	var u models.User
	if e := db.DB.QueryRow(`SELECT id,COALESCE(name,''),COALESCE(email,''),role,
		COALESCE(avatar_url,''),COALESCE(is_seller,false),COALESCE(is_verified,false)
		FROM users WHERE id=$1 AND COALESCE(is_deleted,false)=false`, uid).
		Scan(&u.ID, &u.Name, &u.Email, &u.Role, &u.AvatarURL, &u.IsSeller, &u.IsVerified); e != nil {
		utils.Err(c, http.StatusUnauthorized, "Корбар ёфт нашуд")
		return
	}

	access, _ := auth.GenerateAccessToken(u.ID, u.Role, h.secret)
	refresh, _ := auth.GenerateRefreshToken(u.ID, h.secret)
	db.DB.Exec(`UPDATE users SET refresh_token=$1, updated_at=$2 WHERE id=$3`,
		refresh, time.Now(), u.ID)

	utils.OK(c, gin.H{
		"access_token":  access,
		"refresh_token": refresh,
		"user":          u,
	})
}

// ── Ёрирасонҳо (тестшаванда, бе база) ──────────────────────────────────────

// newSSOCode — коди тасодуфӣ ва ҳэши он. Худи код танҳо як бор — дар ҷавоб
// — дода мешавад; дар база фақат ҳэш мемонад.
func newSSOCode() (code, hash string, err error) {
	buf := make([]byte, ssoCodeBytes)
	if _, err = rand.Read(buf); err != nil {
		return "", "", err
	}
	code = base64.RawURLEncoding.EncodeToString(buf)
	return code, hashSSOCode(code), nil
}

func hashSSOCode(code string) string {
	sum := sha256.Sum256([]byte(strings.TrimSpace(code)))
	return hex.EncodeToString(sum[:])
}
