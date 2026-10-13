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

-- Username — ном барои ёфтани корбар/мағоза (@username), беназир.
ALTER TABLE users ADD COLUMN IF NOT EXISTS username VARCHAR(32) DEFAULT '';
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_username
  ON users(LOWER(username)) WHERE username <> '';

-- Корти фурӯшанда — харидор пеш аз расонидан маблағро мефиристад, то
-- фурӯшанда бе фоида роҳ наравад. Танҳо ба харидори фармоиши ҳамон
-- фурӯшанда кушода мешавад.
ALTER TABLE users ADD COLUMN IF NOT EXISTS card_number TEXT DEFAULT '';
ALTER TABLE users ADD COLUMN IF NOT EXISTS card_holder TEXT DEFAULT '';
ALTER TABLE users ADD COLUMN IF NOT EXISTS business_type TEXT DEFAULT 'shop';
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS images JSONB DEFAULT '[]'::jsonb;

-- Маълумоти доставка ва размери маҳсулот (то харидор напурсад).
ALTER TABLE products ADD COLUMN IF NOT EXISTS delivery_days  INT DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS delivery_price NUMERIC(12,2) DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS size_info      TEXT DEFAULT '';

-- Оё фурӯшанда барои ин маҳсулот расонидан пешниҳод мекунад?
-- Харидор инро пеш аз харид мебинад, то интизори бефоида накашад.
ALTER TABLE products ADD COLUMN IF NOT EXISTS has_delivery BOOLEAN DEFAULT true;

-- Баҳои фурӯшанда (1..10) аз ҷониби харидор пас аз гирифтани мол.
CREATE TABLE IF NOT EXISTS seller_ratings (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	seller_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	buyer_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	order_id  UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
	score     INT NOT NULL CHECK (score BETWEEN 1 AND 10),
	comment   TEXT DEFAULT '',
	created_at TIMESTAMPTZ DEFAULT NOW(),
	-- як харидор барои як фармоиш танҳо як бор баҳо медиҳад
	UNIQUE(seller_id, buyer_id, order_id)
);
CREATE INDEX IF NOT EXISTS idx_seller_ratings_seller ON seller_ratings(seller_id);

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

-- Галочкаи тасдиқ (расмӣ): нарх ва корти қабули пул. Ҳарду аз панели админ
-- иваз мешаванд, то барои тағйири нарх нашри нави барнома лозим набошад.
INSERT INTO settings(key,value) VALUES('verify_price','50') ON CONFLICT(key) DO NOTHING;
INSERT INTO settings(key,value) VALUES('verify_card','9762 0001 9975 7344') ON CONFLICT(key) DO NOTHING;
INSERT INTO settings(key,value) VALUES('verify_card_holder','TajikShop') ON CONFLICT(key) DO NOTHING;

-- ═══ Каталоги УМУМИИ штрих-кодҳо ═══════════════════════════════════════
-- Масъалаи мағозаи хӯрокворӣ: 500 маҳсулот гузоштан — чанд рӯз кор.
-- Ҳар мағоза ҳамон «Coca-Cola 1л»-ро аз нав менависад ва расм меёбад.
--
-- Ҳал: вақте ки ЯК мағоза маҳсулотро бо штрих-код мегузорад, ном, бренд,
-- расм ва воҳиди он ба каталоги умумӣ меафтад. Мағозаи дигар ҳамон кодро
-- сканер мекунад ва ҳамааш худкор пур мешавад — ӯ танҳо нарх ва шумора
-- мегузорад.
--
-- Ҳар мағозаи нав каталогро бойтар мекунад, ва каталоги бойтар мағозаи
-- навбатиро ҷалб мекунад.
CREATE TABLE IF NOT EXISTS barcode_catalog (
	barcode VARCHAR(64) PRIMARY KEY,
	title TEXT NOT NULL,
	brand TEXT DEFAULT '',
	image_url TEXT DEFAULT '',
	unit TEXT DEFAULT 'дона',
	category_id UUID REFERENCES categories(id),
	created_by UUID REFERENCES users(id) ON DELETE SET NULL,
	-- Админ тасдиқ кардааст? Сатри тасдиқшуда аз ҷониби мағозаҳо иваз
	-- намешавад — вагарна як хатои касе ба ҳамаи мағозаҳо мегузарад.
	is_verified BOOLEAN DEFAULT false,
	times_used INT DEFAULT 1,
	created_at TIMESTAMPTZ DEFAULT NOW(),
	updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_catalog_title ON barcode_catalog(title);

-- Мағозаи хӯрокворӣ бе инҳо кор карда наметавонад:
-- воҳид (дона/кг/литр) ва мӯҳлати нигоҳдорӣ.
ALTER TABLE products ADD COLUMN IF NOT EXISTS unit TEXT DEFAULT 'дона';
ALTER TABLE products ADD COLUMN IF NOT EXISTS expires_on DATE;
CREATE INDEX IF NOT EXISTS idx_products_expires ON products(expires_on)
	WHERE expires_on IS NOT NULL;

-- SSO: як ҳисоб барои ҳамаи барномаҳои Raonson. Коди якдафъаина, ки
-- барномаи дигарро ба ҳамон корбар медарорад. Дар база ХУДИ код не,
-- балки ҳэши он нигоҳ дошта мешавад — пас дастрасӣ ба база ба касе
-- сессия намедиҳад.
CREATE TABLE IF NOT EXISTS sso_codes (
	id UUID PRIMARY KEY,
	user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	target_app TEXT NOT NULL,
	code_hash TEXT NOT NULL,
	expires_at TIMESTAMPTZ NOT NULL,
	used_at TIMESTAMPTZ,
	created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_sso_code_hash ON sso_codes(code_hash);
CREATE INDEX IF NOT EXISTS idx_sso_user ON sso_codes(user_id);

-- Сессияҳо: як сатр барои ҳар вуруд (дастгоҳи TajikShop, Raonson, ...).
-- Пештар users.refresh_token ЯК сутун буд, пас ҳар вуруди нав (ё
-- /sso/exchange-и Raonson) сессияи дигарро мекушт. Дар база ҳэши токен
-- (SHA-256) мемонад, на худи токен. prev_token_hash — токени қаблӣ пас аз
-- ротатсия (барои барномаҳои кӯҳна, ки токени навро нигоҳ намедоранд).
-- Сутуни кӯҳнаи users.refresh_token ҳангоми аввалин /auth/refresh ба
-- сессияи client=app гузаронида мешавад (ниг. handles/sessions.go).
CREATE TABLE IF NOT EXISTS auth_sessions (
	id UUID PRIMARY KEY,
	user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	client TEXT NOT NULL DEFAULT 'app',
	token_hash TEXT NOT NULL,
	prev_token_hash TEXT,
	created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
	last_used_at TIMESTAMPTZ,
	expires_at TIMESTAMPTZ NOT NULL,
	revoked_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_auth_sessions_user ON auth_sessions(user_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_auth_sessions_token ON auth_sessions(token_hash);

-- Почта тасдиқ шудааст? Ҳоло TajikShop ҷараёни тасдиқи почта НАДОРАД, пас
-- ҳамеша false аст. Бо is_verified (галочкаи фурӯшанда) омехта накунед.
ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT false;

-- Дархостҳои галочка: харидор/фурӯшанда пул мефиристад ва чекро мегузорад,
-- админ тасдиқ мекунад → users.is_verified=true.
CREATE TABLE IF NOT EXISTS verification_requests (
	id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	amount     NUMERIC(12,2) DEFAULT 0,
	receipt_url TEXT DEFAULT '',
	status     VARCHAR(16) DEFAULT 'pending', -- pending | approved | rejected
	note       TEXT DEFAULT '',
	created_at TIMESTAMPTZ DEFAULT NOW(),
	updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_verify_req_status ON verification_requests(status, created_at);
-- Як корбар танҳо як дархости ҳалнашуда дошта метавонад.
CREATE UNIQUE INDEX IF NOT EXISTS idx_verify_req_one_pending
  ON verification_requests(user_id) WHERE status='pending';

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

-- Тафсилоти суроға, то расонанда гум нашавад: рақами хона ҳатмист,
-- вуруд/ошёна ва нишонаи наздик (ориентир) ихтиёрӣ.
ALTER TABLE addresses ADD COLUMN IF NOT EXISTS house     VARCHAR(32) DEFAULT '';
ALTER TABLE addresses ADD COLUMN IF NOT EXISTS entrance  VARCHAR(16) DEFAULT '';
ALTER TABLE addresses ADD COLUMN IF NOT EXISTS floor     VARCHAR(16) DEFAULT '';
ALTER TABLE addresses ADD COLUMN IF NOT EXISTS apartment VARCHAR(16) DEFAULT '';
ALTER TABLE addresses ADD COLUMN IF NOT EXISTS landmark  TEXT DEFAULT '';
ALTER TABLE addresses ADD COLUMN IF NOT EXISTS region    VARCHAR(80) DEFAULT '';

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

-- ═══════════════════════════════════════════════════════════════════════
--  Фармоиши бисёрфурӯшанда, idempotency ва маҳдудияти купон
-- ═══════════════════════════════════════════════════════════════════════

-- Сурати маҳсулот дар лаҳзаи фармоиш.
--
-- order_items танҳо product_id ва нарх дошт. Агар фурӯшанда баъд
-- номи маҳсулотро иваз кунад, таърихи фармоиши кӯҳна ҳам иваз мешуд —
-- яъне харидор дар фармоиши дусолаи худ номи дигарро мебинад. Ҳоло
-- ном, фурӯшанда ва воҳид дар лаҳзаи фармоиш нигоҳ дошта мешаванд.
ALTER TABLE order_items ADD COLUMN IF NOT EXISTS seller_id UUID;
ALTER TABLE order_items ADD COLUMN IF NOT EXISTS title     TEXT DEFAULT '';
ALTER TABLE order_items ADD COLUMN IF NOT EXISTS unit      TEXT DEFAULT 'дона';
CREATE INDEX IF NOT EXISTS idx_order_items_seller ON order_items(seller_id);

-- Барои сатрҳои кӯҳна seller_id-ро аз маҳсулот мегирем (як бор).
UPDATE order_items oi SET seller_id = p.seller_id
	FROM products p WHERE p.id = oi.product_id AND oi.seller_id IS NULL;

-- Зер-фармоиш: ҳолати ҲАР ФУРӮШАНДА дар як фармоиш.
--
-- Масъалаи аслӣ: дар сабад моли ду фурӯшанда буд, вале orders як сатр
-- буд ва як status дошт. Фурӯшандаи A «фиристодам» мезад — ва тамоми
-- фармоиш, аз ҷумла моли фурӯшандаи B, «фиристода шуд» мешуд. Ҳимояи
-- харидор ҳам барои моли нафиристодаи B сар мешуд.
CREATE TABLE IF NOT EXISTS order_sellers (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
	seller_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	status VARCHAR(30) DEFAULT 'pending',
	subtotal NUMERIC(12,2) NOT NULL DEFAULT 0,
	tracking_code VARCHAR(64) DEFAULT '',
	shipped_at TIMESTAMPTZ,
	delivered_at TIMESTAMPTZ,
	protect_until TIMESTAMPTZ,
	released BOOLEAN DEFAULT false,
	created_at TIMESTAMPTZ DEFAULT NOW(),
	updated_at TIMESTAMPTZ DEFAULT NOW(),
	UNIQUE(order_id, seller_id)
);
CREATE INDEX IF NOT EXISTS idx_order_sellers_seller ON order_sellers(seller_id, status);

-- Фармоишҳои кӯҳнаро ба order_sellers мегузаронем, то фурӯшандагон
-- таърихи худро гум накунанд.
INSERT INTO order_sellers(order_id, seller_id, status, subtotal)
SELECT oi.order_id, oi.seller_id, o.status, SUM(oi.price * oi.quantity)
	FROM order_items oi
	JOIN orders o ON o.id = oi.order_id
	WHERE oi.seller_id IS NOT NULL
	GROUP BY oi.order_id, oi.seller_id, o.status
ON CONFLICT (order_id, seller_id) DO NOTHING;

-- Idempotency: як зеркунӣ = як фармоиш.
--
-- Пештар калид набуд. Агар харидор тугмаро ду бор занад ё интернет
-- ҷавобро гум кунад ва барнома такрор фиристад — ДУ фармоиш сохта мешуд
-- ва аз ҳамёнаш ду бор пул мерафт.
CREATE TABLE IF NOT EXISTS checkout_keys (
	key TEXT PRIMARY KEY,
	user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
	created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Купон: маҳдудияти ҳар корбар.
--
-- coupons.used_count ҷамъи умумӣ буд, пас як корбар метавонист ҳамон
-- купонро бефосила истифода кунад.
ALTER TABLE coupons ADD COLUMN IF NOT EXISTS per_user_limit INT DEFAULT 1;
CREATE TABLE IF NOT EXISTS coupon_redemptions (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	code VARCHAR(40) NOT NULL,
	user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
	created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_coupon_redeem ON coupon_redemptions(code, user_id);

-- Зинаҳои нархи яклухт.
--
-- Пештар маҳсулот ЯК wholesale_price дошт — як рақам, бе ҳеҷ шарт, ва он
-- на дар сабад, на дар checkout истифода намешуд. Савдои яклухти воқеӣ
-- бо зинаҳо кор мекунад: 1-9 дона як нарх, 10-49 нархи камтар, 50+ боз
-- камтар.
CREATE TABLE IF NOT EXISTS product_price_tiers (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
	min_qty INT NOT NULL,
	price NUMERIC(12,2) NOT NULL,
	created_at TIMESTAMPTZ DEFAULT NOW(),
	UNIQUE(product_id, min_qty)
);
CREATE INDEX IF NOT EXISTS idx_price_tiers_product ON product_price_tiers(product_id, min_qty);

-- ═══════════════════════════════════════════════════════════════════════
--  RFQ — дархости нарх (Request for Quotation)
-- ═══════════════════════════════════════════════════════════════════════
--
-- Ин маркази савдои B2B аст. Харидор намегӯяд «ин молро мехарам» —
-- мегӯяд «ба ман 500 кг орд лозим, кӣ чанд медиҳад?». Фурӯшандагон
-- пешниҳод медиҳанд, харидор муқоиса мекунад, гуфтушунид мешавад, ва
-- пешниҳоди қабулшуда ба фармоиш табдил меёбад.
--
-- Бе ин савдои яклухт дар барнома умуман нест: харидори калон маҷбур
-- мешавад бо ҳар фурӯшанда ҷудогона дар чат гуфтугӯ кунад.

CREATE TABLE IF NOT EXISTS rfqs (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	buyer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	title VARCHAR(200) NOT NULL,
	description TEXT DEFAULT '',
	category_id UUID REFERENCES categories(id),
	quantity INT NOT NULL,
	unit TEXT DEFAULT 'дона',
	target_price NUMERIC(12,2) DEFAULT 0,   -- 0 = нишон дода нашуд
	destination VARCHAR(200) DEFAULT '',
	needed_by DATE,
	closes_at TIMESTAMPTZ NOT NULL,
	status VARCHAR(20) DEFAULT 'open',      -- open | closed | awarded | cancelled
	awarded_quote_id UUID,
	created_at TIMESTAMPTZ DEFAULT NOW(),
	updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_rfqs_buyer ON rfqs(buyer_id, created_at DESC);
-- Фурӯшанда дархостҳои КУШОДАро мебинад — пас индекс маҳз аз рӯи ҳолат
-- ва мӯҳлат.
CREATE INDEX IF NOT EXISTS idx_rfqs_open ON rfqs(status, closes_at DESC);

CREATE TABLE IF NOT EXISTS rfq_attachments (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	rfq_id UUID NOT NULL REFERENCES rfqs(id) ON DELETE CASCADE,
	url TEXT NOT NULL,
	created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Пешниҳоди фурӯшанда.
--
-- Версия НИГОҲ ДОШТА МЕШАВАД, иваз намешавад. Фурӯшанда нархро тағйир
-- медиҳад → сатри НАВ бо version+1, сатри кӯҳна 'revised' мешавад.
--
-- Чаро: бе ин харидор нархи дидаашро исбот карда наметавонад. Маҳз
-- ҳамин ҷойест, ки ихтилоф ба вуҷуд меояд — «шумо 80 гуфта будед».
CREATE TABLE IF NOT EXISTS rfq_quotes (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	rfq_id UUID NOT NULL REFERENCES rfqs(id) ON DELETE CASCADE,
	seller_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	version INT NOT NULL DEFAULT 1,
	unit_price NUMERIC(12,2) NOT NULL,
	min_qty INT DEFAULT 1,
	shipping_cost NUMERIC(12,2) DEFAULT 0,
	lead_days INT DEFAULT 0,
	payment_terms VARCHAR(200) DEFAULT '',
	note TEXT DEFAULT '',
	valid_until TIMESTAMPTZ,
	status VARCHAR(20) DEFAULT 'active',
		-- active | revised | withdrawn | accepted | rejected
	created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_rfq_quotes_rfq ON rfq_quotes(rfq_id, status);
CREATE INDEX IF NOT EXISTS idx_rfq_quotes_seller ON rfq_quotes(seller_id, created_at DESC);

-- Гуфтушунид. Паёмҳо ба дархост баста мешаванд, на ба чати умумӣ — то
-- дар як ҷо бошанд ва баъд ҳамчун таърихи шартҳо хонда шаванд.
CREATE TABLE IF NOT EXISTS rfq_messages (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	rfq_id UUID NOT NULL REFERENCES rfqs(id) ON DELETE CASCADE,
	sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	-- Паёми фурӯшанда танҳо ба харидор меравад, на ба рақибон.
	seller_id UUID REFERENCES users(id) ON DELETE CASCADE,
	body TEXT NOT NULL,
	created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_rfq_msgs ON rfq_messages(rfq_id, seller_id, created_at);

-- Фармоише, ки аз пешниҳод сохта шуд — то робита гум нашавад.
ALTER TABLE orders ADD COLUMN IF NOT EXISTS rfq_quote_id UUID;

-- Фармоиши RFQ маҳсулоти мушаххас НАДОРАД.
--
-- Дар дархости нарх харидор «500 кг орд» мехоҳад, на моли мушаххаси
-- ин ё он фурӯшандаро. Пас сатри order_items бе product_id сохта
-- мешавад, вале бо ном, воҳид, фурӯшанда ва нарх ҳамчун СУРАТ.
--
-- Барои ҳамин ҳамаи дархостҳои «моли ин фурӯшанда» аз
-- JOIN products ... WHERE p.seller_id ба oi.seller_id гузаштанд:
-- бо INNER JOIN сатри бе маҳсулот умуман гум мешуд, ва фурӯшанда
-- фармоиши RFQ-и худро дар панелаш НАМЕДИД.
ALTER TABLE order_items ALTER COLUMN product_id DROP NOT NULL;

-- Дафтари амалҳои админ.
--
-- Дар аудит ин ҳамчун камбудии АМНИЯТ навишта шуда буд: админ метавонад
-- корбарро бандад, фурӯшандаро тасдиқ кунад, амалиёти ҳамёнро тасдиқ
-- кунад — ва ҳеҷ осоре намемонад.
--
-- Платформа бо пули ҳақиқӣ кор мекунад. Агар рӯзе маблағе нопадид шавад
-- ё фурӯшандае бегуноҳ баста шавад, бе ин дафтар ҳеҷ роҳе нест фаҳмидан,
-- КӢ ва КАЙ инро кард.
--
-- «ON DELETE SET NULL» барои admin_id: сатри дафтар бояд ҳатто баъди
-- нест шудани ҳисоби админ монад — вагарна осори амал бо худи админ
-- нопадид мешавад.
CREATE TABLE IF NOT EXISTS admin_actions (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	admin_id UUID REFERENCES users(id) ON DELETE SET NULL,
	method VARCHAR(10) NOT NULL,
	path TEXT NOT NULL,
	target_id UUID,
	payload JSONB,
	status INT,
	created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_admin_actions_time ON admin_actions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_actions_admin ON admin_actions(admin_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_actions_target ON admin_actions(target_id);

-- Минтақаи фаъолияти фурӯшанда.
--
-- Барои ҷустуҷӯи таъминкунанда лозим аст: харидори яклухт аввал
-- мепурсад «кӣ дар минтақаи ман кор мекунад?». Ҷадвали `addresses`
-- минтақа дошт, вале он суроғаи ХАРИДОР аст, на минтақаи фаъолияти
-- фурӯшанда.
--
-- Ин майдонро ХУДИ фурӯшанда менависад, пас дар API ҳамчун
-- `self_reported` бармегардад, на ҳамчун маълумоти тасдиқшуда.
ALTER TABLE users ADD COLUMN IF NOT EXISTS region VARCHAR(80) DEFAULT '';
CREATE INDEX IF NOT EXISTS idx_users_seller_region ON users(is_seller, region);

-- Индексҳои ҷустуҷӯ.
--
-- АНДОЗАГИРИИ ВОҚЕӢ (Postgres 16, 60 000 маҳсулот):
--
--   БЕ индекс:  99 мс,  Seq Scan, 51 429 сатр партофта шуд
--   БО pg_trgm: 13 мс,  Bitmap Index Scan  → 7.4 баробар зудтар
--
-- Муҳимтар аз ҳама: дархост ТАҒЙИР НАМЕЁБАД. Ҳамон `ILIKE '%...%'`
-- мемонад — танҳо индекс илова мешавад. Пас маънои ҷустуҷӯ ҳамон
-- мемонад ва хатари вайрон кардани натиҷаҳо нест.
--
-- Чаро `tsvector` НЕ: он калимаи пурра меҷӯяд. Корбар «Samsu» менависад
-- ва «Samsung»-ро интизор аст — `tsvector` онро НАМЕЁБАД, триграм меёбад
-- (андозагирифташуда: 14.5 мс).
--
-- Агар `pg_trgm` дар миз набошад (ҳуқуқ нарасад), `execEach` хаторо ба
-- лог менависад ва мегузарад: ҷустуҷӯ сусттар мемонад, вале кор мекунад.
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS idx_products_title_trgm
  ON products USING gin (title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_products_desc_trgm
  ON products USING gin (description gin_trgm_ops);

-- Ҷустуҷӯи 1-2 ҳарфӣ: триграм ба 3 ҳарф эҳтиёҷ дорад, пас барои
-- калимаҳои кӯтоҳ префикс истифода мешавад.
--
-- АНДОЗАГИРӢ: `ILIKE '%ор%'` = 116 мс Seq Scan; префикси `ор%` бо ин
-- индекс = 0.13 мс, ва ҳолати бенатиҷа (`zz%`) = 0.09 мс.
CREATE INDEX IF NOT EXISTS idx_products_title_prefix
  ON products (lower(title) text_pattern_ops);

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
