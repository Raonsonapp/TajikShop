package handlers

import (
	"database/sql"
	"net/http"
	"tajikshop/internal/auth"
	"tajikshop/internal/db"
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
	Name     string `json:"name" binding:"required"`
	Email    string `json:"email"`
	Phone    string `json:"phone"`
	Password string `json:"password" binding:"required,min=6"`
}

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
	err := db.DB.QueryRow(`SELECT id,name,COALESCE(email,''),COALESCE(phone,''),COALESCE(avatar_url,''),COALESCE(bio,''),role,is_verified,is_seller,COALESCE(store_lat,0),COALESCE(store_lng,0),created_at FROM users WHERE id=$1`, uid).
		Scan(&u.ID, &u.Name, &u.Email, &u.Phone, &u.AvatarURL, &u.Bio, &u.Role, &u.IsVerified, &u.IsSeller, &u.StoreLat, &u.StoreLng, &u.CreatedAt)
	if err != nil {
		utils.Err(c, http.StatusNotFound, "user not found")
		return
	}
	utils.OK(c, u)
}

func (h *UserHandler) UpdateProfile(c *gin.Context) {
	uid := utils.UserID(c)
	var in struct {
		Name string `json:"name"`
		Bio  string `json:"bio"`
	}
	c.ShouldBindJSON(&in)
	db.DB.Exec(`UPDATE users SET name=$1,bio=$2,updated_at=$3 WHERE id=$4`, in.Name, in.Bio, time.Now(), uid)
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
	db.DB.Exec(`UPDATE users SET passport_url=$1,is_seller=true,role='seller',updated_at=$2 WHERE id=$3`,
		url, time.Now(), uid)
	accessToken, _ := auth.GenerateAccessToken(uid, "seller", h.secret)
	refreshToken, _ := auth.GenerateRefreshToken(uid, h.secret)
	db.DB.Exec(`UPDATE users SET refresh_token=$1 WHERE id=$2`, refreshToken, uid)
	utils.OK(c, gin.H{
		"message":       "verification submitted",
		"access_token":  accessToken,
		"refresh_token": refreshToken,
	})
}

func (h *UserHandler) BecomeSellerHandler(c *gin.Context) {
	uid := utils.UserID(c)
	db.DB.Exec(`UPDATE users SET is_seller=true,role='seller',updated_at=$1 WHERE id=$2`, time.Now(), uid)
	// Generate new tokens with updated role='seller' so middleware allows product upload immediately
	accessToken, _ := auth.GenerateAccessToken(uid, "seller", h.secret)
	refreshToken, _ := auth.GenerateRefreshToken(uid, h.secret)
	db.DB.Exec(`UPDATE users SET refresh_token=$1 WHERE id=$2`, refreshToken, uid)
	utils.OK(c, gin.H{
		"message":       "you are now a seller",
		"access_token":  accessToken,
		"refresh_token": refreshToken,
	})
}

// PublicProfile — саҳифаи оммавии фурӯшанда/корбар (бе auth)
func (h *UserHandler) PublicProfile(c *gin.Context) {
	id := c.Param("id")
	var (
		uid, name, avatar, bio, role string
		isVerified                   bool
	)
	err := db.DB.QueryRow(`SELECT id,name,COALESCE(avatar_url,''),COALESCE(bio,''),role,is_verified
		FROM users WHERE id=$1`, id).Scan(&uid, &name, &avatar, &bio, &role, &isVerified)
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
		"id":          uid,
		"name":        name,
		"avatar_url":  avatar,
		"bio":         bio,
		"role":        role,
		"is_verified": isVerified,
		"followers":   followers,
		"products":    products,
		"rating":      rating,
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
