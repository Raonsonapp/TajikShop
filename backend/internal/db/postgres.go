package db

import (
	"database/sql"
	_ "embed"
	"log"
	"strings"
	"time"

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
	// Ping-ро бо такрор месанҷем: агар DB-и Supabase ҳоло бедор шуда истода
	// бошад (cold start), сервер фавран намемурад, балки то 10 маротиба сабр мекунад.
	for i := 1; i <= 10; i++ {
		if err = DB.Ping(); err == nil {
			log.Println("✅ PostgreSQL connected")
			return
		}
		log.Printf("⏳ DB.Ping retry %d/10: %v", i, err)
		time.Sleep(3 * time.Second)
	}
	log.Fatalf("❌ DB.Ping failed after retries: %v", err)
}

// Migrate — ҷадвалҳоро танҳо агар вуҷуд надошта бошанд месозад.
// Init()-ро ДАР PRODUCTION истифода НАБАРЕД — маълумот тоза мешавад!
// schemaSQL — тамоми схема дар файли алоҳида: internal/db/schema.sql
//
// ЧАРО ҶУДО КАРДА ШУД: он пештар сатри raw-и Go буд (бо backtick
// маҳдудшуда), ва ман СЕ БОР дар шарҳи SQL-и дохили он backtick навиштам
// ва сатрро дар ҳамон ҷо пӯшидам. Ҳар бор Go хатои
// «expected ';', found ...» медод, ки ба SQL ҳеҷ рабте надорад ва
// фаҳмиданаш душвор аст.
//
// Огоҳии матнӣ кифоя набуд — бори сеюм ҳам шуд. Дар файли .sql backtick
// аломати оддӣ аст, пас ин синфи хато ДИГАР имконнопазир аст. Ва
// муҳаррир SQL-ро ҳамчун SQL мефаҳмад, на ҳамчун сатри матн.
//
//go:embed schema.sql
var schemaSQL string

func Migrate() {
	// Ҳар як амрро ҷудогона иҷро мекунем: агар яктааш хато диҳад, сервер
	// АЗ КОР НАМЕАФТАД (log.Fatalf нест) — пас login/register ҳамеша кор
	// мекунанд.
	//
	// ⚠️ Нуқсони ин: хатои як амр танҳо ба лог меравад. Пас схема дар CI
	// ба базаи ТОЗА иҷро мешавад (`backend_test.yml`) — вагарна амри
	// вайрон дар production хомӯшона ҳеҷ кор намекунад ва то рӯзи
	// аввалин фармоиш пинҳон мемонад.
	execEach(schemaSQL)
	log.Println("✅ DB schema ready")
	seedCategories()
}

// execEach — схемаро ба амрҳои алоҳида ҷудо карда, ҳар якро иҷро мекунад.
// Хатои як амр тамоми migration-ро (ва серверро) аз кор намебарорад.
func execEach(schema string) {
	for _, s := range splitStatements(schema) {
		if _, err := DB.Exec(s); err != nil {
			log.Printf("⚠️  migration stmt skipped: %v", err)
		}
	}
}

// splitStatements — схемаро ба амрҳои алоҳида ҷудо мекунад.
//
// ЧАРО ИН ФУНКСИЯ ҲАСТ, НА ОДДӢ `strings.Split(schema, ";")`:
//
// Нусхаи кӯҳна ҳамин тавр мекард, ва он дар ШАРҲ мешикаст. Шарҳи
//
//	-- АНДОЗАГИРӢ: ILIKE = 116 мс Seq Scan; префикси ор% бо ин
//	-- индекс = 0.13 мс
//	CREATE INDEX ...
//
// ба ду пора ҷудо мешуд, ва пораи дуюм бо «префикси ор% бо ин» сар
// мешуд — амри нодуруст. Postgres хато медод, `execEach` онро ба лог
// менавишт ва МЕГУЗАШТ, ва `CREATE INDEX`-и баъди он ҲЕҶ ГОҲ иҷро
// намешуд.
//
// Ин хаторо ман худам кардам, ва тести худам (`TestSearchIndexesExist`)
// онро дар CI дошт — индекс сохта нашуда буд. Вагарна ҷустуҷӯ дар
// production хомӯшона суст мемонд.
//
// Ҳоло шарҳҳои сатрӣ ПЕШ аз ҷудокунӣ бароварда мешаванд, бо назардошти
// он ки `--` дар дохили сатри матнӣ шарҳ НЕСТ.
func splitStatements(schema string) []string {
	var clean strings.Builder
	inString := false

	for _, line := range strings.Split(schema, "\n") {
		cut := len(line)
		// Байт ба байт. `'` ва `-` дар UTF-8 ҳеҷ гоҳ дар дохили ҳарфи
		// бисёрбайта пайдо намешаванд, пас индекси байтӣ бехатар аст.
		//
		// ⚠️ Шарт `i < len(line)` аст, на `i+1 < len(line)`.
		//
		// Нусхаи аввали ман `i+1 < len(line)` дошт ва байти ОХИРИНи
		// сатрро ҳеҷ гоҳ намедид. Сатри схема
		//
		//     UPDATE categories SET icon_url = '...' || slug || '/400'
		//
		// бо нохунак тамом мешавад — пас он ҳисоб намешуд, `inString`
		// абадӣ кушода мемонд, ва ҲАМАИ шарҳҳои баъдӣ ҳамчун SQL
		// мегузаштанд. Тести `TestSplitRealSchemaHasNoBrokenStatements`
		// маҳз ҳаминро дошт.
		for i := 0; i < len(line); i++ {
			switch line[i] {
			case '\'':
				inString = !inString
			case '-':
				if !inString && i+1 < len(line) && line[i+1] == '-' {
					cut = i
					i = len(line) // аз ҳалқа мебароем
				}
			}
		}
		clean.WriteString(line[:cut])
		clean.WriteByte('\n')
	}

	var out []string
	for _, stmt := range strings.Split(clean.String(), ";") {
		if s := strings.TrimSpace(stmt); s != "" {
			out = append(out, s)
		}
	}
	return out
}

func seedCategories() {
	var count int
	DB.QueryRow(`SELECT COUNT(*) FROM categories`).Scan(&count)
	if count > 0 {
		return // Аллакай категорияҳо ҳастанд
	}
	cats := []struct{ name, slug string }{
		{"Телефон ва техника", "electronics"},
		{"Либос ва мода", "fashion"},
		{"Хонагӣ ва мебел", "home"},
		{"Косметика ва зебоӣ", "beauty"},
		{"Варзиш", "sports"},
		{"Китоб ва таълим", "books"},
		{"Ғизо ва нӯшидан", "food"},
		{"Мошин ва автомобил", "auto"},
		{"Кӯдакон", "kids"},
		{"Зевар ва тилло", "jewelry"},
		{"Боғ ва растанӣ", "garden"},
		{"Дигар", "other"},
	}
	for _, cat := range cats {
		DB.Exec(`INSERT INTO categories(id,name,slug) VALUES(uuid_generate_v4(),$1,$2)
			ON CONFLICT(slug) DO NOTHING`, cat.name, cat.slug)
	}
	log.Println("✅ Categories seeded")
}

func Init() {
	drops := `
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS stories CASCADE;
DROP TABLE IF EXISTS follows CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS addresses CASCADE;
DROP TABLE IF EXISTS cart_items CASCADE;
DROP TABLE IF EXISTS favorites CASCADE;
DROP TABLE IF EXISTS product_images CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS users CASCADE;
`
	if _, err := DB.Exec(drops); err != nil {
		log.Fatalf("❌ Drop tables failed: %v", err)
	}

	schema := `
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE users (
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

CREATE TABLE categories (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	name VARCHAR(100) NOT NULL,
	slug VARCHAR(100) UNIQUE NOT NULL,
	icon_url TEXT DEFAULT '',
	parent_id UUID REFERENCES categories(id),
	created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE products (
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

CREATE TABLE product_images (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
	url TEXT NOT NULL,
	position INT DEFAULT 0,
	created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE favorites (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
	created_at TIMESTAMPTZ DEFAULT NOW(),
	UNIQUE(user_id, product_id)
);

CREATE TABLE cart_items (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
	quantity INT DEFAULT 1,
	created_at TIMESTAMPTZ DEFAULT NOW(),
	UNIQUE(user_id, product_id)
);

CREATE TABLE addresses (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	title VARCHAR(100) NOT NULL,
	city VARCHAR(100) NOT NULL,
	street TEXT NOT NULL,
	zip VARCHAR(20) DEFAULT '',
	is_default BOOLEAN DEFAULT false,
	created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE orders (
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

CREATE TABLE order_items (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
	product_id UUID NOT NULL REFERENCES products(id),
	quantity INT NOT NULL,
	price NUMERIC(12,2) NOT NULL,
	created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE reviews (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
	rating INT CHECK(rating BETWEEN 1 AND 5),
	comment TEXT DEFAULT '',
	created_at TIMESTAMPTZ DEFAULT NOW(),
	UNIQUE(user_id, product_id)
);

CREATE TABLE follows (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	following_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	created_at TIMESTAMPTZ DEFAULT NOW(),
	UNIQUE(follower_id, following_id)
);

CREATE TABLE stories (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	media_url TEXT NOT NULL,
	media_type VARCHAR(10) DEFAULT 'image',
	expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '24 hours',
	created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE messages (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	content TEXT NOT NULL,
	is_read BOOLEAN DEFAULT false,
	created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE notifications (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	type VARCHAR(50) NOT NULL,
	title VARCHAR(255) NOT NULL,
	body TEXT DEFAULT '',
	is_read BOOLEAN DEFAULT false,
	ref_id UUID,
	created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE payments (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
	user_id UUID NOT NULL REFERENCES users(id),
	amount NUMERIC(12,2) NOT NULL,
	method VARCHAR(50) DEFAULT 'manual',
	status VARCHAR(30) DEFAULT 'pending',
	proof_url TEXT DEFAULT '',
	created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_products_seller ON products(seller_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_receiver ON messages(receiver_id);
CREATE INDEX idx_notifications_user ON notifications(user_id);
`
	if _, err := DB.Exec(schema); err != nil {
		log.Fatalf("❌ Schema migration failed: %v", err)
	}
	log.Println("✅ DB schema migrated")
}

// MigratePhoneVerify — adds new columns if not exist (safe for existing DB)
func MigratePhoneVerify() {
	queries := []string{
		`ALTER TABLE users ADD COLUMN IF NOT EXISTS firebase_uid TEXT UNIQUE DEFAULT ''`,
		`ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN DEFAULT false`,
	}
	for _, q := range queries {
		DB.Exec(q)
	}
}
