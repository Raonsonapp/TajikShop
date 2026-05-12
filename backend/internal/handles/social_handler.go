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

// ========== STORIES ==========

type StoryHandler struct {
	r2 *storage.R2Client
}

func NewStoryHandler(r2 *storage.R2Client) *StoryHandler { return &StoryHandler{r2: r2} }

func (h *StoryHandler) Create(c *gin.Context) {
	uid := utils.UserID(c)
	file, header, err := c.Request.FormFile("media")
	if err != nil {
		utils.Err(c, http.StatusBadRequest, "media file required")
		return
	}
	defer file.Close()
	url, err := h.r2.Upload(file, header, "stories")
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, err.Error())
		return
	}
	mediaType := "image"
	if len(header.Filename) > 4 {
		ext := header.Filename[len(header.Filename)-4:]
		if ext == ".mp4" || ext == ".mov" {
			mediaType = "video"
		}
	}
	id := uuid.NewString()
	db.DB.Exec(`INSERT INTO stories(id,user_id,media_url,media_type) VALUES($1,$2,$3,$4)`,
		id, uid, url, mediaType)
	utils.Created(c, gin.H{"id": id, "media_url": url})
}

func (h *StoryHandler) Feed(c *gin.Context) {
	uid := utils.UserID(c)
	rows, _ := db.DB.Query(`SELECT s.id,s.user_id,s.media_url,s.media_type,s.expires_at,u.name,u.avatar_url
		FROM stories s JOIN users u ON u.id=s.user_id
		WHERE s.expires_at > NOW() AND (s.user_id=$1 OR s.user_id IN (
			SELECT following_id FROM follows WHERE follower_id=$1
		)) ORDER BY s.created_at DESC`, uid)
	defer rows.Close()
	type StoryFeed struct {
		models.Story
		UserName   string `json:"user_name"`
		AvatarURL  string `json:"avatar_url"`
	}
	var stories []StoryFeed
	for rows.Next() {
		var s StoryFeed
		rows.Scan(&s.ID, &s.UserID, &s.MediaURL, &s.MediaType, &s.ExpiresAt, &s.UserName, &s.AvatarURL)
		stories = append(stories, s)
	}
	if stories == nil {
		stories = []StoryFeed{}
	}
	utils.OK(c, stories)
}

// ========== FOLLOW ==========

type FollowHandler struct{}

func NewFollowHandler() *FollowHandler { return &FollowHandler{} }

func (h *FollowHandler) Follow(c *gin.Context) {
	uid := utils.UserID(c)
	targetID := c.Param("id")
	if uid == targetID {
		utils.Err(c, http.StatusBadRequest, "cannot follow yourself")
		return
	}
	db.DB.Exec(`INSERT INTO follows(id,follower_id,following_id) VALUES($1,$2,$3) ON CONFLICT DO NOTHING`,
		uuid.NewString(), uid, targetID)
	// Notification
	db.DB.Exec(`INSERT INTO notifications(id,user_id,type,title,ref_id) VALUES($1,$2,$3,$4,$5)`,
		uuid.NewString(), targetID, "follow", "Someone followed you", uid)
	utils.OK(c, gin.H{"message": "followed"})
}

func (h *FollowHandler) Unfollow(c *gin.Context) {
	uid := utils.UserID(c)
	targetID := c.Param("id")
	db.DB.Exec(`DELETE FROM follows WHERE follower_id=$1 AND following_id=$2`, uid, targetID)
	utils.OK(c, gin.H{"message": "unfollowed"})
}

func (h *FollowHandler) Followers(c *gin.Context) {
	id := c.Param("id")
	rows, _ := db.DB.Query(`SELECT u.id,u.name,u.avatar_url FROM follows f
		JOIN users u ON u.id=f.follower_id WHERE f.following_id=$1`, id)
	defer rows.Close()
	var users []models.User
	for rows.Next() {
		var u models.User
		rows.Scan(&u.ID, &u.Name, &u.AvatarURL)
		users = append(users, u)
	}
	if users == nil {
		users = []models.User{}
	}
	utils.OK(c, users)
}

// ========== MESSAGES ==========

type MessageHandler struct{}

func NewMessageHandler() *MessageHandler { return &MessageHandler{} }

func (h *MessageHandler) Send(c *gin.Context) {
	uid := utils.UserID(c)
	var in struct {
		ReceiverID string `json:"receiver_id" binding:"required"`
		Content    string `json:"content" binding:"required"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}
	id := uuid.NewString()
	db.DB.Exec(`INSERT INTO messages(id,sender_id,receiver_id,content) VALUES($1,$2,$3,$4)`,
		id, uid, in.ReceiverID, in.Content)
	utils.Created(c, gin.H{"id": id})
}

func (h *MessageHandler) Conversation(c *gin.Context) {
	uid := utils.UserID(c)
	otherID := c.Param("user_id")
	rows, _ := db.DB.Query(`SELECT id,sender_id,receiver_id,content,is_read,created_at FROM messages
		WHERE (sender_id=$1 AND receiver_id=$2) OR (sender_id=$2 AND receiver_id=$1)
		ORDER BY created_at ASC`, uid, otherID)
	defer rows.Close()
	var msgs []models.Message
	for rows.Next() {
		var m models.Message
		rows.Scan(&m.ID, &m.SenderID, &m.ReceiverID, &m.Content, &m.IsRead, &m.CreatedAt)
		msgs = append(msgs, m)
	}
	if msgs == nil {
		msgs = []models.Message{}
	}
	db.DB.Exec(`UPDATE messages SET is_read=true WHERE receiver_id=$1 AND sender_id=$2`, uid, otherID)
	utils.OK(c, msgs)
}

// ========== NOTIFICATIONS ==========

type NotificationHandler struct{}

func NewNotificationHandler() *NotificationHandler { return &NotificationHandler{} }

func (h *NotificationHandler) List(c *gin.Context) {
	uid := utils.UserID(c)
	rows, _ := db.DB.Query(`SELECT id,type,title,body,is_read,created_at FROM notifications
		WHERE user_id=$1 ORDER BY created_at DESC LIMIT 50`, uid)
	defer rows.Close()
	var notifs []models.Notification
	for rows.Next() {
		var n models.Notification
		rows.Scan(&n.ID, &n.Type, &n.Title, &n.Body, &n.IsRead, &n.CreatedAt)
		notifs = append(notifs, n)
	}
	if notifs == nil {
		notifs = []models.Notification{}
	}
	utils.OK(c, notifs)
}

func (h *NotificationHandler) MarkRead(c *gin.Context) {
	uid := utils.UserID(c)
	db.DB.Exec(`UPDATE notifications SET is_read=true WHERE user_id=$1`, uid)
	utils.OK(c, gin.H{"message": "marked all read"})
}

// ========== CATEGORIES ==========

type CategoryHandler struct{}

func NewCategoryHandler() *CategoryHandler { return &CategoryHandler{} }

func (h *CategoryHandler) List(c *gin.Context) {
	rows, _ := db.DB.Query(`SELECT id,name,slug,icon_url FROM categories ORDER BY name`)
	defer rows.Close()
	var cats []models.Category
	for rows.Next() {
		var cat models.Category
		rows.Scan(&cat.ID, &cat.Name, &cat.Slug, &cat.IconURL)
		cats = append(cats, cat)
	}
	if cats == nil {
		cats = []models.Category{}
	}
	utils.OK(c, cats)
}

func (h *CategoryHandler) Create(c *gin.Context) {
	var in struct {
		Name    string `json:"name" binding:"required"`
		Slug    string `json:"slug" binding:"required"`
		IconURL string `json:"icon_url"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}
	id := uuid.NewString()
	db.DB.Exec(`INSERT INTO categories(id,name,slug,icon_url) VALUES($1,$2,$3,$4)`,
		id, in.Name, in.Slug, in.IconURL)
	utils.Created(c, gin.H{"id": id})
}

// ========== ADMIN ==========

type AdminHandler struct{}

func NewAdminHandler() *AdminHandler { return &AdminHandler{} }

func (h *AdminHandler) Stats(c *gin.Context) {
	var users, products, orders int
	db.DB.QueryRow(`SELECT COUNT(*) FROM users`).Scan(&users)
	db.DB.QueryRow(`SELECT COUNT(*) FROM products`).Scan(&products)
	db.DB.QueryRow(`SELECT COUNT(*) FROM orders`).Scan(&orders)
	utils.OK(c, gin.H{
		"total_users":    users,
		"total_products": products,
		"total_orders":   orders,
	})
}

func (h *AdminHandler) BanUser(c *gin.Context) {
	id := c.Param("id")
	db.DB.Exec(`UPDATE users SET is_banned=true,updated_at=$1 WHERE id=$2`, time.Now(), id)
	utils.OK(c, gin.H{"message": "user banned"})
}

func (h *AdminHandler) UnbanUser(c *gin.Context) {
	id := c.Param("id")
	db.DB.Exec(`UPDATE users SET is_banned=false,updated_at=$1 WHERE id=$2`, time.Now(), id)
	utils.OK(c, gin.H{"message": "user unbanned"})
}

func (h *AdminHandler) VerifySeller(c *gin.Context) {
	id := c.Param("id")
	db.DB.Exec(`UPDATE users SET is_verified=true,updated_at=$1 WHERE id=$2`, time.Now(), id)
	utils.OK(c, gin.H{"message": "seller verified"})
}

func (h *AdminHandler) DeleteProduct(c *gin.Context) {
	id := c.Param("id")
	db.DB.Exec(`DELETE FROM products WHERE id=$1`, id)
	utils.OK(c, gin.H{"message": "product deleted"})
}

func (h *AdminHandler) ListUsers(c *gin.Context) {
	rows, _ := db.DB.Query(`SELECT id,name,email,phone,role,is_verified,is_banned,created_at FROM users ORDER BY created_at DESC LIMIT 100`)
	defer rows.Close()
	var users []models.User
	for rows.Next() {
		var u models.User
		rows.Scan(&u.ID, &u.Name, &u.Email, &u.Phone, &u.Role, &u.IsVerified, &u.IsBanned, &u.CreatedAt)
		users = append(users, u)
	}
	if users == nil {
		users = []models.User{}
	}
	utils.OK(c, users)
}

func (h *AdminHandler) UpdateOrderStatus(c *gin.Context) {
	oid := c.Param("id")
	var in struct {
		Status string `json:"status" binding:"required"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}
	db.DB.Exec(`UPDATE orders SET status=$1,updated_at=$2 WHERE id=$3`, in.Status, time.Now(), oid)
	utils.OK(c, gin.H{"message": "status updated"})
}

func (h *AdminHandler) ListOrders(c *gin.Context) {
	rows, _ := db.DB.Query(`SELECT id,user_id,status,total,created_at FROM orders ORDER BY created_at DESC LIMIT 100`)
	defer rows.Close()
	var orders []models.Order
	for rows.Next() {
		var o models.Order
		rows.Scan(&o.ID, &o.UserID, &o.Status, &o.Total, &o.CreatedAt)
		orders = append(orders, o)
	}
	if orders == nil {
		orders = []models.Order{}
	}
	utils.OK(c, orders)
}
