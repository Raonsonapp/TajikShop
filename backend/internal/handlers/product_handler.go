package handlers

import (
	"net/http"

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

	filename := uuid.New().String() + "_" + header.Filename

	url, err := storage.Upload(file, filename)
	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}

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
