package middleware

import (
	"net/http"
	"strings"
	"tajikshop/internal/auth"
	"tajikshop/internal/db"

	"github.com/gin-gonic/gin"
)

var jwtSecret string

func SetSecret(s string) { jwtSecret = s }

func Auth() gin.HandlerFunc {
	return func(c *gin.Context) {
		header := c.GetHeader("Authorization")
		if header == "" || !strings.HasPrefix(header, "Bearer ") {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "missing token"})
			return
		}
		tokenStr := strings.TrimPrefix(header, "Bearer ")
		claims, err := auth.ParseToken(tokenStr, jwtSecret)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
			return
		}
		c.Set("user_id", claims.UserID)
		c.Set("role", claims.Role)
		c.Next()
	}
}

func AdminOnly() gin.HandlerFunc {
	return func(c *gin.Context) {
		role, _ := c.Get("role")
		if role != "admin" {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{"error": "admin only"})
			return
		}
		c.Next()
	}
}

// SellerOnly — DB-ро зинда тафтиш мекунад, то тасдиқи админ фавран эътибор пайдо
// кунад (JWT метавонад кӯҳна бошад). Танҳо фурӯшандаи тасдиқшуда/админ иҷозат дорад.
func SellerOnly() gin.HandlerFunc {
	return func(c *gin.Context) {
		if r, _ := c.Get("role"); r == "admin" {
			c.Next()
			return
		}
		uid, _ := c.Get("user_id")
		var isSeller bool
		var role string
		_ = db.DB.QueryRow(`SELECT is_seller, role FROM users WHERE id=$1`, uid).Scan(&isSeller, &role)
		if isSeller || role == "seller" || role == "admin" {
			c.Next()
			return
		}
		c.AbortWithStatusJSON(http.StatusForbidden, gin.H{"error": "Танҳо фурӯшандаи тасдиқшуда метавонад эълон гузорад. Дархости шумо баррасӣ мешавад."})
	}
}

func CORS() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET,POST,PUT,PATCH,DELETE,OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Authorization,Content-Type")
		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	}
}
