package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"

	"tajikshop/internal/db"
	"tajikshop/internal/handlers"
)

func main() {
	// load .env (локально)
	err := godotenv.Load()
	if err != nil {
		log.Println("No .env file found (ok in production)")
	}

	// connect database
	db.Connect()

	// router
	r := gin.Default()

	r.GET("/ping", func(c *gin.Context) {
		c.JSON(200, gin.H{"message": "ok"})
	})

	r.POST("/products", handlers.CreateProduct)

	// port
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Println("🚀 running on", port)
	r.Run(":" + port)
}
