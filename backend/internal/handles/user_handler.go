package handlers

import (
	"database/sql"
	"net/http"
	"strings"
	"tajikshop/internal/auth"
	"tajikshop/internal/db"
	"tajikshop/internal/mailer"
	"tajikshop/internal/models"
	"tajikshop/internal/storage"
	"tajikshop/internal/utils"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type UserHandler struct {
	secret string
	r2     *storage.R2Client
}

func NewUserHandler(secret string, r2 *storage.R2Client) *UserHandler {
	return &UserHandler{secret: secret, r2: r2}
}

type registerInput struct {
	Name         string `json:"name" binding:"required"`
	Email        string `json:"email"`
	Phone        string `json:"phone"`
	Password     string `json:"password" binding:"required,min=6"`
	ReferralCode string `json:"referral_code"`
}

// referralBonus — бонуси даъват (сом) ба ҳарду тараф.
const referralBonus = 10.0

func (h *UserHandler) Register(c *gin.Context) {
	var in registerInput
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}
	if in.Email == "" && in.Phone == "" {
		utils.Err(c, http.StatusBadRequest, "email or phone required")
		return
	}
	hash, err := utils.HashPassword(in.Password)
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, "hash error")
		return
	}
	id := uuid.NewString()
	// NULLIF: майдони холӣ ('') ба NULL табдил мешавад. Дар Postgres ду сатри ''
	// ба UNIQUE(email)/UNIQUE(phone) бархӯрд мекунанд, аммо NULL-ҳо не — пас
	// корбарони танҳо-email (бе телефон) бемушкил сабтном мешаванд.
	_, err = db.DB.Exec(`INSERT INTO users(id,name,email,phone,password_hash)
		VALUES($1,$2,NULLIF($3,''),NULLIF($4,''),$5)`,
		id, in.Name, in.Email, in.Phone, hash)
	if err != nil {
		utils.Err(c, http.StatusConflict, "Ин корбар аллакай вуҷуд дорад")
		return
	}
	// Коди даъвати худи корбар (6 ҳарфи аввали id).
	myCode := strings.ToUpper(strings.ReplaceAll(id, "-", ""))
	if len(myCode) > 6 {
		myCode = myCode[:6]
	}
	db.DB.Exec(`UPDATE users SET referral_code=$1 WHERE id=$2`, myCode, id)
	// Агар бо коди даъват сабтном шуда бошад — ба ҳарду бонус.
	if code := strings.ToUpper(strings.TrimSpace(in.ReferralCode)); code != "" {
		var refID string
		if e := db.DB.QueryRow(`SELECT id FROM users WHERE referral_code=$1`, code).Scan(&refID); e == nil && refID != id {
			db.DB.Exec(`UPDATE users SET referred_by=$1 WHERE id=$2`, refID, id)
			for _, u := range []string{refID, id} {
				db.DB.Exec(`UPDATE users SET wallet_balance=COALESCE(wallet_balance,0)+$1 WHERE id=$2`, referralBonus, u)
				db.DB.Exec(`INSERT INTO wallet_transactions(id,user_id,amount,type,status,note)
					VALUES($1,$2,$3,'referral','completed','🎁 Бонуси даъват')`,
					uuid.NewString(), u, referralBonus)
			}
		}
	}
	accessToken, _ := auth.GenerateAccessToken(id, "buyer", h.secret)
	refreshToken, _ := auth.GenerateRefreshToken(id, h.secret)
	db.DB.Exec(`UPDATE users SET refresh_token=$1 WHERE id=$2`, refreshToken, id)
	utils.Created(c, gin.H{"access_token": accessToken, "refresh_token": refreshToken})
}

type loginInput struct {
	Email    string `json:"email"`
	Phone    string `json:"phone"`
	Password string `json:"password" binding:"required"`
}

func (h *UserHandler) Login(c *gin.Context) {
	var in loginInput
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}
	var u models.User
	var err error
	// COALESCE: email/phone метавонанд NULL бошанд (корбарони танҳо-email/танҳо-телефон).
	// Бе COALESCE сканкунии NULL ба string хато медиҳад (500).
	if in.Email != "" {
		err = db.DB.QueryRow(`SELECT id,name,COALESCE(email,''),COALESCE(phone,''),password_hash,role,is_banned FROM users WHERE email=$1`, in.Email).
			Scan(&u.ID, &u.Name, &u.Email, &u.Phone, &u.PasswordHash, &u.Role, &u.IsBanned)
	} else {
		err = db.DB.QueryRow(`SELECT id,name,COALESCE(email,''),COALESCE(phone,''),password_hash,role,is_banned FROM users WHERE phone=$1`, in.Phone).
			Scan(&u.ID, &u.Name, &u.Email, &u.Phone, &u.PasswordHash, &u.Role, &u.IsBanned)
	}
	if err == sql.ErrNoRows {
		utils.Err(c, http.StatusUnauthorized, "user not found")
		return
	}
	if !utils.CheckPassword(u.PasswordHash, in.Password) {
		utils.Err(c, http.StatusUnauthorized, "wrong password")
		return
	}
	if u.IsBanned {
		utils.Err(c, http.StatusForbidden, "account banned")
		return
	}
	accessToken, _ := auth.GenerateAccessToken(u.ID, u.Role, h.secret)
	refreshToken, _ := auth.GenerateRefreshToken(u.ID, h.secret)
	db.DB.Exec(`UPDATE users SET refresh_token=$1,updated_at=$2 WHERE id=$3`, refreshToken, time.Now(), u.ID)
	utils.OK(c, gin.H{"access_token": accessToken, "refresh_token": refreshToken, "user": u})
}

func (h *UserHandler) Me(c *gin.Context) {
	uid := utils.UserID(c)
	var u models.User
	err := db.DB.QueryRow(`SELECT id,name,COALESCE(email,''),COALESCE(phone,''),COALESCE(avatar_url,''),COALESCE(bio,''),role,is_verified,is_seller,COALESCE(seller_requested,false),COALESCE(store_lat,0),COALESCE(store_lng,0),COALESCE(shop_name,''),COALESCE(shop_desc,''),COALESCE(shop_phone,''),COALESCE(shop_hours,''),COALESCE(business_type,'shop'),COALESCE(card_number,''),COALESCE(card_holder,''),COALESCE(username,''),created_at FROM users WHERE id=$1`, uid).
		Scan(&u.ID, &u.Name, &u.Email, &u.Phone, &u.AvatarURL, &u.Bio, &u.Role, &u.IsVerified, &u.IsSeller, &u.SellerRequested, &u.StoreLat, &u.StoreLng, &u.ShopName, &u.ShopDesc, &u.ShopPhone, &u.ShopHours, &u.BusinessType, &u.CardNumber, &u.CardHolder, &u.Username, &u.CreatedAt)
	if err != nil {
		utils.Err(c, http.StatusNotFound, "user not found")
		return
	}
	utils.OK(c, u)
}

func (h *UserHandler) UpdateProfile(c *gin.Context) {
	uid := utils.UserID(c)
	var in struct {
		Name         string `json:"name"`
		Bio          string `json:"bio"`
		ShopName     string `json:"shop_name"`
		ShopDesc     string `json:"shop_desc"`
		ShopPhone    string `json:"shop_phone"`
		ShopHours    string `json:"shop_hours"`
		BusinessType string `json:"business_type"`
		CardNumber   string `json:"card_number"`
		CardHolder   string `json:"card_holder"`
	}
	c.ShouldBindJSON(&in)
	// Майдонҳои бизнес танҳо ҳангоми фиристодан навсозӣ мешаванд (холӣ = нигоҳ дошта мешавад).
	db.DB.Exec(`UPDATE users SET
		name=$1, bio=$2,
		shop_name     = COALESCE(NULLIF($3,''), shop_name),
		shop_desc     = COALESCE(NULLIF($4,''), shop_desc),
		shop_phone    = COALESCE(NULLIF($5,''), shop_phone),
		shop_hours    = COALESCE(NULLIF($6,''), shop_hours),
		business_type = COALESCE(NULLIF($7,''), business_type),
		card_number   = COALESCE(NULLIF($8,''), card_number),
		card_holder   = COALESCE(NULLIF($9,''), card_holder),
		updated_at=$10 WHERE id=$11`,
		in.Name, in.Bio, in.ShopName, in.ShopDesc, in.ShopPhone, in.ShopHours,
		in.BusinessType, strings.TrimSpace(in.CardNumber), strings.TrimSpace(in.CardHolder),
		time.Now(), uid)
	utils.OK(c, gin.H{"message": "updated"})
}

// UpdateLocation — ҷойгиршавии мағозаи фурӯшандаро (GPS) нигоҳ медорад (ихтиёрӣ).
func (h *UserHandler) UpdateLocation(c *gin.Context) {
	uid := utils.UserID(c)
	var in struct {
		Lat float64 `json:"lat"`
		Lng float64 `json:"lng"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}
	db.DB.Exec(`UPDATE users SET store_lat=$1,store_lng=$2,updated_at=$3 WHERE id=$4`,
		in.Lat, in.Lng, time.Now(), uid)
	utils.OK(c, gin.H{"lat": in.Lat, "lng": in.Lng})
}

func (h *UserHandler) UploadAvatar(c *gin.Context) {
	uid := utils.UserID(c)
	file, header, err := c.Request.FormFile("avatar")
	if err != nil {
		utils.Err(c, http.StatusBadRequest, "file required")
		return
	}
	defer file.Close()
	url, err := h.r2.Upload(file, header, "avatars")
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, err.Error())
		return
	}
	db.DB.Exec(`UPDATE users SET avatar_url=$1,updated_at=$2 WHERE id=$3`, url, time.Now(), uid)
	utils.OK(c, gin.H{"avatar_url": url})
}

// SaveFCMToken — токени push-и дастгоҳро нигоҳ медорад
func (h *UserHandler) SaveFCMToken(c *gin.Context) {
	uid := utils.UserID(c)
	var in struct {
		Token string `json:"token"`
	}
	c.ShouldBindJSON(&in)
	db.DB.Exec(`UPDATE users SET fcm_token=$1,updated_at=$2 WHERE id=$3`, in.Token, time.Now(), uid)
	utils.OK(c, gin.H{"saved": true})
}

// SellerVerify — акси паспортро бор мекунад ва корбарро фурӯшанда мекунад
// (is_verified=false то тасдиқи админ). KYC зидди фиреб.
func (h *UserHandler) SellerVerify(c *gin.Context) {
	uid := utils.UserID(c)
	file, header, err := c.Request.FormFile("passport")
	if err != nil {
		utils.Err(c, http.StatusBadRequest, "акси паспорт лозим аст")
		return
	}
	defer file.Close()
	if h.r2 == nil {
		utils.Err(c, http.StatusInternalServerError, "storage not configured")
		return
	}
	url, err := h.r2.Upload(file, header, "passports")
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, err.Error())
		return
	}
	// Дархост сабт мешавад — фурӯшанда ТАНҲО баъди тасдиқи админ мешавад (is_seller дар ин ҷо гузошта намешавад).
	db.DB.Exec(`UPDATE users SET passport_url=$1,seller_requested=true,updated_at=$2 WHERE id=$3`,
		url, time.Now(), uid)
	var name, email string
	db.DB.QueryRow(`SELECT name, COALESCE(email,'') FROM users WHERE id=$1`, uid).Scan(&name, &email)
	notifyAdmins("seller_request", "Дархости нави фурӯшанда 🏪", name+" мехоҳад фурӯшанда шавад", uid)
	go mailer.NotifySellerRequest(name, email, uid)
	utils.OK(c, gin.H{
		"message": "Дархости шумо фиристода шуд. Баъди тасдиқи админ фурӯшанда мешавед.",
		"pending": true,
	})
}

func (h *UserHandler) BecomeSellerHandler(c *gin.Context) {
	uid := utils.UserID(c)
	// Дархости фурӯшандашавӣ — фавран фурӯшанда НАМЕШАВАД; интизори тасдиқи админ.
	db.DB.Exec(`UPDATE users SET seller_requested=true,updated_at=$1 WHERE id=$2`, time.Now(), uid)
	var name, email string
	db.DB.QueryRow(`SELECT name, COALESCE(email,'') FROM users WHERE id=$1`, uid).Scan(&name, &email)
	notifyAdmins("seller_request", "Дархости нави фурӯшанда 🏪", name+" мехоҳад фурӯшанда шавад", uid)
	go mailer.NotifySellerRequest(name, email, uid)
	utils.OK(c, gin.H{
		"message": "Дархости шумо фиристода шуд. Баъди тасдиқи админ фурӯшанда мешавед.",
		"pending": true,
	})
}

// notifyAdmins — ба ҳамаи админҳо огоҳии дохили барнома мегузорад.
func notifyAdmins(nType, title, body, refID string) {
	db.DB.Exec(`INSERT INTO notifications(user_id,type,title,body,ref_id)
		SELECT id,$1,$2,$3,$4 FROM users WHERE role='admin'`,
		nType, title, body, refID)
}

// SellerStats — омори фурӯши фурӯшандаи ҷорӣ: маҳсулот, фармоишҳо, фурӯхта, даромад.
func (h *UserHandler) SellerStats(c *gin.Context) {
	uid := utils.UserID(c)
	var products, active, orders, sold int
	var revenue float64
	db.DB.QueryRow(`SELECT
		(SELECT COUNT(*) FROM products WHERE seller_id=$1),
		(SELECT COUNT(*) FROM products WHERE seller_id=$1 AND is_active=true AND stock>0),
		COALESCE((SELECT COUNT(DISTINCT oi.order_id) FROM order_items oi JOIN products p ON p.id=oi.product_id WHERE p.seller_id=$1),0),
		COALESCE((SELECT SUM(oi.quantity) FROM order_items oi JOIN products p ON p.id=oi.product_id WHERE p.seller_id=$1),0),
		COALESCE((SELECT SUM(oi.price*oi.quantity) FROM order_items oi JOIN products p ON p.id=oi.product_id WHERE p.seller_id=$1),0)
	`, uid).Scan(&products, &active, &orders, &sold, &revenue)
	utils.OK(c, gin.H{
		"products": products, "active_products": active,
		"orders": orders, "sold": sold, "revenue": revenue,
	})
}

// SellerOrders — рӯйхати фармоишҳое ки маҳсулоти фурӯшандаи ҷориро доранд.
// Барои иҷрои фармоиш: харидор, телефон, шумораи ашё ва маблағи фурӯшанда. GET /seller/orders
func (h *UserHandler) SellerOrders(c *gin.Context) {
	uid := utils.UserID(c)
	// Суроға низ бармегардад — вагарна фурӯшанда намедонад молро ба куҷо барад.
	// Танҳо барои фармоишҳои «расонидан» ва танҳо барои фармоиши худи ӯ.
	rows, err := db.DB.Query(`
		SELECT o.id, o.status, o.created_at, u.name, COALESCE(u.phone,''),
			(SELECT COUNT(*) FROM order_items oi JOIN products p ON p.id=oi.product_id
				WHERE oi.order_id=o.id AND p.seller_id=$1),
			COALESCE((SELECT SUM(oi.price*oi.quantity) FROM order_items oi JOIN products p ON p.id=oi.product_id
				WHERE oi.order_id=o.id AND p.seller_id=$1),0),
			COALESCE(o.fulfilment,'delivery'),
			COALESCE(a.city,''), COALESCE(a.street,''), COALESCE(a.house,''),
			COALESCE(a.entrance,''), COALESCE(a.floor,''), COALESCE(a.apartment,''),
			COALESCE(a.landmark,''), COALESCE(a.lat,0), COALESCE(a.lng,0),
			COALESCE(o.delivery_slot,'')
		FROM orders o
		JOIN users u ON u.id=o.user_id
		LEFT JOIN addresses a ON a.id = o.address_id
		WHERE EXISTS (SELECT 1 FROM order_items oi JOIN products p ON p.id=oi.product_id
			WHERE oi.order_id=o.id AND p.seller_id=$1)
		ORDER BY o.created_at DESC LIMIT 100`, uid)
	if err != nil {
		utils.OK(c, []gin.H{})
		return
	}
	defer rows.Close()
	out := []gin.H{}
	for rows.Next() {
		var id, status, buyer, phone string
		var fulfilment, city, street, house, entrance, floor, apartment, landmark, slot string
		var lat, lng float64
		var createdAt time.Time
		var items int
		var subtotal float64
		rows.Scan(&id, &status, &createdAt, &buyer, &phone, &items, &subtotal,
			&fulfilment, &city, &street, &house, &entrance, &floor, &apartment,
			&landmark, &lat, &lng, &slot)
		row := gin.H{
			"id": id, "status": status, "created_at": createdAt,
			"buyer_name": buyer, "buyer_phone": phone,
			"items": items, "subtotal": subtotal,
			"fulfilment": fulfilment, "delivery_slot": slot,
		}
		// Ҳангоми «аз мағоза гирифтан» суроғаи хонаи харидор лозим нест —
		// онро намефиристем (маълумоти шахсӣ бе зарурат кушода намешавад).
		if fulfilment == "delivery" {
			row["city"] = city
			row["street"] = street
			row["house"] = house
			row["entrance"] = entrance
			row["floor"] = floor
			row["apartment"] = apartment
			row["landmark"] = landmark
			row["lat"] = lat
			row["lng"] = lng
		}
		out = append(out, row)
	}
	utils.OK(c, out)
}

// SellerSalesChart — фурӯши 7 рӯзи охир (барои графики панели фурӯшанда).
// GET /seller/sales-chart → [{date, total}] (рӯзҳои холӣ дар frontend пур мешаванд).
func (h *UserHandler) SellerSalesChart(c *gin.Context) {
	uid := utils.UserID(c)
	rows, err := db.DB.Query(`
		SELECT to_char(DATE(o.created_at),'YYYY-MM-DD') d,
			COALESCE(SUM(oi.price*oi.quantity),0)
		FROM order_items oi
		JOIN products p ON p.id=oi.product_id
		JOIN orders o ON o.id=oi.order_id
		WHERE p.seller_id=$1 AND o.created_at >= (CURRENT_DATE - INTERVAL '6 days')
		GROUP BY DATE(o.created_at)
		ORDER BY d`, uid)
	if err != nil {
		utils.OK(c, []gin.H{})
		return
	}
	defer rows.Close()
	out := []gin.H{}
	for rows.Next() {
		var d string
		var total float64
		rows.Scan(&d, &total)
		out = append(out, gin.H{"date": d, "total": total})
	}
	utils.OK(c, out)
}

// ReferralInfo — коди даъвати корбар + шумораи даъватшудагон + бонуси кофташуда.
func (h *UserHandler) ReferralInfo(c *gin.Context) {
	uid := utils.UserID(c)
	var code string
	db.DB.QueryRow(`SELECT COALESCE(referral_code,'') FROM users WHERE id=$1`, uid).Scan(&code)
	if code == "" {
		code = strings.ToUpper(strings.ReplaceAll(uid, "-", ""))
		if len(code) > 6 {
			code = code[:6]
		}
		db.DB.Exec(`UPDATE users SET referral_code=$1 WHERE id=$2`, code, uid)
	}
	var count int
	var earned float64
	db.DB.QueryRow(`SELECT COUNT(*) FROM users WHERE referred_by=$1`, uid).Scan(&count)
	db.DB.QueryRow(`SELECT COALESCE(SUM(amount),0) FROM wallet_transactions WHERE user_id=$1 AND type='referral'`, uid).Scan(&earned)
	utils.OK(c, gin.H{"code": code, "referrals": count, "earned": earned, "bonus": referralBonus})
}

// ShopsList — рӯйхати мағозаҳо/бизнесҳое, ки ҷойгиршавӣ (GPS) доранд —
// барои харитаи «Дӯконҳои наздик» (бе auth). Хусусияти фарқкунандаи TajikShop Pro.
func (h *UserHandler) ShopsList(c *gin.Context) {
	rows, err := db.DB.Query(`SELECT u.id,
		COALESCE(NULLIF(u.shop_name,''), u.name),
		COALESCE(u.avatar_url,''), COALESCE(u.shop_desc,''), COALESCE(u.business_type,'shop'),
		COALESCE(u.store_lat,0), COALESCE(u.store_lng,0), u.is_verified,
		(SELECT COUNT(*) FROM products p WHERE p.seller_id=u.id AND p.is_active=true AND p.stock>0)
		FROM users u
		WHERE u.is_seller=true AND (COALESCE(u.store_lat,0)<>0 OR COALESCE(u.store_lng,0)<>0)`)
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, err.Error())
		return
	}
	defer rows.Close()
	list := []gin.H{}
	for rows.Next() {
		var id, name, avatar, desc, btype string
		var lat, lng float64
		var verified bool
		var products int
		rows.Scan(&id, &name, &avatar, &desc, &btype, &lat, &lng, &verified, &products)
		list = append(list, gin.H{
			"id": id, "name": name, "avatar_url": avatar, "shop_desc": desc, "business_type": btype,
			"store_lat": lat, "store_lng": lng, "is_verified": verified, "products": products,
		})
	}
	utils.OK(c, list)
}

// PublicProfile — саҳифаи оммавии фурӯшанда/корбар (бе auth)
func (h *UserHandler) PublicProfile(c *gin.Context) {
	id := c.Param("id")
	var (
		uid, name, avatar, bio, role                    string
		shopName, shopDesc, shopPhone, shopHours, bType string
		storeLat, storeLng                              float64
		isVerified                                      bool
	)
	err := db.DB.QueryRow(`SELECT id,name,COALESCE(avatar_url,''),COALESCE(bio,''),role,is_verified,
		COALESCE(shop_name,''),COALESCE(shop_desc,''),COALESCE(shop_phone,''),COALESCE(shop_hours,''),
		COALESCE(business_type,'shop'),COALESCE(store_lat,0),COALESCE(store_lng,0)
		FROM users WHERE id=$1`, id).Scan(&uid, &name, &avatar, &bio, &role, &isVerified,
		&shopName, &shopDesc, &shopPhone, &shopHours, &bType, &storeLat, &storeLng)
	if err != nil {
		utils.Err(c, http.StatusNotFound, "user not found")
		return
	}
	var followers, products int
	var rating float64
	db.DB.QueryRow(`SELECT COUNT(*) FROM follows WHERE following_id=$1`, id).Scan(&followers)
	db.DB.QueryRow(`SELECT COUNT(*) FROM products WHERE seller_id=$1 AND is_active=true`, id).Scan(&products)
	db.DB.QueryRow(`SELECT COALESCE(AVG(r.rating),0) FROM reviews r
		JOIN products p ON p.id=r.product_id WHERE p.seller_id=$1`, id).Scan(&rating)
	utils.OK(c, gin.H{
		"id":            uid,
		"name":          name,
		"avatar_url":    avatar,
		"bio":           bio,
		"role":          role,
		"is_verified":   isVerified,
		"followers":     followers,
		"products":      products,
		"rating":        rating,
		"shop_name":     shopName,
		"shop_desc":     shopDesc,
		"shop_phone":    shopPhone,
		"shop_hours":    shopHours,
		"business_type": bType,
		"store_lat":     storeLat,
		"store_lng":     storeLng,
	})
}

func (h *UserHandler) RefreshToken(c *gin.Context) {
	var in struct {
		RefreshToken string `json:"refresh_token" binding:"required"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}
	claims, err := auth.ParseToken(in.RefreshToken, h.secret)
	if err != nil {
		utils.Err(c, http.StatusUnauthorized, "invalid refresh token")
		return
	}
	var u models.User
	db.DB.QueryRow(`SELECT id,role,refresh_token FROM users WHERE id=$1`, claims.UserID).
		Scan(&u.ID, &u.Role, &u.RefreshToken)
	if u.RefreshToken != in.RefreshToken {
		utils.Err(c, http.StatusUnauthorized, "token mismatch")
		return
	}
	accessToken, _ := auth.GenerateAccessToken(u.ID, u.Role, h.secret)
	utils.OK(c, gin.H{"access_token": accessToken})
}
