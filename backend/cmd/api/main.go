package main

import (
	"context"
	"log"
	"tajikshop/internal/config"
	"tajikshop/internal/db"
	handlers "tajikshop/internal/handles"
	"tajikshop/internal/middleware"
	"tajikshop/internal/payments"
	"tajikshop/internal/push"
	"tajikshop/internal/routes"
	"tajikshop/internal/storage"
	"time"

	"github.com/gin-gonic/gin"
)

func main() {
	cfg := config.Load()

	db.Connect(cfg.DBUrl)
	db.Migrate() // Танҳо ҷадвалҳои нав месозад — DROP намекунад

	push.Init() // Firebase push (агар FIREBASE_SERVICE_ACCOUNT гузошта шуда бошад)

	middleware.SetSecret(cfg.JWTSecret)

	var r2 *storage.R2Client
	if cfg.R2Endpoint != "" && cfg.R2AccessKey != "" {
		var err error
		r2, err = storage.NewR2Client(cfg.R2Endpoint, cfg.R2AccessKey, cfg.R2SecretKey, cfg.R2Bucket, cfg.R2PublicURL)
		if err != nil {
			log.Printf("⚠️  R2 not configured: %v", err)
			r2 = nil
		} else {
			// Калидҳоро ВОҚЕАН месанҷем. Сохтани клиент ба Cloudflare тамос
			// намегирад, пас бе ин санҷиш лог ҳатто бо калиди мӯҳлаташ
			// гузашта ҳам «connected» менавишт ва хатогӣ танҳо ҳангоми
			// боркунии расми корбар маълум мешуд.
			ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
			verr := r2.Verify(ctx)
			cancel()
			if verr != nil {
				log.Printf("❌ Cloudflare R2: %s", r2.Status())
			} else {
				log.Printf("✅ Cloudflare R2 ok (bucket: %s)", cfg.R2Bucket)
			}
			if !r2.PublicURLSet() {
				log.Println("⚠️  R2_PUBLIC_URL холӣ аст — линки расмҳо нопурра мешавад")
			}
		}
	} else {
		log.Println("⚠️  R2 не танзим шуд — боркунии файлҳо кор намекунад")
	}

	// Ҳимояи харидор: маблағи фармоишҳоеро, ки мӯҳлати ҳимояашон гузашт ва
	// харидор шикоят накард, худкор ба фурӯшанда мегузаронад — то фурӯшанда
	// интизори абадии тасдиқи харидор накашад.
	handlers.StartEscrowSweeper()
	// Мӯҳлати нигоҳдорӣ: фурӯшанда 3 рӯз пеш огоҳӣ мегирад.
	handlers.StartExpirySweeper()
	// Дархостҳои нархи мӯҳлаташон гузашта пӯшида мешаванд. Ин барои
	// тозагии маълумот аст, на барои дурустӣ: мӯҳлат дар ҳар дархост
	// ҳамеша санҷида мешавад, пас ҳатто агар ин sweeper кор накунад,
	// ягон пешниҳод ба дархости пӯшида намеравад.
	handlers.StartRFQSweeper()
	// Моли тамомшуда, ки фурӯшанда ба саволи «боз ҳаст?» ҷавоб надод,
	// баъди се рӯз ХУДКОР аз бозор пинҳон мешавад.
	//
	// Бе ин он абадӣ ҳамчун «Тамом шуд» мемонд: харидор онро мебинад,
	// зер мекунад, ва харида наметавонад.
	handlers.StartSoldOutSweeper()

	r := gin.Default()
	// Провайдери пардохт.
	//
	// Холӣ = пардохти онлайн хомӯш, ва ҳамаи масирҳои он 503 медиҳанд.
	// Ин аз «провайдери қалбакӣ, ки ҳамеша мегӯяд пардохт шуд» беҳтар
	// аст — чунин провайдер дар production моли ройгон медод.
	var pay payments.Provider
	switch cfg.PaymentProvider {
	case "sandbox":
		if cfg.PaymentSecret == "" {
			log.Println("⚠️  PAYMENT_PROVIDER=sandbox, вале PAYMENT_WEBHOOK_SECRET холӣ — пардохт хомӯш")
		} else {
			pay = payments.NewSandbox(cfg.PaymentSecret)
			log.Println("🧪 Пардохт: SANDBOX (барои тест, на пули воқеӣ)")
		}
	case "":
		log.Println("ℹ️  Пардохти онлайн хомӯш (PAYMENT_PROVIDER холӣ)")
	default:
		log.Printf("⚠️  Провайдери «%s» ҳанӯз сохта нашудааст — пардохт хомӯш",
			cfg.PaymentProvider)
	}

	routes.Setup(r, cfg.JWTSecret, r2, cfg.SSOPartnerKey, pay)

	log.Printf("🚀 TajikShop API running on :%s", cfg.Port)
	if err := r.Run(":" + cfg.Port); err != nil {
		log.Fatalf("❌ Server failed: %v", err)
	}
}
