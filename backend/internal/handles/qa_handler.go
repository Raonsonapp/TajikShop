package handlers

import (
	"net/http"
	"time"

	"tajikshop/internal/db"
	"tajikshop/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type QAHandler struct{}

func NewQAHandler() *QAHandler { return &QAHandler{} }

type qaItem struct {
	ID         string     `json:"id"`
	Question   string     `json:"question"`
	Answer     string     `json:"answer"`
	UserName   string     `json:"user_name"`
	CreatedAt  time.Time  `json:"created_at"`
	AnsweredAt *time.Time `json:"answered_at,omitempty"`
}

// ByProduct — GET /products/:id/questions (оммавӣ)
func (h *QAHandler) ByProduct(c *gin.Context) {
	pid := c.Param("id")
	rows, _ := db.DB.Query(`SELECT q.id,q.question,COALESCE(q.answer,''),u.name,q.created_at,q.answered_at
		FROM questions q JOIN users u ON u.id=q.user_id
		WHERE q.product_id=$1 ORDER BY q.created_at DESC`, pid)
	defer rows.Close()
	var list []qaItem
	for rows.Next() {
		var q qaItem
		var ans *time.Time
		rows.Scan(&q.ID, &q.Question, &q.Answer, &q.UserName, &q.CreatedAt, &ans)
		q.AnsweredAt = ans
		list = append(list, q)
	}
	if list == nil {
		list = []qaItem{}
	}
	utils.OK(c, list)
}

// Ask — POST /products/:id/questions {question}
func (h *QAHandler) Ask(c *gin.Context) {
	uid := utils.UserID(c)
	pid := c.Param("id")
	var in struct {
		Question string `json:"question" binding:"required"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}
	id := uuid.NewString()
	db.DB.Exec(`INSERT INTO questions(id,product_id,user_id,question) VALUES($1,$2,$3,$4)`,
		id, pid, uid, in.Question)
	// Огоҳии фурӯшанда
	var sellerID string
	if err := db.DB.QueryRow(`SELECT seller_id FROM products WHERE id=$1`, pid).Scan(&sellerID); err == nil && sellerID != "" {
		db.DB.Exec(`INSERT INTO notifications(id,user_id,type,title,body,ref_id)
			VALUES($1,$2,'qa','Саволи нав','Дар бораи маҳсулоти шумо савол доданд',$3)`,
			uuid.NewString(), sellerID, pid)
		pushToUser(sellerID, "Саволи нав", "Дар бораи маҳсулоти шумо савол доданд")
	}
	utils.Created(c, gin.H{"id": id})
}

// Answer — POST /questions/:id/answer {answer} (фурӯшанда ҷавоб медиҳад)
func (h *QAHandler) Answer(c *gin.Context) {
	uid := utils.UserID(c)
	qid := c.Param("id")
	var in struct {
		Answer string `json:"answer" binding:"required"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, err.Error())
		return
	}
	// танҳо соҳиби маҳсулот ҷавоб дода метавонад
	res, _ := db.DB.Exec(`UPDATE questions SET answer=$1,answered_by=$2,answered_at=$3
		WHERE id=$4 AND product_id IN (SELECT id FROM products WHERE seller_id=$2)`,
		in.Answer, uid, time.Now(), qid)
	if n, _ := res.RowsAffected(); n == 0 {
		utils.Err(c, http.StatusForbidden, "танҳо фурӯшанда ҷавоб дода метавонад")
		return
	}
	// огоҳии пурсанда
	var asker string
	if err := db.DB.QueryRow(`SELECT user_id FROM questions WHERE id=$1`, qid).Scan(&asker); err == nil && asker != "" {
		db.DB.Exec(`INSERT INTO notifications(id,user_id,type,title,body)
			VALUES($1,$2,'qa','Ҷавоб ба савол','Ба саволи шумо ҷавоб доданд')`, uuid.NewString(), asker)
		pushToUser(asker, "Ҷавоб ба савол", "Ба саволи шумо ҷавоб доданд")
	}
	utils.OK(c, gin.H{"answered": true})
}
