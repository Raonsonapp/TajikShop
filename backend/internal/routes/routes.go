package routes

import (
	"tajikshop/internal/handlers"
	"tajikshop/internal/middleware"
	"tajikshop/internal/storage"

	"github.com/gin-gonic/gin"
)

func Setup(r *gin.Engine, secret string, r2 *storage.R2Client) {
	r.Use(middleware.CORS())

	// Handlers
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

	api := r.Group("/api/v1")

	// ── Auth ──────────────────────────────────────────────
	auth := api.Group("/auth")
	{
		auth.POST("/register", uh.Register)
		auth.POST("/login", uh.Login)
		auth.POST("/refresh", uh.RefreshToken)
	}

	// ── Users ─────────────────────────────────────────────
	users := api.Group("/users").Use(middleware.Auth())
	{
		users.GET("/me", uh.Me)
		users.PUT("/me", uh.UpdateProfile)
		users.POST("/me/avatar", uh.UploadAvatar)
		users.POST("/me/become-seller", uh.BecomeSellerHandler)
	}

	// ── Products ──────────────────────────────────────────
	products := api.Group("/products")
	{
		products.GET("", ph.List)
		products.GET("/trending", ph.Trending)
		products.GET("/:id", ph.GetByID)
		products.GET("/:product_id/reviews", rh.ByProduct)

		seller := products.Group("").Use(middleware.Auth(), middleware.SellerOnly())
		seller.POST("", ph.Create)
		seller.PUT("/:id", ph.Update)
		seller.DELETE("/:id", ph.Delete)
		seller.POST("/:id/images", ph.UploadImages)
	}

	// ── Categories ────────────────────────────────────────
	api.GET("/categories", ch.List)

	// ── Reviews ───────────────────────────────────────────
	api.POST("/reviews", middleware.Auth(), rh.Create)

	// ── Cart ──────────────────────────────────────────────
	cart := api.Group("/cart").Use(middleware.Auth())
	{
		cart.GET("", oh.GetCart)
		cart.POST("", oh.AddToCart)
		cart.DELETE("/:id", oh.RemoveFromCart)
	}

	// ── Orders ────────────────────────────────────────────
	orders := api.Group("/orders").Use(middleware.Auth())
	{
		orders.POST("/checkout", oh.Checkout)
		orders.GET("", oh.MyOrders)
		orders.GET("/:id", oh.GetOrder)
		orders.POST("/:id/payment-proof", oh.UploadPaymentProof)
	}

	// ── Favorites ─────────────────────────────────────────
	favs := api.Group("/favorites").Use(middleware.Auth())
	{
		favs.GET("", fh.List)
		favs.POST("", fh.Add)
		favs.DELETE("/:product_id", fh.Remove)
	}

	// ── Addresses ─────────────────────────────────────────
	addrs := api.Group("/addresses").Use(middleware.Auth())
	{
		addrs.GET("", ah.List)
		addrs.POST("", ah.Create)
		addrs.DELETE("/:id", ah.Delete)
	}

	// ── Stories ───────────────────────────────────────────
	stories := api.Group("/stories").Use(middleware.Auth())
	{
		stories.GET("/feed", sh.Feed)
		stories.POST("", sh.Create)
	}

	// ── Follow ────────────────────────────────────────────
	follows := api.Group("/users").Use(middleware.Auth())
	{
		follows.POST("/:id/follow", flh.Follow)
		follows.DELETE("/:id/follow", flh.Unfollow)
		follows.GET("/:id/followers", flh.Followers)
	}

	// ── Messages ──────────────────────────────────────────
	msgs := api.Group("/messages").Use(middleware.Auth())
	{
		msgs.POST("", mh.Send)
		msgs.GET("/:user_id", mh.Conversation)
	}

	// ── Notifications ─────────────────────────────────────
	notifs := api.Group("/notifications").Use(middleware.Auth())
	{
		notifs.GET("", nh.List)
		notifs.POST("/read-all", nh.MarkRead)
	}

	// ── Admin ─────────────────────────────────────────────
	admin := api.Group("/admin").Use(middleware.Auth(), middleware.AdminOnly())
	{
		admin.GET("/stats", adm.Stats)
		admin.GET("/users", adm.ListUsers)
		admin.POST("/users/:id/ban", adm.BanUser)
		admin.POST("/users/:id/unban", adm.UnbanUser)
		admin.POST("/users/:id/verify-seller", adm.VerifySeller)
		admin.DELETE("/products/:id", adm.DeleteProduct)
		admin.GET("/orders", adm.ListOrders)
		admin.PATCH("/orders/:id/status", adm.UpdateOrderStatus)
		admin.POST("/categories", ch.Create)
	}

	// Health
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok", "service": "TajikShop API"})
	})
}
