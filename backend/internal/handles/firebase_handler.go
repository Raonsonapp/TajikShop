package handlers

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"tajikshop/internal/auth"
	"tajikshop/internal/db"
	"tajikshop/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type FirebaseHandler struct {
	secret     string
	projectID  string
}

func NewFirebaseHandler(secret, projectID string) *FirebaseHandler {
	return &FirebaseHandler{secret: secret, projectID: projectID}
}

// VerifyFirebaseToken — Firebase ID token-ро тасдиқ мекунад
// Flutter: firebase_auth.currentUser.getIdToken() → фиристед
func (h *FirebaseHandler) VerifyPhone(c *gin.Context) {
	var in struct {
		IDToken string `json:"id_token" binding:"required"`
		Name    string `json:"name"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, "id_token required")
		return
	}

	// Firebase token-ро тасдиқ мекунем
	claims, err := verifyFirebaseIDToken(in.IDToken, h.projectID)
	if err != nil {
		utils.Err(c, http.StatusUnauthorized, "invalid firebase token: "+err.Error())
		return
	}

	phone      := claims["phone_number"].(string)
	firebaseUID := claims["uid"].(string)

	// Корбарро дар DB меёбем ё месозем
	var userID, userName string
	var phoneVerified bool
	err = db.DB.QueryRow(
		`SELECT id, name, phone_verified FROM users WHERE phone=$1 OR firebase_uid=$2`,
		phone, firebaseUID,
	).Scan(&userID, &userName, &phoneVerified)

	if err == sql.ErrNoRows {
		// Корбари нав — месозем
		userID = uuid.NewString()
		name := in.Name
		if name == "" {
			name = "Корбар"
		}
		// Password ройгон барои phone users
		hash, _ := utils.HashPassword(uuid.NewString())
		_, err = db.DB.Exec(
			`INSERT INTO users(id,name,phone,password_hash,firebase_uid,phone_verified,role)
			 VALUES($1,$2,$3,$4,$5,true,'buyer')`,
			userID, name, phone, hash, firebaseUID,
		)
		if err != nil {
			utils.Err(c, http.StatusInternalServerError, "user create error")
			return
		}
		userName = name
	} else if err != nil {
		utils.Err(c, http.StatusInternalServerError, "db error")
		return
	} else {
		// Корбор вуҷуд дорад — firebase_uid ва phone_verified навсоз
		db.DB.Exec(
			`UPDATE users SET firebase_uid=$1, phone_verified=true WHERE id=$2`,
			firebaseUID, userID,
		)
	}

	// Нақши корбарро мегирем
	var role string
	db.DB.QueryRow(`SELECT role FROM users WHERE id=$1`, userID).Scan(&role)
	if role == "" {
		role = "buyer"
	}

	// Token месозем
	accessToken, _ := auth.GenerateAccessToken(userID, role, h.secret)
	refreshToken, _ := auth.GenerateRefreshToken(userID, h.secret)
	db.DB.Exec(`UPDATE users SET refresh_token=$1 WHERE id=$2`, refreshToken, userID)

	utils.Created(c, gin.H{
		"access_token":   accessToken,
		"refresh_token":  refreshToken,
		"user_id":        userID,
		"name":           userName,
		"phone":          phone,
		"phone_verified": true,
		"role":           role,
	})
}

// verifyFirebaseIDToken — Firebase Public Keys орқали токенро тасдиқ мекунад
func verifyFirebaseIDToken(idToken, projectID string) (map[string]interface{}, error) {
	// Firebase token verify endpoint
	url := fmt.Sprintf(
		"https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=%s", projectID)
	
	body := fmt.Sprintf(`{"idToken":"%s"}`, idToken)
	resp, err := http.Post(url, "application/json", strings.NewReader(body))
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	data, _ := io.ReadAll(resp.Body)

	var result map[string]interface{}
	json.Unmarshal(data, &result)

	if errBlock, ok := result["error"]; ok {
		errMap := errBlock.(map[string]interface{})
		return nil, fmt.Errorf("%v", errMap["message"])
	}

	users := result["users"].([]interface{})
	if len(users) == 0 {
		return nil, fmt.Errorf("user not found")
	}
	user := users[0].(map[string]interface{})

	phone, _ := user["phoneNumber"].(string)
	uid, _   := user["localId"].(string)

	return map[string]interface{}{
		"phone_number": phone,
		"uid":          uid,
	}, nil
}
