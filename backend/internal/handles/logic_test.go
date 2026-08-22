package handlers

import "testing"

func TestLoyaltyTier(t *testing.T) {
	cases := []struct {
		spent      float64
		wantTier   string
		wantBonus  int
		wantNextAt float64
	}{
		{0, "bronze", 0, silverThreshold},
		{499, "bronze", 0, silverThreshold},
		{500, "silver", 1, goldThreshold},
		{1999, "silver", 1, goldThreshold},
		{2000, "gold", 2, 0},
		{999999, "gold", 2, 0},
	}
	for _, c := range cases {
		tier, bonus, next := loyaltyTier(c.spent)
		if tier != c.wantTier || bonus != c.wantBonus || next != c.wantNextAt {
			t.Errorf("loyaltyTier(%.0f)=(%s,%d,%.0f), want (%s,%d,%.0f)",
				c.spent, tier, bonus, next, c.wantTier, c.wantBonus, c.wantNextAt)
		}
	}
}

func TestStatusLabelTg(t *testing.T) {
	if statusLabelTg("shipped") == "shipped" {
		t.Error("expected localized label for 'shipped'")
	}
	if statusLabelTg("unknown_x") != "unknown_x" {
		t.Error("unknown status should pass through unchanged")
	}
}

func TestCargoStatusTg(t *testing.T) {
	if cargoStatusTg("delivered") == "delivered" {
		t.Error("expected localized cargo label for 'delivered'")
	}
	if cargoStatusTg("weird") != "weird" {
		t.Error("unknown cargo status should pass through")
	}
}
