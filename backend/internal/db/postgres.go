package db

import (
	"database/sql"
	"log"
	"os"

	_ "github.com/lib/pq"
)

var DB *sql.DB

func Connect() {
	dsn := os.Getenv("DB_URL")
	if dsn == "" {
		log.Fatal("❌ DB_URL is empty — set it in Render Environment Variables")
	}

	var err error
	DB, err = sql.Open("postgres", dsn)
	if err != nil {
		log.Fatalf("❌ sql.Open failed: %v", err)
	}

	if err = DB.Ping(); err != nil {
		log.Fatalf("❌ DB.Ping failed (check DB_URL, password, IP allowlist): %v", err)
	}

	log.Println("✅ DB connected successfully")
}
