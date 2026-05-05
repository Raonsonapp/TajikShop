package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"

	"tajikshop/internal/db"
	"tajikshop/internal/handlers"
	"tajikshop/internal/storage"
)

func main() {
	godotenv.Load()

	db.Connect()
	storage.InitR2()

	r := gin.Default()

	r.GET("/ping", func(c *gin.Context) {
		c.JSON(200, gin.H{"message": "ok"})
	})

	r.POST("/products", handlers.CreateProduct)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Println("🚀 running on", port)
	r.Run(":" + port)
}
