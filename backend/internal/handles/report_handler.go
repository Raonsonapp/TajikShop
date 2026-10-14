package handlers

import (
	"net/http"
	"time"

	"tajikshop/internal/db"
	"tajikshop/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type ReportHandler struct{}

func NewReportHandler() *ReportHandler { return &ReportHandler{} }

// Create — корбар маҳсулот ё корбарро гузориш медиҳад
func (h *ReportHandler) Create(c *gin.Context) {
	uid := utils.UserID(c)
	var in struct {
		TargetType string `json:"target_type" binding:"required"` // product | user
		TargetID   string `json:"target_id" binding:"required"`
		Reason     string `json:"reason" binding:"required"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}
	if in.TargetType != "product" && in.TargetType != "user" {
		utils.Err(c, http.StatusBadRequest, "target_type нодуруст")
		return
	}
	db.DB.Exec(`INSERT INTO reports(id,reporter_id,target_type,target_id,reason) VALUES($1,$2,$3,$4,$5)`,
		uuid.NewString(), uid, in.TargetType, in.TargetID, in.Reason)
	utils.Created(c, gin.H{"message": "гузориш қабул шуд"})
}

// AdminList — рӯйхати гузоришҳо барои админ
func (h *ReportHandler) AdminList(c *gin.Context) {
	rows, qerr := db.DB.Query(`SELECT id,target_type,target_id,reason,resolved,created_at
		FROM reports ORDER BY resolved ASC, created_at DESC LIMIT 200`)
	if qerr != nil {
		utils.Err(c, http.StatusInternalServerError,
			"Маълумот хонда нашуд")
		return
	}
	defer rows.Close()
	type rep struct {
		ID         string    `json:"id"`
		TargetType string    `json:"target_type"`
		TargetID   string    `json:"target_id"`
		Reason     string    `json:"reason"`
		Resolved   bool      `json:"resolved"`
		CreatedAt  time.Time `json:"created_at"`
	}
	var list []rep
	for rows.Next() {
		var r rep
		if e := rows.Scan(&r.ID, &r.TargetType, &r.TargetID, &r.Reason, &r.Resolved, &r.CreatedAt); e != nil {
			continue
		}
		list = append(list, r)
	}
	if list == nil {
		list = []rep{}
	}
	utils.OK(c, list)
}

// AdminResolve — гузоришро ҳалшуда қайд мекунад
func (h *ReportHandler) AdminResolve(c *gin.Context) {
	id := c.Param("id")
	db.DB.Exec(`UPDATE reports SET resolved=true WHERE id=$1`, id)
	utils.OK(c, gin.H{"resolved": true})
}
