package utils

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

func HashPassword(pw string) (string, error) {
	b, err := bcrypt.GenerateFromPassword([]byte(pw), bcrypt.DefaultCost)
	return string(b), err
}

func CheckPassword(hash, pw string) bool {
	return bcrypt.CompareHashAndPassword([]byte(hash), []byte(pw)) == nil
}

func OK(c *gin.Context, data interface{}) {
	c.JSON(http.StatusOK, gin.H{"success": true, "data": data})
}

func Created(c *gin.Context, data interface{}) {
	c.JSON(http.StatusCreated, gin.H{"success": true, "data": data})
}

func Err(c *gin.Context, code int, msg string) {
	c.JSON(code, gin.H{"success": false, "error": msg})
}

// Fail — хатои сохтор дошта, вақте ки барнома бояд на танҳо матн, балки
// ТАФСИЛОТро бигирад.
//
// Мисол: ҳангоми сохтани фармоиш барнома бояд бидонад, КАДОМ маҳсулот
// тамом шуд, то дар сабад маҳз ҳамонро сурх кунад. Бо `Err` танҳо як
// сатри матн мерафт ва барнома маҷбур мешуд онро таҳлил кунад.
//
// `error` ҳамчун матн низ мемонад, то мизоҷони кӯҳна вайрон нашаванд.
func Fail(c *gin.Context, code int, payload gin.H) {
	body := gin.H{"success": false}
	for k, v := range payload {
		body[k] = v
	}
	if msg, ok := payload["message"]; ok {
		body["error"] = msg
	}
	c.JSON(code, body)
}

// UserID — шиносаи корбари воридшуда.
//
// Бе санҷиши навъ `id.(string)` сервери тамомро мепартофт, агар рӯзе
// масире тасодуфан бе middleware-и аутентификатсия сабт шавад. Ҳоло
// сатри холӣ бармегардад, ва дархост танҳо «иҷозат нест» мегирад.
func UserID(c *gin.Context) string {
	v, ok := c.Get("user_id")
	if !ok {
		return ""
	}
	id, ok := v.(string)
	if !ok {
		return ""
	}
	return id
}
