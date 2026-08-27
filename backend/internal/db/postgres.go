package db

import (
	"database/sql"
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
func Migrate() {
	schema := `
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS users (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	name VARCHAR(100) NOT NULL,
	email VARCHAR(255) UNIQUE,
	phone VARCHAR(20) UNIQUE,
	password_hash TEXT NOT NULL,
	firebase_uid TEXT UNIQUE DEFAULT '',
	phone_verified BOOLEAN DEFAULT false,
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
CREATE INDEX IF NOT EXISTS idx_orders_user ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver ON messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);

-- ===== Wallet, Coupons & Payment methods (safe, idempotent) =====
ALTER TABLE users  ADD COLUMN IF NOT EXISTS wallet_balance NUMERIC(12,2) DEFAULT 0;
ALTER TABLE users  ADD COLUMN IF NOT EXISTS fcm_token TEXT DEFAULT '';
ALTER TABLE users  ADD COLUMN IF NOT EXISTS passport_url TEXT DEFAULT '';
ALTER TABLE users  ADD COLUMN IF NOT EXISTS store_lat DOUBLE PRECISION DEFAULT 0;
ALTER TABLE users  ADD COLUMN IF NOT EXISTS store_lng DOUBLE PRECISION DEFAULT 0;
ALTER TABLE users  ADD COLUMN IF NOT EXISTS seller_requested BOOLEAN DEFAULT false;

-- Системаи даъват (referral) — рушди вирусӣ: даъваткунанда ва даъватшуда бонус мегиранд.
ALTER TABLE users ADD COLUMN IF NOT EXISTS referral_code TEXT DEFAULT '';
ALTER TABLE users ADD COLUMN IF NOT EXISTS referred_by UUID;
ALTER TABLE products ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT false;
ALTER TABLE products ADD COLUMN IF NOT EXISTS featured_until TIMESTAMPTZ;
UPDATE users SET referral_code = UPPER(SUBSTRING(REPLACE(id::text,'-','') FROM 1 FOR 6))
  WHERE referral_code IS NULL OR referral_code = '';

-- Профили бизнес/мағоза (TajikShop Pro — соҳибкори офлайн онлайн меравад).
ALTER TABLE users ADD COLUMN IF NOT EXISTS shop_name  TEXT DEFAULT '';
ALTER TABLE users ADD COLUMN IF NOT EXISTS shop_desc  TEXT DEFAULT '';
ALTER TABLE users ADD COLUMN IF NOT EXISTS shop_phone TEXT DEFAULT '';
ALTER TABLE users ADD COLUMN IF NOT EXISTS shop_hours TEXT DEFAULT '';
ALTER TABLE users ADD COLUMN IF NOT EXISTS business_type TEXT DEFAULT 'shop';
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS images JSONB DEFAULT '[]'::jsonb;

-- Маълумоти доставка ва размери маҳсулот (то харидор напурсад).
ALTER TABLE products ADD COLUMN IF NOT EXISTS delivery_days  INT DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS delivery_price NUMERIC(12,2) DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS size_info      TEXT DEFAULT '';

-- Штрих-код (barcode/EAN) барои сканери маҳсулот дар мағоза.
ALTER TABLE products ADD COLUMN IF NOT EXISTS barcode VARCHAR(64) DEFAULT '';
CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode) WHERE barcode <> '';

-- Ҳазфи ҳисоб (Google Play): аломати ҳисоби ҳазфшуда (маълумоти шахсӣ anonymize мешавад).
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- Дархостҳои ҳазфи ҳисоб аз саҳифаи оммавии веб (/delete-account) — барои
-- корбароне ки ба барнома дастрасӣ надоранд. Админ дар давоми ~7 рӯз иҷро мекунад.
CREATE TABLE IF NOT EXISTS deletion_requests (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email      TEXT NOT NULL,
  note       TEXT DEFAULT '',
  status     VARCHAR(16) DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Танзимоти платформа (комиссия ва ғ.). Комиссияи пешфарз: 10%.
CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT NOT NULL);
INSERT INTO settings(key,value) VALUES('commission_percent','10') ON CONFLICT(key) DO NOTHING;
INSERT INTO settings(key,value) VALUES('cashback_percent','2') ON CONFLICT(key) DO NOTHING;

-- Карго (доставка аз Хитой → Тоҷикистон/Русия). Суроға ва тарифҳо (сом/кг).
INSERT INTO settings(key,value) VALUES('cargo_warehouse','Китай, Гуанчжоу (суроғаро админ дар танзимот мегузорад)') ON CONFLICT(key) DO NOTHING;
INSERT INTO settings(key,value) VALUES('cargo_rate_tj','45') ON CONFLICT(key) DO NOTHING;
INSERT INTO settings(key,value) VALUES('cargo_rate_ru','60') ON CONFLICT(key) DO NOTHING;
INSERT INTO settings(key,value) VALUES('cargo_phone','') ON CONFLICT(key) DO NOTHING;

-- Фармоишҳои карго (доставка аз Хитой). status: new→received→shipped→arrived→delivered.
CREATE TABLE IF NOT EXISTS cargo_orders (
  id           UUID PRIMARY KEY,
  user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  track_code   TEXT DEFAULT '',
  product_link TEXT DEFAULT '',
  description  TEXT DEFAULT '',
  destination  VARCHAR(4) DEFAULT 'tj',
  weight       NUMERIC(10,2) DEFAULT 0,
  cost         NUMERIC(12,2) DEFAULT 0,
  status       VARCHAR(16) DEFAULT 'new',
  note         TEXT DEFAULT '',
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_cargo_user ON cargo_orders(user_id);

-- Категорияҳоро бо расм таъмин мекунем (агар холӣ бошанд).
UPDATE categories SET icon_url = 'https://picsum.photos/seed/' || slug || '/400'
  WHERE icon_url IS NULL OR icon_url = '';

-- Маҳсулоти фурӯхташуда (stock<=0), ки дар ягон фармоиш нест, пурра нест мешавад,
-- то серверро бор накунад (order_items бо RESTRICT — таърихи фармоишҳо эмин мемонад).
DELETE FROM products p WHERE p.stock <= 0
  AND NOT EXISTS (SELECT 1 FROM order_items oi WHERE oi.product_id = p.id);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS payment_method VARCHAR(20) DEFAULT 'dc';
ALTER TABLE orders ADD COLUMN IF NOT EXISTS discount NUMERIC(12,2) DEFAULT 0;

-- Тарзи гирифтан (расонидан / аз мағоза), ҳаққи расонидан ва вақти дилхоҳ.
ALTER TABLE orders ADD COLUMN IF NOT EXISTS fulfilment    VARCHAR(20) DEFAULT 'delivery';
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_fee  NUMERIC(12,2) DEFAULT 0;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_slot VARCHAR(10) DEFAULT '';

-- ── Ҳимояи харидор (мисли Alibaba Buyer Protection) ──────────────────────
-- Вақти фиристодан/супоридан ва мӯҳлати ҳимоя. Агар харидор дар ин мӯҳлат
-- шикоят накунад, пул худкор ба фурӯшанда мегузарад (то фурӯшанда интизори
-- абадӣ накашад), вале то он вақт пул дар escrow ҳифз мешавад.
ALTER TABLE orders ADD COLUMN IF NOT EXISTS shipped_at    TIMESTAMPTZ;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivered_at  TIMESTAMPTZ;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS protect_until TIMESTAMPTZ;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS auto_released BOOLEAN DEFAULT false;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS tracking_code VARCHAR(64) DEFAULT '';
CREATE INDEX IF NOT EXISTS idx_orders_protect
  ON orders(protect_until) WHERE status <> 'completed' AND status <> 'cancelled';

-- Таърихи ҳолати фармоиш — харидор ҳар қадамро мебинад (timeline).
CREATE TABLE IF NOT EXISTS order_events (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
	status VARCHAR(30) NOT NULL,
	note TEXT DEFAULT '',
	created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_order_events_order ON order_events(order_id, created_at);
ALTER TABLE addresses ADD COLUMN IF NOT EXISTS lat DOUBLE PRECISION DEFAULT 0;
ALTER TABLE addresses ADD COLUMN IF NOT EXISTS lng DOUBLE PRECISION DEFAULT 0;

CREATE TABLE IF NOT EXISTS wallet_transactions (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	amount NUMERIC(12,2) NOT NULL,
	type VARCHAR(20) NOT NULL,          -- topup | purchase | refund
	status VARCHAR(20) DEFAULT 'pending', -- pending | completed | rejected
	note TEXT DEFAULT '',
	created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_wallet_tx_user ON wallet_transactions(user_id);

CREATE TABLE IF NOT EXISTS coupons (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	code VARCHAR(40) UNIQUE NOT NULL,
	discount_percent INT NOT NULL DEFAULT 0,
	max_uses INT DEFAULT 0,             -- 0 = бемаҳдуд
	used_count INT DEFAULT 0,
	is_active BOOLEAN DEFAULT true,
	expires_at TIMESTAMPTZ,
	created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS reports (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	reporter_id UUID REFERENCES users(id) ON DELETE SET NULL,
	target_type VARCHAR(20) NOT NULL,   -- product | user
	target_id UUID NOT NULL,
	reason TEXT NOT NULL,
	resolved BOOLEAN DEFAULT false,
	created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===== Brands & Product variants (size/color/SKU) + MOQ/wholesale =====
CREATE TABLE IF NOT EXISTS brands (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	name VARCHAR(100) NOT NULL,
	slug VARCHAR(100) UNIQUE NOT NULL,
	logo_url TEXT DEFAULT '',
	created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS product_variants (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
	size VARCHAR(50) DEFAULT '',
	color VARCHAR(50) DEFAULT '',
	sku VARCHAR(80) DEFAULT '',
	price NUMERIC(12,2) DEFAULT 0,
	stock INT DEFAULT 0,
	created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_variants_product ON product_variants(product_id);
ALTER TABLE products ADD COLUMN IF NOT EXISTS brand_id UUID REFERENCES brands(id);
ALTER TABLE products ADD COLUMN IF NOT EXISTS min_order_qty INT DEFAULT 1;
ALTER TABLE products ADD COLUMN IF NOT EXISTS wholesale_price NUMERIC(12,2) DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS sale_ends_at TIMESTAMPTZ;

-- ===== Review helpful votes + Product Q&A =====
CREATE TABLE IF NOT EXISTS review_likes (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	review_id UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
	user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	created_at TIMESTAMPTZ DEFAULT NOW(),
	UNIQUE(review_id, user_id)
);
CREATE TABLE IF NOT EXISTS questions (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
	user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	question TEXT NOT NULL,
	answer TEXT DEFAULT '',
	answered_by UUID,
	created_at TIMESTAMPTZ DEFAULT NOW(),
	answered_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_questions_product ON questions(product_id);

-- ===== Returns / Exchanges =====
CREATE TABLE IF NOT EXISTS returns (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
	user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	type VARCHAR(20) NOT NULL DEFAULT 'return',  -- return | exchange
	reason TEXT NOT NULL,
	status VARCHAR(20) DEFAULT 'pending',         -- pending | approved | rejected | completed
	created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_returns_order ON returns(order_id);

-- ===== Индексҳои иловагӣ барои зудӣ (scale) =====
CREATE INDEX IF NOT EXISTS idx_reviews_product ON reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_favorites_user ON favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_cart_user ON cart_items(user_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_product_images_product ON product_images(product_id);
CREATE INDEX IF NOT EXISTS idx_products_active_created ON products(is_active, created_at DESC);

-- ===== Тоза кардани сатрҳои холӣ дар сутунҳои UNIQUE =====
-- Дар Postgres '' != NULL, пас ду корбари бе телефон/email ба UNIQUE бархӯрд мекунанд.
-- Сатри холиро ба NULL табдил медиҳем — NULL-ҳо ба UNIQUE бархӯрд намекунанд.
UPDATE users SET email=NULL WHERE email='';
UPDATE users SET phone=NULL WHERE phone='';
UPDATE users SET firebase_uid=NULL WHERE firebase_uid='';
ALTER TABLE users ALTER COLUMN firebase_uid DROP DEFAULT;
`
	// Ҳар як амрро ҷудогона иҷро мекунем: агар яктааш хато диҳад, сервер
	// АЗ КОР НАМЕАФТАД (log.Fatalf нест) — пас login/register ҳамеша кор мекунанд.
	execEach(schema)
	log.Println("✅ DB schema ready")
	seedCategories()
}

// execEach — схемаро ба амрҳои алоҳида ҷудо карда, ҳар якро иҷро мекунад.
// Хатои як амр тамоми migration-ро (ва серверро) аз кор намебарорад.
func execEach(schema string) {
	for _, stmt := range strings.Split(schema, ";") {
		s := strings.TrimSpace(stmt)
		if s == "" {
			continue
		}
		if _, err := DB.Exec(s); err != nil {
			log.Printf("⚠️  migration stmt skipped: %v", err)
		}
	}
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
