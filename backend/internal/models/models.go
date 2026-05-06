package models

import "time"

type User struct {
	ID           string    `json:"id"`
	Name         string    `json:"name"`
	Email        string    `json:"email"`
	Phone        string    `json:"phone"`
	PasswordHash string    `json:"-"`
	AvatarURL    string    `json:"avatar_url"`
	Bio          string    `json:"bio"`
	Role         string    `json:"role"`
	IsVerified   bool      `json:"is_verified"`
	IsSeller     bool      `json:"is_seller"`
	IsBanned     bool      `json:"is_banned"`
	RefreshToken string    `json:"-"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

type Product struct {
	ID              string    `json:"id"`
	SellerID        string    `json:"seller_id"`
	CategoryID      string    `json:"category_id"`
	Title           string    `json:"title"`
	Description     string    `json:"description"`
	Price           float64   `json:"price"`
	DiscountPercent int       `json:"discount_percent"`
	Stock           int       `json:"stock"`
	IsActive        bool      `json:"is_active"`
	Views           int       `json:"views"`
	VideoURL        string    `json:"video_url"`
	Images          []string  `json:"images"`
	SellerName      string    `json:"seller_name,omitempty"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
}

type Category struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	Slug      string    `json:"slug"`
	IconURL   string    `json:"icon_url"`
	ParentID  string    `json:"parent_id"`
	CreatedAt time.Time `json:"created_at"`
}

type CartItem struct {
	ID        string    `json:"id"`
	UserID    string    `json:"user_id"`
	ProductID string    `json:"product_id"`
	Quantity  int       `json:"quantity"`
	Product   *Product  `json:"product,omitempty"`
	CreatedAt time.Time `json:"created_at"`
}

type Address struct {
	ID        string    `json:"id"`
	UserID    string    `json:"user_id"`
	Title     string    `json:"title"`
	City      string    `json:"city"`
	Street    string    `json:"street"`
	Zip       string    `json:"zip"`
	IsDefault bool      `json:"is_default"`
	CreatedAt time.Time `json:"created_at"`
}

type Order struct {
	ID           string      `json:"id"`
	UserID       string      `json:"user_id"`
	AddressID    string      `json:"address_id"`
	Status       string      `json:"status"`
	Total        float64     `json:"total"`
	PaymentProof string      `json:"payment_proof"`
	Note         string      `json:"note"`
	Items        []OrderItem `json:"items,omitempty"`
	CreatedAt    time.Time   `json:"created_at"`
	UpdatedAt    time.Time   `json:"updated_at"`
}

type OrderItem struct {
	ID        string    `json:"id"`
	OrderID   string    `json:"order_id"`
	ProductID string    `json:"product_id"`
	Quantity  int       `json:"quantity"`
	Price     float64   `json:"price"`
	CreatedAt time.Time `json:"created_at"`
}

type Review struct {
	ID        string    `json:"id"`
	UserID    string    `json:"user_id"`
	ProductID string    `json:"product_id"`
	Rating    int       `json:"rating"`
	Comment   string    `json:"comment"`
	UserName  string    `json:"user_name,omitempty"`
	CreatedAt time.Time `json:"created_at"`
}

type Message struct {
	ID         string    `json:"id"`
	SenderID   string    `json:"sender_id"`
	ReceiverID string    `json:"receiver_id"`
	Content    string    `json:"content"`
	IsRead     bool      `json:"is_read"`
	CreatedAt  time.Time `json:"created_at"`
}

type Notification struct {
	ID        string    `json:"id"`
	UserID    string    `json:"user_id"`
	Type      string    `json:"type"`
	Title     string    `json:"title"`
	Body      string    `json:"body"`
	IsRead    bool      `json:"is_read"`
	RefID     string    `json:"ref_id"`
	CreatedAt time.Time `json:"created_at"`
}

type Story struct {
	ID        string    `json:"id"`
	UserID    string    `json:"user_id"`
	MediaURL  string    `json:"media_url"`
	MediaType string    `json:"media_type"`
	ExpiresAt time.Time `json:"expires_at"`
	CreatedAt time.Time `json:"created_at"`
}

type Follow struct {
	ID          string    `json:"id"`
	FollowerID  string    `json:"follower_id"`
	FollowingID string    `json:"following_id"`
	CreatedAt   time.Time `json:"created_at"`
}
