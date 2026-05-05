package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"

	"tajikshop/internal/db"
)

func main() {
	// Debug: DB_URL-ро санҷед
	dbURL := os.Getenv("DB_URL")
	if dbURL == "" {
		log.Fatal("❌ ХАТО: DB_URL environment variable холӣ аст! Онро дар Render → Environment илова кун.")
	} else {
		log.Println("✅ DB_URL ёфт шуд, пайваст мешавем...")
	}

	db.Connect()

	r := gin.Default()

	r.GET("/ping", func(c *gin.Context) {
		c.JSON(200, gin.H{"message": "🚀 TajikShop LIVE"})
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Println("Server running on", port)
	r.Run(":" + port)
}
