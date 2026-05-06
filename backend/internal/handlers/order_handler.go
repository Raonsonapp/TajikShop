package handlers

import (
	"net/http"
	"tajikshop/internal/db"
	"tajikshop/internal/models"
	"tajikshop/internal/storage"
	"tajikshop/internal/utils"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type OrderHandler struct {
	r2 *storage.R2Client
}

func NewOrderHandler(r2 *storage.R2Client) *OrderHandler {
	return &OrderHandler{r2: r2}
}

// ========== CART ==========

func (h *OrderHandler) GetCart(c *gin.Context) {
	uid := utils.UserID(c)
	rows, err := db.DB.Query(`SELECT ci.id,ci.product_id,ci.quantity,p.title,p.price FROM cart_items ci
		JOIN products p ON p.id=ci.product_id WHERE ci.user_id=$1`, uid)
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, err.Error())
		return
	}
	defer rows.Close()
	type CartRow struct {
		ID        string  `json:"id"`
		ProductID string  `json:"product_id"`
		Quantity  int     `json:"quantity"`
		Title     string  `json:"title"`
		Price     float64 `json:"price"`
	}
	var items []CartRow
	for rows.Next() {
		var item CartRow
		rows.Scan(&item.ID, &item.ProductID, &item.Quantity, &item.Title, &item.Price)
		items = append(items, item)
	}
	if items == nil {
		items = []CartRow{}
	}
	utils.OK(c, items)
}

func (h *OrderHandler) AddToCart(c *gin.Context) {
	uid := utils.UserID(c)
	var in struct {
		ProductID string `json:"product_id" binding:"required"`
		Quantity  int    `json:"quantity"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}
	if in.Quantity == 0 {
		in.Quantity = 1
	}
	id := uuid.NewString()
	db.DB.Exec(`INSERT INTO cart_items(id,user_id,product_id,quantity) VALUES($1,$2,$3,$4)
		ON CONFLICT(user_id,product_id) DO UPDATE SET quantity=cart_items.quantity+$4`,
		id, uid, in.ProductID, in.Quantity)
	utils.OK(c, gin.H{"message": "added to cart"})
}

func (h *OrderHandler) RemoveFromCart(c *gin.Context) {
	uid := utils.UserID(c)
	itemID := c.Param("id")
	db.DB.Exec(`DELETE FROM cart_items WHERE id=$1 AND user_id=$2`, itemID, uid)
	utils.OK(c, gin.H{"message": "removed"})
}

// ========== ORDERS ==========

func (h *OrderHandler) Checkout(c *gin.Context) {
	uid := utils.UserID(c)
	var in struct {
		AddressID string `json:"address_id"`
		Note      string `json:"note"`
	}
	c.ShouldBindJSON(&in)

	rows, err := db.DB.Query(`SELECT ci.product_id,ci.quantity,p.price FROM cart_items ci
		JOIN products p ON p.id=ci.product_id WHERE ci.user_id=$1`, uid)
	if err != nil || rows == nil {
		utils.Err(c, http.StatusBadRequest, "cart is empty")
		return
	}
	defer rows.Close()

	type item struct {
		ProductID string
		Qty       int
		Price     float64
	}
	var items []item
	var total float64
	for rows.Next() {
		var i item
		rows.Scan(&i.ProductID, &i.Qty, &i.Price)
		items = append(items, i)
		total += i.Price * float64(i.Qty)
	}
	if len(items) == 0 {
		utils.Err(c, http.StatusBadRequest, "cart is empty")
		return
	}

	orderID := uuid.NewString()
	db.DB.Exec(`INSERT INTO orders(id,user_id,address_id,total,note) VALUES($1,$2,$3,$4,$5)`,
		orderID, uid, in.AddressID, total, in.Note)

	for _, i := range items {
		db.DB.Exec(`INSERT INTO order_items(id,order_id,product_id,quantity,price) VALUES($1,$2,$3,$4,$5)`,
			uuid.NewString(), orderID, i.ProductID, i.Qty, i.Price)
	}
	db.DB.Exec(`DELETE FROM cart_items WHERE user_id=$1`, uid)

	utils.Created(c, gin.H{"order_id": orderID, "total": total})
}

func (h *OrderHandler) MyOrders(c *gin.Context) {
	uid := utils.UserID(c)
	rows, _ := db.DB.Query(`SELECT id,status,total,created_at FROM orders WHERE user_id=$1 ORDER BY created_at DESC`, uid)
	defer rows.Close()
	var orders []models.Order
	for rows.Next() {
		var o models.Order
		rows.Scan(&o.ID, &o.Status, &o.Total, &o.CreatedAt)
		orders = append(orders, o)
	}
	if orders == nil {
		orders = []models.Order{}
	}
	utils.OK(c, orders)
}

func (h *OrderHandler) GetOrder(c *gin.Context) {
	uid := utils.UserID(c)
	oid := c.Param("id")
	var o models.Order
	err := db.DB.QueryRow(`SELECT id,user_id,address_id,status,total,note,payment_proof,created_at FROM orders WHERE id=$1 AND user_id=$2`,
		oid, uid).Scan(&o.ID, &o.UserID, &o.AddressID, &o.Status, &o.Total, &o.Note, &o.PaymentProof, &o.CreatedAt)
	if err != nil {
		utils.Err(c, http.StatusNotFound, "order not found")
		return
	}
	rows, _ := db.DB.Query(`SELECT id,product_id,quantity,price FROM order_items WHERE order_id=$1`, oid)
	defer rows.Close()
	for rows.Next() {
		var i models.OrderItem
		rows.Scan(&i.ID, &i.ProductID, &i.Quantity, &i.Price)
		o.Items = append(o.Items, i)
	}
	utils.OK(c, o)
}

func (h *OrderHandler) UploadPaymentProof(c *gin.Context) {
	uid := utils.UserID(c)
	oid := c.Param("id")
	file, header, err := c.Request.FormFile("proof")
	if err != nil {
		utils.Err(c, http.StatusBadRequest, "file required")
		return
	}
	defer file.Close()
	url, err := h.r2.Upload(file, header, "payment_proofs")
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, err.Error())
		return
	}
	db.DB.Exec(`UPDATE orders SET payment_proof=$1,status='payment_uploaded',updated_at=$2 WHERE id=$3 AND user_id=$4`,
		url, time.Now(), oid, uid)
	utils.OK(c, gin.H{"proof_url": url})
}

// ========== REVIEWS ==========

type ReviewHandler struct{}

func NewReviewHandler() *ReviewHandler { return &ReviewHandler{} }

func (h *ReviewHandler) Create(c *gin.Context) {
	uid := utils.UserID(c)
	var in struct {
		ProductID string `json:"product_id" binding:"required"`
		Rating    int    `json:"rating" binding:"required,min=1,max=5"`
		Comment   string `json:"comment"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}
	id := uuid.NewString()
	_, err := db.DB.Exec(`INSERT INTO reviews(id,user_id,product_id,rating,comment) VALUES($1,$2,$3,$4,$5)
		ON CONFLICT(user_id,product_id) DO UPDATE SET rating=$4,comment=$5`,
		id, uid, in.ProductID, in.Rating, in.Comment)
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, err.Error())
		return
	}
	utils.Created(c, gin.H{"id": id})
}

func (h *ReviewHandler) ByProduct(c *gin.Context) {
	pid := c.Param("product_id")
	rows, _ := db.DB.Query(`SELECT r.id,r.rating,r.comment,r.created_at,u.name FROM reviews r
		JOIN users u ON u.id=r.user_id WHERE r.product_id=$1 ORDER BY r.created_at DESC`, pid)
	defer rows.Close()
	var reviews []models.Review
	for rows.Next() {
		var r models.Review
		rows.Scan(&r.ID, &r.Rating, &r.Comment, &r.CreatedAt, &r.UserName)
		reviews = append(reviews, r)
	}
	if reviews == nil {
		reviews = []models.Review{}
	}
	utils.OK(c, reviews)
}

// ========== FAVORITES ==========

type FavoriteHandler struct{}

func NewFavoriteHandler() *FavoriteHandler { return &FavoriteHandler{} }

func (h *FavoriteHandler) Add(c *gin.Context) {
	uid := utils.UserID(c)
	var in struct {
		ProductID string `json:"product_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}
	db.DB.Exec(`INSERT INTO favorites(id,user_id,product_id) VALUES($1,$2,$3) ON CONFLICT DO NOTHING`,
		uuid.NewString(), uid, in.ProductID)
	utils.OK(c, gin.H{"message": "favorited"})
}

func (h *FavoriteHandler) Remove(c *gin.Context) {
	uid := utils.UserID(c)
	pid := c.Param("product_id")
	db.DB.Exec(`DELETE FROM favorites WHERE user_id=$1 AND product_id=$2`, uid, pid)
	utils.OK(c, gin.H{"message": "removed"})
}

func (h *FavoriteHandler) List(c *gin.Context) {
	uid := utils.UserID(c)
	rows, _ := db.DB.Query(`SELECT p.id,p.title,p.price FROM favorites f
		JOIN products p ON p.id=f.product_id WHERE f.user_id=$1`, uid)
	defer rows.Close()
	var products []models.Product
	for rows.Next() {
		var p models.Product
		rows.Scan(&p.ID, &p.Title, &p.Price)
		products = append(products, p)
	}
	if products == nil {
		products = []models.Product{}
	}
	utils.OK(c, products)
}

// ========== ADDRESSES ==========

type AddressHandler struct{}

func NewAddressHandler() *AddressHandler { return &AddressHandler{} }

func (h *AddressHandler) Create(c *gin.Context) {
	uid := utils.UserID(c)
	var in struct {
		Title  string `json:"title" binding:"required"`
		City   string `json:"city" binding:"required"`
		Street string `json:"street" binding:"required"`
		Zip    string `json:"zip"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}
	id := uuid.NewString()
	db.DB.Exec(`INSERT INTO addresses(id,user_id,title,city,street,zip) VALUES($1,$2,$3,$4,$5,$6)`,
		id, uid, in.Title, in.City, in.Street, in.Zip)
	utils.Created(c, gin.H{"id": id})
}

func (h *AddressHandler) List(c *gin.Context) {
	uid := utils.UserID(c)
	rows, _ := db.DB.Query(`SELECT id,title,city,street,zip,is_default FROM addresses WHERE user_id=$1`, uid)
	defer rows.Close()
	var addrs []models.Address
	for rows.Next() {
		var a models.Address
		rows.Scan(&a.ID, &a.Title, &a.City, &a.Street, &a.Zip, &a.IsDefault)
		addrs = append(addrs, a)
	}
	if addrs == nil {
		addrs = []models.Address{}
	}
	utils.OK(c, addrs)
}

func (h *AddressHandler) Delete(c *gin.Context) {
	uid := utils.UserID(c)
	id := c.Param("id")
	db.DB.Exec(`DELETE FROM addresses WHERE id=$1 AND user_id=$2`, id, uid)
	utils.OK(c, gin.H{"message": "deleted"})
}
