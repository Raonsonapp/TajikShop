package handlers

import (
	"net/http"
	"strconv"
	"time"

	"tajikshop/internal/db"
	"tajikshop/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// ═══════════════════════════════════════════════════════════════════════════
//  Карго — доставка аз Хитой → Тоҷикистон / Русия (хизматрасонии шарик).
// ═══════════════════════════════════════════════════════════════════════════

type CargoHandler struct{}

func NewCargoHandler() *CargoHandler { return &CargoHandler{} }

func settingStr(key, def string) string {
	var v string
	if err := db.DB.QueryRow(`SELECT value FROM settings WHERE key=$1`, key).Scan(&v); err == nil && v != "" {
		return v
	}
	return def
}

func cargoRate(dest string) float64 {
	key := "cargo_rate_tj"
	if dest == "ru" {
		key = "cargo_rate_ru"
	}
	if f, e := strconv.ParseFloat(settingStr(key, "0"), 64); e == nil {
		return f
	}
	return 0
}

// Info — суроғаи анбори Хитой + тарифҳо (сом/кг) + телефони шарик. GET /cargo/info
func (h *CargoHandler) Info(c *gin.Context) {
	utils.OK(c, gin.H{
		"warehouse": settingStr("cargo_warehouse", ""),
		"rate_tj":   cargoRate("tj"),
		"rate_ru":   cargoRate("ru"),
		"phone":     settingStr("cargo_phone", ""),
	})
}

// Create — дархости интиқол. POST /cargo
func (h *CargoHandler) Create(c *gin.Context) {
	uid := utils.UserID(c)
	var in struct {
		ProductLink string `json:"product_link"`
		Description string `json:"description" binding:"required"`
		Destination string `json:"destination"`
		TrackCode   string `json:"track_code"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}
	dest := "tj"
	if in.Destination == "ru" {
		dest = "ru"
	}
	id := uuid.NewString()
	_, err := db.DB.Exec(`INSERT INTO cargo_orders(id,user_id,product_link,description,destination,track_code,status)
		VALUES($1,$2,$3,$4,$5,$6,'new')`,
		id, uid, in.ProductLink, in.Description, dest, in.TrackCode)
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, err.Error())
		return
	}
	notifyAdmins("cargo", "Дархости карго", "Дархости нави доставка аз Хитой", id)
	utils.Created(c, gin.H{"id": id})
}

func scanCargo(rows interface {
	Scan(...interface{}) error
}) gin.H {
	var id, track, link, desc, dest, status, note string
	var weight, cost float64
	var createdAt, updatedAt time.Time
	rows.Scan(&id, &track, &link, &desc, &dest, &weight, &cost, &status, &note, &createdAt, &updatedAt)
	return gin.H{
		"id": id, "track_code": track, "product_link": link, "description": desc,
		"destination": dest, "weight": weight, "cost": cost, "status": status,
		"note": note, "created_at": createdAt, "updated_at": updatedAt,
	}
}

const cargoCols = `id,track_code,product_link,description,destination,weight,cost,status,note,created_at,updated_at`

// MyList — посылкаҳои корбари ҷорӣ. GET /cargo
func (h *CargoHandler) MyList(c *gin.Context) {
	uid := utils.UserID(c)
	rows, _ := db.DB.Query(`SELECT `+cargoCols+` FROM cargo_orders WHERE user_id=$1 ORDER BY created_at DESC`, uid)
	defer rows.Close()
	out := []gin.H{}
	for rows.Next() {
		out = append(out, scanCargo(rows))
	}
	utils.OK(c, out)
}

// AdminList — ҳамаи дархостҳои карго (барои шарик/админ). GET /admin/cargo
func (h *CargoHandler) AdminList(c *gin.Context) {
	rows, _ := db.DB.Query(`SELECT ` + cargoCols + ` FROM cargo_orders ORDER BY
		CASE status WHEN 'new' THEN 0 WHEN 'received' THEN 1 WHEN 'shipped' THEN 2
			WHEN 'arrived' THEN 3 ELSE 4 END, created_at DESC LIMIT 200`)
	defer rows.Close()
	out := []gin.H{}
	for rows.Next() {
		out = append(out, scanCargo(rows))
	}
	utils.OK(c, out)
}

// AdminUpdate — навсозии track/вазн/арзиш/статус аз тарафи шарик. PATCH /admin/cargo/:id
func (h *CargoHandler) AdminUpdate(c *gin.Context) {
	id := c.Param("id")
	var in struct {
		TrackCode string  `json:"track_code"`
		Weight    float64 `json:"weight"`
		Status    string  `json:"status"`
		Note      string  `json:"note"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}
	var dest string
	var ownerID string
	db.DB.QueryRow(`SELECT destination,user_id FROM cargo_orders WHERE id=$1`, id).Scan(&dest, &ownerID)
	cost := in.Weight * cargoRate(dest) // арзиш = вазн × тарифи самт
	_, err := db.DB.Exec(`UPDATE cargo_orders SET
		track_code=COALESCE(NULLIF($1,''),track_code),
		weight=$2, cost=$3,
		status=COALESCE(NULLIF($4,''),status),
		note=$5, updated_at=NOW() WHERE id=$6`,
		in.TrackCode, in.Weight, cost, in.Status, in.Note, id)
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, err.Error())
		return
	}
	if ownerID != "" && in.Status != "" {
		db.DB.Exec(`INSERT INTO notifications(id,user_id,type,title,body)
			VALUES($1,$2,'cargo','Карго нав шуд',$3)`,
			uuid.NewString(), ownerID, "Ҳолати посылкаи шумо: "+cargoStatusTg(in.Status))
		pushToUser(ownerID, "Карго нав шуд", "Ҳолати посылкаи шумо: "+cargoStatusTg(in.Status))
	}
	utils.OK(c, gin.H{"updated": true})
}

func cargoStatusTg(s string) string {
	switch s {
	case "new":
		return "Қабул шуд"
	case "received":
		return "Ба анбори Хитой расид"
	case "shipped":
		return "Фиристода шуд"
	case "arrived":
		return "Ба кишвар расид"
	case "delivered":
		return "Супорида шуд"
	default:
		return s
	}
}
