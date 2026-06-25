package push

import (
	"context"
	"log"
	"os"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"google.golang.org/api/option"
)

var client *messaging.Client

// Init — Firebase Admin-ро аз service account оғоз мекунад.
// Манбаи credential:
//   - FIREBASE_SERVICE_ACCOUNT  (мӯҳтавои JSON-и калид — тавсияшаванда барои Render/HF)
//   - GOOGLE_APPLICATION_CREDENTIALS (роҳи файли .json)
//
// Агар ҳеҷ яке набошад, push хомӯш мемонад (барнома кор мекунад).
func Init() {
	ctx := context.Background()
	var opt option.ClientOption
	if creds := os.Getenv("FIREBASE_SERVICE_ACCOUNT"); creds != "" {
		opt = option.WithCredentialsJSON([]byte(creds))
	} else if path := os.Getenv("GOOGLE_APPLICATION_CREDENTIALS"); path != "" {
		opt = option.WithCredentialsFile(path)
	} else {
		log.Println("ℹ️  FCM: credential нест (FIREBASE_SERVICE_ACCOUNT) — push хомӯш")
		return
	}
	app, err := firebase.NewApp(ctx, nil, opt)
	if err != nil {
		log.Printf("⚠️  FCM init failed: %v", err)
		return
	}
	client, err = app.Messaging(ctx)
	if err != nil {
		log.Printf("⚠️  FCM messaging failed: %v", err)
		return
	}
	log.Println("✅ FCM push enabled")
}

// SendToToken — як push мефиристад (async, безарар агар хомӯш бошад).
func SendToToken(token, title, body string) {
	if client == nil || token == "" {
		return
	}
	go func() {
		_, err := client.Send(context.Background(), &messaging.Message{
			Token: token,
			Notification: &messaging.Notification{
				Title: title,
				Body:  body,
			},
		})
		if err != nil {
			log.Printf("FCM send err: %v", err)
		}
	}()
}
