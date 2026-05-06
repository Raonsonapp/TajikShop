package config

import (
	"log"
	"os"
)

type Config struct {
	Port        string
	DBUrl       string
	JWTSecret   string
	R2Endpoint  string
	R2AccessKey string
	R2SecretKey string
	R2Bucket    string
	R2PublicURL string
}

func Load() *Config {
	cfg := &Config{
		Port:        getEnv("PORT", "8080"),
		DBUrl:       mustEnv("DB_URL"),
		JWTSecret:   mustEnv("JWT_SECRET"),
		R2Endpoint:  getEnv("R2_ENDPOINT", ""),
		R2AccessKey: getEnv("R2_ACCESS_KEY", ""),
		R2SecretKey: getEnv("R2_SECRET_KEY", ""),
		R2Bucket:    getEnv("R2_BUCKET", "tajikshop"),
		R2PublicURL: getEnv("R2_PUBLIC_URL", ""),
	}
	return cfg
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func mustEnv(key string) string {
	v := os.Getenv(key)
	if v == "" {
		log.Fatalf("❌ Required env var %s is not set", key)
	}
	return v
}
