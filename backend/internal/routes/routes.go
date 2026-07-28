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

	uh := handlers.NewUserHandler(secret, r2)
	ph := handlers.NewProductHandler(r2)
	oh := handlers.NewOrderHandler(r2)
	rh := handlers.NewReviewHandler()
	fh := handlers.NewFavoriteHandler()
	ah := handlers.NewAddressHandler()
	sh := handlers.NewStoryHandler(r2)
	flh := handlers.NewFollowHandler()
	mh := handlers.NewMessageHandler()
	nh := handlers.NewNotificationHandler()
	ch := handlers.NewCategoryHandler()
	adm := handlers.NewAdminHandler()
	wh := handlers.NewWalletHandler()
	cph := handlers.NewCouponHandler()
	rph := handlers.NewReportHandler()
	bh := handlers.NewBrandHandler()
	vh := handlers.NewVariantHandler()
	qah := handlers.NewQAHandler()
	reh := handlers.NewReturnHandler()

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
	api.POST("/users/me/seller-verify", middleware.Auth(), uh.SellerVerify)
	api.POST("/users/me/fcm-token", middleware.Auth(), uh.SaveFCMToken)
	api.PUT("/users/me/location", middleware.Auth(), uh.UpdateLocation)
	api.POST("/users/:id/follow", middleware.Auth(), flh.Follow)
	api.DELETE("/users/:id/follow", middleware.Auth(), flh.Unfollow)
	api.GET("/users/:id/followers", middleware.Auth(), flh.Followers)
	api.GET("/users/:id/public", uh.PublicProfile)

	// Products
	api.GET("/products", ph.List)
	api.GET("/products/trending", ph.Trending)
	api.GET("/products/:id", ph.GetByID)
	api.POST("/products", middleware.Auth(), middleware.SellerOnly(), ph.Create)
	api.PUT("/products/:id", middleware.Auth(), middleware.SellerOnly(), ph.Update)
	api.DELETE("/products/:id", middleware.Auth(), middleware.SellerOnly(), ph.Delete)
	api.POST("/products/:id/images", middleware.Auth(), middleware.SellerOnly(), ph.UploadImages)
	api.GET("/products/:id/variants", vh.ByProduct)
	api.POST("/products/:id/variants", middleware.Auth(), middleware.SellerOnly(), vh.Add)
	api.DELETE("/variants/:id", middleware.Auth(), middleware.SellerOnly(), vh.Delete)

	// Brands
	api.GET("/brands", bh.List)
	api.POST("/admin/brands", middleware.Auth(), middleware.AdminOnly(), bh.Create)

	// Reviews — separate path to avoid conflict
	api.GET("/reviews/product/:product_id", rh.ByProduct)
	api.POST("/reviews", middleware.Auth(), rh.Create)
	api.POST("/reviews/:id/helpful", middleware.Auth(), rh.Helpful)

	// Q&A (савол-ҷавоб дар маҳсулот)
	api.GET("/products/:id/questions", qah.ByProduct)
	api.POST("/products/:id/questions", middleware.Auth(), qah.Ask)
	api.POST("/questions/:id/answer", middleware.Auth(), qah.Answer)

	// Categories
	api.GET("/categories", ch.List)

	// Cart
	api.GET("/cart", middleware.Auth(), oh.GetCart)
	api.POST("/cart", middleware.Auth(), oh.AddToCart)
	api.PATCH("/cart/:id", middleware.Auth(), oh.UpdateCartItem)
	api.DELETE("/cart/:id", middleware.Auth(), oh.RemoveFromCart)

	// Orders
	api.POST("/orders/checkout", middleware.Auth(), oh.Checkout)
	api.GET("/orders", middleware.Auth(), oh.MyOrders)
	api.GET("/orders/:id", middleware.Auth(), oh.GetOrder)
	api.POST("/orders/:id/payment-proof", middleware.Auth(), oh.UploadPaymentProof)
	api.POST("/orders/:id/cancel", middleware.Auth(), oh.Cancel)
	api.POST("/orders/:id/confirm", middleware.Auth(), oh.Confirm)
	api.POST("/orders/:id/return", middleware.Auth(), reh.Create)
	api.GET("/orders/:id/return", middleware.Auth(), reh.ForOrder)

	// Favorites
	api.GET("/favorites", middleware.Auth(), fh.List)
	api.POST("/favorites", middleware.Auth(), fh.Add)
	api.DELETE("/favorites/:product_id", middleware.Auth(), fh.Remove)

	// Addresses
	api.GET("/addresses", middleware.Auth(), ah.List)
	api.POST("/addresses", middleware.Auth(), ah.Create)
	api.PATCH("/addresses/:id/default", middleware.Auth(), ah.SetDefault)
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

	// Wallet
	api.GET("/wallet", middleware.Auth(), wh.Get)
	api.POST("/wallet/topup", middleware.Auth(), wh.TopUp)

	// Coupons
	api.GET("/coupons/validate", middleware.Auth(), cph.Validate)

	// Reports (зидди сӯиистифода)
	api.POST("/reports", middleware.Auth(), rph.Create)
	api.GET("/admin/reports", middleware.Auth(), middleware.AdminOnly(), rph.AdminList)
	api.POST("/admin/reports/:id/resolve", middleware.Auth(), middleware.AdminOnly(), rph.AdminResolve)

	// Admin
	api.GET("/admin/stats", middleware.Auth(), middleware.AdminOnly(), adm.Stats)
	api.GET("/admin/users", middleware.Auth(), middleware.AdminOnly(), adm.ListUsers)
	api.POST("/admin/users/:id/ban", middleware.Auth(), middleware.AdminOnly(), adm.BanUser)
	api.POST("/admin/users/:id/unban", middleware.Auth(), middleware.AdminOnly(), adm.UnbanUser)
	api.POST("/admin/users/:id/verify-seller", middleware.Auth(), middleware.AdminOnly(), adm.VerifySeller)
	api.POST("/admin/users/:id/reject-seller", middleware.Auth(), middleware.AdminOnly(), adm.RejectSeller)
	api.GET("/admin/seller-requests", middleware.Auth(), middleware.AdminOnly(), adm.SellerRequests)
	api.DELETE("/admin/products/:id", middleware.Auth(), middleware.AdminOnly(), adm.DeleteProduct)
	api.GET("/admin/orders", middleware.Auth(), middleware.AdminOnly(), adm.ListOrders)
	api.PATCH("/admin/orders/:id/status", middleware.Auth(), middleware.AdminOnly(), adm.UpdateOrderStatus)
	api.POST("/admin/categories", middleware.Auth(), middleware.AdminOnly(), ch.Create)
	api.POST("/admin/coupons", middleware.Auth(), middleware.AdminOnly(), cph.Create)
	api.GET("/admin/coupons", middleware.Auth(), middleware.AdminOnly(), cph.List)
	api.GET("/admin/returns", middleware.Auth(), middleware.AdminOnly(), reh.AdminList)
	api.POST("/admin/returns/:id/status", middleware.Auth(), middleware.AdminOnly(), reh.AdminUpdate)
	api.GET("/admin/wallet/pending", middleware.Auth(), middleware.AdminOnly(), wh.AdminPending)
	api.POST("/admin/wallet/tx/:id/approve", middleware.Auth(), middleware.AdminOnly(), wh.AdminApprove)
	api.POST("/admin/wallet/tx/:id/reject", middleware.Auth(), middleware.AdminOnly(), wh.AdminReject)

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
