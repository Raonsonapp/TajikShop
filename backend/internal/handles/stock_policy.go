package handlers

import (
	"strings"
	"tajikshop/internal/db"
	"time"

	"github.com/google/uuid"
)

// ═══════════════════════════════════════════════════════════════════════════
//  Сиёсати захира: шумораи ихтиёрӣ ва моли тамомшуда
// ═══════════════════════════════════════════════════════════════════════════
//
// Ду масъалаи воқеӣ, ки фурӯшандагон доранд.
//
// 1. НА ҲАР ФУРӮШАНДА АНБОР ДОРАД.
//
// Дӯзанда, нонвой, устои мебел бо ФАРМОИШ месозанд. Барои онҳо «3 дона
// мондааст» маъно надорад — онҳо ҳар қадар лозим бошад месозанд. Вале
// барнома шуморо ҳатмӣ мекард, ва онҳо маҷбур мешуданд рақами бофта
// гузоранд (масалан 999), ки баъд ҳам нодуруст аст.
//
// 2. МОЛИ ТАМОМШУДА АБАДӢ МЕМОНД.
//
// Ҳамин ки захира ба сифр мерасад, фурӯшанда огоҳӣ мегирад: «боз ҳаст?».
// Вале агар ӯ ҷавоб надиҳад — ва аксаран ҷавоб намедиҳад — мол дар бозор
// ҳамчун «Тамом шуд» мемонад. Харидор онро мебинад, зер мекунад, ва
// харида наметавонад.
//
// Акнун мол баъди мӯҳлат ХУДКОР аз бозор пинҳон мешавад.

// Чанд рӯз интизори ҷавоби фурӯшанда.
//
// Чаро 3: камтар — фурӯшанда ҳатто фурсати дидани огоҳиро надорад;
// бештар — моли нобуда ҳафтаҳо дар бозор мемонад ва харидорро хафа
// мекунад.
const soldOutGraceDays = 3

// hideSoldOutSQL — чаро маҳз ПИНҲОН, на ҳазфи сахт.
//
// Ҳазфи сахт таърихи фармоишро вайрон мекунад: харидор дар фармоиши
// кӯҳнаи худ моли «нестшуда» мебинад. Ва фурӯшанда наметавонад онро
// баргардонад, агар мол боз пайдо шавад.
//
// Пинҳон кардан ҳарду масъаларо ҳал мекунад: аз бозор меравад, вале
// бозгашт як зеркунист.
const hideSoldOutSQL = `UPDATE products
	SET is_active = false, updated_at = NOW()
	WHERE COALESCE(track_stock, true) = true
	  AND stock <= 0
	  AND COALESCE(is_active, true) = true
	  AND sold_out_asked_at IS NOT NULL
	  AND sold_out_asked_at < NOW() - ($1 || ' days')::interval
	RETURNING id, seller_id, COALESCE(title,'')`

// ── Мантиқи тоза (бе база) ───────────────────────────────────────────────

// stockInput — он чизе, ки фурӯшанда ҳангоми гузоштани эълон медиҳад.
type stockInput struct {
	TrackStock bool
	Stock      int
}

// maxStock — ҳадди болоии захира.
//
// Бе он касе метавонад `{"stock": 2000000000}` фиристад, ва ҳисобҳои
// баъдӣ аз ҳудуди бехатар мебароянд.
const maxStock = 1_000_000

// normalizeStock — шумораро ба ҳолати дуруст меорад.
//
// Вақте фурӯшанда шуморо намегирад (`track_stock=false`), захира маъно
// надорад — вале сутун `NOT NULL` аст ва бояд арзише дошта бошад. Мо 0
// намегузорем: ҳамаи дархостҳои мавҷуд `stock > 0`-ро ҳамчун «дастрас»
// мефаҳманд, ва 0 молро аз бозор пинҳон мекард.
func normalizeStock(in stockInput) stockInput {
	if !in.TrackStock {
		// Рақами рамзӣ: мол ҳамеша дастрас аст. Ба харидор НИШОН ДОДА
		// НАМЕШАВАД — экран ҳангоми `track_stock=false` шуморо пинҳон
		// мекунад.
		return stockInput{TrackStock: false, Stock: maxStock}
	}
	s := in.Stock
	if s < 0 {
		s = 0
	}
	if s > maxStock {
		s = maxStock
	}
	return stockInput{TrackStock: true, Stock: s}
}

// stockAvailable — оё мол харида мешавад?
func stockAvailable(trackStock bool, stock, want int) bool {
	if want <= 0 {
		return false
	}
	if !trackStock {
		return true // шумора пайгирӣ намешавад
	}
	return stock >= want
}

// shouldAskSoldOut — оё баъди фурӯш аз фурӯшанда «боз ҳаст?» пурсем?
//
// Танҳо барои моле, ки захираашро ПАЙГИРӢ мекунад. Моли бешумор ҳеҷ гоҳ
// тамом намешавад, пас чунин савол маъно надорад ва фурӯшандаро безор
// мекунад.
func shouldAskSoldOut(trackStock bool, stockAfter int) bool {
	return trackStock && stockAfter <= 0
}

// ── Матни огоҳӣ ──────────────────────────────────────────────────────────

func soldOutAskBody(title string) string {
	return "«" + trimTitle(title) + "» тамом шуд. Оё боз ҳаст?"
}

// soldOutHiddenBody — огоҳии ДУЮМ, вақте мол худкор пинҳон шуд.
//
// Ин ҳатмист: вагарна фурӯшанда як рӯз мебинад, ки эълонаш нопадид шуд,
// ва намефаҳмад чаро. Матн сабабро мегӯяд ва роҳи бозгаштро нишон
// медиҳад.
func soldOutHiddenBody(title string) string {
	return "«" + trimTitle(title) + "» аз бозор пинҳон шуд, чунки тамом " +
		"шуда буд ва ҷавоб наомад. Агар боз ҳаст — онро баргардонед."
}

// trimTitle — номи дароз огоҳиро нохоно мекунад.
func trimTitle(s string) string {
	s = strings.TrimSpace(s)
	r := []rune(s)
	if len(r) <= 40 {
		return s
	}
	return string(r[:40]) + "…"
}

// ── Sweeper ──────────────────────────────────────────────────────────────

// StartSoldOutSweeper — моли тамомшударо, ки ҷавоб наомад, пинҳон
// мекунад.
//
// Ҳар 6 соат. Зудтар лозим нест: мӯҳлат 3 рӯз аст, ва чанд соат фарқ
// намекунад.
func StartSoldOutSweeper() {
	go func() {
		// Сервер нав оғоз шуд — пеш аз аввалин санҷиш каме сабр.
		time.Sleep(4 * time.Minute)
		for {
			hideUnansweredSoldOut()
			time.Sleep(6 * time.Hour)
		}
	}()
}

// hideUnansweredSoldOut — худи кор.
//
// Ҷудо аз `StartSoldOutSweeper`, то тест онро бе интизори соатҳо даъват
// карда тавонад.
func hideUnansweredSoldOut() int {
	rows, err := db.DB.Query(hideSoldOutSQL, soldOutGraceDays)
	if err != nil || rows == nil {
		return 0
	}
	type hidden struct{ id, seller, title string }
	var list []hidden
	for rows.Next() {
		var h hidden
		if e := rows.Scan(&h.id, &h.seller, &h.title); e != nil {
			continue
		}
		list = append(list, h)
	}
	rows.Close()

	for _, h := range list {
		if h.seller == "" {
			continue
		}
		body := soldOutHiddenBody(h.title)
		db.DB.Exec(`INSERT INTO notifications(id,user_id,type,title,body,ref_id)
			VALUES($1,$2,'stock','Эълон пинҳон шуд',$3,$4)`,
			uuid.NewString(), h.seller, body, h.id)
		pushToUser(h.seller, "Эълон пинҳон шуд", body)
	}
	return len(list)
}
