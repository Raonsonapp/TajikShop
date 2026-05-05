package handlers

import (
	"io"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"tajikshop/internal/db"
	"tajikshop/internal/storage"
)

func CreateProduct(c *gin.Context) {
	title := c.PostForm("title")
	description := c.PostForm("description")
	price := c.PostForm("price")

	file, header, err := c.Request.FormFile("image")
	if err != nil {
		c.JSON(400, gin.H{"error": "image required"})
		return
	}
	defer file.Close()

	// 📦 файлро ба []byte табдил медиҳем
	fileBytes, err := io.ReadAll(file)
	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}

	fileName := uuid.New().String() + "_" + header.Filename

	// 🔥 R2 INIT
	r2 := storage.NewR2(
		os.Getenv("R2_ACCOUNT_ID"),
		os.Getenv("R2_ACCESS_KEY"),
		os.Getenv("R2_SECRET_KEY"),
		os.Getenv("R2_BUCKET"),
	)

	// 🚀 Upload
	url, err := r2.Upload(fileName, fileBytes)
	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}

	// 💾 DB save
	_, err = db.DB.Exec(`
		INSERT INTO products (id, title, description, price)
		VALUES ($1,$2,$3,$4)
	`,
		uuid.New().String(),
		title,
		description,
		price,
	)

	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "product created",
		"image":   url,
	})
}
