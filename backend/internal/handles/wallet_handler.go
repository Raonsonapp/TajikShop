package handlers

import (
	"database/sql"
	"net/http"
	"strings"
	"time"

	"tajikshop/internal/db"
	"tajikshop/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// ========== WALLET ==========

type WalletHandler struct{}

func NewWalletHandler() *WalletHandler { return &WalletHandler{} }

type walletTx struct {
	ID        string    `json:"id"`
	Amount    float64   `json:"amount"`
	Type      string    `json:"type"`
	Status    string    `json:"status"`
	Note      string    `json:"note"`
	CreatedAt time.Time `json:"created_at"`
}

func (h *WalletHandler) Get(c *gin.Context) {
	uid := utils.UserID(c)
	var balance float64
	db.DB.QueryRow(`SELECT COALESCE(wallet_balance,0) FROM users WHERE id=$1`, uid).Scan(&balance)

	rows, _ := db.DB.Query(`SELECT id,amount,type,status,note,created_at FROM wallet_transactions
		WHERE user_id=$1 ORDER BY created_at DESC LIMIT 100`, uid)
	defer rows.Close()
	var txs []walletTx
	for rows.Next() {
		var t walletTx
		rows.Scan(&t.ID, &t.Amount, &t.Type, &t.Status, &t.Note, &t.CreatedAt)
		txs = append(txs, t)
	}
	if txs == nil {
		txs = []walletTx{}
	}
	utils.OK(c, gin.H{"balance": balance, "transactions": txs})
}

// TopUp — дархости пополнение (status=pending), админ тасдиқ мекунад
func (h *WalletHandler) TopUp(c *gin.Context) {
	uid := utils.UserID(c)
	var in struct {
		Amount float64 `json:"amount" binding:"required,gt=0"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}
	id := uuid.NewString()
	db.DB.Exec(`INSERT INTO wallet_transactions(id,user_id,amount,type,status,note)
		VALUES($1,$2,$3,'topup','pending','Дархости пополнение')`, id, uid, in.Amount)
	utils.Created(c, gin.H{"id": id, "status": "pending"})
}

// AdminPending — дархостҳои пополненияи интизор
func (h *WalletHandler) AdminPending(c *gin.Context) {
	rows, _ := db.DB.Query(`SELECT wt.id,wt.user_id,wt.amount,wt.created_at,u.name,u.email
		FROM wallet_transactions wt JOIN users u ON u.id=wt.user_id
		WHERE wt.status='pending' AND wt.type='topup' ORDER BY wt.created_at DESC`)
	defer rows.Close()
	type pend struct {
		ID        string    `json:"id"`
		UserID    string    `json:"user_id"`
		Amount    float64   `json:"amount"`
		CreatedAt time.Time `json:"created_at"`
		Name      string    `json:"name"`
		Email     string    `json:"email"`
	}
	var list []pend
	for rows.Next() {
		var p pend
		rows.Scan(&p.ID, &p.UserID, &p.Amount, &p.CreatedAt, &p.Name, &p.Email)
		list = append(list, p)
	}
	if list == nil {
		list = []pend{}
	}
	utils.OK(c, list)
}

// AdminApprove — тасдиқ + ҳисоб ба тавозун
func (h *WalletHandler) AdminApprove(c *gin.Context) {
	txID := c.Param("id")
	tx, err := db.DB.Begin()
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, "tx begin failed")
		return
	}
	var uid string
	var amount float64
	var status string
	err = tx.QueryRow(`SELECT user_id,amount,status FROM wallet_transactions WHERE id=$1 FOR UPDATE`, txID).
		Scan(&uid, &amount, &status)
	if err != nil || status != "pending" {
		tx.Rollback()
		utils.Err(c, http.StatusBadRequest, "tranзаксия нодуруст")
		return
	}
	tx.Exec(`UPDATE wallet_transactions SET status='completed' WHERE id=$1`, txID)
	tx.Exec(`UPDATE users SET wallet_balance=COALESCE(wallet_balance,0)+$1 WHERE id=$2`, amount, uid)
	if err := tx.Commit(); err != nil {
		utils.Err(c, http.StatusInternalServerError, "commit failed")
		return
	}
	utils.OK(c, gin.H{"approved": true})
}

func (h *WalletHandler) AdminReject(c *gin.Context) {
	txID := c.Param("id")
	db.DB.Exec(`UPDATE wallet_transactions SET status='rejected' WHERE id=$1 AND status='pending'`, txID)
	utils.OK(c, gin.H{"rejected": true})
}

// ========== COUPONS ==========

type CouponHandler struct{}

func NewCouponHandler() *CouponHandler { return &CouponHandler{} }

// Validate — GET /coupons/validate?code=
func (h *CouponHandler) Validate(c *gin.Context) {
	code := strings.ToUpper(strings.TrimSpace(c.Query("code")))
	if code == "" {
		utils.Err(c, http.StatusBadRequest, "code лозим аст")
		return
	}
	disc, ok, msg := lookupCoupon(code)
	if !ok {
		utils.Err(c, http.StatusBadRequest, msg)
		return
	}
	utils.OK(c, gin.H{"code": code, "discount_percent": disc})
}

// lookupCoupon — фоизи тахфифро бармегардонад агар купон эътибор дошта бошад
func lookupCoupon(code string) (int, bool, string) {
	var disc, maxUses, used int
	var active bool
	var expires sql.NullTime
	err := db.DB.QueryRow(`SELECT discount_percent,max_uses,used_count,is_active,expires_at
		FROM coupons WHERE UPPER(code)=$1`, strings.ToUpper(code)).
		Scan(&disc, &maxUses, &used, &active, &expires)
	if err != nil {
		return 0, false, "Купон ёфт нашуд"
	}
	if !active {
		return 0, false, "Купон ғайрифаъол аст"
	}
	if expires.Valid && expires.Time.Before(time.Now()) {
		return 0, false, "Мӯҳлати купон гузаштааст"
	}
	if maxUses > 0 && used >= maxUses {
		return 0, false, "Лимити истифодаи купон тамом шуд"
	}
	return disc, true, ""
}

// ActiveList — купонҳои фаъол барои харидорон (кашф кардани промокодҳо).
// GET /coupons/active
func (h *CouponHandler) ActiveList(c *gin.Context) {
	rows, _ := db.DB.Query(`SELECT code,discount_percent
		FROM coupons
		WHERE is_active=true
			AND (expires_at IS NULL OR expires_at > NOW())
			AND (max_uses <= 0 OR used_count < max_uses)
		ORDER BY discount_percent DESC LIMIT 20`)
	defer rows.Close()
	out := []gin.H{}
	for rows.Next() {
		var code string
		var disc int
		rows.Scan(&code, &disc)
		out = append(out, gin.H{"code": code, "discount_percent": disc})
	}
	utils.OK(c, out)
}

// Create — admin
func (h *CouponHandler) Create(c *gin.Context) {
	var in struct {
		Code            string `json:"code" binding:"required"`
		DiscountPercent int    `json:"discount_percent" binding:"required,min=1,max=100"`
		MaxUses         int    `json:"max_uses"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}
	id := uuid.NewString()
	_, err := db.DB.Exec(`INSERT INTO coupons(id,code,discount_percent,max_uses)
		VALUES($1,UPPER($2),$3,$4)`, id, in.Code, in.DiscountPercent, in.MaxUses)
	if err != nil {
		utils.Err(c, http.StatusBadRequest, "Купон сохта нашуд (шояд аллакай вуҷуд дорад)")
		return
	}
	utils.Created(c, gin.H{"id": id})
}

func (h *CouponHandler) List(c *gin.Context) {
	rows, _ := db.DB.Query(`SELECT id,code,discount_percent,max_uses,used_count,is_active,created_at
		FROM coupons ORDER BY created_at DESC`)
	defer rows.Close()
	type cpn struct {
		ID              string    `json:"id"`
		Code            string    `json:"code"`
		DiscountPercent int       `json:"discount_percent"`
		MaxUses         int       `json:"max_uses"`
		UsedCount       int       `json:"used_count"`
		IsActive        bool      `json:"is_active"`
		CreatedAt       time.Time `json:"created_at"`
	}
	var list []cpn
	for rows.Next() {
		var x cpn
		rows.Scan(&x.ID, &x.Code, &x.DiscountPercent, &x.MaxUses, &x.UsedCount, &x.IsActive, &x.CreatedAt)
		list = append(list, x)
	}
	if list == nil {
		list = []cpn{}
	}
	utils.OK(c, list)
}
