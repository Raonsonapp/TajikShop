package db

import (
	"database/sql"
	"log"

	_ "github.com/lib/pq"
)

var DB *sql.DB

func Connect(dsn string) {
	var err error
	DB, err = sql.Open("postgres", dsn)
	if err != nil {
		log.Fatalf("❌ sql.Open failed: %v", err)
	}
	DB.SetMaxOpenConns(25)
	DB.SetMaxIdleConns(5)
	if err = DB.Ping(); err != nil {
		log.Fatalf("❌ DB.Ping failed: %v", err)
	}
	log.Println("✅ PostgreSQL connected")
}

func Init() {
	schema := `
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS users (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	name VARCHAR(100) NOT NULL,
	email VARCHAR(255) UNIQUE,
	phone VARCHAR(20) UNIQUE,
	password_hash TEXT NOT NULL,
	avatar_url TEXT DEFAULT '',
	bio TEXT DEFAULT '',
	role VARCHAR(20) DEFAULT 'buyer',
	is_verified BOOLEAN DEFAULT false,
	is_seller BOOLEAN DEFAULT false,
	is_banned BOOLEAN DEFAULT false,
	refresh_token TEXT DEFAULT '',
	created_at TIMESTAMPTZ DEFAULT NOW(),
	updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS categories (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	name VARCHAR(100) NOT NULL,
	slug VARCHAR(100) UNIQUE NOT NULL,
	icon_url TEXT DEFAULT '',
	parent_id UUID REFERENCES categories(id),
	created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS products (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	seller_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	category_id UUID REFERENCES categories(id),
	title VARCHAR(255) NOT NULL,
	description TEXT DEFAULT '',
	price NUMERIC(12,2) NOT NULL,
	discount_percent INT DEFAULT 0,
	stock INT DEFAULT 0,
	is_active BOOLEAN DEFAULT true,
	views INT DEFAULT 0,
	video_url TEXT DEFAULT '',
	created_at TIMESTAMPTZ DEFAULT NOW(),
	updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS product_images (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
	url TEXT NOT NULL,
	position INT DEFAULT 0,
	created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS favorites (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
	created_at TIMESTAMPTZ DEFAULT NOW(),
	UNIQUE(user_id, product_id)
);

CREATE TABLE IF NOT EXISTS cart_items (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
	quantity INT DEFAULT 1,
	created_at TIMESTAMPTZ DEFAULT NOW(),
	UNIQUE(user_id, product_id)
);

CREATE TABLE IF NOT EXISTS addresses (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	title VARCHAR(100) NOT NULL,
	city VARCHAR(100) NOT NULL,
	street TEXT NOT NULL,
	zip VARCHAR(20) DEFAULT '',
	is_default BOOLEAN DEFAULT false,
	created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS orders (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	user_id UUID NOT NULL REFERENCES users(id),
	address_id UUID REFERENCES addresses(id),
	status VARCHAR(30) DEFAULT 'pending',
	total NUMERIC(12,2) NOT NULL,
	payment_proof TEXT DEFAULT '',
	note TEXT DEFAULT '',
	created_at TIMESTAMPTZ DEFAULT NOW(),
	updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS order_items (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
	product_id UUID NOT NULL REFERENCES products(id),
	quantity INT NOT NULL,
	price NUMERIC(12,2) NOT NULL,
	created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS reviews (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
	rating INT CHECK(rating BETWEEN 1 AND 5),
	comment TEXT DEFAULT '',
	created_at TIMESTAMPTZ DEFAULT NOW(),
	UNIQUE(user_id, product_id)
);

CREATE TABLE IF NOT EXISTS follows (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	following_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	created_at TIMESTAMPTZ DEFAULT NOW(),
	UNIQUE(follower_id, following_id)
);

CREATE TABLE IF NOT EXISTS stories (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	media_url TEXT NOT NULL,
	media_type VARCHAR(10) DEFAULT 'image',
	expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '24 hours',
	created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS messages (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	content TEXT NOT NULL,
	is_read BOOLEAN DEFAULT false,
	created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notifications (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	type VARCHAR(50) NOT NULL,
	title VARCHAR(255) NOT NULL,
	body TEXT DEFAULT '',
	is_read BOOLEAN DEFAULT false,
	ref_id UUID,
	created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS payments (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
	user_id UUID NOT NULL REFERENCES users(id),
	amount NUMERIC(12,2) NOT NULL,
	method VARCHAR(50) DEFAULT 'manual',
	status VARCHAR(30) DEFAULT 'pending',
	proof_url TEXT DEFAULT '',
	created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_products_seller ON products(seller_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_active ON products(is_active);
CREATE INDEX IF NOT EXISTS idx_orders_user ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver ON messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
`
	if _, err := DB.Exec(schema); err != nil {
		log.Fatalf("❌ Schema migration failed: %v", err)
	}
	log.Println("✅ DB schema migrated")
}
