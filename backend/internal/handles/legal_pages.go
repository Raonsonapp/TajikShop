package handlers

import (
	"net/http"
	"strings"

	"tajikshop/internal/db"
	"tajikshop/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// Саҳифаҳои оммавии ҳуқуқӣ (Privacy / Terms / Delete Account) — барои Google Play.
// Аз ҷониби backend-и Go хизмат карда мешаванд, HTTPS, бе login, mobile-friendly.
type LegalHandler struct{}

func NewLegalHandler() *LegalHandler { return &LegalHandler{} }

const (
	appName    = "TajikShop"
	devName    = "Ehson Mahmadmurodov"
	contactEml = "ehsonmahmadmurodov@gmail.com"
	lastUpdate = "August 2026"
)

func page(title, body string) string {
	return `<!doctype html><html lang="tg"><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>` + title + ` — ` + appName + `</title>
<style>
:root{--g:#00D084;--b:#00A3FF}
*{box-sizing:border-box}
body{margin:0;font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;
 color:#1a1a2e;background:#f5f7fa;line-height:1.6}
.hd{background:linear-gradient(120deg,var(--g),var(--b));color:#fff;padding:28px 20px}
.hd h1{margin:0;font-size:22px}
.hd .sub{opacity:.9;font-size:13px;margin-top:4px}
.wrap{max-width:820px;margin:0 auto;padding:20px}
.card{background:#fff;border-radius:16px;padding:22px;margin:16px 0;box-shadow:0 4px 18px rgba(0,0,0,.06)}
h2{font-size:17px;margin:22px 0 8px;color:#0a7d52}
h3{font-size:15px;margin:16px 0 6px}
a{color:#00A3FF}
code{background:#eef2f6;padding:2px 6px;border-radius:6px;font-size:13px}
.upd{color:#6b7280;font-size:12px}
table{width:100%;border-collapse:collapse;font-size:13px;margin:8px 0}
th,td{border:1px solid #e5e9ef;padding:7px 9px;text-align:left;vertical-align:top}
th{background:#f0f9f4}
.btn{display:inline-block;background:linear-gradient(120deg,var(--g),var(--b));color:#fff;
 border:0;border-radius:12px;padding:13px 20px;font-size:15px;font-weight:700;cursor:pointer;text-decoration:none}
input,textarea{width:100%;padding:12px;border:1px solid #d7dee6;border-radius:10px;font-size:15px;margin:6px 0 12px;font-family:inherit}
.ok{background:#e6f7ef;color:#0a7d52;padding:12px;border-radius:10px;display:none;margin-top:10px}
.err{background:#fdecec;color:#c0392b;padding:12px;border-radius:10px;display:none;margin-top:10px}
.foot{text-align:center;color:#9aa5b1;font-size:12px;padding:24px}
</style></head><body>
<div class="hd"><h1>` + appName + `</h1><div class="sub">` + title + `</div></div>
<div class="wrap">` + body + `
<div class="foot">© ` + appName + ` · ` + devName + ` · <a href="mailto:` + contactEml + `">` + contactEml + `</a></div>
</div></body></html>`
}

// GET /privacy
func (h *LegalHandler) Privacy(c *gin.Context) {
	body := `<div class="card">
<p class="upd">Last updated / Санаи навсозӣ: ` + lastUpdate + `</p>
<p><b>` + appName + `</b> is an online marketplace for Tajikistan operated by <b>` + devName +
		`</b> ("we"). This policy explains what data we collect, why, and your rights. Contact: <a href="mailto:` +
		contactEml + `">` + contactEml + `</a>.</p>

<h2>1. Who we are</h2>
<p>` + appName + ` is a mobile e-commerce / marketplace app (buyers and sellers) with an optional
China→Tajikistan/Russia cargo delivery service. Operator: ` + devName + `, Dushanbe, Tajikistan.</p>

<h2>2. Data we collect</h2>
<table>
<tr><th>Category</th><th>Examples</th><th>Why</th></tr>
<tr><td>Account</td><td>Name, email, phone number, password (stored hashed), avatar, bio</td><td>Create and secure your account, sign-in</td></tr>
<tr><td>Seller / shop</td><td>Shop name, description, phone, working hours, business type, store location</td><td>Run a storefront (only if you become a seller)</td></tr>
<tr><td>Addresses & location</td><td>Delivery addresses; approximate device location (with permission)</td><td>Delivery, "nearby shops" map, store pin</td></tr>
<tr><td>Orders & payments</td><td>Orders, order items, payment method, wallet balance & transactions</td><td>Process purchases, wallet/cashback, records</td></tr>
<tr><td>Shopping activity</td><td>Cart, favorites, recently viewed (stored on your device), reviews, ratings, questions</td><td>App functionality</td></tr>
<tr><td>Messages</td><td>Chat messages between buyers and sellers</td><td>Buyer–seller communication</td></tr>
<tr><td>Cargo requests</td><td>Product link, description, destination, weight, tracking</td><td>China delivery service (optional)</td></tr>
<tr><td>Media</td><td>Uploaded avatar, product images, review photos, stories</td><td>Show products and profiles</td></tr>
<tr><td>Device / push</td><td>Push notification token (FCM)</td><td>Send order & activity notifications</td></tr>
<tr><td>Advertising</td><td>See "Advertising" below</td><td>In-app ads</td></tr>
</table>

<h2>3. How we collect it</h2>
<p>Directly from you (registration, profile, listings, orders, chat), automatically from your device
where you grant permission (location, notifications), and from your interactions with the app.</p>

<h2>4. Third-party service providers</h2>
<ul>
<li><b>Google Firebase Cloud Messaging</b> — push notifications; optional Firebase phone verification.</li>
<li><b>Yandex Mobile Ads</b> — in-app advertising SDK (see "Advertising").</li>
<li><b>Cloudflare R2</b> — storage of uploaded images/media.</li>
<li><b>Our API server & PostgreSQL database</b> — hosted backend that stores your account and marketplace data.</li>
</ul>
<p>We do not sell your personal data.</p>

<h2>5. Location data</h2>
<p>If you grant location permission, we use your approximate device location to show nearby shops,
set a store/delivery pin, and improve delivery. You can deny or revoke this permission at any time in
your device settings; the app remains usable without it.</p>

<h2>6. Notifications</h2>
<p>With your permission we send push notifications (order status, cargo status, messages, follows).
You can turn them off in device settings.</p>

<h2>7. Advertising</h2>
<p>The app shows ads via the Yandex Mobile Ads SDK. Ad SDKs may access device and advertising
identifiers to serve and measure ads. See our in-app and Play Console Ads declaration. You can reset
or limit your advertising ID in your device settings.</p>

<h2>8. Payments & orders</h2>
<p>Order and payment/wallet records are processed to fulfil purchases and are retained for
legal, accounting and fraud-prevention purposes even after account deletion (in anonymized form).</p>

<h2>9. Storage & security</h2>
<p>Passwords are hashed. Data is transmitted over HTTPS and access is protected by authentication
(JWT). No method of transmission or storage is 100% secure, but we take reasonable measures.</p>

<h2>10. Data retention</h2>
<p>We keep personal data while your account is active. When you delete your account, personal data is
deleted or anonymized (see below). Financial/transaction records are retained in anonymized form as
required for legitimate legal, accounting and fraud-prevention reasons.</p>

<h2>11. Account & data deletion</h2>
<p>You can delete your account and personal data at any time:</p>
<ul>
<li><b>In the app:</b> Profile → Settings → Delete account.</li>
<li><b>On the web:</b> <a href="/delete-account">` + appName + ` Delete Account page</a>.</li>
</ul>
<p>Deletion removes/anonymizes: name, email, phone, password, avatar, bio, addresses, cart,
favorites, follows, stories, chat messages, notifications, reviews, questions, cargo requests, and
listings not tied to existing orders (with their media). Orders, payments and wallet records are
retained in anonymized form for the reasons above.</p>

<h2>12. Your rights</h2>
<p>You may access, correct, or delete your personal data, and object to certain processing. Contact
<a href="mailto:` + contactEml + `">` + contactEml + `</a>.</p>

<h2>13. Children's privacy</h2>
<p>` + appName + ` is a general-audience marketplace and is <b>not directed to children under 13</b>.
We do not knowingly collect data from children. If you believe a child provided us data, contact us
and we will delete it.</p>

<h2>14. Changes</h2>
<p>We may update this policy; the "Last updated" date reflects the latest version.</p>

<h2>15. Contact</h2>
<p>` + devName + ` — <a href="mailto:` + contactEml + `">` + contactEml + `</a></p>
</div>`
	c.Header("Content-Type", "text/html; charset=utf-8")
	c.String(http.StatusOK, page("Privacy Policy", body))
}

// GET /terms
func (h *LegalHandler) Terms(c *gin.Context) {
	body := `<div class="card">
<p class="upd">Last updated: ` + lastUpdate + `</p>
<h2>1. Acceptance</h2>
<p>By using ` + appName + ` you agree to these Terms. If you do not agree, do not use the app.</p>
<h2>2. The service</h2>
<p>` + appName + ` is a marketplace connecting buyers and sellers in Tajikistan, with an optional
cargo delivery service. We provide the platform; sellers are responsible for their listings and orders.</p>
<h2>3. Accounts</h2>
<p>You must provide accurate information and keep your credentials secure. You are responsible for
activity on your account. You may delete your account at any time (Profile → Settings → Delete account,
or the <a href="/delete-account">Delete Account page</a>).</p>
<h2>4. Acceptable use</h2>
<p>Do not post illegal, fraudulent, counterfeit, or offensive content; do not harass other users; do
not misuse the chat, reviews, or reporting features. We may remove content or suspend accounts that
violate these Terms.</p>
<h2>5. Listings, orders & payments</h2>
<p>Sellers set prices, delivery terms and stock. Buyers are responsible for the accuracy of order and
delivery details. Wallet/cashback features are provided as-is.</p>
<h2>6. Content you provide</h2>
<p>You retain ownership of content you upload but grant ` + appName + ` a licence to display it in the
app for the purpose of operating the marketplace.</p>
<h2>7. Disclaimer & liability</h2>
<p>The service is provided "as is" without warranties. To the extent permitted by law, ` + appName + `
is not liable for indirect or consequential damages.</p>
<h2>8. Changes</h2>
<p>We may update these Terms; continued use means acceptance of the updated Terms.</p>
<h2>9. Contact</h2>
<p>` + devName + ` — <a href="mailto:` + contactEml + `">` + contactEml + `</a></p>
</div>`
	c.Header("Content-Type", "text/html; charset=utf-8")
	c.String(http.StatusOK, page("Terms of Service", body))
}

// GET /delete-account — саҳифаи оммавӣ бо формаи кории дархости ҳазф.
func (h *LegalHandler) DeleteAccountPage(c *gin.Context) {
	body := `<div class="card">
<h2>Delete your ` + appName + ` account</h2>
<p>You can permanently delete your ` + appName + ` account and personal data. There are two ways:</p>

<h3>Option 1 — In the app (fastest)</h3>
<p>Open ` + appName + ` → <b>Profile → Settings → Delete account</b> → confirm. Your account and
personal data are deleted immediately.</p>

<h3>Option 2 — Request here</h3>
<p>If you cannot access the app, submit a deletion request below. We process requests within <b>7 days</b>
and email you when done.</p>
<form id="f">
<label>Account email</label>
<input id="email" type="email" required placeholder="you@example.com">
<label>Note (optional)</label>
<textarea id="note" rows="3" placeholder="Anything that helps us find your account"></textarea>
<button class="btn" type="submit">Request account deletion</button>
<div class="ok" id="ok">✅ Request received. We will process it within 7 days.</div>
<div class="err" id="err">Something went wrong. Please email ` + contactEml + `.</div>
</form>

<h2>What is deleted</h2>
<p>Name, email, phone, password, avatar, bio, addresses, cart, favorites, follows, stories, chat
messages, notifications, reviews, questions, cargo requests, and listings not tied to existing orders
(including their images).</p>
<h2>What is retained (anonymized)</h2>
<p>Order, payment and wallet records are kept in anonymized form for legal, accounting and
fraud-prevention reasons, as described in our <a href="/privacy">Privacy Policy</a>.</p>
<h2>Contact</h2>
<p>` + devName + ` — <a href="mailto:` + contactEml + `">` + contactEml + `</a></p>
</div>
<script>
document.getElementById('f').addEventListener('submit',async function(e){
 e.preventDefault();
 var ok=document.getElementById('ok'),err=document.getElementById('err');
 ok.style.display='none';err.style.display='none';
 try{
  var r=await fetch('/api/v1/account/deletion-request',{method:'POST',
   headers:{'Content-Type':'application/json'},
   body:JSON.stringify({email:document.getElementById('email').value,note:document.getElementById('note').value})});
  if(r.ok){ok.style.display='block';document.getElementById('f').reset();}else{err.style.display='block';}
 }catch(_){err.style.display='block';}
});
</script>`
	c.Header("Content-Type", "text/html; charset=utf-8")
	c.String(http.StatusOK, page("Delete Account", body))
}

// POST /api/v1/account/deletion-request — формаи веб (бе login) → сабти дархост.
func (h *LegalHandler) DeletionRequest(c *gin.Context) {
	var in struct {
		Email string `json:"email"`
		Note  string `json:"note"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		utils.Err(c, http.StatusBadRequest, "invalid request")
		return
	}
	email := strings.TrimSpace(in.Email)
	if email == "" || !strings.Contains(email, "@") {
		utils.Err(c, http.StatusBadRequest, "valid email required")
		return
	}
	_, err := db.DB.Exec(`INSERT INTO deletion_requests(id,email,note) VALUES($1,$2,$3)`,
		uuid.NewString(), email, in.Note)
	if err != nil {
		utils.Err(c, http.StatusInternalServerError, "could not save request")
		return
	}
	notifyAdmins("account", "Дархости ҳазфи ҳисоб", "Дархости ҳазф аз веб: "+email, "")
	utils.OK(c, gin.H{"received": true})
}
