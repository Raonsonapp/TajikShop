package handlers

import (
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"errors"
	"strings"
	"time"

	"tajikshop/internal/auth"
	"tajikshop/internal/db"

	"github.com/google/uuid"
)

// ═══════════════════════════════════════════════════════════════════════════
//  Сессияҳо (токенҳои навсозӣ) — ҳар вуруд сатри худро дорад
// ═══════════════════════════════════════════════════════════════════════════
//
// Пештар users.refresh_token ЯК сутун буд: ҳар вуруди нав — ё
// /sso/exchange-и Raonson — онро иваз мекард ва сессияи дигар (масалан худи
// барномаи TajikShop-и корбар) дигар нав намешуд.
//
// Акнун:
//   • ҳар вуруд сатри auth_sessions месозад (client: app | raonson | …);
//   • токени навсозӣ `sid`-и сессияро дар бар мегирад, дар база танҳо
//     ҳэши SHA-256-и он мемонад;
//   • /auth/refresh токенро ИВАЗ мекунад (ротатсия) — танҳо дар ҳамон
//     сессия, дигар сессияҳо дахл надоранд;
//   • logout танҳо ҳамон сессияро мебандад, ивази парол / ҳазфи ҳисоб /
//     бан — ҳамаашро.
//
// Мутобиқат бо барномаҳои кӯҳна:
//   • Токени кӯҳна (бе `sid`, дар users.refresh_token) ҳангоми аввалин
//     /auth/refresh ба сессияи client=app гузаронида мешавад — корбар
//     аз барнома берун намешавад.
//   • Барномаи кӯҳна аз ҷавоби /auth/refresh танҳо access_token-ро
//     мегирад ва бо ҳамон токени навсозии кӯҳна давом медиҳад. Барои ҳамин
//     токени қаблӣ (prev_token_hash) низ қабул мешавад ва ҳангоми
//     истифодаи он prev иваз намешавад. Вақте ки барнома токени НАВро
//     истифода бурд (яъне ротатсияро медонад), prev ба он мегузарад ва
//     токени кӯҳна мемирад.

// Номи client-и худи барномаи TajikShop.
const clientApp = "app"

var (
	errSessionInvalid = errors.New("invalid refresh token")
	errUserBlocked    = errors.New("account blocked")
)

// sqlRunner — *sql.DB ва *sql.Tx ҳарду.
type sqlRunner interface {
	Exec(query string, args ...any) (sql.Result, error)
	QueryRow(query string, args ...any) *sql.Row
}

// hashToken — ҳэши токен барои база (худи токен нигоҳ дошта намешавад).
func hashToken(tok string) string {
	sum := sha256.Sum256([]byte(strings.TrimSpace(tok)))
	return hex.EncodeToString(sum[:])
}

// sessionClientForApp — барномаи SSO → номи client-и сессия.
func sessionClientForApp(appID string) string {
	id := strings.ToLower(strings.TrimSpace(appID))
	if id == "" || id == "tajikshop" {
		return clientApp
	}
	return id
}

// issueSession — сессияи нав месозад ва токени навсозии онро бармегардонад.
// Дигар сессияҳои корбар ДАХЛ НАДОРАНД.
func issueSession(q sqlRunner, secret, userID, client string) (string, error) {
	if client == "" {
		client = clientApp
	}
	sid := uuid.NewString()
	exp := time.Now().Add(auth.RefreshTTL)
	tok, err := auth.GenerateSessionRefreshToken(userID, sid, secret, exp)
	if err != nil {
		return "", err
	}
	if _, err := q.Exec(`INSERT INTO auth_sessions(id,user_id,client,token_hash,expires_at,last_used_at)
		VALUES($1,$2,$3,$4,$5,NOW())`, sid, userID, client, hashToken(tok), exp); err != nil {
		return "", err
	}
	return tok, nil
}

// refreshResult — натиҷаи /auth/refresh.
type refreshResult struct {
	UserID  string
	Role    string
	Refresh string // токени НАВи навсозӣ (ротатсия)
	Client  string
}

// rotateRefreshToken — токени навсозиро месанҷад ва ИВАЗ мекунад.
func rotateRefreshToken(secret, token string) (*refreshResult, error) {
	token = strings.TrimSpace(token)
	claims, err := auth.ParseToken(token, secret)
	if err != nil || claims.UserID == "" {
		return nil, errSessionInvalid
	}
	h := hashToken(token)

	tx, err := db.DB.Begin()
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()

	sid := claims.SessionID
	if sid == "" {
		// Токени кӯҳна (пеш аз сессияҳо).
		sid, err = migrateLegacyToken(tx, claims, token, h)
		if err != nil {
			return nil, err
		}
	}

	var (
		userID, client, cur string
		prev                sql.NullString
		expires             time.Time
		revoked             sql.NullTime
	)
	if err := tx.QueryRow(`SELECT user_id::text, client, token_hash, prev_token_hash, expires_at, revoked_at
		FROM auth_sessions WHERE id=$1 FOR UPDATE`, sid).
		Scan(&userID, &client, &cur, &prev, &expires, &revoked); err != nil {
		return nil, errSessionInvalid
	}
	if userID != claims.UserID || revoked.Valid || !expires.After(time.Now()) {
		return nil, errSessionInvalid
	}

	var newPrev any
	switch {
	case h == cur:
		newPrev = cur // ротатсияи оддӣ: ҷорӣ → қаблӣ
	case prev.Valid && h == prev.String:
		// Мизоҷ токени навро нигоҳ надошт (барномаи кӯҳна) ё ду дархости
		// баробар. prev ҳамон мемонад, то он мизоҷ кор кардан гирад.
		newPrev = prev.String
	default:
		// Токени аз ин ҳам кӯҳнатар. Сессияро намебандем (шояд пойгаи ду
		// дархост бошад), вале қабул ҳам намекунем.
		return nil, errSessionInvalid
	}

	var role string
	var banned, deleted bool
	if err := tx.QueryRow(`SELECT COALESCE(role,'buyer'), COALESCE(is_banned,false), COALESCE(is_deleted,false)
		FROM users WHERE id=$1`, userID).Scan(&role, &banned, &deleted); err != nil {
		return nil, errSessionInvalid
	}
	if banned || deleted {
		tx.Exec(`UPDATE auth_sessions SET revoked_at=NOW() WHERE user_id=$1 AND revoked_at IS NULL`, userID)
		tx.Commit()
		return nil, errUserBlocked
	}

	exp := time.Now().Add(auth.RefreshTTL)
	fresh, err := auth.GenerateSessionRefreshToken(userID, sid, secret, exp)
	if err != nil {
		return nil, err
	}
	if _, err := tx.Exec(`UPDATE auth_sessions
		SET token_hash=$2, prev_token_hash=$3, last_used_at=NOW(), expires_at=$4
		WHERE id=$1`, sid, hashToken(fresh), newPrev, exp); err != nil {
		return nil, err
	}
	if err := tx.Commit(); err != nil {
		return nil, err
	}
	return &refreshResult{UserID: userID, Role: role, Refresh: fresh, Client: client}, nil
}

// migrateLegacyToken — токени кӯҳнаро (users.refresh_token) ба сессияи
// client=app мегузаронад. Агар аллакай гузаронида шуда бошад — ҳамон
// сессияро меёбад. Бармегардонад: id-и сессия.
func migrateLegacyToken(tx *sql.Tx, claims *auth.Claims, token, h string) (string, error) {
	// Аввал: шояд аллакай гузаронида шудааст (ҷорӣ ё қаблӣ).
	var sid string
	err := tx.QueryRow(`SELECT id::text FROM auth_sessions
		WHERE user_id=$1 AND (token_hash=$2 OR prev_token_hash=$2)
		ORDER BY created_at LIMIT 1`, claims.UserID, h).Scan(&sid)
	if err == nil {
		return sid, nil
	}
	if !errors.Is(err, sql.ErrNoRows) {
		return "", err
	}

	// UPDATE … RETURNING сатрро қуфл мекунад: ду дархости баробар наметавонанд
	// ду сессия созанд. Сутун пок мешавад — токен акнун дар auth_sessions аст.
	var uid string
	err = tx.QueryRow(`UPDATE users SET refresh_token=''
		WHERE id=$1 AND refresh_token=$2 AND refresh_token<>''
		RETURNING id::text`, claims.UserID, token).Scan(&uid)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			// Ё токени иваз шуда, ё дархости баробар аллакай гузаронид.
			if e := tx.QueryRow(`SELECT id::text FROM auth_sessions
				WHERE user_id=$1 AND (token_hash=$2 OR prev_token_hash=$2) LIMIT 1`,
				claims.UserID, h).Scan(&sid); e == nil {
				return sid, nil
			}
			return "", errSessionInvalid
		}
		return "", err
	}

	// Мӯҳлат ҳамон мемонад, ки дар худи токен буд.
	exp := time.Now().Add(auth.RefreshTTL)
	if claims.ExpiresAt != nil {
		exp = claims.ExpiresAt.Time
	}
	sid = uuid.NewString()
	if _, err := tx.Exec(`INSERT INTO auth_sessions(id,user_id,client,token_hash,expires_at)
		VALUES($1,$2,$3,$4,$5)`, sid, uid, clientApp, h, exp); err != nil {
		return "", err
	}
	return sid, nil
}

// revokeSessionByToken — logout: танҳо сессияи ҳамин токенро мебандад.
// Токени мӯҳлаташ гузашта ё нодуруст хато нест — натиҷа ҳамон аст.
func revokeSessionByToken(secret, token string) {
	token = strings.TrimSpace(token)
	if token == "" {
		return
	}
	h := hashToken(token)
	claims, err := auth.ParseToken(token, secret)
	if err != nil {
		// Имзо дуруст аст, вале мӯҳлат гузашт — ба ҳар ҳол аз рӯи ҳэш мебандем.
		db.DB.Exec(`UPDATE auth_sessions SET revoked_at=NOW()
			WHERE (token_hash=$1 OR prev_token_hash=$1) AND revoked_at IS NULL`, h)
		return
	}
	if claims.SessionID != "" {
		db.DB.Exec(`UPDATE auth_sessions SET revoked_at=NOW()
			WHERE id=$1 AND user_id=$2 AND (token_hash=$3 OR prev_token_hash=$3) AND revoked_at IS NULL`,
			claims.SessionID, claims.UserID, h)
		return
	}
	// Токени кӯҳна: ё ҳанӯз дар сутун, ё аллакай гузаронида шуда.
	db.DB.Exec(`UPDATE users SET refresh_token='' WHERE id=$1 AND refresh_token=$2`, claims.UserID, token)
	db.DB.Exec(`UPDATE auth_sessions SET revoked_at=NOW()
		WHERE user_id=$1 AND (token_hash=$2 OR prev_token_hash=$2) AND revoked_at IS NULL`, claims.UserID, h)
}

// revokeAllSessions — ивази парол, ҳазфи ҳисоб, бан: ҲАМАИ сессияҳо
// (барнома, Raonson, …) ва токени кӯҳна баста мешаванд.
func revokeAllSessions(q sqlRunner, userID string) error {
	if _, err := q.Exec(`UPDATE auth_sessions SET revoked_at=NOW()
		WHERE user_id=$1 AND revoked_at IS NULL`, userID); err != nil {
		return err
	}
	_, err := q.Exec(`UPDATE users SET refresh_token='' WHERE id=$1`, userID)
	return err
}
