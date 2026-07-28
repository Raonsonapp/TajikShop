// Package mailer — огоҳии email ба админ (Gmail) мефиристад.
// Танҳо агар SMTP_USER ва SMTP_PASS дар env танзим шуда бошанд кор мекунад;
// вагарна бесамар мегузарад (build/логин вайрон намешавад).
package mailer

import (
	"fmt"
	"log"
	"net/smtp"
	"os"
	"strings"
)

// adminEmail — гирандаи огоҳиҳо. Аз env ADMIN_EMAIL, вагарна пешфарз.
func adminEmail() string {
	if v := os.Getenv("ADMIN_EMAIL"); v != "" {
		return v
	}
	return "ehsonmahmadmurodov@gmail.com"
}

func smtpAddr() string {
	if v := os.Getenv("SMTP_HOST"); v != "" {
		return v
	}
	return "smtp.gmail.com:587"
}

// Notify — email-и оддии матнӣ ба админ мефиристад (дар goroutine ҷеғ занед).
// Барои Gmail: SMTP_USER=you@gmail.com, SMTP_PASS=<App Password-и 16-рақама>.
func Notify(subject, body string) {
	user := os.Getenv("SMTP_USER")
	pass := os.Getenv("SMTP_PASS")
	if user == "" || pass == "" {
		log.Printf("[mailer] SMTP не танзим шуд — огоҳӣ фиристода нашуд: %s", subject)
		return
	}
	to := adminEmail()
	addr := smtpAddr()
	host := addr
	if i := strings.Index(addr, ":"); i > 0 {
		host = addr[:i]
	}
	msg := "From: TajikShop <" + user + ">\r\n" +
		"To: " + to + "\r\n" +
		"Subject: " + subject + "\r\n" +
		"MIME-Version: 1.0\r\n" +
		"Content-Type: text/plain; charset=\"UTF-8\"\r\n\r\n" +
		body + "\r\n"
	auth := smtp.PlainAuth("", user, pass, host)
	if err := smtp.SendMail(addr, auth, user, []string{to}, []byte(msg)); err != nil {
		log.Printf("[mailer] хатои фиристодани email: %v", err)
		return
	}
	log.Printf("[mailer] огоҳӣ ба %s фиристода шуд: %s", to, subject)
}

// NotifySellerRequest — огоҳии махсуси дархости фурӯшандашавӣ.
func NotifySellerRequest(name, email, userID string) {
	subject := "🏪 Дархости нави фурӯшанда — TajikShop"
	body := fmt.Sprintf(
		"Корбари нав мехоҳад фурӯшанда шавад:\n\nНом: %s\nEmail: %s\nID: %s\n\n"+
			"Барои тасдиқ ба панели админ → Корбарон → «Тасдиқи фурӯшанда» ворид шавед.",
		name, email, userID)
	Notify(subject, body)
}
