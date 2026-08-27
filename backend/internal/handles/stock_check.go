package handlers

import (
	"net/http"
	"strings"
	"tajikshop/internal/db"
	"tajikshop/internal/utils"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// ── Маҳсулоти тамомшуда ─────────────────────────────────────────────────────
//
// Пештар маҳсулоти тамомшуда дар барнома ҳамчун «Тамом шуд» меистод ва ҳеҷ гоҳ
// нест намешуд. Акнун ҳамин ки захира ба сифр мерасад, аз фурӯшанда пурсида
// мешавад: «Ин маҳсулот боз ҳаст?»
//
//	Ҳа  → шумораи навро мегӯяд, маҳсулот ба бозор бармегардад;
//	Не  → маҳсулот худ ба худ нест мешавад (soft-delete).
//
// Маҳсулот бе ҷавоби фурӯшанда ҳеҷ гоҳ нест намешавад — нест кардани чизи
// каси дигар бе пурсидан мумкин нест.

// notifySoldOut — ҳангоми ба сифр расидани захира фурӯшандаро огоҳ мекунад.
// Пас аз ҳар фармоиш барои маҳсулоти фурӯхташуда даъват мешавад.
func notifySoldOut(productID string) {
	var sellerID, title string
	var stock int
	var active bool
	err := db.DB.QueryRow(`SELECT seller_id, COALESCE(title,''), stock, COALESCE(is_active,true)
		FROM products WHERE id=$1`, productID).Scan(&sellerID, &title, &stock, &active)
	if err != nil || stock > 0 || !active || sellerID == "" {
		return
	}

	// Огоҳии такрориро намефиристем — фурӯшанда як бор мепурсад, бас.
	var already bool
	db.DB.QueryRow(`SELECT EXISTS(SELECT 1 FROM notifications
		WHERE user_id=$1 AND type='stock' AND ref_id=$2 AND created_at > NOW() - INTERVAL '3 days')`,
		sellerID, productID).Scan(&already)
	if already {
		return
	}

	body := "«" + title + "» тамом шуд. Оё боз ҳаст?"
	db.DB.Exec(`INSERT INTO notifications(id,user_id,type,title,body,ref_id)
		VALUES($1,$2,'stock','Маҳсулот тамом шуд',$3,$4)`,
		uuid.NewString(), sellerID, body, productID)
	pushToUser(sellerID, "Маҳсулот тамом шуд", body)
}

// SoldOutProducts — GET /seller/products/sold-out
// Маҳсулоти фурӯшанда, ки захирааш сифр аст ва ҳанӯз нест нашудааст.
func (h *ProductHandler) SoldOutProducts(c *gin.Context) {
	uid := utils.UserID(c)
	rows, err := db.DB.Query(`SELECT p.id, COALESCE(p.title,''), p.price,
			COALESCE((SELECT url FROM product_images WHERE product_id=p.id
				ORDER BY position LIMIT 1),''),
			p.updated_at
		FROM products p
		WHERE p.seller_id=$1 AND p.stock=0 AND COALESCE(p.is_active,true)=true
		ORDER BY p.updated_at DESC LIMIT 100`, uid)
	if err != nil || rows == nil {
		utils.OK(c, []gin.H{})
		return
	}
	defer rows.Close()

	out := []gin.H{}
	for rows.Next() {
		var id, title, image string
		var price float64
		var updated time.Time
		if e := rows.Scan(&id, &title, &price, &image, &updated); e != nil {
			continue
		}
		out = append(out, gin.H{
			"id": id, "title": title, "price": price,
			"image": image, "updated_at": updated,
		})
	}
	utils.OK(c, out)
}

// Restock — POST /seller/products/:id/restock  {stock}
// «Ҳа, боз ҳаст» — маҳсулот бо шумораи нав ба бозор бармегардад.
func (h *ProductHandler) Restock(c *gin.Context) {
	uid := utils.UserID(c)
	id := c.Param("id")

	var in struct {
		Stock int `json:"stock"`
	}
	c.ShouldBindJSON(&in)
	if in.Stock < 1 {
		in.Stock = 1
	}
	if in.Stock > 100000 {
		in.Stock = 100000
	}

	res, err := db.DB.Exec(`UPDATE products SET stock=$1, is_active=true, updated_at=$2
		WHERE id=$3 AND seller_id=$4`, in.Stock, time.Now(), id, uid)
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, "restock failed")
		return
	}
	if n, _ := res.RowsAffected(); n == 0 {
		utils.Err(c, http.StatusNotFound, "product not found")
		return
	}

	// Огоҳии «тамом шуд» дигар лозим нест.
	db.DB.Exec(`DELETE FROM notifications WHERE type='stock' AND ref_id=$1 AND user_id=$2`, id, uid)
	utils.OK(c, gin.H{"id": id, "stock": in.Stock})
}

// cleanupDeadReferences — маҳсулоти нестшударо аз сабад ва дӯстдоштаҳо
// мебарорад, то харидор ба саҳифаи «Чизе нодуруст рафт» нахӯрад.
func cleanupDeadReferences(productID string) {
	if strings.TrimSpace(productID) == "" {
		return
	}
	db.DB.Exec(`DELETE FROM cart_items WHERE product_id=$1`, productID)
	db.DB.Exec(`DELETE FROM favorites WHERE product_id=$1`, productID)
}
