package routes

import (
	"os"
	"tajikshop/internal/handles"
	"tajikshop/internal/middleware"
	"tajikshop/internal/storage"

	"github.com/gin-gonic/gin"
)

func Setup(r *gin.Engine, secret string, r2 *storage.R2Client) {
	r.Use(middleware.CORS())

	uh  := handlers.NewUserHandler(secret, r2)
	ph  := handlers.NewProductHandler(r2)
	oh  := handlers.NewOrderHandler(r2)
	rh  := handlers.NewReviewHandler()
	fh  := handlers.NewFavoriteHandler()
	ah  := handlers.NewAddressHandler()
	sh  := handlers.NewStoryHandler(r2)
	flh := handlers.NewFollowHandler()
	mh  := handlers.NewMessageHandler()
	nh  := handlers.NewNotificationHandler()
	ch  := handlers.NewCategoryHandler()
	adm := handlers.NewAdminHandler()

	// Firebase handler — FIREBASE_PROJECT_ID env-дан мегирад
	fbh := handlers.NewFirebaseHandler(secret, getenv("FIREBASE_WEB_API_KEY", ""))

	api := r.Group("/api/v1")

	// Auth
	api.POST("/auth/register", uh.Register)
	api.POST("/auth/login", uh.Login)
	api.POST("/auth/refresh", uh.RefreshToken)
	api.POST("/auth/phone-verify", fbh.VerifyPhone)

	// Users
	api.GET("/users/me", middleware.Auth(), uh.Me)
	api.PUT("/users/me", middleware.Auth(), uh.UpdateProfile)
	api.POST("/users/me/avatar", middleware.Auth(), uh.UploadAvatar)
	api.POST("/users/me/become-seller", middleware.Auth(), uh.BecomeSellerHandler)
	api.POST("/users/:id/follow", middleware.Auth(), flh.Follow)
	api.DELETE("/users/:id/follow", middleware.Auth(), flh.Unfollow)
	api.GET("/users/:id/followers", middleware.Auth(), flh.Followers)

	// Products
	api.GET("/products", ph.List)
	api.GET("/products/trending", ph.Trending)
	api.GET("/products/:id", ph.GetByID)
	api.POST("/products", middleware.Auth(), middleware.SellerOnly(), ph.Create)
	api.PUT("/products/:id", middleware.Auth(), middleware.SellerOnly(), ph.Update)
	api.DELETE("/products/:id", middleware.Auth(), middleware.SellerOnly(), ph.Delete)
	api.POST("/products/:id/images", middleware.Auth(), middleware.SellerOnly(), ph.UploadImages)

	// Reviews — separate path to avoid conflict
	api.GET("/reviews/product/:product_id", rh.ByProduct)
	api.POST("/reviews", middleware.Auth(), rh.Create)

	// Categories
	api.GET("/categories", ch.List)

	// Cart
	api.GET("/cart", middleware.Auth(), oh.GetCart)
	api.POST("/cart", middleware.Auth(), oh.AddToCart)
	api.DELETE("/cart/:id", middleware.Auth(), oh.RemoveFromCart)

	// Orders
	api.POST("/orders/checkout", middleware.Auth(), oh.Checkout)
	api.GET("/orders", middleware.Auth(), oh.MyOrders)
	api.GET("/orders/:id", middleware.Auth(), oh.GetOrder)
	api.POST("/orders/:id/payment-proof", middleware.Auth(), oh.UploadPaymentProof)

	// Favorites
	api.GET("/favorites", middleware.Auth(), fh.List)
	api.POST("/favorites", middleware.Auth(), fh.Add)
	api.DELETE("/favorites/:product_id", middleware.Auth(), fh.Remove)

	// Addresses
	api.GET("/addresses", middleware.Auth(), ah.List)
	api.POST("/addresses", middleware.Auth(), ah.Create)
	api.DELETE("/addresses/:id", middleware.Auth(), ah.Delete)

	// Stories
	api.GET("/stories/feed", middleware.Auth(), sh.Feed)
	api.POST("/stories", middleware.Auth(), sh.Create)

	// Messages
	api.POST("/messages", middleware.Auth(), mh.Send)
	api.GET("/messages/:user_id", middleware.Auth(), mh.Conversation)

	// Notifications
	api.GET("/notifications", middleware.Auth(), nh.List)
	api.POST("/notifications/read-all", middleware.Auth(), nh.MarkRead)

	// Admin
	api.GET("/admin/stats", middleware.Auth(), middleware.AdminOnly(), adm.Stats)
	api.GET("/admin/users", middleware.Auth(), middleware.AdminOnly(), adm.ListUsers)
	api.POST("/admin/users/:id/ban", middleware.Auth(), middleware.AdminOnly(), adm.BanUser)
	api.POST("/admin/users/:id/unban", middleware.Auth(), middleware.AdminOnly(), adm.UnbanUser)
	api.POST("/admin/users/:id/verify-seller", middleware.Auth(), middleware.AdminOnly(), adm.VerifySeller)
	api.DELETE("/admin/products/:id", middleware.Auth(), middleware.AdminOnly(), adm.DeleteProduct)
	api.GET("/admin/orders", middleware.Auth(), middleware.AdminOnly(), adm.ListOrders)
	api.PATCH("/admin/orders/:id/status", middleware.Auth(), middleware.AdminOnly(), adm.UpdateOrderStatus)
	api.POST("/admin/categories", middleware.Auth(), middleware.AdminOnly(), ch.Create)

	// Health
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok", "service": "TajikShop API"})
	})
}

func getenv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
