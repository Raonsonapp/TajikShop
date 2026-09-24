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
   - `GET /health` → `{ "status": "ok", "service": "TajikShop API", "storage": "ok", "storage_public_url": true }`
   - `GET /privacy`, `GET /terms`, `GET /delete-account` → HTML pages load
   - `GET /api/v1/products` → product list JSON
4. Smoke‑test: register → login → list products → create order → `DELETE /api/v1/users/me` (on a throwaway account) → confirm the account can no longer log in.
5. Confirm the migration ran (new `deletion_requests` table; `users.is_deleted` column). `db.Migrate()` runs on boot (idempotent `IF NOT EXISTS`).

## After changing the Cloudflare R2 keys

Creating the R2 client never contacts Cloudflare, so a wrong or expired key
used to look fine and only surfaced as a failed photo upload. The server now
sends a real `HeadBucket` request at startup and reports the truth.

**Check it in one step** — open `https://<host>/health` and read `storage`:

| `storage` value | What it means | What to do |
|---|---|---|
| `ok` | The new keys work | Nothing |
| `credentials rejected — …` | Key or secret is wrong/expired | Re-copy `R2_ACCESS_KEY` and `R2_SECRET_KEY` from Cloudflare → R2 → Manage API tokens |
| `bucket not found: <name>` | Bucket name does not match | Fix `R2_BUCKET` (default `tajikshop`) |
| `unreachable — …` | Endpoint wrong or network blocked | Fix `R2_ENDPOINT` (`https://<account-id>.r2.cloudflarestorage.com`) |
| `not configured` | `R2_ENDPOINT`/`R2_ACCESS_KEY` empty | Set them in the Space secrets |

`storage_public_url: false` means `R2_PUBLIC_URL` is empty — uploads will
succeed but the stored links are incomplete, so images will not open in the
app. Set it to the bucket's public base URL.

The Space's startup logs carry the same line (`✅ Cloudflare R2 ok (bucket: …)`
or `❌ Cloudflare R2: …`). No key is ever written to the logs or to `/health`.

**Note:** changing a secret in the Space settings requires a **restart/rebuild**
of the Space for the new value to be picked up — pushing code alone does not
re-read secrets of an already-running container.

## Verified locally (in this environment)
- `go build ./...` → OK · `go vet ./...` → OK · `go test ./...` → OK.
