# Google Play — Final Production Audit (TajikShop)

App: **TajikShop** · Package: **`com.tajikshop.app`** · Version: `1.0.0+1`
Backend: Go/Gin + PostgreSQL + Cloudflare R2 + Firebase (FCM/phone) · Ads: Yandex Mobile Ads.

Legend: **PASS** = implemented & verified in this repo · **EXTERNAL** = requires action outside the repo (console/deploy) · **VERIFY** = needs runtime verification not possible from the build environment.

| # | Requirement | Status | Evidence | Remaining action |
|---|---|---|---|---|
| 1 | Account creation | PASS | `POST /api/v1/auth/register`, `/auth/login`; JWT | — |
| 2 | In‑app account deletion | PASS | Profile→Settings→**Ҳазфи ҳисоб** → `_deleteAccount()` → `DELETE /users/me` | — |
| 3 | External account‑deletion URL | PASS (code) · EXTERNAL (deploy) | `GET /delete-account` + working form → `POST /account/deletion-request` (`legal_pages.go`, `deletion_requests` table) | Deploy backend at public HTTPS domain; enter URL in Play Console |
| 4 | Actual associated data deletion | PASS | `account_deletion.go`: deletes personal data + R2 media; anonymizes user; retains order/payment (anonymized) | — |
| 5 | Privacy Policy public URL | PASS (code) · EXTERNAL (deploy) | `GET /privacy` (`legal_pages.go`) | Confirm reachable at `https://<domain>/privacy`; enter in Play |
| 6 | Privacy Policy inside app | PASS | Profile→Settings→**Сиёсати махфият** → `url_launcher` → `/privacy` | — |
| 7 | Terms public URL | PASS (code) · EXTERNAL (deploy) | `GET /terms` | Confirm reachable |
| 8 | Production package name | PASS | `applicationId`/`namespace`=`com.tajikshop.app`; MainActivity moved; grep clean | Confirm `com.tajikshop.app` unused on Play (could not verify from here) |
| 9 | Firebase package consistency | **EXTERNAL ACTION REQUIRED** | `google-services.json` package renamed so build passes, but Firebase app is registered as old package | Register `com.tajikshop.app` in Firebase console → download & replace `google-services.json`; else FCM push + Firebase phone auth won't work under new package |
| 10 | Dedicated TajikShop signing key | PASS | Fresh keystore generated for this app (`raonson-release.jks`, alias `raonson`) — NOT the other app's key; release signing wired in `build.gradle` | See #11 |
| 11 | Secrets removed from source control | **DECISION / EXTERNAL** | Keystore + `key.properties` are **committed by explicit owner request** for auto‑signing; CI‑secrets fallback also wired (`flutter_build.yml` reads `KEYSTORE_BASE64` etc.) | Security tradeoff: on a public repo the key is exposed. Recommended: make repo **private** (owner 1‑click) OR remove keystore & use GitHub Secrets. See "Security note" below |
| 12 | Android release configuration | PASS | targetSdk 35, compileSdk 35, minSdk 23, Kotlin 2.1.0, Java 17, AGP 8.3, Gradle 8.7, release signing, cleartext disabled (network_security_config), R8 off | — |
| 13 | Minimal necessary permissions | PASS | Manifest: INTERNET, ACCESS_NETWORK_STATE, ACCESS_WIFI_STATE, FINE/COARSE location (location genuinely used) | — |
| 14 | Data Safety audit | PASS | `docs/GOOGLE_PLAY_DATA_SAFETY_AUDIT.md` | Enter answers in Play Console |
| 15 | Ads audit | PASS | `docs/GOOGLE_PLAY_ADS_AUDIT.md` (Yandex banner/interstitial) | Declare "contains ads"; set real ad IDs for revenue (optional) |
| 16 | Target audience | PASS | `docs/GOOGLE_PLAY_TARGET_AUDIENCE_AUDIT.md` (recommend 18+/adults) | Set in Play Console |
| 17 | Content rating | PASS | `docs/GOOGLE_PLAY_CONTENT_RATING_AUDIT.md` | Complete questionnaire truthfully |
| 18 | User‑generated content | PASS | reviews, chat, listings, stories + reports/moderation (`reports`, admin removal) | Consider adding chat "block user" (future) |
| 19 | Payment/order functionality | PASS | `orders`, `order_items`, `payments`, `wallet_transactions`, checkout | — |
| 20 | Location disclosure | PASS | Privacy §5; optional runtime permission; used for nearby shops/delivery | — |
| 21 | Notification disclosure | PASS | Privacy §6; FCM token; user‑permission | — |
| 22 | Backend health | VERIFY | `GET /health` → `{status: ok}` exists in `routes.go` | Confirm deployed backend is live & reachable at the public domain |
| 23 | Authentication | PASS | JWT (`middleware.Auth`), bcrypt password hashing | — |
| 24 | Authorization | PASS | `Auth`/`SellerOnly`/`AdminOnly`; deletion uses caller's own `uid` (no arbitrary ID) | — |
| 25 | Security audit | PASS (baseline) | `docs`‑level review; parameterized SQL (no string‑concat user input in queries), hashed passwords, HTTPS, role checks | See Security note (secrets in repo, rate limiting not present) |
| 26 | Flutter analyze | PASS | CI run `659972a` — analyze step succeeded (0 errors) | — |
| 27 | Flutter tests | PARTIAL | `test/models_test.dart` (model parsing) + placeholder; pure Go logic tested | Full account‑deletion widget/integration test needs API mocking / test DB (not added) |
| 28 | AAB release build | PASS | CI run `659972a` — `flutter build appbundle --release` succeeded (signed) | — |
| 29 | Go tests | PASS | `go test ./...` → ok (`internal/handles`, `internal/storage`) | Full deletion integration test needs a test PostgreSQL DB |
| 30 | Go vet | PASS | `go vet ./...` clean | — |
| 31 | Go build | PASS | `go build ./...` clean | — |
| 32 | Public legal pages | PASS (code) · EXTERNAL (deploy) | `/privacy`, `/terms`, `/delete-account` served by backend | Deploy + verify URLs |
| 33 | Reviewer instructions | PASS | `docs/GOOGLE_PLAY_REVIEW_INSTRUCTIONS.md` | Provide test account in Play Console App access |
| 34 | Google Play submission readiness | **NOT READY — EXTERNAL ACTION REQUIRED** | Items #3,5,7,9,11,22 depend on deploy/console/Firebase | Complete external actions below |

## Security note (#11, #25)
- The release **keystore and passwords are committed** to the repo at the owner's explicit request (for automatic consistent signing). On a **public** repo this exposes the signing key. **Recommended:** make the repository **private** (Settings → Danger Zone → Change visibility) — the code cannot do this — OR delete `android/app/raonson-release.jks` + `android/key.properties` from git and use the already‑wired GitHub Secrets (`KEYSTORE_BASE64`, `STORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`).
- No rate limiting on auth endpoints (consider adding for production hardening — not a Play blocker).

## External actions required before submission
1. **Firebase:** register `com.tajikshop.app` in the Firebase console, replace `android/app/google-services.json` (else push/phone‑auth break under new package).
2. **Deploy** the backend so `/privacy`, `/terms`, `/delete-account`, `/health` and the API are live over HTTPS; confirm each loads.
3. **Play Console:** enter Privacy Policy URL, Delete Account URL, Data Safety answers, Ads declaration, Target Audience (18+), Content Rating questionnaire, App Access (reviewer account).
4. **Signing key exposure:** make repo private or move keystore to CI secrets.
5. **(Optional, revenue):** set real Yandex ad unit IDs (`useDemoAds=false`).
6. **Verify** `com.tajikshop.app` is not already taken on Google Play.

## Verified in this environment
- `go build ./...`, `go vet ./...`, `go test ./...` → all pass locally.
- `flutter analyze`, `flutter build apk --release`, `flutter build appbundle --release` → pass in CI (run `659972a`). (Flutter toolchain is not available in the coding environment; verified via GitHub Actions.)
