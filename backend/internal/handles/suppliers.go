package handlers

import (
	"database/sql"
	"strconv"
	"strings"
	"tajikshop/internal/db"
	"tajikshop/internal/utils"

	"github.com/gin-gonic/gin"
)

// ═══════════════════════════════════════════════════════════════════════════
//  Ҷустуҷӯи таъминкунанда
// ═══════════════════════════════════════════════════════════════════════════
//
// Харидори яклухт аввал МОЛ-ро намеҷӯяд — ӯ ТАЪМИНКУНАНДА меҷӯяд: кӣ
// боэътимод аст, кӣ дар вақташ мефиристад, кӣ дар минтақаи ман кор
// мекунад. Баъд аз ӯ мефармояд, ва баъд ҳамеша аз ӯ мефармояд.
//
// `GET /shops` буд, вале он танҳо дӯконҳои дар ХАРИТА (бо координата)
// барои «дӯконҳои наздик» медод. Барои савдои яклухт ин кифоя нест:
// таъминкунанда метавонад анбор дошта бошад, на дӯкони дар кӯча.
//
// ҚОИДАИ АСОСӢ: рақами бофташуда нест.
//
// Ҳар рақами ин ҷо аз сатрҳои ВОҚЕИИ база ҳисоб мешавад. «Холи эътимод»
// ё «дараҷа»-и аз ҳаво гирифташуда нест — чунин рақам харидорро фиреб
// медиҳад ва баъд ба ӯ зарари пулӣ мерасонад.
//
// Ва он чизе, ки фурӯшанда ХУДАШ навиштааст (номи дӯкон, тавзеҳ,
// минтақа), аз он чизе, ки ТАСДИҚ шудааст (галочкаи админ, шумораи
// фармоиши анҷомёфта), ҷудо карда мешавад — `self_reported` ва
// `verified`. Харидор бояд фарқро бинад.

// Suppliers — GET /suppliers
//
// Филтрҳо:
//   - `verified=1` — танҳо фурӯшандаи тасдиқшудаи админ
//   - `region=...` — минтақа (он чизе, ки фурӯшанда худаш навиштааст)
//   - `q=...` — ҷустуҷӯ аз рӯи ном
//   - `min_products=N` — камтар аз N мол надошта бошад
//   - `sort=orders|rating|products|new`
func (h *UserHandler) Suppliers(c *gin.Context) {
	onlyVerified := c.Query("verified") == "1" || c.Query("verified") == "true"
	region := strings.TrimSpace(c.Query("region"))
	q := strings.TrimSpace(c.Query("q"))
	minProducts := 0
	if n, err := strconv.Atoi(c.Query("min_products")); err == nil && n > 0 {
		minProducts = n
	}
	limit := 50
	if n, err := strconv.Atoi(c.Query("limit")); err == nil && n > 0 && n <= 200 {
		limit = n
	}

	// Тартиб аз рӯйхати САХТ интихоб мешавад, на аз сатри корбар —
	// вагарна ин роҳи SQL injection мешуд.
	orderBy := "orders_done DESC, products DESC"
	switch c.Query("sort") {
	case "rating":
		orderBy = "rating DESC NULLS LAST, orders_done DESC"
	case "products":
		orderBy = "products DESC"
	case "new":
		orderBy = "u.created_at DESC"
	}

	// Ҳамаи рақамҳо аз сатрҳои воқеӣ.
	//
	// `orders_done` — фармоиши АНҶОМЁФТА, на ҳамаи фармоишҳо. Фармоиши
	// бекоршуда ё дар роҳ эътимод нишон намедиҳад.
	rows, err := db.DB.Query(`
		SELECT u.id,
			COALESCE(NULLIF(u.shop_name,''), u.name, '') AS shop,
			COALESCE(u.avatar_url,''),
			COALESCE(u.shop_desc,''),
			COALESCE(u.business_type,'shop'),
			COALESCE(u.is_verified,false),
			COALESCE(u.region,''),
			u.created_at,
			(SELECT COUNT(*) FROM products p
				WHERE p.seller_id=u.id AND COALESCE(p.is_active,true)=true
				  AND p.stock > 0) AS products,
			(SELECT COUNT(DISTINCT os.order_id) FROM order_sellers os
				WHERE os.seller_id=u.id AND os.status IN ('delivered','completed'))
				AS orders_done,
			(SELECT COUNT(DISTINCT os.order_id) FROM order_sellers os
				WHERE os.seller_id=u.id AND os.status='cancelled')
				AS orders_cancelled,
			(SELECT ROUND(AVG(sr.score)::numeric, 2) FROM seller_ratings sr
				WHERE sr.seller_id=u.id) AS rating,
			(SELECT COUNT(*) FROM seller_ratings sr WHERE sr.seller_id=u.id)
				AS rating_count,
			(SELECT COUNT(*) FROM product_price_tiers t
				JOIN products p2 ON p2.id=t.product_id
				WHERE p2.seller_id=u.id) AS wholesale_items
		FROM users u
		WHERE COALESCE(u.is_seller,false)=true
		  AND COALESCE(u.is_banned,false)=false
		  AND COALESCE(u.is_deleted,false)=false
		  AND ($1::bool = false OR COALESCE(u.is_verified,false)=true)
		  AND ($2 = '' OR COALESCE(u.region,'') ILIKE '%' || $2 || '%')
		  AND ($3 = '' OR COALESCE(NULLIF(u.shop_name,''), u.name, '') ILIKE '%' || $3 || '%')
		ORDER BY `+orderBy+`
		LIMIT $4`, onlyVerified, region, q, limit)
	if err != nil || rows == nil {
		utils.OK(c, []gin.H{})
		return
	}
	defer rows.Close()

	out := []gin.H{}
	for rows.Next() {
		var id, shop, avatar, desc, btype, reg string
		var verified bool
		var createdAt sql.NullTime
		var products, ordersDone, ordersCancelled, ratingCount, wholesale int
		var rating sql.NullFloat64
		if e := rows.Scan(&id, &shop, &avatar, &desc, &btype, &verified, &reg,
			&createdAt, &products, &ordersDone, &ordersCancelled,
			&rating, &ratingCount, &wholesale); e != nil {
			continue
		}
		if products < minProducts {
			continue
		}

		row := gin.H{
			"id":         id,
			"name":       shop,
			"avatar_url": avatar,
			"products":   products,

			// ТАСДИҚШУДА — аз сатрҳои воқеӣ ё қарори админ.
			"verified": gin.H{
				// Галочка — қарори админ, на даъвои фурӯшанда.
				"badge":            verified,
				"orders_completed": ordersDone,
				"orders_cancelled": ordersCancelled,
				"rating":           nil,
				"rating_count":     ratingCount,
				"wholesale_items":  wholesale,
			},

			// ХУДИ ФУРӮШАНДА НАВИШТААСТ — тасдиқ нашудааст.
			//
			// Ҷудо нигоҳ дошта мешавад, то харидор фарқро бинад. Ин
			// ҳамон ҷойест, ки платформаҳо одатан фиреб мекунанд:
			// «минтақаи фаъолият» ҳамчун маълумоти тасдиқшуда нишон
			// дода мешавад, ҳол он ки онро худи фурӯшанда навиштааст.
			"self_reported": gin.H{
				"description":   desc,
				"business_type": btype,
				"region":        reg,
			},
		}
		if rating.Valid && ratingCount > 0 {
			row["verified"].(gin.H)["rating"] = rating.Float64
		}
		// Фоизи анҷом — танҳо агар фармоиш кофӣ бошад.
		//
		// Дар 2 фармоиш «100% анҷом» маъно надорад ва харидорро фиреб
		// медиҳад. Беҳтар аст, ки рақам УМУМАН набошад.
		if total := ordersDone + ordersCancelled; total >= 5 {
			row["verified"].(gin.H)["completion_rate"] =
				ordersDone * 100 / total
		}
		if createdAt.Valid {
			row["verified"].(gin.H)["seller_since"] =
				createdAt.Time.Format("2006-01")
		}
		out = append(out, row)
	}
	utils.OK(c, out)
}

// SupplierProfile — GET /suppliers/:id
//
// Ҳамон маълумот барои як таъминкунанда, бо рӯйхати молҳои яклухт.
func (h *UserHandler) SupplierProfile(c *gin.Context) {
	id := c.Param("id")

	var shop, avatar, desc, btype, reg, phone string
	var verified bool
	var createdAt sql.NullTime
	err := db.DB.QueryRow(`SELECT
			COALESCE(NULLIF(u.shop_name,''), u.name, ''),
			COALESCE(u.avatar_url,''), COALESCE(u.shop_desc,''),
			COALESCE(u.business_type,'shop'), COALESCE(u.region,''),
			COALESCE(u.shop_phone,''), COALESCE(u.is_verified,false),
			u.created_at
		FROM users u
		WHERE u.id=$1 AND COALESCE(u.is_seller,false)=true
		  AND COALESCE(u.is_banned,false)=false
		  AND COALESCE(u.is_deleted,false)=false`, id).
		Scan(&shop, &avatar, &desc, &btype, &reg, &phone, &verified, &createdAt)
	if err != nil {
		utils.Err(c, 404, "Таъминкунанда ёфт нашуд")
		return
	}

	var products, ordersDone, ordersCancelled, ratingCount int
	var rating sql.NullFloat64
	db.DB.QueryRow(`SELECT
			(SELECT COUNT(*) FROM products p WHERE p.seller_id=$1
				AND COALESCE(p.is_active,true)=true AND p.stock>0),
			(SELECT COUNT(DISTINCT os.order_id) FROM order_sellers os
				WHERE os.seller_id=$1 AND os.status IN ('delivered','completed')),
			(SELECT COUNT(DISTINCT os.order_id) FROM order_sellers os
				WHERE os.seller_id=$1 AND os.status='cancelled'),
			(SELECT COUNT(*) FROM seller_ratings sr WHERE sr.seller_id=$1),
			(SELECT ROUND(AVG(sr.score)::numeric,2) FROM seller_ratings sr
				WHERE sr.seller_id=$1)`, id).
		Scan(&products, &ordersDone, &ordersCancelled, &ratingCount, &rating)

	ver := gin.H{
		"badge":            verified,
		"orders_completed": ordersDone,
		"orders_cancelled": ordersCancelled,
		"rating_count":     ratingCount,
	}
	if rating.Valid && ratingCount > 0 {
		ver["rating"] = rating.Float64
	}
	if total := ordersDone + ordersCancelled; total >= 5 {
		ver["completion_rate"] = ordersDone * 100 / total
	}
	if createdAt.Valid {
		ver["seller_since"] = createdAt.Time.Format("2006-01")
	}

	utils.OK(c, gin.H{
		"id": id, "name": shop, "avatar_url": avatar,
		"products": products,
		"verified": ver,
		"self_reported": gin.H{
			"description":   desc,
			"business_type": btype,
			"region":        reg,
			"phone":         phone,
		},
		"wholesale": supplierWholesaleItems(id),
	})
}

// supplierWholesaleItems — молҳои ин фурӯшанда, ки зинаи яклухт доранд.
//
// Маҳз инҳо барои харидори яклухт муҳиманд: молҳои бе зина нархи чакана
// доранд ва ба ӯ намеарзанд.
func supplierWholesaleItems(sellerID string) []gin.H {
	rows, err := db.DB.Query(`SELECT p.id, COALESCE(p.title,''), p.price,
			COALESCE(p.min_order_qty,1), COALESCE(p.unit,'дона'),
			(SELECT MIN(t.price) FROM product_price_tiers t WHERE t.product_id=p.id),
			(SELECT MIN(t.min_qty) FROM product_price_tiers t WHERE t.product_id=p.id),
			COALESCE((SELECT url FROM product_images WHERE product_id=p.id
				ORDER BY position LIMIT 1),'')
		FROM products p
		WHERE p.seller_id=$1 AND COALESCE(p.is_active,true)=true AND p.stock>0
		  AND EXISTS(SELECT 1 FROM product_price_tiers t WHERE t.product_id=p.id)
		ORDER BY p.created_at DESC LIMIT 50`, sellerID)
	out := []gin.H{}
	if err != nil || rows == nil {
		return out
	}
	defer rows.Close()
	for rows.Next() {
		var id, title, unit, image string
		var price float64
		var minQty int
		var bestPrice sql.NullFloat64
		var fromQty sql.NullInt64
		if e := rows.Scan(&id, &title, &price, &minQty, &unit,
			&bestPrice, &fromQty, &image); e != nil {
			continue
		}
		row := gin.H{
			"id": id, "title": title, "price": price,
			"min_order_qty": minQty, "unit": unit, "image": image,
		}
		if bestPrice.Valid {
			row["wholesale_from"] = bestPrice.Float64
		}
		if fromQty.Valid {
			row["wholesale_min_qty"] = fromQty.Int64
		}
		out = append(out, row)
	}
	return out
}
