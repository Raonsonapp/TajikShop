package handlers

import (
	"net/http"

	"tajikshop/internal/db"
	"tajikshop/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// ========== BRANDS ==========

type BrandHandler struct{}

func NewBrandHandler() *BrandHandler { return &BrandHandler{} }

func (h *BrandHandler) List(c *gin.Context) {
	rows, _ := db.DB.Query(`SELECT id,name,slug,COALESCE(logo_url,'') FROM brands ORDER BY name`)
	defer rows.Close()
	type brand struct {
		ID   string `json:"id"`
		Name string `json:"name"`
		Slug string `json:"slug"`
		Logo string `json:"logo_url"`
	}
	var list []brand
	for rows.Next() {
		var b brand
		rows.Scan(&b.ID, &b.Name, &b.Slug, &b.Logo)
		list = append(list, b)
	}
	if list == nil {
		list = []brand{}
	}
	utils.OK(c, list)
}

func (h *BrandHandler) Create(c *gin.Context) {
	var in struct {
		Name string `json:"name" binding:"required"`
		Slug string `json:"slug" binding:"required"`
		Logo string `json:"logo_url"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}
	id := uuid.NewString()
	_, err := db.DB.Exec(`INSERT INTO brands(id,name,slug,logo_url) VALUES($1,$2,LOWER($3),$4)`,
		id, in.Name, in.Slug, in.Logo)
	if err != nil {
		utils.Err(c, http.StatusBadRequest, "бренд сохта нашуд (шояд такрорӣ)")
		return
	}
	utils.Created(c, gin.H{"id": id})
}

// ========== PRODUCT VARIANTS ==========

type VariantHandler struct{}

func NewVariantHandler() *VariantHandler { return &VariantHandler{} }

type variantOut struct {
	ID    string  `json:"id"`
	Size  string  `json:"size"`
	Color string  `json:"color"`
	SKU   string  `json:"sku"`
	Price float64 `json:"price"`
	Stock int     `json:"stock"`
}

// getProductVariants — барои дохил кардан ба маҳсулот истифода мешавад
func getProductVariants(productID string) []variantOut {
	rows, err := db.DB.Query(`SELECT id,size,color,sku,price,stock FROM product_variants
		WHERE product_id=$1 ORDER BY created_at`, productID)
	if err != nil {
		return []variantOut{}
	}
	defer rows.Close()
	var list []variantOut
	for rows.Next() {
		var v variantOut
		rows.Scan(&v.ID, &v.Size, &v.Color, &v.SKU, &v.Price, &v.Stock)
		list = append(list, v)
	}
	if list == nil {
		return []variantOut{}
	}
	return list
}

func (h *VariantHandler) ByProduct(c *gin.Context) {
	utils.OK(c, getProductVariants(c.Param("id")))
}

func (h *VariantHandler) Add(c *gin.Context) {
	uid := utils.UserID(c)
	pid := c.Param("id")
	// тасдиқи моликият
	var ownerID string
	if err := db.DB.QueryRow(`SELECT seller_id FROM products WHERE id=$1`, pid).Scan(&ownerID); err != nil || ownerID != uid {
		utils.Err(c, http.StatusForbidden, "маҳсулоти шумо нест")
		return
	}
	var in struct {
		Size  string  `json:"size"`
		Color string  `json:"color"`
		SKU   string  `json:"sku"`
		Price float64 `json:"price"`
		Stock int     `json:"stock"`
	}
	c.ShouldBindJSON(&in)
	id := uuid.NewString()
	db.DB.Exec(`INSERT INTO product_variants(id,product_id,size,color,sku,price,stock)
		VALUES($1,$2,$3,$4,$5,$6,$7)`, id, pid, in.Size, in.Color, in.SKU, in.Price, in.Stock)
	utils.Created(c, gin.H{"id": id})
}

func (h *VariantHandler) Delete(c *gin.Context) {
	uid := utils.UserID(c)
	vid := c.Param("id")
	db.DB.Exec(`DELETE FROM product_variants WHERE id=$1 AND product_id IN
		(SELECT id FROM products WHERE seller_id=$2)`, vid, uid)
	utils.OK(c, gin.H{"deleted": true})
}
