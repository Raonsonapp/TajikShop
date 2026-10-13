package handlers

import (
	"net/http"
	"strings"
	"tajikshop/internal/db"
	"tajikshop/internal/utils"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// ═══════════════════════════════════════════════════════════════════════════
//  Каталоги умумии штрих-кодҳо — барои мағозаҳои хӯрокворӣ
// ═══════════════════════════════════════════════════════════════════════════
//
// Мағозаи хӯрокворӣ 500–2000 ном маҳсулот дорад. Гузоштани ҳар кадом бо
// даст — чанд рӯз кор, ва маҳз ҳамин мағозаҳоро аз ҳар барномаи савдо дур
// мекунад.
//
// Ин ҷо: ҳамин ки ЯК мағоза маҳсулотро бо штрих-код гузошт, ном, бренд,
// расм ва воҳиди он ба каталоги умумӣ меафтад. Мағозаи дигар ҳамон кодро
// сканер мекунад → ҳамааш худкор пур мешавад → ӯ танҳо нарх ва шумора
// мегузорад.
//
// Ин шабакаи фоида месозад: ҳар мағозаи нав каталогро бойтар мекунад, ва
// каталоги бойтар мағозаи навбатиро ҷалб мекунад.

// Воҳидҳои иҷозатдодашуда — то дар каталог «кг», «Кг», «килограмм» ва
// «kg» ҳамзамон пайдо нашаванд.
var allowedUnits = map[string]bool{
	"дона": true, "кг": true, "грамм": true, "литр": true,
	"мл": true, "баста": true, "қуттӣ": true, "халта": true,
}

func normalizeUnit(u string) string {
	u = strings.ToLower(strings.TrimSpace(u))
	switch u {
	case "":
		return "дона"
	case "kg", "килограмм", "kилограмм":
		return "кг"
	case "l", "л", "литре":
		return "литр"
	case "pcs", "шт", "штука":
		return "дона"
	case "g", "гр":
		return "грамм"
	case "ml":
		return "мл"
	}
	if allowedUnits[u] {
		return u
	}
	return "дона"
}

// normalizeBarcode — штрих-кодро ба шакли ягона меорад. Сканер метавонад
// фосила ё аломати ғайрирақамӣ диҳад, ва он гоҳ ҳамон маҳсулот ду сатри
// гуногуни каталог месозад.
func normalizeBarcode(code string) string {
	var b strings.Builder
	for _, r := range code {
		if r >= '0' && r <= '9' {
			b.WriteRune(r)
		}
	}
	return b.String()
}

type CatalogHandler struct{}

func NewCatalogHandler() *CatalogHandler { return &CatalogHandler{} }

// Lookup — GET /catalog/barcode/:code   (оммавӣ)
//
// Фурӯшанда кодро сканер мекунад ва ин ҷо ном/бренд/расм/воҳидро мегирад.
// Ин аз `/products/barcode/:code` фарқ мекунад: он ҷо маҳсулоти як
// фурӯшандаи мушаххас бармегардад, ин ҷо маълумоти УМУМӢ барои сохтани
// эълони худи шумо.
func (h *CatalogHandler) Lookup(c *gin.Context) {
	code := normalizeBarcode(c.Param("code"))
	if code == "" {
		utils.Err(c, http.StatusBadRequest, "Штрих-коди нодуруст")
		return
	}

	var title, brand, image, unit, catID string
	var verified bool
	var used int
	err := db.DB.QueryRow(`SELECT title, COALESCE(brand,''), COALESCE(image_url,''),
		COALESCE(unit,'дона'), COALESCE(category_id::text,''),
		COALESCE(is_verified,false), COALESCE(times_used,1)
		FROM barcode_catalog WHERE barcode=$1`, code).
		Scan(&title, &brand, &image, &unit, &catID, &verified, &used)
	if err != nil {
		// Ҳанӯз касе ин кодро нагузоштааст — ин хато нест.
		utils.OK(c, gin.H{"found": false, "barcode": code})
		return
	}

	utils.OK(c, gin.H{
		"found": true, "barcode": code, "title": title, "brand": brand,
		"image_url": image, "unit": unit, "category_id": catID,
		"is_verified": verified, "times_used": used,
	})
}

// Contribute — POST /catalog/barcode  (фурӯшанда)
// Фурӯшанда маълумоти маҳсулотро ба каталоги умумӣ мегузорад.
func (h *CatalogHandler) Contribute(c *gin.Context) {
	uid := utils.UserID(c)
	var in struct {
		Barcode    string `json:"barcode"`
		Title      string `json:"title"`
		Brand      string `json:"brand"`
		ImageURL   string `json:"image_url"`
		Unit       string `json:"unit"`
		CategoryID string `json:"category_id"`
	}
	c.ShouldBindJSON(&in)

	code := normalizeBarcode(in.Barcode)
	title := strings.TrimSpace(in.Title)
	if code == "" || title == "" {
		utils.Err(c, http.StatusBadRequest, "Штрих-код ва ном лозиманд")
		return
	}
	upsertCatalog(code, title, in.Brand, in.ImageURL, in.Unit, in.CategoryID, uid)
	utils.OK(c, gin.H{"saved": true, "barcode": code})
}

// upsertCatalog — сатри каталогро месозад ё бой мекунад.
//
// Қоидаҳо, то як хатои касе ба ҳамаи мағозаҳо нагузарад:
//   - сатри аз ҷониби админ ТАСДИҚШУДА иваз намешавад;
//   - майдони холии нав майдони пурраи кӯҳнаро нест намекунад
//     (`NULLIF`+`COALESCE`);
//   - ҳар истифода `times_used`-ро зиёд мекунад — аз рӯи он баъдтар
//     маълум мешавад, ки кадом сатрҳо воқеан коранд.
func upsertCatalog(code, title, brand, image, unit, catID, userID string) {
	if code == "" || strings.TrimSpace(title) == "" {
		return
	}
	var cat interface{}
	if strings.TrimSpace(catID) != "" {
		cat = strings.TrimSpace(catID)
	}
	db.DB.Exec(`
		INSERT INTO barcode_catalog(barcode,title,brand,image_url,unit,category_id,created_by)
		VALUES($1,$2,$3,$4,$5,$6,$7)
		ON CONFLICT (barcode) DO UPDATE SET
			title       = CASE WHEN barcode_catalog.is_verified THEN barcode_catalog.title
			                   ELSE COALESCE(NULLIF(EXCLUDED.title,''), barcode_catalog.title) END,
			brand       = CASE WHEN barcode_catalog.is_verified THEN barcode_catalog.brand
			                   ELSE COALESCE(NULLIF(EXCLUDED.brand,''), barcode_catalog.brand) END,
			image_url   = CASE WHEN barcode_catalog.is_verified THEN barcode_catalog.image_url
			                   ELSE COALESCE(NULLIF(EXCLUDED.image_url,''), barcode_catalog.image_url) END,
			unit        = COALESCE(NULLIF(EXCLUDED.unit,''), barcode_catalog.unit),
			category_id = COALESCE(EXCLUDED.category_id, barcode_catalog.category_id),
			times_used  = barcode_catalog.times_used + 1,
			updated_at  = NOW()`,
		code, strings.TrimSpace(title), strings.TrimSpace(brand),
		strings.TrimSpace(image), normalizeUnit(unit), cat, nullIfEmpty(userID))
}

func nullIfEmpty(s string) interface{} {
	if strings.TrimSpace(s) == "" {
		return nil
	}
	return s
}

// ── Мӯҳлати нигоҳдорӣ ──────────────────────────────────────────────────────

// ExpiringSoon — GET /seller/products/expiring  (фурӯшанда)
// Маҳсулоте, ки мӯҳлаташон дар 7 рӯзи наздик тамом мешавад.
func (h *CatalogHandler) ExpiringSoon(c *gin.Context) {
	uid := utils.UserID(c)
	rows, err := db.DB.Query(`SELECT p.id, COALESCE(p.title,''), p.price, p.stock,
			p.expires_on,
			COALESCE((SELECT url FROM product_images WHERE product_id=p.id
				ORDER BY position LIMIT 1),'')
		FROM products p
		WHERE p.seller_id=$1 AND p.expires_on IS NOT NULL
		  AND COALESCE(p.is_active,true)=true
		  AND p.expires_on <= CURRENT_DATE + 7
		ORDER BY p.expires_on ASC LIMIT 200`, uid)
	if err != nil || rows == nil {
		utils.OK(c, []gin.H{})
		return
	}
	defer rows.Close()

	out := []gin.H{}
	today := time.Now()
	for rows.Next() {
		var id, title, image string
		var price float64
		var stock int
		var exp time.Time
		if e := rows.Scan(&id, &title, &price, &stock, &exp, &image); e != nil {
			continue
		}
		days := int(exp.Sub(today).Hours() / 24)
		out = append(out, gin.H{
			"id": id, "title": title, "price": price, "stock": stock,
			"image": image, "expires_on": exp.Format("2006-01-02"),
			"days_left": days, "expired": days < 0,
		})
	}
	utils.OK(c, out)
}

// notifyExpiring — ҳар рӯз як бор фурӯшандагонро огоҳ мекунад.
// Барои мағозаи хӯрокворӣ ин пул аст: моли мӯҳлаташ гузашта зарар аст,
// вале моли се рӯз мондаро бо тахфиф фурӯхтан мумкин.
func notifyExpiring() {
	rows, err := db.DB.Query(`SELECT p.seller_id, COUNT(*)
		FROM products p
		WHERE p.expires_on IS NOT NULL AND COALESCE(p.is_active,true)=true
		  AND p.stock > 0
		  AND p.expires_on BETWEEN CURRENT_DATE AND CURRENT_DATE + 3
		GROUP BY p.seller_id`)
	if err != nil || rows == nil {
		return
	}
	type row struct {
		seller string
		n      int
	}
	var list []row
	for rows.Next() {
		var r row
		if e := rows.Scan(&r.seller, &r.n); e == nil && r.seller != "" {
			list = append(list, r)
		}
	}
	rows.Close()

	for _, r := range list {
		// Дар як рӯз як огоҳӣ, на бештар.
		var already bool
		db.DB.QueryRow(`SELECT EXISTS(SELECT 1 FROM notifications
			WHERE user_id=$1 AND type='expiry' AND created_at > NOW() - INTERVAL '20 hours')`,
			r.seller).Scan(&already)
		if already {
			continue
		}
		title := "Мӯҳлат наздик аст ⏳"
		body := "Якчанд маҳсулоти шумо дар 3 рӯз тамом мешавад. " +
			"Тахфиф гузоред, то зарар нашавад."
		db.DB.Exec(`INSERT INTO notifications(id,user_id,type,title,body)
			VALUES($1,$2,'expiry',$3,$4)`, uuid.NewString(), r.seller, title, body)
		pushToUser(r.seller, title, body)
	}
}

// StartExpirySweeper — ҳар 6 соат маҳсулоти мӯҳлаташ наздикро месанҷад.
func StartExpirySweeper() {
	go func() {
		// Сервер нав оғоз шуд — пеш аз аввалин санҷиш каме сабр мекунем.
		time.Sleep(2 * time.Minute)
		for {
			notifyExpiring()
			time.Sleep(6 * time.Hour)
		}
	}()
}
