package handlers

import (
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

	// ── Сатри корбарро anonymize мекунем (фармоиш/пардохт/ҳамён нигоҳ дошта мешавад) ──
	// email/phone/firebase_uid UNIQUE-анд → қиматҳои беназири «deleted» мегузорем.
	if _, e := tx.Exec(`UPDATE users SET
			name='Корбари ҳазфшуда',
			email='deleted_'||id::text||'@deleted.tajikshop.local',
			phone=NULL,
			password_hash='',
			refresh_token='',
			firebase_uid='deleted_'||id::text,
			fcm_token='',
			avatar_url='',
			bio='',
			shop_name='', shop_desc='', shop_phone='', shop_hours='',
			store_lat=0, store_lng=0,
			referral_code='', referred_by=NULL,
			is_seller=false, seller_requested=false, is_verified=false,
			is_banned=true, is_deleted=true, deleted_at=$2,
			updated_at=$2
		WHERE id=$1`, uid, time.Now()); e != nil {
		utils.Err(c, http.StatusInternalServerError, "delete failed: "+e.Error())
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
