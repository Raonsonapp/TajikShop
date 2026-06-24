package handlers

import (
	"tajikshop/internal/db"
	"tajikshop/internal/push"
)

// pushToUser — токени FCM-и корбарро меёбад ва push мефиристад (best-effort).
// Огоҳии in-app алоҳида тавассути INSERT INTO notifications сабт мешавад.
func pushToUser(userID, title, body string) {
	if userID == "" {
		return
	}
	var token string
	db.DB.QueryRow(`SELECT COALESCE(fcm_token,'') FROM users WHERE id=$1`, userID).Scan(&token)
	push.SendToToken(token, title, body)
}
