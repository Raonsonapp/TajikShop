package handlers

import (
	"encoding/json"
	"net/http"
	"strings"
	"tajikshop/internal/db"
	"tajikshop/internal/models"
	"tajikshop/internal/storage"
	"tajikshop/internal/utils"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// Ҳадди болоии ҳаққи расонидан (сом.) — муштарӣ наметавонад аз ин зиёд диҳад.
const maxDeliveryFee = 200

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

// UpdateCartItem — миқдорро тағйир медиҳад (0 → нест мекунад)
func (h *OrderHandler) UpdateCartItem(c *gin.Context) {
	uid := utils.UserID(c)
	itemID := c.Param("id")
	var in struct {
		Quantity int `json:"quantity"`
	}
	c.ShouldBindJSON(&in)
	if in.Quantity <= 0 {
		db.DB.Exec(`DELETE FROM cart_items WHERE id=$1 AND user_id=$2`, itemID, uid)
		utils.OK(c, gin.H{"removed": true})
		return
	}
	db.DB.Exec(`UPDATE cart_items SET quantity=$1 WHERE id=$2 AND user_id=$3`, in.Quantity, itemID, uid)
	utils.OK(c, gin.H{"updated": true, "quantity": in.Quantity})
}

// ========== ORDERS ==========

func (h *OrderHandler) Checkout(c *gin.Context) {
	uid := utils.UserID(c)
	var in struct {
		AddressID     string  `json:"address_id"`
		Note          string  `json:"note"`
		PaymentMethod string  `json:"payment_method"` // dc | cod | wallet
		CouponCode    string  `json:"coupon_code"`
		Fulfilment    string  `json:"fulfilment"` // delivery | pickup
		DeliveryFee   float64 `json:"delivery_fee"`
		DeliveryASAP  *bool   `json:"delivery_asap"`
		DeliverySlot  string  `json:"delivery_slot"` // "HH:MM"
	}
	c.ShouldBindJSON(&in)
	method := in.PaymentMethod
	if method != "cod" && method != "wallet" {
		method = "dc"
	}
	// Тарзи гирифтан: ҳангоми «аз мағоза гирифтан» расонидан ройгон аст.
	fulfilment := in.Fulfilment
	if fulfilment != "pickup" {
		fulfilment = "delivery"
	}
	deliveryFee := in.DeliveryFee
	if fulfilment == "pickup" || deliveryFee < 0 {
		deliveryFee = 0
	}
	if deliveryFee > maxDeliveryFee {
		deliveryFee = maxDeliveryFee // муҳофизат аз арзиши бофташудаи муштарӣ
	}
	slot := strings.TrimSpace(in.DeliverySlot)
	if in.DeliveryASAP != nil && *in.DeliveryASAP {
		slot = ""
	}
	if len(slot) > 5 {
		slot = slot[:5]
	}

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

	// Купон (агар эътибор дошта бошад)
	couponCode := strings.ToUpper(strings.TrimSpace(in.CouponCode))
	discountPct := 0
	if couponCode != "" {
		if d, ok, _ := lookupCoupon(couponCode); ok {
			discountPct = d
		} else {
			couponCode = ""
		}
	}
	// Ҷамъ = маҳсулот + расонидан, баъд тахфиф (мисли ҳисоби экрани сабад).
	gross := total + deliveryFee
	discountAmt := gross * float64(discountPct) / 100
	finalTotal := gross - discountAmt

	// address_id метавонад холӣ бошад (NULL)
	var addr interface{}
	if in.AddressID != "" {
		addr = in.AddressID
	}

	orderID := uuid.NewString()

	// Маҳсулоте, ки бо ин фармоиш метавонад тамом шавад — баъди commit
	// аз фурӯшандаашон мепурсем: «боз ҳаст?»
	soldOut := []string{}

	// ── Пардохт аз ҳамён: тавозунро месанҷем ва кам мекунем (атомӣ) ──
	if method == "wallet" {
		tx, txErr := db.DB.Begin()
		if txErr != nil {
			utils.Err(c, http.StatusInternalServerError, "tx begin failed")
			return
		}
		var bal float64
		tx.QueryRow(`SELECT COALESCE(wallet_balance,0) FROM users WHERE id=$1 FOR UPDATE`, uid).Scan(&bal)
		if bal < finalTotal {
			tx.Rollback()
			utils.Err(c, http.StatusBadRequest, "Тавозуни ҳамён нокифоя аст")
			return
		}
		if _, e := tx.Exec(`INSERT INTO orders(id,user_id,address_id,total,note,payment_method,discount,fulfilment,delivery_fee,delivery_slot,status)
			VALUES($1,$2,$3,$4,$5,'wallet',$6,$7,$8,$9,'paid')`,
			orderID, uid, addr, finalTotal, in.Note, discountAmt, fulfilment, deliveryFee, slot); e != nil {
			tx.Rollback()
			utils.Err(c, http.StatusInternalServerError, e.Error())
			return
		}
		for _, i := range items {
			tx.Exec(`INSERT INTO order_items(id,order_id,product_id,quantity,price) VALUES($1,$2,$3,$4,$5)`,
				uuid.NewString(), orderID, i.ProductID, i.Qty, i.Price)
			tx.Exec(`UPDATE products SET stock=GREATEST(stock-$1,0) WHERE id=$2`, i.Qty, i.ProductID)
			soldOut = append(soldOut, i.ProductID)
		}
		tx.Exec(`UPDATE users SET wallet_balance=wallet_balance-$1 WHERE id=$2`, finalTotal, uid)
		tx.Exec(`INSERT INTO wallet_transactions(id,user_id,amount,type,status,note)
			VALUES($1,$2,$3,'purchase','completed',$4)`,
			uuid.NewString(), uid, -finalTotal, "Харид #"+shortID(orderID))
		tx.Exec(`INSERT INTO notifications(id,user_id,type,title,body,ref_id)
			VALUES($1,$2,'order','Фармоиш қабул шуд','Фармоиши #`+shortID(orderID)+` бо ҳамён пардохт шуд',$3)`,
			uuid.NewString(), uid, orderID)
		tx.Exec(`DELETE FROM cart_items WHERE user_id=$1`, uid)
		if couponCode != "" {
			tx.Exec(`UPDATE coupons SET used_count=used_count+1 WHERE UPPER(code)=$1`, couponCode)
		}
		if e := tx.Commit(); e != nil {
			utils.Err(c, http.StatusInternalServerError, "checkout failed")
			return
		}
		pushToUser(uid, "Фармоиш қабул шуд", "Фармоиши #"+shortID(orderID)+" бо ҳамён пардохт шуд")
		// Фурӯшанда(гон) бояд фавран бидонанд, ки фармоиш омад.
		notifySellersOfNewOrder(orderID)
		// Ҳар маҳсулоте, ки бо ин фармоиш тамом шуд — аз фурӯшанда мепурсем.
		for _, pid := range soldOut {
			notifySoldOut(pid)
		}
		utils.Created(c, gin.H{"order_id": orderID, "total": finalTotal, "status": "paid", "discount": discountAmt})
		return
	}

	// ── DC ё Cash-on-Delivery ──
	if _, e := db.DB.Exec(`INSERT INTO orders(id,user_id,address_id,total,note,payment_method,discount,fulfilment,delivery_fee,delivery_slot,status)
		VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,'pending')`,
		orderID, uid, addr, finalTotal, in.Note, method, discountAmt, fulfilment, deliveryFee, slot); e != nil {
		utils.Err(c, http.StatusInternalServerError, e.Error())
		return
	}
	for _, i := range items {
		db.DB.Exec(`INSERT INTO order_items(id,order_id,product_id,quantity,price) VALUES($1,$2,$3,$4,$5)`,
			uuid.NewString(), orderID, i.ProductID, i.Qty, i.Price)
		db.DB.Exec(`UPDATE products SET stock=GREATEST(stock-$1,0) WHERE id=$2`, i.Qty, i.ProductID)
		soldOut = append(soldOut, i.ProductID)
	}
	db.DB.Exec(`DELETE FROM cart_items WHERE user_id=$1`, uid)
	if couponCode != "" {
		db.DB.Exec(`UPDATE coupons SET used_count=used_count+1 WHERE UPPER(code)=$1`, couponCode)
	}
	db.DB.Exec(`INSERT INTO notifications(id,user_id,type,title,body,ref_id)
		VALUES($1,$2,'order','Фармоиш қабул шуд','Фармоиши #`+shortID(orderID)+` қабул шуд',$3)`,
		uuid.NewString(), uid, orderID)
	pushToUser(uid, "Фармоиш қабул шуд", "Фармоиши #"+shortID(orderID)+" қабул шуд")
	// Фурӯшанда(гон) бояд фавран бидонанд, ки фармоиш омад.
	notifySellersOfNewOrder(orderID)
	for _, pid := range soldOut {
		notifySoldOut(pid)
	}

	utils.Created(c, gin.H{"order_id": orderID, "total": finalTotal, "discount": discountAmt})
}

func shortID(id string) string {
	if len(id) > 8 {
		return id[:8]
	}
	return id
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

// Cancel — фармоишро бекор мекунад; агар бо ҳамён пардохт шуда бошад, пул бармегардад
func (h *OrderHandler) Cancel(c *gin.Context) {
	uid := utils.UserID(c)
	oid := c.Param("id")
	var status, method string
	var total float64
	err := db.DB.QueryRow(`SELECT status,COALESCE(payment_method,'dc'),total FROM orders WHERE id=$1 AND user_id=$2`,
		oid, uid).Scan(&status, &method, &total)
	if err != nil {
		utils.Err(c, http.StatusNotFound, "order not found")
		return
	}
	if status == "delivered" || status == "cancelled" || status == "shipped" {
		utils.Err(c, http.StatusBadRequest, "Ин фармоишро бекор кардан мумкин нест")
		return
	}
	tx, txErr := db.DB.Begin()
	if txErr != nil {
		utils.Err(c, http.StatusInternalServerError, "tx begin failed")
		return
	}
	tx.Exec(`UPDATE orders SET status='cancelled',updated_at=$1 WHERE id=$2`, time.Now(), oid)
	tx.Exec(`INSERT INTO notifications(id,user_id,type,title,body,ref_id)
		VALUES($1,$2,'order','Фармоиш бекор шуд','Фармоиши #`+shortID(oid)+` бекор карда шуд',$3)`,
		uuid.NewString(), uid, oid)
	refunded := false
	if method == "wallet" && (status == "paid" || status == "processing") {
		tx.Exec(`UPDATE users SET wallet_balance=COALESCE(wallet_balance,0)+$1 WHERE id=$2`, total, uid)
		tx.Exec(`INSERT INTO wallet_transactions(id,user_id,amount,type,status,note)
			VALUES($1,$2,$3,'refund','completed',$4)`,
			uuid.NewString(), uid, total, "Бозгашти фармоиш #"+shortID(oid))
		refunded = true
	}
	if err := tx.Commit(); err != nil {
		utils.Err(c, http.StatusInternalServerError, "cancel failed")
		return
	}
	pushToUser(uid, "Фармоиш бекор шуд", "Фармоиши #"+shortID(oid)+" бекор карда шуд")
	utils.OK(c, gin.H{"cancelled": true, "refunded": refunded})
}

// Confirm — харидор расидани молро тасдиқ мекунад → пул аз escrow ба фурӯшанда(он)
// мегузарад (танҳо барои пардохти ҳамён). Ин зидди фиреб аст.
func (h *OrderHandler) Confirm(c *gin.Context) {
	uid := utils.UserID(c)
	oid := c.Param("id")
	var status, method string
	var total float64
	err := db.DB.QueryRow(`SELECT status,COALESCE(payment_method,'dc'),total FROM orders WHERE id=$1 AND user_id=$2`,
		oid, uid).Scan(&status, &method, &total)
	if err != nil {
		utils.Err(c, http.StatusNotFound, "order not found")
		return
	}
	if status == "completed" || status == "cancelled" {
		utils.Err(c, http.StatusBadRequest, "Ин фармоиш аллакай анҷом ёфтааст")
		return
	}
	// Ҳамон мантиқи пул, ки озодкунии худкор истифода мебарад (settleOrder),
	// то ду роҳи ҳисоббаробаркунӣ ҳеҷ гоҳ фарқ накунанд.
	settleOrder(oid, uid, total, method, false)
	utils.OK(c, gin.H{"completed": true, "released": method == "wallet"})
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

type ReviewHandler struct{ r2 *storage.R2Client }

func NewReviewHandler(r2 *storage.R2Client) *ReviewHandler { return &ReviewHandler{r2: r2} }

func (h *ReviewHandler) Create(c *gin.Context) {
	uid := utils.UserID(c)
	var in struct {
		ProductID string   `json:"product_id" binding:"required"`
		Rating    int      `json:"rating" binding:"required,min=1,max=5"`
		Comment   string   `json:"comment"`
		Images    []string `json:"images"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}
	if in.Images == nil {
		in.Images = []string{}
	}
	imgJSON, _ := json.Marshal(in.Images)
	id := uuid.NewString()
	_, err := db.DB.Exec(`INSERT INTO reviews(id,user_id,product_id,rating,comment,images) VALUES($1,$2,$3,$4,$5,$6)
		ON CONFLICT(user_id,product_id) DO UPDATE SET rating=$4,comment=$5,images=$6`,
		id, uid, in.ProductID, in.Rating, in.Comment, imgJSON)
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, err.Error())
		return
	}
	utils.Created(c, gin.H{"id": id})
}

// UploadImages — расмҳои шарҳро ба R2 бор мекунад ва рӯйхати URL-ро бармегардонад.
func (h *ReviewHandler) UploadImages(c *gin.Context) {
	form, err := c.MultipartForm()
	if err != nil {
		utils.Err(c, http.StatusBadRequest, "multipart error")
		return
	}
	files := form.File["images"]
	var urls []string
	for _, fh := range files {
		f, _ := fh.Open()
		var url string
		if h.r2 != nil {
			url, err = h.r2.Upload(f, fh, "reviews")
		}
		f.Close()
		if err != nil || url == "" {
			continue
		}
		urls = append(urls, url)
	}
	if urls == nil {
		urls = []string{}
	}
	utils.OK(c, gin.H{"urls": urls})
}

func (h *ReviewHandler) ByProduct(c *gin.Context) {
	pid := c.Param("product_id")
	rows, _ := db.DB.Query(`SELECT r.id,r.rating,r.comment,COALESCE(r.images,'[]'::jsonb),r.created_at,u.name,
		COALESCE((SELECT COUNT(*) FROM review_likes rl WHERE rl.review_id=r.id),0)
		FROM reviews r JOIN users u ON u.id=r.user_id
		WHERE r.product_id=$1 ORDER BY COALESCE((SELECT COUNT(*) FROM review_likes rl WHERE rl.review_id=r.id),0) DESC, r.created_at DESC`, pid)
	defer rows.Close()
	var reviews []models.Review
	for rows.Next() {
		var r models.Review
		var imgRaw []byte
		rows.Scan(&r.ID, &r.Rating, &r.Comment, &imgRaw, &r.CreatedAt, &r.UserName, &r.HelpfulCount)
		if len(imgRaw) > 0 {
			json.Unmarshal(imgRaw, &r.Images)
		}
		if r.Images == nil {
			r.Images = []string{}
		}
		reviews = append(reviews, r)
	}
	if reviews == nil {
		reviews = []models.Review{}
	}
	utils.OK(c, reviews)
}

// Helpful — овози «фоиданок»-ро иваз мекунад (toggle)
func (h *ReviewHandler) Helpful(c *gin.Context) {
	uid := utils.UserID(c)
	rid := c.Param("id")
	var exists bool
	db.DB.QueryRow(`SELECT EXISTS(SELECT 1 FROM review_likes WHERE review_id=$1 AND user_id=$2)`, rid, uid).Scan(&exists)
	if exists {
		db.DB.Exec(`DELETE FROM review_likes WHERE review_id=$1 AND user_id=$2`, rid, uid)
	} else {
		db.DB.Exec(`INSERT INTO review_likes(id,review_id,user_id) VALUES($1,$2,$3) ON CONFLICT DO NOTHING`,
			uuid.NewString(), rid, uid)
	}
	var count int
	db.DB.QueryRow(`SELECT COUNT(*) FROM review_likes WHERE review_id=$1`, rid).Scan(&count)
	utils.OK(c, gin.H{"helpful": !exists, "count": count})
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
		Title     string  `json:"title" binding:"required"`
		City      string  `json:"city" binding:"required"`
		Street    string  `json:"street" binding:"required"`
		House     string  `json:"house"`
		Entrance  string  `json:"entrance"`
		Floor     string  `json:"floor"`
		Apartment string  `json:"apartment"`
		Landmark  string  `json:"landmark"`
		Region    string  `json:"region"`
		Zip       string  `json:"zip"`
		Lat       float64 `json:"lat"`
		Lng       float64 `json:"lng"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}
	// Рақами хона барои расонидан ҳатмист — бе он расонанда гум мешавад.
	if strings.TrimSpace(in.House) == "" {
		utils.Err(c, http.StatusBadRequest, "Рақами хона ҳатмист")
		return
	}
	id := uuid.NewString()
	db.DB.Exec(`INSERT INTO addresses(id,user_id,title,city,street,house,entrance,floor,apartment,landmark,region,zip,lat,lng)
		VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)`,
		id, uid, in.Title, in.City, in.Street, strings.TrimSpace(in.House),
		in.Entrance, in.Floor, in.Apartment, in.Landmark, in.Region, in.Zip, in.Lat, in.Lng)
	utils.Created(c, gin.H{"id": id})
}

func (h *AddressHandler) List(c *gin.Context) {
	uid := utils.UserID(c)
	rows, _ := db.DB.Query(`SELECT id,title,city,street,COALESCE(house,''),COALESCE(entrance,''),
		COALESCE(floor,''),COALESCE(apartment,''),COALESCE(landmark,''),COALESCE(region,''),
		zip,is_default,COALESCE(lat,0),COALESCE(lng,0)
		FROM addresses WHERE user_id=$1`, uid)
	defer rows.Close()
	type addr struct {
		ID        string  `json:"id"`
		Title     string  `json:"title"`
		City      string  `json:"city"`
		Street    string  `json:"street"`
		House     string  `json:"house"`
		Entrance  string  `json:"entrance"`
		Floor     string  `json:"floor"`
		Apartment string  `json:"apartment"`
		Landmark  string  `json:"landmark"`
		Region    string  `json:"region"`
		Zip       string  `json:"zip"`
		IsDefault bool    `json:"is_default"`
		Lat       float64 `json:"lat"`
		Lng       float64 `json:"lng"`
	}
	var addrs []addr
	for rows.Next() {
		var a addr
		rows.Scan(&a.ID, &a.Title, &a.City, &a.Street, &a.House, &a.Entrance,
			&a.Floor, &a.Apartment, &a.Landmark, &a.Region,
			&a.Zip, &a.IsDefault, &a.Lat, &a.Lng)
		addrs = append(addrs, a)
	}
	if addrs == nil {
		addrs = []addr{}
	}
	utils.OK(c, addrs)
}

func (h *AddressHandler) Delete(c *gin.Context) {
	uid := utils.UserID(c)
	id := c.Param("id")
	db.DB.Exec(`DELETE FROM addresses WHERE id=$1 AND user_id=$2`, id, uid)
	utils.OK(c, gin.H{"message": "deleted"})
}

func (h *AddressHandler) SetDefault(c *gin.Context) {
	uid := utils.UserID(c)
	id := c.Param("id")
	tx, err := db.DB.Begin()
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, "tx begin failed")
		return
	}
	tx.Exec(`UPDATE addresses SET is_default=false WHERE user_id=$1`, uid)
	tx.Exec(`UPDATE addresses SET is_default=true WHERE id=$1 AND user_id=$2`, id, uid)
	tx.Commit()
	utils.OK(c, gin.H{"updated": true})
}
