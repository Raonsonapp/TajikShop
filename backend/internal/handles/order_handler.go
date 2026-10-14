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

type OrderHandler struct {
	r2 *storage.R2Client
}

func NewOrderHandler(r2 *storage.R2Client) *OrderHandler {
	return &OrderHandler{r2: r2}
}

// ========== CART ==========

// GetCart — GET /cart
//
// Ҳоло ҳолати ҳақиқии анбор низ бармегардад (`stock`, `available`,
// `min_order_qty`). Пештар сабад танҳо ном ва нархро медод, пас харидор
// метавонист моли хомӯш ё тамомшударо дар сабадаш бинад ва то лаҳзаи
// пардохт нафаҳмад, ки он нест.
func (h *OrderHandler) GetCart(c *gin.Context) {
	uid := utils.UserID(c)
	rows, err := db.DB.Query(`SELECT ci.id, ci.product_id, ci.quantity,
			COALESCE(p.title,''), p.price, p.stock,
			COALESCE(p.is_active,true), COALESCE(p.min_order_qty,1),
			p.seller_id,
			COALESCE((SELECT url FROM product_images WHERE product_id=p.id
				ORDER BY position LIMIT 1),'')
		FROM cart_items ci
		JOIN products p ON p.id = ci.product_id
		WHERE ci.user_id = $1
		ORDER BY ci.created_at DESC`, uid)
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, "Сабад хонда нашуд")
		return
	}
	defer rows.Close()
	type CartRow struct {
		ID        string  `json:"id"`
		ProductID string  `json:"product_id"`
		Quantity  int     `json:"quantity"`
		Title     string  `json:"title"`
		Price     float64 `json:"price"`
		Stock     int     `json:"stock"`
		Active    bool    `json:"is_active"`
		MinQty    int     `json:"min_order_qty"`
		SellerID  string  `json:"seller_id"`
		Image     string  `json:"image"`
		Available bool    `json:"available"`
		// `price` нархи ВОҚЕАН гирифташаванда аст (бо зинаи яклухт);
		// `retail_price` нархи чакана — то экран «90 сом. ба ҷои 100»
		// нишон диҳад.
		RetailPrice float64     `json:"retail_price"`
		Wholesale   bool        `json:"wholesale"`
		Tiers       []priceTier `json:"tiers,omitempty"`
	}
	items := []CartRow{}
	ids := []string{}
	for rows.Next() {
		var it CartRow
		if e := rows.Scan(&it.ID, &it.ProductID, &it.Quantity, &it.Title, &it.Price,
			&it.Stock, &it.Active, &it.MinQty, &it.SellerID, &it.Image); e != nil {
			continue
		}
		it.Available = it.Active && it.Stock >= it.Quantity && it.Quantity >= it.MinQty
		it.RetailPrice = it.Price
		items = append(items, it)
		ids = append(ids, it.ProductID)
	}

	// Нархи зинаи яклухтро ҲАМИН ҶО татбиқ мекунем.
	//
	// Бе ин сабад нархи чаканаро нишон медод, вале checkout нархи
	// яклухтро мегирифт — ду рақами гуногун дар як амал. Ҳатто агар
	// фарқият ба фоидаи харидор бошад, ин боварии ӯро мешиканад.
	//
	// Манбаи ягонаи ҳақиқат сервер аст: ҳам сабад, ҳам checkout ҳамон
	// `priceForQty`-ро истифода мебаранд.
	if len(ids) > 0 {
		tiers := loadTiersForDB(ids)
		for i := range items {
			t := tiers[items[i].ProductID]
			if len(t) == 0 {
				continue
			}
			unit := priceForQty(t, toDirams(items[i].Price), items[i].Quantity)
			items[i].Price = toSomoni(unit)
			items[i].Wholesale = unit < toDirams(items[i].RetailPrice)
			items[i].Tiers = t
		}
	}
	utils.OK(c, items)
}

// AddToCart — POST /cart
//
// Пештар ин ҷо ҳеҷ санҷиш набуд: `INSERT` фавран иҷро мешуд. Яъне
// метавонистед моли хомӯш, моли тамомшуда ё `{"quantity": 2000000000}`-ро
// ба сабад гузоред, ва хато танҳо дар лаҳзаи пардохт пайдо мешуд.
func (h *OrderHandler) AddToCart(c *gin.Context) {
	uid := utils.UserID(c)
	var in struct {
		ProductID string `json:"product_id" binding:"required"`
		Quantity  int    `json:"quantity"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, "Маҳсулот нишон дода нашуд")
		return
	}
	if in.Quantity <= 0 {
		in.Quantity = 1
	}

	var stock, minQty int
	var active bool
	var sellerID, title string
	err := db.DB.QueryRow(`SELECT p.stock, COALESCE(p.min_order_qty,1),
			COALESCE(p.is_active,true), p.seller_id, COALESCE(p.title,'')
		FROM products p WHERE p.id=$1`, in.ProductID).
		Scan(&stock, &minQty, &active, &sellerID, &title)
	if err != nil {
		utils.Err(c, http.StatusNotFound, "Маҳсулот ёфт нашуд")
		return
	}
	if !active || stock <= 0 {
		utils.Err(c, http.StatusConflict, "Ин маҳсулот ҳоло дастрас нест")
		return
	}
	// Фурӯшанда моли худашро нахарад — вагарна ҳисоби фурӯш вайрон мешавад.
	if sellerID == uid {
		utils.Err(c, http.StatusBadRequest, "Моли худро харидан мумкин нест")
		return
	}
	if minQty > 1 && in.Quantity < minQty {
		in.Quantity = minQty // ҳадди ақали фурӯшандаро худкор мегирем
	}

	// Шумораи ниҳоӣ набояд аз анбор зиёд шавад — аз ҷумла баъди ҷамъ
	// шудан бо он чизе, ки аллакай дар сабад аст.
	var have int
	db.DB.QueryRow(`SELECT COALESCE(quantity,0) FROM cart_items
		WHERE user_id=$1 AND product_id=$2`, uid, in.ProductID).Scan(&have)
	want := have + in.Quantity
	if want > stock {
		want = stock
	}
	if want > maxLineQty {
		want = maxLineQty
	}

	if _, e := db.DB.Exec(`INSERT INTO cart_items(id,user_id,product_id,quantity)
		VALUES($1,$2,$3,$4)
		ON CONFLICT(user_id,product_id) DO UPDATE SET quantity=$4`,
		uuid.NewString(), uid, in.ProductID, want); e != nil {
		utils.Err(c, http.StatusInternalServerError, "Ба сабад илова нашуд")
		return
	}
	utils.OK(c, gin.H{
		"message": "added to cart", "quantity": want,
		"capped": want < have+in.Quantity, "stock": stock,
	})
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

	// Шумора бо анбор ва ҳадди ақали фурӯшанда маҳдуд мешавад. Бе ин
	// харидор метавонист дар сабад 500 дона гузорад, дар ҳоле ки дар
	// анбор 3 дона буд.
	var stock, minQty int
	err := db.DB.QueryRow(`SELECT p.stock, COALESCE(p.min_order_qty,1)
		FROM cart_items ci JOIN products p ON p.id=ci.product_id
		WHERE ci.id=$1 AND ci.user_id=$2`, itemID, uid).Scan(&stock, &minQty)
	if err != nil {
		utils.Err(c, http.StatusNotFound, "Ин мол дар сабади шумо нест")
		return
	}
	q := in.Quantity
	if q > stock {
		q = stock
	}
	if q > maxLineQty {
		q = maxLineQty
	}
	if minQty > 1 && q < minQty {
		q = minQty
	}
	if q <= 0 {
		db.DB.Exec(`DELETE FROM cart_items WHERE id=$1 AND user_id=$2`, itemID, uid)
		utils.OK(c, gin.H{"removed": true, "reason": "out_of_stock"})
		return
	}

	if _, e := db.DB.Exec(`UPDATE cart_items SET quantity=$1 WHERE id=$2 AND user_id=$3`,
		q, itemID, uid); e != nil {
		utils.Err(c, http.StatusInternalServerError, "Нав карда нашуд")
		return
	}
	utils.OK(c, gin.H{
		"updated": true, "quantity": q,
		"capped": q != in.Quantity, "stock": stock, "min_order_qty": minQty,
	})
}

// ========== ORDERS ==========

func shortID(id string) string {
	if len(id) > 8 {
		return id[:8]
	}
	return id
}

func (h *OrderHandler) MyOrders(c *gin.Context) {
	uid := utils.UserID(c)
	rows, qerr := db.DB.Query(`SELECT id,status,total,created_at FROM orders WHERE user_id=$1 ORDER BY created_at DESC`, uid)
	if qerr != nil {
		utils.Err(c, http.StatusInternalServerError,
			"Маълумот хонда нашуд")
		return
	}
	defer rows.Close()
	var orders []models.Order
	for rows.Next() {
		var o models.Order
		if e := rows.Scan(&o.ID, &o.Status, &o.Total, &o.CreatedAt); e != nil {
			continue
		}
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
	rows, qerr := db.DB.Query(`SELECT id,product_id,quantity,price FROM order_items WHERE order_id=$1`, oid)
	if qerr != nil {
		utils.Err(c, http.StatusInternalServerError,
			"Маълумот хонда нашуд")
		return
	}
	defer rows.Close()
	for rows.Next() {
		var i models.OrderItem
		if e := rows.Scan(&i.ID, &i.ProductID, &i.Quantity, &i.Price); e != nil {
			continue
		}
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
	rows, qerr := db.DB.Query(`SELECT r.id,r.rating,r.comment,COALESCE(r.images,'[]'::jsonb),r.created_at,u.name,
		COALESCE((SELECT COUNT(*) FROM review_likes rl WHERE rl.review_id=r.id),0)
		FROM reviews r JOIN users u ON u.id=r.user_id
		WHERE r.product_id=$1 ORDER BY COALESCE((SELECT COUNT(*) FROM review_likes rl WHERE rl.review_id=r.id),0) DESC, r.created_at DESC`, pid)
	if qerr != nil {
		utils.Err(c, http.StatusInternalServerError,
			"Маълумот хонда нашуд")
		return
	}
	defer rows.Close()
	var reviews []models.Review
	for rows.Next() {
		var r models.Review
		var imgRaw []byte
		if e := rows.Scan(&r.ID, &r.Rating, &r.Comment, &imgRaw, &r.CreatedAt, &r.UserName, &r.HelpfulCount); e != nil {
			continue
		}
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
	rows, qerr := db.DB.Query(`SELECT p.id,p.title,p.price FROM favorites f
		JOIN products p ON p.id=f.product_id WHERE f.user_id=$1`, uid)
	if qerr != nil {
		utils.Err(c, http.StatusInternalServerError,
			"Маълумот хонда нашуд")
		return
	}
	defer rows.Close()
	var products []models.Product
	for rows.Next() {
		var p models.Product
		if e := rows.Scan(&p.ID, &p.Title, &p.Price); e != nil {
			continue
		}
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
	rows, qerr := db.DB.Query(`SELECT id,title,city,street,COALESCE(house,''),COALESCE(entrance,''),
		COALESCE(floor,''),COALESCE(apartment,''),COALESCE(landmark,''),COALESCE(region,''),
		zip,is_default,COALESCE(lat,0),COALESCE(lng,0)
		FROM addresses WHERE user_id=$1`, uid)
	if qerr != nil {
		utils.Err(c, http.StatusInternalServerError,
			"Маълумот хонда нашуд")
		return
	}
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
		if e := rows.Scan(&a.ID, &a.Title, &a.City, &a.Street, &a.House, &a.Entrance,
			&a.Floor, &a.Apartment, &a.Landmark, &a.Region,
			&a.Zip, &a.IsDefault, &a.Lat, &a.Lng); e != nil {
			continue
		}
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
