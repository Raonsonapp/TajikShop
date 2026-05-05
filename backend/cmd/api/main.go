package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"

	"tajikshop/internal/db"
)

func main() {
	// 👉 ИН САТРРО ИЛОВА КУН
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
