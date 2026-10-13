package middleware

import (
	"bytes"
	"encoding/json"
	"io"
	"strings"
	"tajikshop/internal/db"

	"github.com/gin-gonic/gin"
)

// ═══════════════════════════════════════════════════════════════════════════
//  Дафтари амалҳои админ
// ═══════════════════════════════════════════════════════════════════════════
//
// Дар аудит ин ҳамчун камбудии АМНИЯТ навишта шуда буд, ва он воқеан
// ҳамин аст: админ метавонад корбарро бандад, фурӯшандаро тасдиқ кунад,
// амалиёти ҳамёнро тасдиқ кунад, маҳсулотро нест кунад — ва ҳеҷ осоре
// намемонад.
//
// Чаро ин муҳим аст: платформа бо пули ҳақиқӣ кор мекунад. Агар рӯзе
// маблағе нопадид шавад ё фурӯшандае бегуноҳ баста шавад, ҳоло ҳеҷ роҳе
// нест фаҳмидан, КӢ ва КАЙ инро кард. Дар мағозаи як нафара ин масъала
// нест; ҳамин ки корманди дуюм пайдо шавад, он масъалаи калон мешавад.
//
// ҚАРОРИ МЕЪМОРӢ: ин middleware аст, на даъвати дастӣ дар ҳар handler.
//
// Варианти дастӣ («дар ҳар handler `logAdminAction` навис») дар назар
// тозатар менамуд, вале он як нуқсони ҳалкунанда дорад: handler-и нав
// иловашуда онро ФАРОМӮШ мекунад, ва дафтар сӯрох мешавад — бе он ки
// касе фаҳмад. Middleware ҳамаи амалҳоро худкор мегирад, аз ҷумла онҳое,
// ки фардо илова мешаванд.

// Калимаҳое, ки арзишашон ҳеҷ гоҳ сабт намешавад.
//
// Масирҳои админ ҳоло парол намегиранд, вале дафтар абадӣ мемонад ва
// handler-и нав метавонад гирад. Беҳтар аст, ки ин ҳоло баста шавад.
var secretKeys = []string{
	"password", "parol", "token", "secret", "key", "proof",
	"card_number", "card", "cvv", "pin",
}

// maxAuditBody — ҳадди бадани сабтшаванда.
//
// Бе ин як дархости калон (масалан расми base64) дафтарро пур мекунад ва
// база аз ҳад зиёд мешавад.
const maxAuditBody = 2000

// AuditAdmin — ҳар амали ТАҒЙИРДИҲАНДАИ муваффақи админро сабт мекунад.
//
// `GET` сабт намешавад: хондан амал нест, ва сабти ҳар кушодани саҳифа
// дафтарро бефоида пур мекунад. Хатоҳо (4xx/5xx) низ не — он амал рӯй
// надод.
func AuditAdmin() gin.HandlerFunc {
	return func(c *gin.Context) {
		method := c.Request.Method
		if method == "GET" || method == "HEAD" || method == "OPTIONS" {
			c.Next()
			return
		}

		// Баданро ПЕШ аз handler мехонем ва баъд бармегардонем —
		// вагарна handler баданро холӣ мебинад.
		var raw []byte
		if c.Request.Body != nil {
			raw, _ = io.ReadAll(io.LimitReader(c.Request.Body, maxAuditBody+1))
			c.Request.Body = io.NopCloser(bytes.NewReader(raw))
		}

		c.Next()

		// Танҳо амали МУВАФФАҚ.
		if c.Writer.Status() >= 400 {
			return
		}

		adminID, _ := c.Get("user_id")
		id, _ := adminID.(string)
		if id == "" {
			return
		}

		// Параметрҳои масир (`:id`) — маҳз онҳо мегӯянд, ки амал ба КӢ
		// расид.
		target := ""
		for _, p := range c.Params {
			if p.Key == "id" {
				target = p.Value
				break
			}
		}

		db.DB.Exec(`INSERT INTO admin_actions
			(admin_id, method, path, target_id, payload, status)
			VALUES($1,$2,$3,$4,$5,$6)`,
			id, method, c.FullPath(), nullIfNotUUID(target),
			redact(raw), c.Writer.Status())
	}
}

// nullIfNotUUID — `target_id` сутуни UUID аст; агар параметр UUID набошад
// (масалан slug), NULL мегузорем — вагарна тамоми `INSERT` хато медиҳад
// ва дафтар хомӯшона кор намекунад.
func nullIfNotUUID(s string) interface{} {
	if len(s) != 36 {
		return nil
	}
	for i, r := range s {
		switch i {
		case 8, 13, 18, 23:
			if r != '-' {
				return nil
			}
		default:
			isHex := (r >= '0' && r <= '9') || (r >= 'a' && r <= 'f') ||
				(r >= 'A' && r <= 'F')
			if !isHex {
				return nil
			}
		}
	}
	return s
}

// redact — майдонҳои ҳассосро пеш аз сабт иваз мекунад.
//
// Агар бадан JSON набошад (масалан `multipart` бо расм), он умуман сабт
// намешавад: дар он ҷо ҷои ҳассос бисёр аст ва фоидаи сабт кам.
func redact(raw []byte) interface{} {
	if len(raw) == 0 {
		return nil
	}
	if len(raw) > maxAuditBody {
		return map[string]string{"_note": "бадан хеле калон — сабт нашуд"}
	}
	var m map[string]interface{}
	if err := json.Unmarshal(raw, &m); err != nil {
		return nil // JSON нест — сабт намекунем
	}
	for k := range m {
		lower := strings.ToLower(k)
		for _, bad := range secretKeys {
			if strings.Contains(lower, bad) {
				m[k] = "«пинҳон»"
				break
			}
		}
	}
	out, err := json.Marshal(m)
	if err != nil {
		return nil
	}
	return string(out)
}
