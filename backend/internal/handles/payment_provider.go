package handlers

import (
	"context"
	"io"
	"net/http"
	"strings"
	"tajikshop/internal/db"
	"tajikshop/internal/payments"
	"tajikshop/internal/utils"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// ═══════════════════════════════════════════════════════════════════════════
//  Пардохт тавассути провайдер
// ═══════════════════════════════════════════════════════════════════════════
//
// РӮИРОСТ: провайдери воқеӣ (Алиф / Корти Миллӣ) ҳанӯз пайваст
// нашудааст — маълумоти merchant лозим, ва он аз мо вобаста нест.
//
// Вале се чизи аз ҳама хатарноки пардохт ба провайдер ҲЕҶ РАБТЕ
// НАДОРАНД, ва маҳз онҳо ин ҷо сохта ва санҷида мешаванд:
//
//  1. ТАКРОРИ WEBHOOK. Провайдер ҳамон рӯйдодро чанд бор мефиристад —
//     ин меъёри кор аст. Агар мо ҳар борро «пардохти нав» ҳисоб кунем,
//     фармоиш чанд бор пардохтшуда мешавад.
//
//  2. ИМЗО. Бе он ҳар кас метавонад ба суроғаи webhook «пардохт шуд»
//     фиристад ва моли ройгон гирад.
//
//  3. ТАРТИБИ ҲОЛАТҲО. Рӯйдодҳо метавонанд бо тартиби вайрон расанд.
//     Агар баъди «paid» рӯйдоди «pending» қабул шавад, фармоиши
//     пардохтшуда ба «интизори пардохт» бармегардад.
//
// Ҳамаи се ҳоло кор мекунанд ва тест доранд. Вақте маълумоти merchant
// омад, танҳо як adapter навишта мешавад.

type PaymentHandler struct {
	provider payments.Provider
}

// NewPaymentHandler — агар провайдер танзим нашуда бошад, `nil` қабул
// мешавад ва ҳамаи масирҳо 503 медиҳанд.
//
// Ин аз «провайдери қалбакӣ, ки ҳамеша мегӯяд пардохт шуд» беҳтар аст:
// чунин провайдер дар production моли ройгон медод.
func NewPaymentHandler(p payments.Provider) *PaymentHandler {
	return &PaymentHandler{provider: p}
}

func (h *PaymentHandler) ready(c *gin.Context) bool {
	if h.provider == nil {
		utils.Err(c, http.StatusServiceUnavailable,
			"Пардохти онлайн ҳанӯз пайваст нашудааст")
		return false
	}
	return true
}

// Start — POST /payments/start
//
// Пардохтро оғоз мекунад ва суроғаи саҳифаи пардохтро бармегардонад.
func (h *PaymentHandler) Start(c *gin.Context) {
	if !h.ready(c) {
		return
	}
	uid := utils.UserID(c)
	var in struct {
		OrderID   string `json:"order_id"`
		ReturnURL string `json:"return_url"`
	}
	if err := c.ShouldBindJSON(&in); err != nil || strings.TrimSpace(in.OrderID) == "" {
		utils.Err(c, http.StatusBadRequest, "Фармоиш нишон дода нашуд")
		return
	}

	// Фармоиш бояд аз ҲАМИН харидор бошад ва ҳанӯз пардохт нашуда бошад.
	var total float64
	var status string
	err := db.DB.QueryRow(`SELECT total, status FROM orders
		WHERE id=$1 AND user_id=$2`, in.OrderID, uid).Scan(&total, &status)
	if err != nil {
		utils.Err(c, http.StatusNotFound, "Фармоиш ёфт нашуд")
		return
	}
	if status == "paid" || status == "completed" {
		utils.Err(c, http.StatusConflict, "Ин фармоиш аллакай пардохт шудааст")
		return
	}
	if status == "cancelled" {
		utils.Err(c, http.StatusConflict, "Фармоиш бекор шудааст")
		return
	}

	// Калиди idempotency аз сарлавҳа, ё аз фармоиш.
	//
	// Агар корбар тугмаро ду бор занад, ҳамон пардохт бармегардад — на
	// пардохти дуюм.
	key := strings.TrimSpace(c.GetHeader("Idempotency-Key"))
	if key == "" {
		key = "ord-" + in.OrderID
	}
	if len(key) > 120 {
		key = key[:120]
	}

	// Интенти аллакай мавҷуд?
	var prevRef, prevStatus string
	if e := db.DB.QueryRow(`SELECT provider_ref, status FROM payment_intents
		WHERE user_id=$1 AND idempotency_key=$2`, uid, key).
		Scan(&prevRef, &prevStatus); e == nil {
		if prevStatus == string(payments.StatusPaid) {
			utils.Err(c, http.StatusConflict, "Ин пардохт аллакай анҷом ёфт")
			return
		}
	}

	ctx, cancel := context.WithTimeout(c.Request.Context(), 20*time.Second)
	defer cancel()
	res, perr := h.provider.Initiate(ctx, payments.InitiateRequest{
		OrderID:        in.OrderID,
		UserID:         uid,
		AmountDirams:   toDirams(total),
		Currency:       "TJS",
		Description:    "TajikShop #" + shortID(in.OrderID),
		ReturnURL:      in.ReturnURL,
		IdempotencyKey: key,
	})
	if perr != nil {
		utils.Err(c, http.StatusBadGateway, "Провайдери пардохт ҷавоб надод")
		return
	}

	// `ON CONFLICT` ҳатмист: ду дархости ҳамзамон ҳарду метавонанд
	// санҷиши болоро гузаранд, вале `UNIQUE` танҳо якеро мегузорад.
	db.DB.Exec(`INSERT INTO payment_intents
		(id,order_id,user_id,provider,provider_ref,amount,currency,status,idempotency_key)
		VALUES($1,$2,$3,$4,$5,$6,'TJS',$7,$8)
		ON CONFLICT (provider, provider_ref) DO UPDATE
			SET status=EXCLUDED.status, updated_at=NOW()`,
		uuid.NewString(), in.OrderID, uid, h.provider.Name(),
		res.ProviderRef, total, string(res.Status), key)

	utils.OK(c, gin.H{
		"provider":     h.provider.Name(),
		"provider_ref": res.ProviderRef,
		"pay_url":      res.PayURL,
		"status":       string(res.Status),
		"amount":       total,
	})
}

// Webhook — POST /payments/webhook/:provider  (БЕ аутентификатсия)
//
// Ин масир аз берун кушода аст — провайдер токени мо надорад. Ҳимоя
// танҳо ИМЗО аст, пас он бояд ҳар дархостро санҷад, ҳатто пеш аз
// хондани бадан.
func (h *PaymentHandler) Webhook(c *gin.Context) {
	if h.provider == nil {
		// Провайдер нест — вале 200 бармегардонем, вагарна провайдер
		// рӯйдодро абадӣ такрор мекунад.
		c.JSON(http.StatusOK, gin.H{"ignored": true})
		return
	}
	// Ҳадди бадан: бе он як дархости калон хотираро пур мекунад.
	body, err := io.ReadAll(io.LimitReader(c.Request.Body, 64*1024))
	if err != nil {
		utils.Err(c, http.StatusBadRequest, "bad body")
		return
	}

	headers := map[string]string{}
	for k, v := range c.Request.Header {
		if len(v) > 0 {
			headers[k] = v[0]
		}
	}

	ev, verr := h.provider.VerifyWebhook(headers, body)
	if verr != nil {
		// Имзои нодуруст — 401, ва ҳеҷ чиз сабт намешавад.
		//
		// Паёми тафсилотӣ дода намешавад: он ба ҳамлакунанда мегӯяд,
		// кадом қисми имзо нодуруст аст.
		utils.Err(c, http.StatusUnauthorized, "signature rejected")
		return
	}

	// ── Idempotency дар БАЗА ──
	//
	// `UNIQUE(provider, event_id)` ин корро мекунад, на санҷиши код:
	// ду дархости ҳамзамон метавонанд ҳарду санҷиши «оё аллакай ҳаст?»
	// -ро гузаранд, вале `UNIQUE` ҳеҷ гоҳ ду сатр намегузорад.
	res, ierr := db.DB.Exec(`INSERT INTO payment_events
		(id,provider,event_id,provider_ref,status,amount,raw)
		VALUES($1,$2,$3,$4,$5,$6,$7)
		ON CONFLICT (provider, event_id) DO NOTHING`,
		uuid.NewString(), h.provider.Name(), ev.EventID, ev.ProviderRef,
		string(ev.Status), toSomoni(ev.AmountDirams), ev.Raw)
	if ierr != nil {
		utils.Err(c, http.StatusInternalServerError, "store failed")
		return
	}
	if n, _ := res.RowsAffected(); n == 0 {
		// Такрор. 200 бармегардонем, то провайдер бас кунад.
		c.JSON(http.StatusOK, gin.H{"duplicate": true})
		return
	}

	applyPaymentEvent(h.provider.Name(), ev)
	c.JSON(http.StatusOK, gin.H{"ok": true})
}

// applyPaymentEvent — рӯйдодро ба фармоиш татбиқ мекунад.
//
// Дар транзаксия, бо қулфи интент — то ду рӯйдоди гуногун ҳамзамон
// ҳолатро вайрон накунанд.
func applyPaymentEvent(provider string, ev payments.Event) {
	tx, err := db.DB.Begin()
	if err != nil {
		return
	}
	committed := false
	defer func() {
		if !committed {
			tx.Rollback()
		}
	}()

	var intentID, orderID, cur string
	if e := tx.QueryRow(`SELECT id, order_id, status FROM payment_intents
		WHERE provider=$1 AND provider_ref=$2 FOR UPDATE`,
		provider, ev.ProviderRef).Scan(&intentID, &orderID, &cur); e != nil {
		// Интенти ношинос. Ин метавонад пардохти берун аз барнома
		// бошад — рӯйдод дар дафтар монд, вале ба ягон фармоиш татбиқ
		// намешавад. Админ онро дар дафтар мебинад.
		return
	}

	// ТАРТИБИ ҲОЛАТҲО. Рӯйдодҳо метавонанд бо тартиби вайрон расанд.
	if !payments.CanTransition(payments.Status(cur), ev.Status) {
		tx.Exec(`UPDATE payment_events SET applied=false
			WHERE provider=$1 AND event_id=$2`, provider, ev.EventID)
		tx.Commit()
		committed = true
		return
	}

	if _, e := tx.Exec(`UPDATE payment_intents SET status=$1, updated_at=NOW()
		WHERE id=$2`, string(ev.Status), intentID); e != nil {
		return
	}

	// Фармоиш танҳо ҳангоми «paid» ҳолат иваз мекунад.
	//
	// Пулро ба фурӯшанда ин ҷо ТАҚСИМ НАМЕКУНЕМ: он кори `settleOrder`
	// аст, ки баъди супоридани мол ва мӯҳлати ҳимояи харидор иҷро
	// мешавад ва тестҳои худашро дорад. Омехта кардани ин ду роҳ
	// хатарноктарин чизе мебуд, ки дар ин ҷо кардан мумкин аст.
	if ev.Status == payments.StatusPaid {
		if _, e := tx.Exec(`UPDATE orders SET status='paid', updated_at=NOW()
			WHERE id=$1 AND status NOT IN ('completed','cancelled')`,
			orderID); e != nil {
			return
		}
	}

	if _, e := tx.Exec(`UPDATE payment_events SET applied=true
		WHERE provider=$1 AND event_id=$2`, provider, ev.EventID); e != nil {
		return
	}
	if e := tx.Commit(); e != nil {
		return
	}
	committed = true

	// Огоҳӣ берун аз транзаксия.
	if ev.Status == payments.StatusPaid {
		var buyer string
		db.DB.QueryRow(`SELECT user_id FROM orders WHERE id=$1`, orderID).Scan(&buyer)
		if buyer != "" {
			short := shortID(orderID)
			t := "Пардохт қабул шуд"
			b := "Фармоиши #" + short + " пардохт шуд"
			db.DB.Exec(`INSERT INTO notifications(id,user_id,type,title,body,ref_id)
				VALUES($1,$2,'order',$3,$4,$5)`,
				uuid.NewString(), buyer, t, b, orderID)
			pushToUser(buyer, t, b)
		}
		logOrderEvent(orderID, "paid", provider)
		notifySellersOfNewOrder(orderID)
	}
}

// Reconcile — POST /admin/payments/reconcile  (админ)
//
// Webhook метавонад ГУМ шавад: шабака, сервери хоб, HF Space аз нав
// оғозшуда. Он гоҳ фармоиш абадӣ «интизори пардохт» мемонад, ҳол он ки
// пул аллакай гирифта шудааст — ва харидор моли пардохткардаашро
// намегирад.
//
// Ин масир ҳолати ҳақиқиро аз ПРОВАЙДЕР мепурсад.
func (h *PaymentHandler) Reconcile(c *gin.Context) {
	if !h.ready(c) {
		return
	}
	rows, err := db.DB.Query(`SELECT provider_ref, status FROM payment_intents
		WHERE provider=$1 AND status='pending'
		  AND created_at < NOW() - INTERVAL '10 minutes'
		ORDER BY created_at LIMIT 100`, h.provider.Name())
	if err != nil || rows == nil {
		utils.OK(c, gin.H{"checked": 0, "updated": 0})
		return
	}
	var refs []string
	for rows.Next() {
		var ref, st string
		if e := rows.Scan(&ref, &st); e == nil {
			refs = append(refs, ref)
		}
	}
	rows.Close()

	updated := 0
	for _, ref := range refs {
		ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
		st, perr := h.provider.Status(ctx, ref)
		cancel()
		if perr != nil || st == payments.StatusPending {
			continue
		}
		// Ҳамон роҳи татбиқ, бо ҳамон санҷишҳо. Рӯйдоди сунъӣ бо
		// шиносаи аз `ref` сохташуда — то такрори ҳисоббаробаркунӣ
		// низ idempotent бошад.
		ev := payments.Event{
			EventID:     "reconcile:" + ref + ":" + string(st),
			ProviderRef: ref, Status: st,
		}
		res, _ := db.DB.Exec(`INSERT INTO payment_events
			(id,provider,event_id,provider_ref,status,raw)
			VALUES($1,$2,$3,$4,$5,'reconcile')
			ON CONFLICT (provider, event_id) DO NOTHING`,
			uuid.NewString(), h.provider.Name(), ev.EventID, ref, string(st))
		if res != nil {
			if n, _ := res.RowsAffected(); n == 0 {
				continue
			}
		}
		applyPaymentEvent(h.provider.Name(), ev)
		updated++
	}
	utils.OK(c, gin.H{"checked": len(refs), "updated": updated})
}

// Status — GET /payments/:order_id/status
func (h *PaymentHandler) Status(c *gin.Context) {
	uid := utils.UserID(c)
	var provider, ref, st string
	var amount float64
	err := db.DB.QueryRow(`SELECT provider, provider_ref, status, amount
		FROM payment_intents
		WHERE order_id=$1 AND user_id=$2
		ORDER BY created_at DESC LIMIT 1`, c.Param("order_id"), uid).
		Scan(&provider, &ref, &st, &amount)
	if err != nil {
		utils.OK(c, gin.H{"status": "none"})
		return
	}
	utils.OK(c, gin.H{
		"provider": provider, "provider_ref": ref,
		"status": st, "amount": amount,
	})
}
