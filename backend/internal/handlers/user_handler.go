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
	_, err = db.DB.Exec(`INSERT INTO users(id,name,email,phone,password_hash) VALUES($1,$2,$3,$4,$5)`,
		id, in.Name, in.Email, in.Phone, hash)
	if err != nil {
		utils.Err(c, http.StatusConflict, "user already exists")
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
	if in.Email != "" {
		err = db.DB.QueryRow(`SELECT id,name,email,phone,password_hash,role,is_banned FROM users WHERE email=$1`, in.Email).
			Scan(&u.ID, &u.Name, &u.Email, &u.Phone, &u.PasswordHash, &u.Role, &u.IsBanned)
	} else {
		err = db.DB.QueryRow(`SELECT id,name,email,phone,password_hash,role,is_banned FROM users WHERE phone=$1`, in.Phone).
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
	err := db.DB.QueryRow(`SELECT id,name,email,phone,avatar_url,bio,role,is_verified,is_seller,created_at FROM users WHERE id=$1`, uid).
		Scan(&u.ID, &u.Name, &u.Email, &u.Phone, &u.AvatarURL, &u.Bio, &u.Role, &u.IsVerified, &u.IsSeller, &u.CreatedAt)
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

func (h *UserHandler) BecomeSellerHandler(c *gin.Context) {
	uid := utils.UserID(c)
	db.DB.Exec(`UPDATE users SET is_seller=true,role='seller',updated_at=$1 WHERE id=$2`, time.Now(), uid)
	utils.OK(c, gin.H{"message": "you are now a seller"})
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
