package handlers

import "strings"

// ═══════════════════════════════════════════════════════════════════════════
//  Пул ва ҳисоби фармоиш — мантиқи тоза, бе базаи додаҳо
// ═══════════════════════════════════════════════════════════════════════════
//
// Ҳамаи ҳисоб бо ДИРАМИ БУТУН (int64) аст, на бо `float64`.
//
// Чаро: `float64` рақами даҳиро дақиқ нигоҳ намедорад. 0.1+0.2 дар он
// 0.30000000000000004 мешавад. Дар савдо ин маънои онро дорад, ки ҷамъи
// сабад ва ҷамъи фармоиш метавонанд бо як дирам фарқ кунанд — ва он гоҳ
// харидор дар экран як рақам мебинад, вале аз ҳамёнаш рақами дигар
// меравад. Чунин фарқият баъд дар ҳисобот ҷамъ мешавад ва пайдо кардани
// сабабаш хеле душвор аст.
//
// Пас: аз базаи додаҳо `NUMERIC(12,2)` мехонем → фавран ба дирам табдил
// медиҳем → ҳамаи ҷамъ, тахфиф ва тақсим дар бутун → танҳо дар охир
// барои базаи додаҳо ва ҷавоби JSON ба сомонӣ бармегардонем.

const diramsPerSomoni = 100

// Пули расонидан — ҳамон 20 сомонӣ, ки `kDeliveryFee` дар
// `lib/modules/cart/cart_screen.dart` нишон медиҳад.
//
// Ин рақам бояд дар СЕРВЕР ҳисоб шавад. Пеш аз ин сервер `delivery_fee`-ро
// аз муштарӣ мегирифт ва танҳо бо 200 маҳдуд мекард — яъне ҳар касе
// метавонист `{"delivery_fee": 0}` фиристад ва расониданро ройгон кунад.
const deliveryFeeDirams int64 = 20 * diramsPerSomoni

// toDirams — сомонии `float64` (аз `NUMERIC`) ба дирами бутун.
//
// `+0.5` лозим аст: 19.99 дар `float64` каме камтар аз 19.99 аст, ва
// `int64(19.99*100)` 1998 медиҳад, на 1999 — яъне як дирам гум мешавад.
func toDirams(somoni float64) int64 {
	if somoni < 0 {
		return -int64(-somoni*diramsPerSomoni + 0.5)
	}
	return int64(somoni*diramsPerSomoni + 0.5)
}

// toSomoni — барои базаи додаҳо ва ҷавоби JSON.
func toSomoni(dirams int64) float64 {
	return float64(dirams) / diramsPerSomoni
}

// ── Сатри сабад ҳангоми ҳисоб ────────────────────────────────────────────

type checkoutLine struct {
	ProductID string
	SellerID  string
	Title     string
	Qty       int
	UnitPrice int64 // дирам
	Stock     int
	MinQty    int
	Active    bool
}

// Сабабҳои он, ки сатр ба фармоиш намегузарад.
const (
	issueInactive     = "inactive"      // маҳсулот нест ё хомӯш шуд
	issueOutOfStock   = "out_of_stock"  // тамоман тамом шуд
	issueNotEnough    = "not_enough"    // аз анбор камтар аст
	issueBelowMinQty  = "below_min_qty" // аз ҳадди ақали фурӯшанда камтар
	issueInvalidQty   = "invalid_qty"   // ≤0 ё аз ҳад зиёд
	issueInvalidPrice = "invalid_price" // нархи 0 ё манфӣ
)

// maxLineQty — ҳадди болоии шумора дар як сатр.
//
// Бе ин муштарӣ метавонад `{"quantity": 2000000000}` фиристад ва
// ҳисоби ҷамъ аз ҳудуди `int64` берун равад.
const maxLineQty = 10000

type lineIssue struct {
	ProductID string `json:"product_id"`
	Title     string `json:"title"`
	Code      string `json:"code"`
	Available int    `json:"available"`
	MinQty    int    `json:"min_qty"`
}

// validateLines — пеш аз сохтани фармоиш ҳар сатрро месанҷад.
//
// Пештар санҷиш ТАМОМАН набуд: `UPDATE products SET stock=GREATEST(stock-$1,0)`
// ҳар шуморро қабул мекард. Дар анбор 3 дона буд, харидор 100 дона мефармуд
// — фармоиш қабул мешуд, анбор 0 мешуд, ва фурӯшанда 100 донаи надоштаашро
// бояд мефиристод.
func validateLines(lines []checkoutLine) []lineIssue {
	issues := []lineIssue{}
	for _, l := range lines {
		code := ""
		switch {
		case !l.Active:
			code = issueInactive
		case l.Qty <= 0 || l.Qty > maxLineQty:
			code = issueInvalidQty
		case l.UnitPrice <= 0:
			code = issueInvalidPrice
		case l.Stock <= 0:
			code = issueOutOfStock
		case l.Qty > l.Stock:
			code = issueNotEnough
		case l.MinQty > 1 && l.Qty < l.MinQty:
			code = issueBelowMinQty
		}
		if code != "" {
			issues = append(issues, lineIssue{
				ProductID: l.ProductID, Title: l.Title, Code: code,
				Available: l.Stock, MinQty: l.MinQty,
			})
		}
	}
	return issues
}

// ── Ҷамъи фармоиш ────────────────────────────────────────────────────────

type checkoutTotals struct {
	Items    int64 // ҷамъи маҳсулот
	Delivery int64 // расонидан
	Discount int64 // тахфифи купон
	Final    int64 // он чизе, ки харидор воқеан мепардозад
}

// computeTotals — ҳамон тартиби ҳисоб, ки экрани сабад нишон медиҳад:
// (маҳсулот + расонидан), баъд тахфиф аз ҷамъ.
//
// Тахфиф бо бутун ҳисоб мешавад, бо мудаввар кардани «ними боло»:
// `(gross*pct + 50) / 100`. Бе `+50` ҳар тахфиф ба фоидаи платформа
// мудаввар мешуд — чизи хурд, вале дар ҳисобот ҷамъ мешавад.
func computeTotals(lines []checkoutLine, delivery int64, discountPct int) checkoutTotals {
	var items int64
	for _, l := range lines {
		if l.Qty <= 0 || l.Qty > maxLineQty || l.UnitPrice <= 0 {
			continue
		}
		items += l.UnitPrice * int64(l.Qty)
	}
	if delivery < 0 {
		delivery = 0
	}
	if discountPct < 0 {
		discountPct = 0
	}
	if discountPct > 100 {
		discountPct = 100
	}
	gross := items + delivery
	discount := (gross*int64(discountPct) + 50) / 100
	if discount > gross {
		discount = gross
	}
	final := gross - discount
	if final < 0 {
		final = 0
	}
	return checkoutTotals{Items: items, Delivery: delivery, Discount: discount, Final: final}
}

// sellerSubtotals — ҷамъи ҳар фурӯшанда дар фармоиши бисёрфурӯшанда.
//
// Пули расонидан ва тахфиф ба ин дохил намешавад: онҳо ба тамоми фармоиш
// тааллуқ доранд, на ба як фурӯшанда.
func sellerSubtotals(lines []checkoutLine) map[string]int64 {
	out := map[string]int64{}
	for _, l := range lines {
		if l.SellerID == "" || l.Qty <= 0 || l.Qty > maxLineQty || l.UnitPrice <= 0 {
			continue
		}
		out[l.SellerID] += l.UnitPrice * int64(l.Qty)
	}
	return out
}

// deliveryFeeFor — пули расонидан аз рӯи тарзи гирифтан.
// «Аз мағоза мегирам» → ройгон.
func deliveryFeeFor(fulfilment string) int64 {
	if normalizeFulfilment(fulfilment) == "pickup" {
		return 0
	}
	return deliveryFeeDirams
}

func normalizeFulfilment(f string) string {
	if strings.TrimSpace(strings.ToLower(f)) == "pickup" {
		return "pickup"
	}
	return "delivery"
}

func normalizePaymentMethod(m string) string {
	switch strings.TrimSpace(strings.ToLower(m)) {
	case "cod":
		return "cod"
	case "wallet":
		return "wallet"
	}
	return "dc"
}
