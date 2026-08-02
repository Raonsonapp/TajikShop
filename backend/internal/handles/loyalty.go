package handlers

import (
	"tajikshop/internal/db"
	"tajikshop/internal/utils"

	"github.com/gin-gonic/gin"
)

// Барномаи вафодорӣ — сатҳҳо аз рӯи маблағи умумии харид (фармоишҳои иҷрошуда).
// Ҳар сатҳ бонуси cashback-и иловагӣ медиҳад (болои cashback-и асосии settings).
//
//	Bronze: 0–499      → +0%
//	Silver: 500–1999   → +1%
//	Gold:   2000+      → +2%
const (
	silverThreshold = 500.0
	goldThreshold   = 2000.0
)

// userTotalSpent — ҷамъи фармоишҳои иҷрошудаи корбар.
func userTotalSpent(uid string) float64 {
	var s float64
	db.DB.QueryRow(`SELECT COALESCE(SUM(total),0) FROM orders WHERE user_id=$1 AND status='completed'`, uid).Scan(&s)
	return s
}

// loyaltyTier — аз рӯи маблағ: (номи сатҳ, бонуси cashback %, ҳадди сатҳи оянда).
func loyaltyTier(spent float64) (tier string, bonus int, nextAt float64) {
	switch {
	case spent >= goldThreshold:
		return "gold", 2, 0
	case spent >= silverThreshold:
		return "silver", 1, goldThreshold
	default:
		return "bronze", 0, silverThreshold
	}
}

// loyaltyBonusPercent — бонуси cashback-и сатҳи корбар (барои Confirm).
func loyaltyBonusPercent(uid string) int {
	_, bonus, _ := loyaltyTier(userTotalSpent(uid))
	return bonus
}

// LoyaltyInfo — маълумоти вафодории корбари ҷорӣ. GET /users/me/loyalty
func (h *UserHandler) LoyaltyInfo(c *gin.Context) {
	uid := utils.UserID(c)
	spent := userTotalSpent(uid)
	tier, bonus, nextAt := loyaltyTier(spent)
	effective := cashbackPercent() + float64(bonus)
	utils.OK(c, gin.H{
		"tier":             tier,
		"total_spent":      spent,
		"bonus_percent":    bonus,
		"cashback_percent": effective, // асосӣ + бонуси сатҳ
		"next_tier_at":     nextAt,    // 0 = сатҳи болоӣ
	})
}
