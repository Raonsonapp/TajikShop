package handlers

import (
	"net/http"
	"time"

	"tajikshop/internal/db"
	"tajikshop/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type ReturnHandler struct{}

func NewReturnHandler() *ReturnHandler { return &ReturnHandler{} }

// Create — POST /orders/:id/return {type, reason}
func (h *ReturnHandler) Create(c *gin.Context) {
	uid := utils.UserID(c)
	oid := c.Param("id")
	var in struct {
		Type   string `json:"type"`
		Reason string `json:"reason" binding:"required"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}
	if in.Type != "exchange" {
		in.Type = "return"
	}
	// фармоиш бояд аз они корбар бошад ва расида/анҷомёфта бошад
	var status string
	if err := db.DB.QueryRow(`SELECT status FROM orders WHERE id=$1 AND user_id=$2`, oid, uid).Scan(&status); err != nil {
		utils.Err(c, http.StatusNotFound, "order not found")
		return
	}
	s := status
	if s != "delivered" && s != "completed" {
		utils.Err(c, http.StatusBadRequest, "Танҳо барои фармоиши расида мумкин аст")
		return
	}
	// дархости такрориро манъ мекунем
	var exists bool
	db.DB.QueryRow(`SELECT EXISTS(SELECT 1 FROM returns WHERE order_id=$1 AND status IN ('pending','approved'))`, oid).Scan(&exists)
	if exists {
		utils.Err(c, http.StatusBadRequest, "Дархост аллакай мавҷуд аст")
		return
	}
	id := uuid.NewString()
	db.DB.Exec(`INSERT INTO returns(id,order_id,user_id,type,reason) VALUES($1,$2,$3,$4,$5)`,
		id, oid, uid, in.Type, in.Reason)
	utils.Created(c, gin.H{"id": id, "status": "pending"})
}

// ForOrder — GET /orders/:id/return → дархости охирини ин фармоиш (ё холӣ)
func (h *ReturnHandler) ForOrder(c *gin.Context) {
	uid := utils.UserID(c)
	oid := c.Param("id")
	var r struct {
		ID        string    `json:"id"`
		Type      string    `json:"type"`
		Reason    string    `json:"reason"`
		Status    string    `json:"status"`
		CreatedAt time.Time `json:"created_at"`
	}
	err := db.DB.QueryRow(`SELECT id,type,reason,status,created_at FROM returns
		WHERE order_id=$1 AND user_id=$2 ORDER BY created_at DESC LIMIT 1`, oid, uid).
		Scan(&r.ID, &r.Type, &r.Reason, &r.Status, &r.CreatedAt)
	if err != nil {
		utils.OK(c, nil)
		return
	}
	utils.OK(c, r)
}

// AdminList — GET /admin/returns
func (h *ReturnHandler) AdminList(c *gin.Context) {
	rows, _ := db.DB.Query(`SELECT rt.id,rt.order_id,rt.type,rt.reason,rt.status,rt.created_at,u.name
		FROM returns rt JOIN users u ON u.id=rt.user_id
		ORDER BY (rt.status='pending') DESC, rt.created_at DESC LIMIT 200`)
	defer rows.Close()
	type ret struct {
		ID        string    `json:"id"`
		OrderID   string    `json:"order_id"`
		Type      string    `json:"type"`
		Reason    string    `json:"reason"`
		Status    string    `json:"status"`
		CreatedAt time.Time `json:"created_at"`
		UserName  string    `json:"user_name"`
	}
	var list []ret
	for rows.Next() {
		var r ret
		rows.Scan(&r.ID, &r.OrderID, &r.Type, &r.Reason, &r.Status, &r.CreatedAt, &r.UserName)
		list = append(list, r)
	}
	if list == nil {
		list = []ret{}
	}
	utils.OK(c, list)
}

// AdminUpdate — POST /admin/returns/:id/status {status}
func (h *ReturnHandler) AdminUpdate(c *gin.Context) {
	rid := c.Param("id")
	var in struct {
		Status string `json:"status" binding:"required"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}
	// маълумоти дархост
	var orderID, userID, rtype string
	if err := db.DB.QueryRow(`SELECT order_id,user_id,type FROM returns WHERE id=$1`, rid).Scan(&orderID, &userID, &rtype); err != nil {
		utils.Err(c, http.StatusNotFound, "return not found")
		return
	}
	db.DB.Exec(`UPDATE returns SET status=$1 WHERE id=$2`, in.Status, rid)

	// Ҳангоми "completed" барои бозгашт — агар бо ҳамён пардохта шуда бошад, пул бармегардад
	if in.Status == "completed" && rtype == "return" {
		var method string
		var total float64
		if err := db.DB.QueryRow(`SELECT COALESCE(payment_method,'dc'),total FROM orders WHERE id=$1`, orderID).Scan(&method, &total); err == nil {
			if method == "wallet" {
				db.DB.Exec(`UPDATE users SET wallet_balance=COALESCE(wallet_balance,0)+$1 WHERE id=$2`, total, userID)
				db.DB.Exec(`INSERT INTO wallet_transactions(id,user_id,amount,type,status,note)
					VALUES($1,$2,$3,'refund','completed','Бозгашти мол')`, uuid.NewString(), userID, total)
			}
		}
		db.DB.Exec(`UPDATE orders SET status='returned',updated_at=$1 WHERE id=$2`, time.Now(), orderID)
	}

	// Огоҳии корбар
	titles := map[string]string{"approved": "Дархост қабул шуд", "rejected": "Дархост рад шуд", "completed": "Бозгашт анҷом ёфт"}
	if t, ok := titles[in.Status]; ok {
		db.DB.Exec(`INSERT INTO notifications(id,user_id,type,title,body) VALUES($1,$2,'return',$3,$4)`,
			uuid.NewString(), userID, t, "Ҳолати дархости бозгашт/иваз")
		pushToUser(userID, t, "Ҳолати дархости бозгашт/иваз")
	}
	utils.OK(c, gin.H{"updated": true})
}
