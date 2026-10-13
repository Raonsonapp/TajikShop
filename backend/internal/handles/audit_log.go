package handlers

import (
	"database/sql"
	"net/http"
	"strconv"
	"tajikshop/internal/db"
	"tajikshop/internal/utils"
	"time"

	"github.com/gin-gonic/gin"
)

// AuditLog — GET /admin/audit  (админ)
//
// Дафтари амалҳои админ. Худи ин дархост сабт НАМЕШАВАД: он `GET` аст,
// ва middleware танҳо амалҳои тағйирдиҳандаро мегирад — вагарна ҳар
// кушодани ин саҳифа дафтарро пур мекард.
//
// Филтрҳо: аз рӯи админ ё аз рӯи ҳадаф. «Кӣ ин корбарро баст?» маҳз
// филтри дуюм аст, ва он сабаби аслии вуҷуди ин дафтар.
func (h *AdminHandler) AuditLog(c *gin.Context) {
	limit := 100
	if n, err := strconv.Atoi(c.Query("limit")); err == nil && n > 0 && n <= 500 {
		limit = n
	}
	adminID := nullIfEmpty(c.Query("admin_id"))
	targetID := nullIfEmpty(c.Query("target_id"))

	rows, err := db.DB.Query(`SELECT a.id, a.admin_id,
			COALESCE(NULLIF(u.name,''), '—'),
			a.method, a.path, a.target_id, a.payload, a.status, a.created_at
		FROM admin_actions a
		LEFT JOIN users u ON u.id = a.admin_id
		WHERE ($1::uuid IS NULL OR a.admin_id = $1::uuid)
		  AND ($2::uuid IS NULL OR a.target_id = $2::uuid)
		ORDER BY a.created_at DESC
		LIMIT $3`, adminID, targetID, limit)
	if err != nil || rows == nil {
		utils.OK(c, []gin.H{})
		return
	}
	defer rows.Close()

	out := []gin.H{}
	for rows.Next() {
		var id, method, path, adminName string
		var admin, target, payload sql.NullString
		var status sql.NullInt64
		var createdAt time.Time
		if e := rows.Scan(&id, &admin, &adminName, &method, &path, &target,
			&payload, &status, &createdAt); e != nil {
			continue
		}
		row := gin.H{
			"id": id, "admin_name": adminName,
			"method": method, "path": path,
			"created_at": createdAt,
		}
		if admin.Valid {
			row["admin_id"] = admin.String
		}
		if target.Valid {
			row["target_id"] = target.String
		}
		if payload.Valid && payload.String != "" {
			row["payload"] = payload.String
		}
		if status.Valid {
			row["status"] = status.Int64
		}
		out = append(out, row)
	}
	utils.OK(c, out)
}

// AuditLogForUser — GET /admin/users/:id/audit  (админ)
//
// «Ба ин корбар кӣ чӣ кор кард?» — саволи аз ҳама зиёд додашаванда
// ҳангоми ихтилоф.
func (h *AdminHandler) AuditLogForUser(c *gin.Context) {
	uid := c.Param("id")
	if uid == "" {
		utils.Err(c, http.StatusBadRequest, "Корбар нишон дода нашуд")
		return
	}
	rows, err := db.DB.Query(`SELECT a.id, a.admin_id,
			COALESCE(NULLIF(u.name,''), '—'),
			a.method, a.path, a.payload, a.status, a.created_at
		FROM admin_actions a
		LEFT JOIN users u ON u.id = a.admin_id
		WHERE a.target_id = $1::uuid
		ORDER BY a.created_at DESC LIMIT 200`, uid)
	if err != nil || rows == nil {
		utils.OK(c, []gin.H{})
		return
	}
	defer rows.Close()

	out := []gin.H{}
	for rows.Next() {
		var id, method, path, adminName string
		var admin, payload sql.NullString
		var status sql.NullInt64
		var createdAt time.Time
		if e := rows.Scan(&id, &admin, &adminName, &method, &path,
			&payload, &status, &createdAt); e != nil {
			continue
		}
		row := gin.H{
			"id": id, "admin_name": adminName, "method": method,
			"path": path, "created_at": createdAt,
		}
		if admin.Valid {
			row["admin_id"] = admin.String
		}
		if payload.Valid && payload.String != "" {
			row["payload"] = payload.String
		}
		if status.Valid {
			row["status"] = status.Int64
		}
		out = append(out, row)
	}
	utils.OK(c, out)
}
