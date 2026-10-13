package routes

import (
	"os"
	"tajikshop/internal/handles"
	"tajikshop/internal/middleware"
	"tajikshop/internal/storage"

	"github.com/gin-gonic/gin"
)

func Setup(r *gin.Engine, secret string, r2 *storage.R2Client, ssoPartnerKey string) {
	r.Use(middleware.CORS())

	uh := handlers.NewUserHandler(secret, r2)
	ph := handlers.NewProductHandler(r2)
	oh := handlers.NewOrderHandler(r2)
	rh := handlers.NewReviewHandler(r2)
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
	rfq := handlers.NewRFQHandler()
	cargo := handlers.NewCargoHandler()
	rph := handlers.NewReportHandler()
	bh := handlers.NewBrandHandler()
	vh := handlers.NewVariantHandler()
	qah := handlers.NewQAHandler()
	reh := handlers.NewReturnHandler()
	vh2 := handlers.NewVerificationHandler(r2)

	// Firebase handler — FIREBASE_PROJECT_ID env-дан мегирад
	fbh := handlers.NewFirebaseHandler(secret, getenv("FIREBASE_WEB_API_KEY", ""))

	// ── Саҳифаҳои оммавии ҳуқуқӣ (Google Play) — root, бе login ──
	legal := handlers.NewLegalHandler()
	r.GET("/privacy", legal.Privacy)
	r.GET("/terms", legal.Terms)
	r.GET("/delete-account", legal.DeleteAccountPage)

	api := r.Group("/api/v1")
	api.POST("/account/deletion-request", legal.DeletionRequest)

	// Auth
	api.POST("/auth/register", uh.Register)
	api.POST("/auth/login", uh.Login)
	api.POST("/auth/refresh", uh.RefreshToken)
	api.POST("/auth/logout", uh.Logout)
	api.PUT("/users/me/password", middleware.Auth(), uh.ChangePassword)
	api.POST("/auth/phone-verify", fbh.VerifyPhone)

	// Users
	api.GET("/users/me", middleware.Auth(), uh.Me)
	api.PUT("/users/me", middleware.Auth(), uh.UpdateProfile)
	api.DELETE("/users/me", middleware.Auth(), uh.DeleteAccount)
	api.POST("/users/me/avatar", middleware.Auth(), uh.UploadAvatar)
	api.POST("/users/me/become-seller", middleware.Auth(), uh.BecomeSellerHandler)
	api.POST("/users/me/seller-verify", middleware.Auth(), uh.SellerVerify)
	api.GET("/seller/stats", middleware.Auth(), uh.SellerStats)
	api.GET("/seller/orders", middleware.Auth(), middleware.SellerOnly(), uh.SellerOrders)
	api.POST("/seller/orders/:id/status", middleware.Auth(), middleware.SellerOnly(), oh.SellerUpdateOrderStatus)
	api.POST("/seller/payments/confirm-sms", middleware.Auth(), middleware.SellerOnly(), oh.ConfirmPaymentBySMS)
	api.GET("/seller/sales-chart", middleware.Auth(), middleware.SellerOnly(), uh.SellerSalesChart)
	api.GET("/users/me/referral", middleware.Auth(), uh.ReferralInfo)
	api.GET("/users/me/loyalty", middleware.Auth(), uh.LoyaltyInfo)
	api.GET("/settings", adm.PublicSettings)
	api.GET("/shops", uh.ShopsList)
	api.POST("/admin/settings/commission", middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), adm.SetCommission)
	api.POST("/admin/settings/cashback", middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), adm.SetCashback)
	api.POST("/users/me/fcm-token", middleware.Auth(), uh.SaveFCMToken)
	api.PUT("/users/me/location", middleware.Auth(), uh.UpdateLocation)
	api.POST("/users/:id/follow", middleware.Auth(), flh.Follow)
	api.DELETE("/users/:id/follow", middleware.Auth(), flh.Unfollow)
	api.GET("/users/:id/followers", middleware.Auth(), flh.Followers)
	api.GET("/users/:id/public", uh.PublicProfile)
	api.GET("/users/:id/rating", oh.SellerRating)
	api.PUT("/users/me/username", middleware.Auth(), oh.SetUsername)
	api.GET("/users/username-available", oh.CheckUsername)

	// Галочкаи тасдиқ (пардохт ба корти TajikShop → тасдиқи админ)
	// ── SSO: як ҳисоб барои Raonson ва TajikShop ──
	sso := handlers.NewSSOHandler(secret, ssoPartnerKey)
	api.GET("/sso/apps", sso.Apps)
	api.POST("/sso/code", middleware.Auth(), sso.IssueCode)
	api.POST("/sso/exchange", sso.Exchange)

	api.GET("/verification/info", vh2.Info)
	api.GET("/users/me/verification", middleware.Auth(), vh2.MyRequest)
	api.POST("/users/me/verification", middleware.Auth(), vh2.Request)
	api.GET("/admin/verification-requests", middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), vh2.AdminList)
	api.POST("/admin/verification-requests/:id/decide", middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), vh2.AdminDecide)

	// Products
	api.GET("/products", ph.List)
	api.GET("/products/trending", ph.Trending)
	api.GET("/products/flash", ph.FlashDeals)
	api.GET("/products/deals", ph.Deals)
	api.GET("/products/bestsellers", ph.Bestsellers)
	api.GET("/products/barcode/:code", ph.GetByBarcode)
	// ── Каталоги умумии штрих-кодҳо (мағозаҳои хӯрокворӣ) ──
	cat := handlers.NewCatalogHandler()
	api.GET("/catalog/barcode/:code", cat.Lookup)
	api.POST("/catalog/barcode", middleware.Auth(), middleware.SellerOnly(), cat.Contribute)
	api.GET("/seller/products/expiring", middleware.Auth(), middleware.SellerOnly(), cat.ExpiringSoon)
	api.GET("/products/:id", ph.GetByID)
	api.POST("/products", middleware.Auth(), middleware.SellerOnly(), ph.Create)
	api.PUT("/products/:id", middleware.Auth(), middleware.SellerOnly(), ph.Update)
	api.DELETE("/products/:id", middleware.Auth(), middleware.SellerOnly(), ph.Delete)
	api.POST("/products/:id/boost", middleware.Auth(), middleware.SellerOnly(), ph.Boost)
	// Маҳсулоти тамомшуда: «боз ҳаст?» → ҳа (restock) ё не (DELETE-и болоӣ).
	api.GET("/seller/products/sold-out", middleware.Auth(), middleware.SellerOnly(), ph.SoldOutProducts)
	api.POST("/products/:id/restock", middleware.Auth(), middleware.SellerOnly(), ph.Restock)
	api.POST("/products/:id/images", middleware.Auth(), middleware.SellerOnly(), ph.UploadImages)
	// Зинаҳои нархи яклухт (1–9 чакана, 10–49 яклухт, 50+ ...).
	// Хондан оммавӣ аст — харидор бояд зинаҳоро пеш аз харид бинад.
	api.GET("/products/:id/tiers", ph.GetTiers)
	api.PUT("/products/:id/tiers", middleware.Auth(), middleware.SellerOnly(), ph.SetTiers)
	api.GET("/products/:id/variants", vh.ByProduct)
	api.POST("/products/:id/variants", middleware.Auth(), middleware.SellerOnly(), vh.Add)
	api.DELETE("/variants/:id", middleware.Auth(), middleware.SellerOnly(), vh.Delete)

	// Brands
	api.GET("/brands", bh.List)
	api.POST("/admin/brands", middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), bh.Create)

	// Reviews — separate path to avoid conflict
	api.GET("/reviews/product/:product_id", rh.ByProduct)
	api.POST("/reviews", middleware.Auth(), rh.Create)
	api.POST("/reviews/upload", middleware.Auth(), rh.UploadImages)
	api.POST("/reviews/:id/helpful", middleware.Auth(), rh.Helpful)

	// Q&A (савол-ҷавоб дар маҳсулот)
	api.GET("/products/:id/questions", qah.ByProduct)
	api.POST("/products/:id/questions", middleware.Auth(), qah.Ask)
	api.POST("/questions/:id/answer", middleware.Auth(), qah.Answer)

	// Categories
	api.GET("/categories", ch.List)

	// Cart
	api.GET("/cart", middleware.Auth(), oh.GetCart)
	api.GET("/cart/sellers", middleware.Auth(), oh.CartSellers)
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
	api.GET("/orders/:id/timeline", middleware.Auth(), oh.OrderTimeline)
	api.POST("/orders/:id/rate-seller", middleware.Auth(), oh.RateSeller)
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
	api.GET("/stories/discover", sh.Discover)
	api.POST("/stories", middleware.Auth(), sh.Create)

	// Messages
	api.GET("/messages", middleware.Auth(), mh.Inbox)
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
	api.GET("/coupons/active", middleware.Auth(), cph.ActiveList)

	// Карго (доставка аз Хитой → ТҶ/РУ)
	api.GET("/cargo/info", cargo.Info)
	api.GET("/cargo", middleware.Auth(), cargo.MyList)
	api.POST("/cargo", middleware.Auth(), cargo.Create)
	api.GET("/admin/cargo", middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), cargo.AdminList)
	api.PATCH("/admin/cargo/:id", middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), cargo.AdminUpdate)
	api.POST("/admin/cargo/settings", middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), cargo.AdminSettings)

	// Reports (зидди сӯиистифода)
	api.POST("/reports", middleware.Auth(), rph.Create)
	api.GET("/admin/reports", middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), rph.AdminList)
	api.POST("/admin/reports/:id/resolve", middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), rph.AdminResolve)

	// Admin
	api.GET("/admin/stats", middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), adm.Stats)
	// Дафтари амалҳои админ. Худи хондан сабт намешавад (`GET`).
	api.GET("/admin/audit", middleware.Auth(), middleware.AdminOnly(), adm.AuditLog)
	api.GET("/admin/users/:id/audit", middleware.Auth(), middleware.AdminOnly(), adm.AuditLogForUser)
	api.GET("/admin/users", middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), adm.ListUsers)
	api.POST("/admin/users/:id/ban", middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), adm.BanUser)
	api.POST("/admin/users/:id/unban", middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), adm.UnbanUser)
	api.POST("/admin/users/:id/verify-seller", middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), adm.VerifySeller)
	api.POST("/admin/users/:id/reject-seller", middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), adm.RejectSeller)
	api.GET("/admin/seller-requests", middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), adm.SellerRequests)
	api.DELETE("/admin/products/:id", middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), adm.DeleteProduct)
	api.GET("/admin/orders", middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), adm.ListOrders)
	api.PATCH("/admin/orders/:id/status", middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), adm.UpdateOrderStatus)
	api.POST("/admin/categories", middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), ch.Create)
	api.POST("/admin/coupons", middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), cph.Create)
	api.GET("/admin/coupons", middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), cph.List)
	api.GET("/admin/returns", middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), reh.AdminList)
	api.POST("/admin/returns/:id/status", middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), reh.AdminUpdate)
	api.GET("/admin/wallet/pending", middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), wh.AdminPending)
	api.POST("/admin/wallet/tx/:id/approve", middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), wh.AdminApprove)
	api.POST("/admin/wallet/tx/:id/reject", middleware.Auth(), middleware.AdminOnly(), middleware.AuditAdmin(), wh.AdminReject)

	// Health — ҳолати сервер ВА анбори файлҳо (R2).
	//
	// Пас аз иваз кардани калидҳои Cloudflare маҳз ҳамин ҷо санҷида мешавад:
	// `storage: "ok"` маънои онро дорад, ки калидҳои нав кор мекунанд.
	// Ҳеҷ як калид ин ҷо намоён намешавад.
	// ── RFQ: дархости нарх (Request for Quotation) ───────────────────────
	//
	// Қоидаи амният: фурӯшанда пешниҳоди РАҚИБОНАШро намебинад. Бе ин
	// тамоми RFQ бефоида аст — фурӯшандаи дуюм нархи аввалро мебинад ва
	// як дирам камтар мегузорад.
	api.POST("/rfqs", middleware.Auth(), rfq.Create)
	api.GET("/rfqs/my", middleware.Auth(), rfq.MyRFQs)
	api.GET("/rfqs/open", middleware.Auth(), middleware.SellerOnly(), rfq.Open)
	api.GET("/rfqs/:id", middleware.Auth(), rfq.Get)
	api.POST("/rfqs/:id/close", middleware.Auth(), rfq.Close)
	api.POST("/rfqs/:id/quotes", middleware.Auth(), middleware.SellerOnly(), rfq.Quote)
	api.POST("/quotes/:id/withdraw", middleware.Auth(), middleware.SellerOnly(), rfq.Withdraw)
	api.POST("/quotes/:id/accept", middleware.Auth(), rfq.Award)

	r.GET("/health", func(c *gin.Context) {
		out := gin.H{"status": "ok", "service": "TajikShop API"}
		if r2 == nil {
			out["storage"] = "not configured"
			out["storage_public_url"] = false
		} else {
			out["storage"] = r2.Status()
			out["storage_public_url"] = r2.PublicURLSet()
		}
		c.JSON(200, out)
	})
}

func getenv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
