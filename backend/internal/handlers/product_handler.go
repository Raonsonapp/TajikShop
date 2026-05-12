package handlers

import (
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"tajikshop/internal/db"
	"tajikshop/internal/models"
	"tajikshop/internal/storage"
	"tajikshop/internal/utils"
)

type ProductHandler struct{ r2 *storage.R2Client }

func NewProductHandler(r2 *storage.R2Client) *ProductHandler { return &ProductHandler{r2: r2} }

func (h *ProductHandler) Create(c *gin.Context) {
	uid := utils.UserID(c)
	var in struct {
		CategoryID      string  `json:"category_id"`
		Title           string  `json:"title" binding:"required"`
		Description     string  `json:"description"`
		Price           float64 `json:"price" binding:"required,gt=0"`
		DiscountPercent int     `json:"discount_percent"`
		Stock           int     `json:"stock"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}
	// Stock default = 999 агар фиристода нашуда бошад
	if in.Stock == 0 {
		in.Stock = 999
	}
	id := uuid.NewString()
	var catID interface{}
	if in.CategoryID != "" {
		catID = in.CategoryID
	}
	_, err := db.DB.Exec(`INSERT INTO products(id,seller_id,category_id,title,description,price,discount_percent,stock,is_active)
		VALUES($1,$2,$3,$4,$5,$6,$7,$8,true)`,
		id, uid, catID, in.Title, in.Description, in.Price, in.DiscountPercent, in.Stock)
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, err.Error())
		return
	}
	utils.Created(c, gin.H{"id": id})
}

func (h *ProductHandler) List(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	search := c.Query("search")
	if search == "" {
		search = c.Query("q")
	}
	category := c.Query("category_id")
	offset := (page - 1) * limit

	query := `SELECT p.id, p.seller_id, p.category_id, p.title, p.description,
		p.price, p.discount_percent, p.stock, p.is_active, p.views, p.created_at,
		u.name as seller_name
		FROM products p JOIN users u ON u.id=p.seller_id
		WHERE p.is_active=true`
	args := []interface{}{}
	argIdx := 1

	if search != "" {
		query += fmt.Sprintf(" AND (p.title ILIKE $%d OR p.description ILIKE $%d)", argIdx, argIdx)
		args = append(args, "%"+search+"%")
		argIdx++
	}
	if category != "" {
		query += fmt.Sprintf(" AND p.category_id=$%d", argIdx)
		args = append(args, category)
		argIdx++
	}
	query += fmt.Sprintf(" ORDER BY p.created_at DESC LIMIT $%d OFFSET $%d", argIdx, argIdx+1)
	args = append(args, limit, offset)

	rows, err := db.DB.Query(query, args...)
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, err.Error())
		return
	}
	defer rows.Close()

	var products []models.Product
	for rows.Next() {
		var p models.Product
		rows.Scan(&p.ID, &p.SellerID, &p.CategoryID, &p.Title, &p.Description,
			&p.Price, &p.DiscountPercent, &p.Stock, &p.IsActive, &p.Views, &p.CreatedAt, &p.SellerName)
		p.Images = getProductImages(p.ID)
		products = append(products, p)
	}
	if products == nil {
		products = []models.Product{}
	}
	utils.OK(c, gin.H{"products": products, "page": page, "limit": limit})
}

func (h *ProductHandler) GetByID(c *gin.Context) {
	id := c.Param("id")
	var p models.Product
	err := db.DB.QueryRow(`SELECT p.id, p.seller_id, p.category_id, p.title, p.description,
		p.price, p.discount_percent, p.stock, p.is_active, p.views, p.video_url, p.created_at, u.name
		FROM products p JOIN users u ON u.id=p.seller_id WHERE p.id=$1`, id).
		Scan(&p.ID, &p.SellerID, &p.CategoryID, &p.Title, &p.Description, &p.Price,
			&p.DiscountPercent, &p.Stock, &p.IsActive, &p.Views, &p.VideoURL, &p.CreatedAt, &p.SellerName)
	if err != nil {
		utils.Err(c, http.StatusNotFound, "product not found")
		return
	}
	p.Images = getProductImages(id)
	db.DB.Exec(`UPDATE products SET views=views+1 WHERE id=$1`, id)
	utils.OK(c, p)
}

func (h *ProductHandler) Update(c *gin.Context) {
	uid := utils.UserID(c)
	id := c.Param("id")
	var in struct {
		Title           string  `json:"title"`
		Description     string  `json:"description"`
		Price           float64 `json:"price"`
		DiscountPercent int     `json:"discount_percent"`
		Stock           int     `json:"stock"`
		IsActive        bool    `json:"is_active"`
	}
	c.ShouldBindJSON(&in)
	res, err := db.DB.Exec(`UPDATE products SET title=$1, description=$2, price=$3,
		discount_percent=$4, stock=$5, is_active=$6, updated_at=$7
		WHERE id=$8 AND seller_id=$9`,
		in.Title, in.Description, in.Price, in.DiscountPercent, in.Stock, in.IsActive, time.Now(), id, uid)
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, err.Error())
		return
	}
	n, _ := res.RowsAffected()
	if n == 0 {
		utils.Err(c, http.StatusForbidden, "not your product")
		return
	}
	utils.OK(c, gin.H{"updated": true})
}

func (h *ProductHandler) Delete(c *gin.Context) {
	uid := utils.UserID(c)
	id := c.Param("id")
	res, err := db.DB.Exec(`DELETE FROM products WHERE id=$1 AND seller_id=$2`, id, uid)
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, err.Error())
		return
	}
	n, _ := res.RowsAffected()
	if n == 0 {
		utils.Err(c, http.StatusForbidden, "not your product")
		return
	}
	utils.OK(c, gin.H{"deleted": true})
}

func (h *ProductHandler) UploadImages(c *gin.Context) {
	id := c.Param("id")
	form, err := c.MultipartForm()
	if err != nil {
		utils.Err(c, http.StatusBadRequest, "multipart error")
		return
	}
	files := form.File["images"]
	var urls []string
	for i, fh := range files {
		f, _ := fh.Open()
		var url string
		if h.r2 != nil {
			url, err = h.r2.Upload(f, fh, "products")
		}
		f.Close()
		if err != nil || url == "" {
			continue
		}
		imgID := uuid.NewString()
		db.DB.Exec(`INSERT INTO product_images(id,product_id,url,position) VALUES($1,$2,$3,$4)`,
			imgID, id, url, i)
		urls = append(urls, url)
	}
	if urls == nil {
		urls = []string{}
	}
	utils.OK(c, gin.H{"urls": urls})
}

func (h *ProductHandler) Trending(c *gin.Context) {
	rows, err := db.DB.Query(`
		SELECT p.id, p.seller_id, p.category_id, p.title, p.description,
			p.price, p.discount_percent, p.stock, p.is_active, p.views, p.created_at,
			u.name as seller_name
		FROM products p
		JOIN users u ON u.id = p.seller_id
		WHERE p.is_active = true
		ORDER BY p.views DESC, p.created_at DESC
		LIMIT 20`)
	if err != nil {
		utils.OK(c, gin.H{"products": []models.Product{}})
		return
	}
	defer rows.Close()
	var products []models.Product
	for rows.Next() {
		var p models.Product
		rows.Scan(&p.ID, &p.SellerID, &p.CategoryID, &p.Title, &p.Description,
			&p.Price, &p.DiscountPercent, &p.Stock, &p.IsActive, &p.Views, &p.CreatedAt, &p.SellerName)
		p.Images = getProductImages(p.ID)
		products = append(products, p)
	}
	if products == nil {
		products = []models.Product{}
	}
	utils.OK(c, gin.H{"products": products})
}

func getProductImages(productID string) []string {
	rows, err := db.DB.Query(`SELECT url FROM product_images WHERE product_id=$1 ORDER BY position`, productID)
	if err != nil {
		return []string{}
	}
	defer rows.Close()
	var urls []string
	for rows.Next() {
		var url string
		rows.Scan(&url)
		if url != "" {
			urls = append(urls, url)
		}
	}
	if urls == nil {
		return []string{}
	}
	return urls
}
