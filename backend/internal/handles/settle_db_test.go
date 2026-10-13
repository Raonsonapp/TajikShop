package handlers

// Роҳи ПУЛ: озод кардани маблағ ба фурӯшанда(гон).
//
// Ман ин кодро даст расондам: дархости пардохт аз
// `JOIN products ... GROUP BY p.seller_id` ба `oi.seller_id` гузашт, то
// фармоиши RFQ (ки маҳсулоти мушаххас надорад) низ пардохт шавад.
//
// Ин хатарноктарин коди барнома аст — хато дар он ё пули дукарата
// медиҳад, ё пулро гум мекунад. Пас тест ҲАТМИСТ, ва он пештар набуд.

import (
	"fmt"
	"testing"

	"tajikshop/internal/db"

	"github.com/google/uuid"
)

func walletOf(t *testing.T, uid string) float64 {
	t.Helper()
	var v float64
	if err := db.DB.QueryRow(`SELECT COALESCE(wallet_balance,0) FROM users
		WHERE id=$1`, uid).Scan(&v); err != nil {
		t.Fatalf("ҳамён хонда нашуд: %v", err)
	}
	return v
}

// walletOrder — фармоиши пардохтшуда бо ҳамён, дар ҳолати 'delivered'.
func walletOrder(t *testing.T, buyerID string,
	lines []struct {
		SellerID string
		Qty      int
		Price    float64
	}) (string, float64) {
	t.Helper()
	oid := uuid.NewString()
	var total float64
	for _, l := range lines {
		total += l.Price * float64(l.Qty)
	}
	if _, err := db.DB.Exec(`INSERT INTO orders
		(id,user_id,total,status,payment_method)
		VALUES($1,$2,$3,'delivered','wallet')`, oid, buyerID, total); err != nil {
		t.Fatalf("фармоиш сохта нашуд: %v", err)
	}
	for _, l := range lines {
		if _, err := db.DB.Exec(`INSERT INTO order_items
			(id,order_id,product_id,seller_id,title,quantity,price)
			VALUES($1,$2,NULL,$3,'Моли тестӣ',$4,$5)`,
			uuid.NewString(), oid, l.SellerID, l.Qty, l.Price); err != nil {
			t.Fatalf("моли фармоиш сохта нашуд: %v", err)
		}
		db.DB.Exec(`INSERT INTO order_sellers(id,order_id,seller_id,status,subtotal)
			VALUES($1,$2,$3,'delivered',$4)
			ON CONFLICT (order_id,seller_id) DO NOTHING`,
			uuid.NewString(), oid, l.SellerID, l.Price*float64(l.Qty))
	}
	t.Cleanup(func() {
		db.DB.Exec(`DELETE FROM wallet_transactions WHERE note LIKE $1`,
			"%"+shortID(oid)+"%")
		db.DB.Exec(`DELETE FROM order_sellers WHERE order_id=$1`, oid)
		db.DB.Exec(`DELETE FROM order_items WHERE order_id=$1`, oid)
		db.DB.Exec(`DELETE FROM order_events WHERE order_id=$1`, oid)
		db.DB.Exec(`DELETE FROM orders WHERE id=$1`, oid)
	})
	return oid, total
}

type payLine = struct {
	SellerID string
	Qty      int
	Price    float64
}

// Фармоиши як фурӯшанда: тамоми маблағ ба ӯ меравад.
func TestSettlePaysSingleSeller(t *testing.T) {
	needDB(t)
	buyerID, _ := newTestUser(t)
	sellerID, _ := newTestUser(t)

	oid, total := walletOrder(t, buyerID, []payLine{
		{SellerID: sellerID, Qty: 10, Price: 25}, // 250 сом.
	})
	before := walletOf(t, sellerID)

	settleOrder(oid, buyerID, total, "wallet", true)

	after := walletOf(t, sellerID)
	if fmt.Sprintf("%.2f", after-before) != "250.00" {
		t.Fatalf("фурӯшанда %.2f гирифт, мехостам 250.00", after-before)
	}
	var status string
	db.DB.QueryRow(`SELECT status FROM orders WHERE id=$1`, oid).Scan(&status)
	if status != "completed" {
		t.Fatalf("ҳолати фармоиш = %q, мехостам completed", status)
	}
}

// Фармоиши ду фурӯшанда: ҳар кас ҳиссаи ХУДашро мегирад, ва ҷамъи
// ҳиссаҳо аз ҷамъи фармоиш зиёд нашавад.
func TestSettleSplitsBetweenSellers(t *testing.T) {
	needDB(t)
	buyerID, _ := newTestUser(t)
	s1, _ := newTestUser(t)
	s2, _ := newTestUser(t)

	// 200 + 300 = 500 сом.
	oid, total := walletOrder(t, buyerID, []payLine{
		{SellerID: s1, Qty: 2, Price: 100},
		{SellerID: s2, Qty: 3, Price: 100},
	})
	b1, b2 := walletOf(t, s1), walletOf(t, s2)

	settleOrder(oid, buyerID, total, "wallet", true)

	g1 := walletOf(t, s1) - b1
	g2 := walletOf(t, s2) - b2
	if fmt.Sprintf("%.2f", g1) != "200.00" {
		t.Errorf("фурӯшандаи 1 %.2f гирифт, мехостам 200.00", g1)
	}
	if fmt.Sprintf("%.2f", g2) != "300.00" {
		t.Errorf("фурӯшандаи 2 %.2f гирифт, мехостам 300.00", g2)
	}
	// Платформа набояд аз ҷамъ бештар диҳад.
	if g1+g2 > total+0.01 {
		t.Fatalf("ҷамъи дода %.2f > ҷамъи фармоиш %.2f", g1+g2, total)
	}
}

// Пардохти ДУКАРАТА — камбудии аз ҳама гарон.
//
// `settleOrder` аз ду ҷо даъват мешавад: «Тасдиқи харидор» ва озодкунии
// худкор. Агар ҳарду якҷоя кор кунанд, фурӯшанда ду бор пул мегирад.
func TestSettleNeverPaysTwice(t *testing.T) {
	needDB(t)
	buyerID, _ := newTestUser(t)
	sellerID, _ := newTestUser(t)

	oid, total := walletOrder(t, buyerID, []payLine{
		{SellerID: sellerID, Qty: 1, Price: 500},
	})
	before := walletOf(t, sellerID)

	// Се бор — гӯё харидор тасдиқ кард ва sweeper ҳам кор кард.
	settleOrder(oid, buyerID, total, "wallet", true)
	settleOrder(oid, buyerID, total, "wallet", false)
	settleOrder(oid, buyerID, total, "wallet", true)

	got := walletOf(t, sellerID) - before
	if fmt.Sprintf("%.2f", got) != "500.00" {
		t.Fatalf("фурӯшанда %.2f гирифт, мехостам 500.00 — "+
			"пардохт бояд ЯК бор шавад", got)
	}
}

// Фармоиши бекоршуда пардохт намешавад.
func TestSettleSkipsCancelled(t *testing.T) {
	needDB(t)
	buyerID, _ := newTestUser(t)
	sellerID, _ := newTestUser(t)

	oid, total := walletOrder(t, buyerID, []payLine{
		{SellerID: sellerID, Qty: 1, Price: 100},
	})
	db.DB.Exec(`UPDATE orders SET status='cancelled' WHERE id=$1`, oid)
	before := walletOf(t, sellerID)

	settleOrder(oid, buyerID, total, "wallet", true)

	if got := walletOf(t, sellerID) - before; got != 0 {
		t.Fatalf("фурӯшанда %.2f гирифт, мехостам 0 — фармоиши бекоршуда", got)
	}
}

// Фармоиши RFQ (бе `product_id`) низ пардохт мешавад.
//
// Маҳз барои ҳамин ман дархости пардохтро иваз кардам. Бо
// `JOIN products` сатри бе маҳсулот гум мешуд, ва фурӯшанда ҳеҷ чиз
// намегирифт — пул дар ҳеҷ ҷо мемонд.
func TestSettlePaysRFQOrderWithoutProduct(t *testing.T) {
	needDB(t)
	buyerID, _ := newTestUser(t)
	sellerID, _ := newTestUser(t)

	// `walletOrder` ҳамеша `product_id=NULL` мегузорад — маҳз ҳолати RFQ.
	oid, total := walletOrder(t, buyerID, []payLine{
		{SellerID: sellerID, Qty: 500, Price: 4.60}, // 2300 сом.
	})
	before := walletOf(t, sellerID)

	settleOrder(oid, buyerID, total, "wallet", true)

	got := walletOf(t, sellerID) - before
	if fmt.Sprintf("%.2f", got) != "2300.00" {
		t.Fatalf("фурӯшанда %.2f гирифт, мехостам 2300.00 — "+
			"фармоиши RFQ маҳсулот надорад ва пештар пардохт намешуд", got)
	}
}

// Пардохти ғайри-ҳамён: пул дар ҳамён нест, пас озод кардан чизе
// намедиҳад — вале фармоиш бояд «completed» шавад.
func TestSettleNonWalletJustCompletes(t *testing.T) {
	needDB(t)
	buyerID, _ := newTestUser(t)
	sellerID, _ := newTestUser(t)

	oid, total := walletOrder(t, buyerID, []payLine{
		{SellerID: sellerID, Qty: 1, Price: 100},
	})
	db.DB.Exec(`UPDATE orders SET payment_method='cod' WHERE id=$1`, oid)
	before := walletOf(t, sellerID)

	settleOrder(oid, buyerID, total, "cod", true)

	if got := walletOf(t, sellerID) - before; got != 0 {
		t.Errorf("фурӯшанда %.2f гирифт — барои COD пул дар ҳамён нест", got)
	}
	var status string
	db.DB.QueryRow(`SELECT status FROM orders WHERE id=$1`, oid).Scan(&status)
	if status != "completed" {
		t.Fatalf("ҳолат = %q, мехостам completed", status)
	}
}
