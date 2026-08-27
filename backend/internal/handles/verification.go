package handlers

import (
	"net/http"
	"strconv"
	"strings"
	"tajikshop/internal/db"
	"tajikshop/internal/storage"
	"tajikshop/internal/utils"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// ── Галочкаи тасдиқ (расмӣ) ─────────────────────────────────────────────────
//
// Корбар маблағро ба корти TajikShop мефиристад, чекро дар барнома мегузорад,
// админ як пахш тасдиқ мекунад → `users.is_verified=true` ва галочкаи сабз
// пайдо мешавад.
//
// Чаро дастӣ, на «SMS-ро худкор хондан»: Android иҷозати SMS-ро банк ба банк
// ҷудо намекунад ва Google Play онро ба барномаи савдо намедиҳад. Ин ҷо
// админ ҳамон корро як пахш мекунад — ҳамон натиҷа, вале қонунӣ.

type VerificationHandler struct{ r2 *storage.R2Client }

func NewVerificationHandler(r2 *storage.R2Client) *VerificationHandler {
	return &VerificationHandler{r2: r2}
}

func verifyPrice() float64 {
	v, err := strconv.ParseFloat(settingStr("verify_price", "50"), 64)
	if err != nil || v < 0 {
		return 50
	}
	return v
}

// Info — GET /verification/info
// Нарх ва корт барои пардохт (оммавӣ: корбар пеш аз дархост инро мебинад).
func (h *VerificationHandler) Info(c *gin.Context) {
	utils.OK(c, gin.H{
		"price":       verifyPrice(),
		"card":        settingStr("verify_card", ""),
		"card_holder": settingStr("verify_card_holder", "TajikShop"),
	})
}

// MyRequest — GET /users/me/verification
// Ҳолати корбар: аллакай тасдиқшуда, ё дархости интизор/радшуда.
func (h *VerificationHandler) MyRequest(c *gin.Context) {
	uid := utils.UserID(c)

	var verified bool
	db.DB.QueryRow(`SELECT COALESCE(is_verified,false) FROM users WHERE id=$1`, uid).Scan(&verified)

	var id, status, note, receipt string
	var amount float64
	var created time.Time
	err := db.DB.QueryRow(`SELECT id,status,COALESCE(note,''),COALESCE(receipt_url,''),
		COALESCE(amount,0),created_at
		FROM verification_requests WHERE user_id=$1
		ORDER BY created_at DESC LIMIT 1`, uid).
		Scan(&id, &status, &note, &receipt, &amount, &created)

	out := gin.H{
		"is_verified": verified,
		"price":       verifyPrice(),
		"card":        settingStr("verify_card", ""),
		"card_holder": settingStr("verify_card_holder", "TajikShop"),
	}
	if err == nil {
		out["request"] = gin.H{
			"id": id, "status": status, "note": note,
			"receipt_url": receipt, "amount": amount, "created_at": created,
		}
	}
	utils.OK(c, out)
}

// Request — POST /users/me/verification  (multipart: receipt)
// Корбар чеки пардохтро мегузорад ва дархост месозад.
func (h *VerificationHandler) Request(c *gin.Context) {
	uid := utils.UserID(c)

	var verified bool
	db.DB.QueryRow(`SELECT COALESCE(is_verified,false) FROM users WHERE id=$1`, uid).Scan(&verified)
	if verified {
		utils.Err(c, http.StatusBadRequest, "Шумо аллакай тасдиқшудаед")
		return
	}

	// Дархости интизори такрорӣ намесозем.
	var pending bool
	db.DB.QueryRow(`SELECT EXISTS(SELECT 1 FROM verification_requests
		WHERE user_id=$1 AND status='pending')`, uid).Scan(&pending)
	if pending {
		utils.Err(c, http.StatusBadRequest,
			"Дархости шумо аллакай баррасӣ шуда истодааст")
		return
	}

	// Чек ҳатмист — бе он админ пардохтро санҷида наметавонад.
	file, header, err := c.Request.FormFile("receipt")
	if err != nil {
		utils.Err(c, http.StatusBadRequest, "Расми чеки пардохтро замима кунед")
		return
	}
	defer file.Close()
	if h.r2 == nil {
		utils.Err(c, http.StatusServiceUnavailable, "Файлҳо ҳоло қабул намешаванд")
		return
	}
	url, upErr := h.r2.Upload(file, header, "verification")
	if upErr != nil {
		utils.Err(c, http.StatusInternalServerError, "Чек бор нашуд")
		return
	}

	id := uuid.NewString()
	if _, e := db.DB.Exec(`INSERT INTO verification_requests(id,user_id,amount,receipt_url,status)
		VALUES($1,$2,$3,$4,'pending')`, id, uid, verifyPrice(), url); e != nil {
		utils.Err(c, http.StatusInternalServerError, e.Error())
		return
	}

	// Ба админҳо хабар медиҳем, то дархост дар навбат нахобад.
	rows, _ := db.DB.Query(`SELECT id FROM users WHERE role='admin'`)
	if rows != nil {
		defer rows.Close()
		for rows.Next() {
			var admin string
			rows.Scan(&admin)
			db.DB.Exec(`INSERT INTO notifications(id,user_id,type,title,body,ref_id)
				VALUES($1,$2,'verify','Дархости галочка','Корбар барои тасдиқ пул фиристод',$3)`,
				uuid.NewString(), admin, id)
			pushToUser(admin, "Дархости галочка", "Корбар барои тасдиқ пул фиристод")
		}
	}

	utils.Created(c, gin.H{"id": id, "status": "pending"})
}

// AdminList — GET /admin/verification-requests
func (h *VerificationHandler) AdminList(c *gin.Context) {
	status := strings.TrimSpace(c.DefaultQuery("status", "pending"))
	rows, err := db.DB.Query(`SELECT v.id,v.user_id,u.name,COALESCE(u.phone,''),
		COALESCE(u.username,''),COALESCE(v.amount,0),COALESCE(v.receipt_url,''),
		v.status,COALESCE(v.note,''),v.created_at
		FROM verification_requests v JOIN users u ON u.id=v.user_id
		WHERE v.status=$1 ORDER BY v.created_at DESC LIMIT 200`, status)
	if err != nil || rows == nil {
		utils.OK(c, []gin.H{})
		return
	}
	defer rows.Close()

	out := []gin.H{}
	for rows.Next() {
		var id, uid, name, phone, username, receipt, st, note string
		var amount float64
		var created time.Time
		rows.Scan(&id, &uid, &name, &phone, &username, &amount, &receipt, &st, &note, &created)
		out = append(out, gin.H{
			"id": id, "user_id": uid, "name": name, "phone": phone,
			"username": username, "amount": amount, "receipt_url": receipt,
			"status": st, "note": note, "created_at": created,
		})
	}
	utils.OK(c, out)
}

// AdminDecide — POST /admin/verification-requests/:id/decide  {approve, note}
func (h *VerificationHandler) AdminDecide(c *gin.Context) {
	id := c.Param("id")
	var in struct {
		Approve bool   `json:"approve"`
		Note    string `json:"note"`
	}
	c.ShouldBindJSON(&in)

	var uid, cur string
	if err := db.DB.QueryRow(`SELECT user_id,status FROM verification_requests WHERE id=$1`, id).
		Scan(&uid, &cur); err != nil {
		utils.Err(c, http.StatusNotFound, "request not found")
		return
	}
	if cur != "pending" {
		utils.Err(c, http.StatusBadRequest, "Ин дархост аллакай баррасӣ шудааст")
		return
	}

	status := "rejected"
	if in.Approve {
		status = "approved"
	}
	// Шартан навсозӣ мекунем — то ду админ якбора тасдиқ накунанд.
	res, err := db.DB.Exec(`UPDATE verification_requests
		SET status=$1, note=$2, updated_at=$3
		WHERE id=$4 AND status='pending'`,
		status, strings.TrimSpace(in.Note), time.Now(), id)
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, "update failed")
		return
	}
	if n, _ := res.RowsAffected(); n == 0 {
		utils.Err(c, http.StatusBadRequest, "Ин дархост аллакай баррасӣ шудааст")
		return
	}

	title := "Дархости галочка рад шуд"
	body := "Сабаб: " + strings.TrimSpace(in.Note)
	if in.Approve {
		db.DB.Exec(`UPDATE users SET is_verified=true, updated_at=$1 WHERE id=$2`, time.Now(), uid)
		title = "Галочкаи тасдиқ фаъол шуд ✅"
		body = "Табрик! Акнун профили шумо галочкаи расмӣ дорад."
	}
	db.DB.Exec(`INSERT INTO notifications(id,user_id,type,title,body,ref_id)
		VALUES($1,$2,'verify',$3,$4,$5)`, uuid.NewString(), uid, title, body, id)
	pushToUser(uid, title, body)

	utils.OK(c, gin.H{"status": status})
}
