package handlers

import (
	"net/http"
	"regexp"
	"strconv"
	"strings"
	"tajikshop/internal/db"
	"tajikshop/internal/utils"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// ── Тасдиқи худкори пардохт аз матни SMS-и бонк ─────────────────────────────
//
// Чаро ин тавр, на хондани SMS-и телефон:
//   • Android иҷозати SMS-ро банк ба банк ҷудо карда наметавонад — READ_SMS
//     ҳамаи паёмҳоро мекушояд;
//   • Google Play READ_SMS-ро танҳо ба барномаи SMS-и пешфарз медиҳад, пас
//     барномаи савдо бо он рад мешавад.
//
// Ба ҷои он фурӯшанда SMS-и бонкро «Share → TajikShop» мекунад (як пахш).
// Матн ба ҳамин ҷо меояд, маблағ хонда мешавад ва фармоиши интизори ҳамон
// фурӯшанда бо ҳамон маблағ ёфта, худкор тасдиқ мешавад.

// Маблағи SMS-ҳои бонкҳои Тоҷикистон.
//
// Намунаҳо:
//   "Popolnenie 250.00 TJS. Karta *7344"
//   "Пополнение 250,00 TJS"
//   "Зачисление 1 250.50 смн"
//   "Amount: 250.00 TJS"
var amountRe = regexp.MustCompile(
	`(?i)(\d[\d\s\x{00A0}]*[.,]?\d*)\s*(TJS|СМН|смн|сомонӣ|сомони)`)

// Рақами охири корт: "*7344", "**** 7344", "...7344"
var cardTailRe = regexp.MustCompile(`(?:\*+|\.{2,})\s*(\d{4})`)

// Калимаҳое, ки маънои «пул ОМАД»-ро доранд. Бе яке аз инҳо матнро
// ҳамчун воридот қабул намекунем (то SMS-и хароҷот тасдиқ нашавад).
var incomingWords = []string{
	"popolnenie", "пополнение", "зачисление", "зачислено",
	"postuplenie", "поступление", "credit", "received",
	"ворид", "воридот", "иловашуд", "илова шуд",
}

// parseBankSMS — маблағ ва рақами охири кортро аз матн мегирад.
//
// Бармегардонад (amount, cardTail, ok). ok=false вақте матн ба воридоти
// пул монанд нест — он гоҳ ҳеҷ чиз тасдиқ намешавад.
func parseBankSMS(text string) (float64, string, bool) {
	low := strings.ToLower(text)

	incoming := false
	for _, w := range incomingWords {
		if strings.Contains(low, w) {
			incoming = true
			break
		}
	}
	if !incoming {
		return 0, "", false
	}

	m := amountRe.FindStringSubmatch(text)
	if m == nil {
		return 0, "", false
	}
	raw := m[1]
	// "1 250,50" → "1250.50"
	raw = strings.ReplaceAll(raw, " ", "")
	raw = strings.ReplaceAll(raw, " ", "")
	raw = strings.ReplaceAll(raw, ",", ".")
	amount, err := strconv.ParseFloat(raw, 64)
	if err != nil || amount <= 0 {
		return 0, "", false
	}

	tail := ""
	if cm := cardTailRe.FindStringSubmatch(text); cm != nil {
		tail = cm[1]
	}
	return amount, tail, true
}

// Фарқи иҷозатдодашуда байни маблағи SMS ва ҷамъи фармоиш (сом.).
// Бонкҳо баъзан комиссия мегиранд, пас каме таҳаммул лозим аст.
const amountTolerance = 1.0

// ConfirmPaymentBySMS — POST /seller/payments/confirm-sms
//
// Фурӯшанда матни SMS-и бонкро мефиристад. Агар фармоиши интизори ҳамон
// фурӯшанда бо ҳамон маблағ ёфт шавад, он «пардохтшуда» қайд мешавад ва
// харидор огоҳӣ мегирад.
func (h *OrderHandler) ConfirmPaymentBySMS(c *gin.Context) {
	uid := utils.UserID(c)
	var in struct {
		Text    string `json:"text"`
		OrderID string `json:"order_id"` // ихтиёрӣ: агар фурӯшанда худаш интихоб кунад
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}

	amount, tail, ok := parseBankSMS(in.Text)
	if !ok {
		utils.Err(c, http.StatusBadRequest,
			"Дар ин матн воридоти пул ёфт нашуд. Матни пурраи SMS-и бонкро фиристед.")
		return
	}

	// Кортро месанҷем: агар SMS рақами охири корт дошта бошад ва он ба корти
	// фурӯшанда мувофиқ набошад — ин пули ӯ нест.
	if tail != "" {
		var card string
		db.DB.QueryRow(`SELECT COALESCE(card_number,'') FROM users WHERE id=$1`, uid).Scan(&card)
		digits := onlyDigits(card)
		if len(digits) >= 4 && digits[len(digits)-4:] != tail {
			utils.Err(c, http.StatusBadRequest,
				"Ин SMS ба корти шумо тааллуқ надорад (*"+tail+")")
			return
		}
	}

	// Фармоиши мувофиқ: интизори пардохт, маҳсулоти ҳамин фурӯшанда,
	// ҷамъаш ба маблағи SMS наздик. Навтаринро мегирем.
	var orderID, buyer string
	var total float64
	q := `SELECT o.id, o.user_id, o.total
		FROM orders o
		WHERE o.status IN ('pending','payment_uploaded')
		  AND ABS(o.total - $1) <= $2
		  AND EXISTS (SELECT 1 FROM order_items oi JOIN products p ON p.id=oi.product_id
		              WHERE oi.order_id=o.id AND p.seller_id=$3)`
	args := []interface{}{amount, amountTolerance, uid}
	if strings.TrimSpace(in.OrderID) != "" {
		q += ` AND o.id=$4`
		args = append(args, strings.TrimSpace(in.OrderID))
	}
	q += ` ORDER BY o.created_at DESC LIMIT 1`

	if err := db.DB.QueryRow(q, args...).Scan(&orderID, &buyer, &total); err != nil {
		utils.Err(c, http.StatusNotFound,
			"Фармоиши интизори "+strconv.FormatFloat(amount, 'f', 2, 64)+" сом. ёфт нашуд")
		return
	}

	// Фармоишро пардохтшуда мекунем (танҳо агар ҳанӯз нашуда бошад).
	res, err := db.DB.Exec(`UPDATE orders SET status='paid', updated_at=$1
		WHERE id=$2 AND status IN ('pending','payment_uploaded')`, time.Now(), orderID)
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, "update failed")
		return
	}
	if n, _ := res.RowsAffected(); n == 0 {
		utils.Err(c, http.StatusBadRequest, "Ин фармоиш аллакай пардохт шудааст")
		return
	}

	short := shortID(orderID)
	logOrderEvent(orderID, "paid", "Тасдиқи худкор аз SMS-и бонк")
	db.DB.Exec(`INSERT INTO payments(id,order_id,user_id,amount,method,status)
		VALUES($1,$2,$3,$4,'bank_sms','completed')`,
		uuid.NewString(), orderID, buyer, amount)

	title := "Пардохт тасдиқ шуд ✅"
	body := "Хариди шумо тайёр аст. Фармоиши #" + short +
		" — дар «Фармоишҳо» пайгирӣ кунед."
	db.DB.Exec(`INSERT INTO notifications(id,user_id,type,title,body,ref_id)
		VALUES($1,$2,'order',$3,$4,$5)`,
		uuid.NewString(), buyer, title, body, orderID)
	pushToUser(buyer, title, body)

	utils.OK(c, gin.H{
		"matched":  true,
		"order_id": orderID,
		"amount":   amount,
		"total":    total,
	})
}

func onlyDigits(s string) string {
	var b strings.Builder
	for _, r := range s {
		if r >= '0' && r <= '9' {
			b.WriteRune(r)
		}
	}
	return b.String()
}

// ── Username ────────────────────────────────────────────────────────────────

// Username: ҳарфҳои лотинӣ, рақам ва _ , аз 3 то 32 аломат.
var usernameRe = regexp.MustCompile(`^[a-zA-Z0-9_]{3,32}$`)

// SetUsername — PUT /users/me/username
func (h *OrderHandler) SetUsername(c *gin.Context) {
	uid := utils.UserID(c)
	var in struct {
		Username string `json:"username"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}
	u := strings.TrimSpace(strings.TrimPrefix(in.Username, "@"))
	if !usernameRe.MatchString(u) {
		utils.Err(c, http.StatusBadRequest,
			"Username: 3–32 аломат, танҳо ҳарфҳои лотинӣ, рақам ва _")
		return
	}

	// Банде, ки аллакай гирифта шудааст — рӯирост мегӯем.
	var taken bool
	db.DB.QueryRow(`SELECT EXISTS(SELECT 1 FROM users
		WHERE LOWER(username)=LOWER($1) AND id<>$2)`, u, uid).Scan(&taken)
	if taken {
		utils.Err(c, http.StatusConflict, "Ин username аллакай гирифта шудааст")
		return
	}

	if _, err := db.DB.Exec(`UPDATE users SET username=$1, updated_at=$2 WHERE id=$3`,
		u, time.Now(), uid); err != nil {
		utils.Err(c, http.StatusInternalServerError, "update failed")
		return
	}
	utils.OK(c, gin.H{"username": u})
}

// CheckUsername — GET /users/username-available?u=xxx
func (h *OrderHandler) CheckUsername(c *gin.Context) {
	u := strings.TrimSpace(strings.TrimPrefix(c.Query("u"), "@"))
	if !usernameRe.MatchString(u) {
		utils.OK(c, gin.H{"available": false, "reason": "invalid"})
		return
	}
	var taken bool
	db.DB.QueryRow(`SELECT EXISTS(SELECT 1 FROM users WHERE LOWER(username)=LOWER($1))`, u).
		Scan(&taken)
	utils.OK(c, gin.H{"available": !taken})
}
