package handlers

import (
	"database/sql"
	"log"
	"net/http"
	"time"

	"tajikshop/internal/db"
	"tajikshop/internal/utils"

	"github.com/gin-gonic/gin"
)

// DeleteAccount — DELETE /users/me
//
// Ҳисоби корбари воридшударо ҳазф мекунад (Google Play requirement):
//   - Маълумоти шахсии зерин ПУРРА ҳазф мешавад: сабад, дӯстдоштаҳо, суроғаҳо,
//     пайгириҳо, ҳикояҳо, паёмҳо, огоҳиномаҳо, шарҳҳо, саволҳо, дархостҳои
//     карго/бозгашт, маҳсулоти дар ягон фармоиш набуда, ва расмҳои шахсӣ (R2).
//   - Сабтҳои молиявӣ/ҳуқуқӣ (фармоишҳо, пардохтҳо, ҳамён) барои қонунгузорӣ,
//     ҳисобдорӣ ва пешгирии қаллобӣ НИГОҲ дошта, вале ба корбари беном (anonymized)
//     пайваст мешаванд. Ин дар Сиёсати махфият ошкор шудааст.
//   - Сатри корбар anonymize мешавад (ному тел./почта/парол/аватар пок) ва login
//     баста мешавад (is_banned=true, is_deleted=true).
//
// Танҳо худи корбар метавонад ҳисоби худро ҳазф кунад (server-side authorization
// аз JWT). Идемпотент: ҳисоби аллакай ҳазфшуда бехато бармегардад.
func (h *UserHandler) DeleteAccount(c *gin.Context) {
	uid := utils.UserID(c)
	if uid == "" {
		utils.Err(c, http.StatusUnauthorized, "unauthorized")
		return
	}

	// Аллакай ҳазфшуда? → идемпотент.
	var alreadyDeleted bool
	if err := db.DB.QueryRow(`SELECT COALESCE(is_deleted,false) FROM users WHERE id=$1`, uid).Scan(&alreadyDeleted); err != nil {
		utils.Err(c, http.StatusNotFound, "user not found")
		return
	}
	if alreadyDeleted {
		utils.OK(c, gin.H{"deleted": true, "message": "account already deleted"})
		return
	}

	// ── Расмҳои R2-ро барои ҳазфи best-effort ҷамъ мекунем (пеш аз ҳазфи сатрҳо) ──
	mediaURLs := []string{}
	var avatar string
	db.DB.QueryRow(`SELECT COALESCE(avatar_url,'') FROM users WHERE id=$1`, uid).Scan(&avatar)
	if avatar != "" {
		mediaURLs = append(mediaURLs, avatar)
	}
	// Расмҳои маҳсулоти дар ягон фармоиш набуда (онҳо ҳазф мешаванд).
	if rows, err := db.DB.Query(`SELECT pi.url FROM product_images pi
		JOIN products p ON p.id=pi.product_id
		WHERE p.seller_id=$1 AND NOT EXISTS (SELECT 1 FROM order_items oi WHERE oi.product_id=p.id)`, uid); err == nil {
		for rows.Next() {
			var u string
			rows.Scan(&u)
			if u != "" {
				mediaURLs = append(mediaURLs, u)
			}
		}
		rows.Close()
	}
	// Медиаи ҳикояҳо.
	if rows, err := db.DB.Query(`SELECT media_url FROM stories WHERE user_id=$1`, uid); err == nil {
		for rows.Next() {
			var u string
			rows.Scan(&u)
			if u != "" {
				mediaURLs = append(mediaURLs, u)
			}
		}
		rows.Close()
	}

	tx, err := db.DB.Begin()
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, "delete failed")
		return
	}
	defer tx.Rollback()

	// ── Маълумоти сирф шахсиро ҳазф мекунем ──
	personal := []string{
		// Ҳамаи сессияҳо (барнома, Raonson, …) — токенҳои навсозӣ мемиранд.
		`DELETE FROM auth_sessions WHERE user_id=$1`,
		`DELETE FROM sso_codes WHERE user_id=$1`,
		`DELETE FROM cart_items WHERE user_id=$1`,
		`DELETE FROM favorites WHERE user_id=$1`,
		`DELETE FROM addresses WHERE user_id=$1`,
		`DELETE FROM follows WHERE follower_id=$1 OR following_id=$1`,
		`DELETE FROM stories WHERE user_id=$1`,
		`DELETE FROM messages WHERE sender_id=$1 OR receiver_id=$1`,
		`DELETE FROM notifications WHERE user_id=$1`,
		`DELETE FROM review_likes WHERE user_id=$1`,
		`DELETE FROM reviews WHERE user_id=$1`,
		`DELETE FROM questions WHERE user_id=$1`,
		`DELETE FROM returns WHERE user_id=$1`,
		`DELETE FROM cargo_orders WHERE user_id=$1`,
	}
	for _, q := range personal {
		if _, e := tx.Exec(q, uid); e != nil {
			utils.Err(c, http.StatusInternalServerError, "delete failed: "+e.Error())
			return
		}
	}

	// ── Маҳсулоти фурӯшанда ──
	// Ҳамаро пинҳон мекунем; онҳое ки дар ягон фармоиш нестанд, ҳазф мешаванд
	// (расмҳояшон бо CASCADE ҳазф мешаванд). Дар фармоиш бударо нигоҳ медорем.
	if _, e := tx.Exec(`UPDATE products SET is_active=false, stock=0 WHERE seller_id=$1`, uid); e != nil {
		utils.Err(c, http.StatusInternalServerError, "delete failed: "+e.Error())
		return
	}
	if _, e := tx.Exec(`DELETE FROM products WHERE seller_id=$1
		AND NOT EXISTS (SELECT 1 FROM order_items oi WHERE oi.product_id=products.id)`, uid); e != nil {
		utils.Err(c, http.StatusInternalServerError, "delete failed: "+e.Error())
		return
	}

	// ── Сатри корбарро anonymize мекунем ──
	//
	// Фармоиш, пардохт ва ҳамён нигоҳ дошта мешаванд: онҳо таърихи
	// ФУРӮШАНДА ва ҳисоботи пулӣ ҳастанд, на маълумоти шахсии ин корбар.
	//
	// ЧАРО СУТУНҲО АЗ БАЗА ПУРСИДА МЕШАВАНД, на сахт навишта:
	//
	// Дар тести эмулятор ин масир дар production **500** дод, ҳол он ки
	// дар базаи маҳаллии тоза ҳамаи шаш тест сабз буданд. Фарқ дар он
	// аст, ки базаи production кӯҳна аст ва тавассути `ALTER TABLE`
	// рушд кардааст — ва `execEach` хатои ҳар амрро ба лог менависад ва
	// МЕГУЗАРАД. Яъне як `ALTER TABLE` метавонад солҳо пеш афтода бошад,
	// ва он сутун дар production НЕСТ.
	//
	// Як UPDATE-и калон бо сутуни нестбуда ПУРРА меафтад — ва он гоҳ
	// корбар ҳисобашро нест карда наметавонад. Google Play инро ҳатмӣ
	// талаб мекунад.
	//
	// Пас: сутунҳои МАВҶУД пурсида мешаванд, ва танҳо онҳо иваз
	// мешаванд. Маълумоти ҳассос (`core`) ҳатмист — агар он набошад,
	// база вайрон аст ва хато додан дуруст аст.
	cols := existingUserColumns(tx)

	// Ин сутунҳо ҳатман бояд бошанд: бе онҳо маълумоти шахсӣ нест
	// намешавад, ва «нест кардан» маъно надорад.
	core := `UPDATE users SET
			name='Корбари ҳазфшуда',
			email='deleted_'||id::text||'@deleted.tajikshop.local',
			phone=NULL,
			password_hash='',
			is_banned=true,
			updated_at=$2`
	// Сутунҳои иловагӣ — ҳар кадом танҳо агар вуҷуд дошта бошад.
	optional := []struct{ col, set string }{
		{"refresh_token", "refresh_token=''"},
		{"firebase_uid", "firebase_uid='deleted_'||id::text"},
		{"fcm_token", "fcm_token=''"},
		{"avatar_url", "avatar_url=''"},
		{"bio", "bio=''"},
		{"shop_name", "shop_name=''"},
		{"shop_desc", "shop_desc=''"},
		{"shop_phone", "shop_phone=''"},
		{"shop_hours", "shop_hours=''"},
		{"store_lat", "store_lat=0"},
		{"store_lng", "store_lng=0"},
		{"region", "region=''"},
		{"card_number", "card_number=''"},
		{"card_holder", "card_holder=''"},
		{"username", "username=NULL"},
		{"referral_code", "referral_code=''"},
		{"referred_by", "referred_by=NULL"},
		{"is_seller", "is_seller=false"},
		{"seller_requested", "seller_requested=false"},
		{"is_verified", "is_verified=false"},
		{"is_deleted", "is_deleted=true"},
		{"deleted_at", "deleted_at=$2"},
	}
	for _, o := range optional {
		if cols[o.col] {
			core += ",\n\t\t\t" + o.set
		}
	}
	core += "\n\t\tWHERE id=$1"

	if _, e := tx.Exec(core, uid, time.Now()); e != nil {
		// Хатои ҳақиқӣ ба лог меравад: паёми корбар онро пинҳон
		// мекунад, ва бе лог сабаб пайдо кардан номумкин аст.
		log.Printf("❌ DeleteAccount: %v", e)
		utils.Err(c, http.StatusInternalServerError,
			"Ҳисоб нест карда нашуд. Лутфан бо дастгирӣ тамос гиред.")
		return
	}

	if err := tx.Commit(); err != nil {
		utils.Err(c, http.StatusInternalServerError, "delete failed")
		return
	}

	// ── Best-effort: расмҳоро аз R2 ҳазф мекунем (хатогиҳо login-ро халалдор намекунанд) ──
	if h.r2 != nil {
		for _, u := range mediaURLs {
			_ = h.r2.DeleteByURL(u)
		}
	}

	utils.OK(c, gin.H{"deleted": true, "message": "Ҳисоб ва маълумоти шахсии шумо ҳазф шуд"})
}

// existingUserColumns — сутунҳои воқеан мавҷуди ҷадвали `users`.
//
// Базаи production тавассути `ALTER TABLE ... IF NOT EXISTS` рушд
// кардааст, ва `execEach` хатои ҳар амрро ба лог менависад ва мегузарад
// — пас сутуне метавонад НАБОШАД, ҳол он ки дар схема ҳаст.
func existingUserColumns(tx *sql.Tx) map[string]bool {
	out := map[string]bool{}
	rows, err := tx.Query(`SELECT column_name FROM information_schema.columns
		WHERE table_name='users'`)
	if err != nil || rows == nil {
		return out
	}
	defer rows.Close()
	for rows.Next() {
		var c string
		if e := rows.Scan(&c); e == nil {
			out[c] = true
		}
	}
	return out
}
