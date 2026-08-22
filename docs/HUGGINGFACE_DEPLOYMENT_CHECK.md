# Hugging Face Backend — Deployment Check (TajikShop)

Backend: Go/Gin, currently hosted at `https://mahmadmurodov-tajikshop.hf.space`.

> The coding environment **cannot reach** this host (outbound proxy blocks it), so liveness was **NOT verified from here**. The currently‑running deployment also serves the **previous** build — the new endpoints (`/privacy`, `/terms`, `/delete-account`, `DELETE /users/me`, `POST /account/deletion-request`, `/health`) go live only after **redeploying** the merged `main`.

## Required environment variables (NAMES only — never commit values)
| Variable | Required | Purpose |
|---|---|---|
| `DB_URL` | **Yes** (`mustEnv`) | PostgreSQL connection string |
| `JWT_SECRET` | **Yes** (`mustEnv`) | JWT signing secret |
| `PORT` | No (default 8080; HF sets it) | Listen port |
| `R2_ENDPOINT` | For uploads | Cloudflare R2 S3 endpoint |
| `R2_ACCESS_KEY` | For uploads | R2 access key |
| `R2_SECRET_KEY` | For uploads | R2 secret key |
| `R2_BUCKET` | No (default `tajikshop`) | R2 bucket name |
| `R2_PUBLIC_URL` | For uploads | Public base URL for stored media |
| `FIREBASE_SERVICE_ACCOUNT` | For push | Service‑account JSON (FCM sends). No‑op if unset |
| `FIREBASE_PROJECT_ID` | For phone auth | Firebase project id |
| `FIREBASE_WEB_API_KEY` | For phone auth | Firebase Web API key (phone verify) |
| `SMTP_USER`, `SMTP_PASS` | Optional | Admin email notifications (no‑op if unset) |

(Names taken from `internal/config/config.go`, `internal/push`, `internal/routes/routes.go`, `internal/mailer`.)

## Redeploy checklist
1. Ensure all required env vars/secrets above are set in the Hugging Face Space settings.
2. Redeploy the Space from the latest `main` (contains account deletion + legal pages + `/health`).
3. Verify the following return 200 over HTTPS:
   - `GET /health` → `{ "status": "ok", "service": "TajikShop API" }`
   - `GET /privacy`, `GET /terms`, `GET /delete-account` → HTML pages load
   - `GET /api/v1/products` → product list JSON
4. Smoke‑test: register → login → list products → create order → `DELETE /api/v1/users/me` (on a throwaway account) → confirm the account can no longer log in.
5. Confirm the migration ran (new `deletion_requests` table; `users.is_deleted` column). `db.Migrate()` runs on boot (idempotent `IF NOT EXISTS`).

## Verified locally (in this environment)
- `go build ./...` → OK · `go vet ./...` → OK · `go test ./...` → OK.
