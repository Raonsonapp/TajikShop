package handlers

import (
	"database/sql"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/lib/pq"
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
		BrandID         string  `json:"brand_id"`
		Title           string  `json:"title" binding:"required"`
		Description     string  `json:"description"`
		Price           float64 `json:"price" binding:"required,gt=0"`
		DiscountPercent int     `json:"discount_percent"`
		Stock           int     `json:"stock"`
		MinOrderQty     int     `json:"min_order_qty"`
		WholesalePrice  float64 `json:"wholesale_price"`
		DeliveryDays    int     `json:"delivery_days"`
		DeliveryPrice   float64 `json:"delivery_price"`
		SizeInfo        string  `json:"size_info"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}
	// Stock default = 999 агар фиристода нашуда бошад
	if in.Stock == 0 {
		in.Stock = 999
	}
	if in.MinOrderQty < 1 {
		in.MinOrderQty = 1
	}
	id := uuid.NewString()
	var catID, brandID interface{}
	if in.CategoryID != "" {
		catID = in.CategoryID
	}
	if in.BrandID != "" {
		brandID = in.BrandID
	}
	_, err := db.DB.Exec(`INSERT INTO products(id,seller_id,category_id,brand_id,title,description,price,discount_percent,stock,min_order_qty,wholesale_price,delivery_days,delivery_price,size_info,is_active)
		VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,true)`,
		id, uid, catID, brandID, in.Title, in.Description, in.Price, in.DiscountPercent, in.Stock, in.MinOrderQty, in.WholesalePrice, in.DeliveryDays, in.DeliveryPrice, in.SizeInfo)
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, err.Error())
		return
	}
	utils.Created(c, gin.H{"id": id})
}

func (h *ProductHandler) List(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}
	search := c.Query("search")
	if search == "" {
		search = c.Query("q")
	}
	category := c.Query("category_id")
	seller := c.Query("seller_id")
	minPrice := c.Query("min_price")
	maxPrice := c.Query("max_price")
	minRating := c.Query("min_rating")
	offset := (page - 1) * limit

	// ── WHERE (барои COUNT ва main муштарак) ──
	where := " WHERE 1=1"
	args := []interface{}{}
	argIdx := 1
	if seller != "" {
		where += fmt.Sprintf(" AND p.seller_id=$%d", argIdx)
		args = append(args, seller)
		argIdx++
		// Маҳсулоти нестшуда (soft-delete: is_active=false ва stock=0) намоиш дода намешавад.
		where += " AND NOT (p.is_active=false AND p.stock=0)"
	} else {
		// Маҳсулоти фурӯхташуда (stock=0) худ ба худ аз бозор пинҳон мешавад
		where += " AND p.is_active=true AND p.stock > 0"
	}
	for _, w := range strings.Fields(search) {
		where += fmt.Sprintf(" AND (p.title ILIKE $%d OR p.description ILIKE $%d)", argIdx, argIdx)
		args = append(args, "%"+w+"%")
		argIdx++
	}
	if category != "" {
		where += fmt.Sprintf(" AND p.category_id=$%d", argIdx)
		args = append(args, category)
		argIdx++
	}
	if v, err := strconv.ParseFloat(minPrice, 64); err == nil {
		where += fmt.Sprintf(" AND p.price >= $%d", argIdx)
		args = append(args, v)
		argIdx++
	}
	if v, err := strconv.ParseFloat(maxPrice, 64); err == nil {
		where += fmt.Sprintf(" AND p.price <= $%d", argIdx)
		args = append(args, v)
		argIdx++
	}
	if v, err := strconv.ParseFloat(minRating, 64); err == nil && v > 0 {
		where += fmt.Sprintf(" AND COALESCE((SELECT AVG(rating) FROM reviews r WHERE r.product_id=p.id),0) >= $%d", argIdx)
		args = append(args, v)
		argIdx++
	}

	// ── Шумораи умумӣ (барои pagination) ──
	var total int
	db.DB.QueryRow(`SELECT COUNT(*) FROM products p JOIN users u ON u.id=p.seller_id`+where, args...).Scan(&total)

	// ── Тартиб ──
	mainArgs := append([]interface{}{}, args...)
	orderBy := "p.created_at DESC"
	switch c.Query("sort") {
	case "price_asc":
		orderBy = "p.price ASC"
	case "price_desc":
		orderBy = "p.price DESC"
	case "popular":
		orderBy = "p.views DESC, p.created_at DESC"
	case "newest":
		orderBy = "p.created_at DESC"
	default:
		if search != "" {
			orderBy = fmt.Sprintf("(CASE WHEN p.title ILIKE $%d THEN 0 ELSE 1 END), p.views DESC, p.created_at DESC", argIdx)
			mainArgs = append(mainArgs, "%"+search+"%")
			argIdx++
		}
	}

	query := `SELECT p.id, p.seller_id, p.category_id, p.title, p.description,
		p.price, p.discount_percent, p.stock, p.is_active, p.views, p.created_at,
		u.name as seller_name, p.sale_ends_at,
		(COALESCE(p.is_featured,false) AND COALESCE(p.featured_until, NOW()) > NOW()) AS is_featured
		FROM products p JOIN users u ON u.id=p.seller_id` + where +
		" ORDER BY (COALESCE(p.is_featured,false) AND COALESCE(p.featured_until, NOW()) > NOW()) DESC, " + orderBy +
		fmt.Sprintf(" LIMIT $%d OFFSET $%d", argIdx, argIdx+1)
	mainArgs = append(mainArgs, limit, offset)

	rows, err := db.DB.Query(query, mainArgs...)
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, err.Error())
		return
	}
	defer rows.Close()

	var products []models.Product
	for rows.Next() {
		var p models.Product
		var saleEnds sql.NullTime
		rows.Scan(&p.ID, &p.SellerID, &p.CategoryID, &p.Title, &p.Description,
			&p.Price, &p.DiscountPercent, &p.Stock, &p.IsActive, &p.Views, &p.CreatedAt, &p.SellerName, &saleEnds, &p.IsFeatured)
		if saleEnds.Valid {
			p.SaleEndsAt = &saleEnds.Time
		}
		products = append(products, p)
	}
	if products == nil {
		products = []models.Product{}
	}
	fillImages(products) // batch — 1 query ба ҷои N
	utils.OK(c, gin.H{
		"products": products,
		"page":     page,
		"limit":    limit,
		"total":    total,
		"has_more": offset+len(products) < total,
	})
}

func (h *ProductHandler) GetByID(c *gin.Context) {
	id := c.Param("id")
	var p models.Product
	var brandID, brandName sql.NullString
	var moq int
	var wholesale float64
	var saleEnds sql.NullTime
	err := db.DB.QueryRow(`SELECT p.id, p.seller_id, p.category_id, p.title, p.description,
		p.price, p.discount_percent, p.stock, p.is_active, p.views, p.video_url, p.created_at, u.name,
		COALESCE(u.is_verified,false),
		p.brand_id, COALESCE(p.min_order_qty,1), COALESCE(p.wholesale_price,0), b.name, p.sale_ends_at,
		COALESCE(p.delivery_days,0), COALESCE(p.delivery_price,0), COALESCE(p.size_info,'')
		FROM products p JOIN users u ON u.id=p.seller_id
		LEFT JOIN brands b ON b.id=p.brand_id WHERE p.id=$1`, id).
		Scan(&p.ID, &p.SellerID, &p.CategoryID, &p.Title, &p.Description, &p.Price,
			&p.DiscountPercent, &p.Stock, &p.IsActive, &p.Views, &p.VideoURL, &p.CreatedAt, &p.SellerName,
			&p.SellerVerified,
			&brandID, &moq, &wholesale, &brandName, &saleEnds,
			&p.DeliveryDays, &p.DeliveryPrice, &p.SizeInfo)
	if err != nil {
		utils.Err(c, http.StatusNotFound, "product not found")
		return
	}
	p.Images = getProductImages(id)
	p.BrandID = brandID.String
	p.BrandName = brandName.String
	p.MinOrderQty = moq
	p.WholesalePrice = wholesale
	if saleEnds.Valid {
		p.SaleEndsAt = &saleEnds.Time
	}
	p.Variants = getProductVariants(id)
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
		SaleHours       int     `json:"sale_hours"` // >0 = flash sale то N соат; <0 = бекор
		DeliveryDays    int     `json:"delivery_days"`
		DeliveryPrice   float64 `json:"delivery_price"`
		SizeInfo        string  `json:"size_info"`
	}
	c.ShouldBindJSON(&in)
	res, err := db.DB.Exec(`UPDATE products SET title=$1, description=$2, price=$3,
		discount_percent=$4, stock=$5, is_active=$6,
		delivery_days=$7, delivery_price=$8, size_info=$9, updated_at=$10
		WHERE id=$11 AND seller_id=$12`,
		in.Title, in.Description, in.Price, in.DiscountPercent, in.Stock, in.IsActive,
		in.DeliveryDays, in.DeliveryPrice, in.SizeInfo, time.Now(), id, uid)
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, err.Error())
		return
	}
	n, _ := res.RowsAffected()
	if n == 0 {
		utils.Err(c, http.StatusForbidden, "not your product")
		return
	}
	// Flash sale
	if in.SaleHours > 0 {
		db.DB.Exec(`UPDATE products SET sale_ends_at = NOW() + ($1 * INTERVAL '1 hour') WHERE id=$2 AND seller_id=$3`,
			in.SaleHours, id, uid)
	} else if in.SaleHours < 0 {
		db.DB.Exec(`UPDATE products SET sale_ends_at = NULL WHERE id=$1 AND seller_id=$2`, id, uid)
	}
	utils.OK(c, gin.H{"updated": true})
}

// Boost — маҳсулотро ба сари рӯйхат мебарорад (реклама, 7 рӯз). Хусусияти Pro.
func (h *ProductHandler) Boost(c *gin.Context) {
	uid := utils.UserID(c)
	id := c.Param("id")
	res, err := db.DB.Exec(`UPDATE products SET is_featured=true, featured_until=NOW()+INTERVAL '7 days', updated_at=NOW()
		WHERE id=$1 AND seller_id=$2`, id, uid)
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, err.Error())
		return
	}
	if n, _ := res.RowsAffected(); n == 0 {
		utils.Err(c, http.StatusForbidden, "not your product")
		return
	}
	utils.OK(c, gin.H{"boosted": true, "days": 7})
}

func (h *ProductHandler) Delete(c *gin.Context) {
	uid := utils.UserID(c)
	id := c.Param("id")
	// Агар маҳсулот дар фармоишҳо бошад, hard-delete мумкин нест (order_items RESTRICT,
	// таърихи фармоишҳо бояд эмин монад) — пас soft-delete: аз бозор ва рӯйхати фурӯшанда
	// пинҳон мешавад (is_active=false, stock=0). Вагарна пурра нест мешавад.
	var ordered bool
	db.DB.QueryRow(`SELECT EXISTS(SELECT 1 FROM order_items WHERE product_id=$1)`, id).Scan(&ordered)
	var res sql.Result
	var err error
	if ordered {
		res, err = db.DB.Exec(`UPDATE products SET is_active=false, stock=0, updated_at=$1 WHERE id=$2 AND seller_id=$3`,
			time.Now(), id, uid)
	} else {
		res, err = db.DB.Exec(`DELETE FROM products WHERE id=$1 AND seller_id=$2`, id, uid)
	}
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

// FlashDeals — маҳсулоти тахфифдор бо мӯҳлати маҳдуд (sale_ends_at дар оянда).
// Аввал онҳое ки зудтар тамом мешаванд. GET /products/flash
func (h *ProductHandler) FlashDeals(c *gin.Context) {
	rows, err := db.DB.Query(`
		SELECT p.id, p.seller_id, p.category_id, p.title, p.description,
			p.price, p.discount_percent, p.stock, p.is_active, p.views, p.created_at,
			u.name as seller_name, p.sale_ends_at
		FROM products p
		JOIN users u ON u.id = p.seller_id
		WHERE p.is_active = true AND p.stock > 0
			AND p.discount_percent > 0
			AND p.sale_ends_at IS NOT NULL AND p.sale_ends_at > NOW()
		ORDER BY p.sale_ends_at ASC
		LIMIT 20`)
	if err != nil {
		utils.OK(c, gin.H{"products": []models.Product{}})
		return
	}
	defer rows.Close()
	var products []models.Product
	for rows.Next() {
		var p models.Product
		var saleEnds sql.NullTime
		rows.Scan(&p.ID, &p.SellerID, &p.CategoryID, &p.Title, &p.Description,
			&p.Price, &p.DiscountPercent, &p.Stock, &p.IsActive, &p.Views, &p.CreatedAt, &p.SellerName, &saleEnds)
		if saleEnds.Valid {
			p.SaleEndsAt = &saleEnds.Time
		}
		products = append(products, p)
	}
	if products == nil {
		products = []models.Product{}
	}
	fillImages(products)
	utils.OK(c, gin.H{"products": products})
}

// Deals — ҳамаи маҳсулоти тахфифдор (discount_percent > 0), новобаста ба мӯҳлат.
// Аввал онҳое ки тахфифи бештар доранд. GET /products/deals
func (h *ProductHandler) Deals(c *gin.Context) {
	rows, err := db.DB.Query(`
		SELECT p.id, p.seller_id, p.category_id, p.title, p.description,
			p.price, p.discount_percent, p.stock, p.is_active, p.views, p.created_at,
			u.name as seller_name, p.sale_ends_at
		FROM products p
		JOIN users u ON u.id = p.seller_id
		WHERE p.is_active = true AND p.stock > 0 AND p.discount_percent > 0
		ORDER BY p.discount_percent DESC, p.views DESC
		LIMIT 60`)
	if err != nil {
		utils.OK(c, gin.H{"products": []models.Product{}})
		return
	}
	defer rows.Close()
	var products []models.Product
	for rows.Next() {
		var p models.Product
		var saleEnds sql.NullTime
		rows.Scan(&p.ID, &p.SellerID, &p.CategoryID, &p.Title, &p.Description,
			&p.Price, &p.DiscountPercent, &p.Stock, &p.IsActive, &p.Views, &p.CreatedAt, &p.SellerName, &saleEnds)
		if saleEnds.Valid {
			p.SaleEndsAt = &saleEnds.Time
		}
		products = append(products, p)
	}
	if products == nil {
		products = []models.Product{}
	}
	fillImages(products)
	utils.OK(c, gin.H{"products": products})
}

// Bestsellers — маҳсулоти аз ҳама бештар фурӯхташуда (аз рӯи миқдори фурӯш).
// GET /products/bestsellers
func (h *ProductHandler) Bestsellers(c *gin.Context) {
	rows, err := db.DB.Query(`
		SELECT p.id, p.seller_id, p.category_id, p.title, p.description,
			p.price, p.discount_percent, p.stock, p.is_active, p.views, p.created_at,
			u.name as seller_name, p.sale_ends_at
		FROM products p
		JOIN users u ON u.id = p.seller_id
		LEFT JOIN order_items oi ON oi.product_id = p.id
		WHERE p.is_active = true AND p.stock > 0
		GROUP BY p.id, u.name
		HAVING COALESCE(SUM(oi.quantity),0) > 0
		ORDER BY COALESCE(SUM(oi.quantity),0) DESC, p.views DESC
		LIMIT 40`)
	if err != nil {
		utils.OK(c, gin.H{"products": []models.Product{}})
		return
	}
	defer rows.Close()
	var products []models.Product
	for rows.Next() {
		var p models.Product
		var saleEnds sql.NullTime
		rows.Scan(&p.ID, &p.SellerID, &p.CategoryID, &p.Title, &p.Description,
			&p.Price, &p.DiscountPercent, &p.Stock, &p.IsActive, &p.Views, &p.CreatedAt, &p.SellerName, &saleEnds)
		if saleEnds.Valid {
			p.SaleEndsAt = &saleEnds.Time
		}
		products = append(products, p)
	}
	if products == nil {
		products = []models.Product{}
	}
	fillImages(products)
	utils.OK(c, gin.H{"products": products})
}

func (h *ProductHandler) Trending(c *gin.Context) {
	rows, err := db.DB.Query(`
		SELECT p.id, p.seller_id, p.category_id, p.title, p.description,
			p.price, p.discount_percent, p.stock, p.is_active, p.views, p.created_at,
			u.name as seller_name
		FROM products p
		JOIN users u ON u.id = p.seller_id
		WHERE p.is_active = true AND p.stock > 0
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
		products = append(products, p)
	}
	if products == nil {
		products = []models.Product{}
	}
	fillImages(products) // batch — 1 query ба ҷои N
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

// getProductImagesBatch — расмҳои ҳамаи маҳсулотро дар ЯК query мегирад (N+1-ро бартараф мекунад)
func getProductImagesBatch(ids []string) map[string][]string {
	out := map[string][]string{}
	if len(ids) == 0 {
		return out
	}
	rows, err := db.DB.Query(`SELECT product_id, url FROM product_images
		WHERE product_id = ANY($1) ORDER BY position`, pq.Array(ids))
	if err != nil {
		return out
	}
	defer rows.Close()
	for rows.Next() {
		var pid, url string
		rows.Scan(&pid, &url)
		if url != "" {
			out[pid] = append(out[pid], url)
		}
	}
	return out
}

// fillImages — Images-и ҳар маҳсулотро аз харита пур мекунад
func fillImages(products []models.Product) {
	ids := make([]string, len(products))
	for i := range products {
		ids[i] = products[i].ID
	}
	imgs := getProductImagesBatch(ids)
	for i := range products {
		if v, ok := imgs[products[i].ID]; ok {
			products[i].Images = v
		} else {
			products[i].Images = []string{}
		}
	}
}
