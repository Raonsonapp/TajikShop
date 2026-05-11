package main

import (
	"log"
	"tajikshop/internal/config"
	"tajikshop/internal/db"
	"tajikshop/internal/middleware"
	"tajikshop/internal/routes"
	"tajikshop/internal/storage"

	"github.com/gin-gonic/gin"
)

func main() {
	cfg := config.Load()

	db.Connect(cfg.DBUrl)
	db.Migrate() // Танҳо ҷадвалҳои нав месозад — DROP намекунад

	middleware.SetSecret(cfg.JWTSecret)

	var r2 *storage.R2Client
	if cfg.R2Endpoint != "" && cfg.R2AccessKey != "" {
		var err error
		r2, err = storage.NewR2Client(cfg.R2Endpoint, cfg.R2AccessKey, cfg.R2SecretKey, cfg.R2Bucket, cfg.R2PublicURL)
		if err != nil {
			log.Printf("⚠️  R2 not configured: %v", err)
		} else {
			log.Println("✅ Cloudflare R2 connected")
		}
	}

	r := gin.Default()
	routes.Setup(r, cfg.JWTSecret, r2)

	log.Printf("🚀 TajikShop API running on :%s", cfg.Port)
	if err := r.Run(":" + cfg.Port); err != nil {
		log.Fatalf("❌ Server failed: %v", err)
	}
}
