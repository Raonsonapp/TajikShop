# Google Play — Data Safety Audit (TajikShop)

Mapped from the **actual codebase** (Flutter app + Go/Gin backend + PostgreSQL + Cloudflare R2 + Firebase + Yandex Mobile Ads). Use this to fill Play Console → App content → **Data safety**.

- App: **TajikShop** · Package: `com.tajikshop.app`
- Data encrypted in transit: **Yes** (HTTPS to backend; SDKs use HTTPS).
- Users can request deletion: **Yes** — in‑app (Profile → Settings → Ҳазфи ҳисоб → `DELETE /users/me`) and web (`/delete-account`).
- Passwords stored **hashed** (bcrypt) server‑side.

> "Collected" = sent off the device. "Shared" = transferred to a third party. Cloudflare R2 and our own PostgreSQL are **processors/first‑party infrastructure**, not "sharing".

| Data type | Collected | Shared | Optional? | Purpose | Evidence (code) |
|---|---|---|---|---|---|
| **Name** | Yes | No | Required | Account, orders | `users.name`; `Register`/`UpdateProfile` |
| **Email address** | Yes | No | Required (email or phone) | Account, sign‑in | `users.email`; `Login`/`Register` |
| **Phone number** | Yes | No | Required (email or phone) | Account, sign‑in, delivery contact | `users.phone`; phone auth (Firebase) |
| **Password** | Yes | No | Required | Authentication (stored hashed) | `users.password_hash` (bcrypt) |
| **User IDs** | Yes | No | Required | Account identity (UUID), JWT | `users.id`, JWT middleware |
| **Address** | Yes | No | Optional | Delivery | `addresses` table |
| **Approximate/precise location** | Yes | No | Optional | "Nearby shops" map, store pin, delivery | `geolocator`; `users.store_lat/lng`, `addresses.lat/lng`; `PUT /users/me/location` |
| **Photos** | Yes | No | Optional | Avatar, product images, review photos, stories | `image_picker` → `POST .../images`, `/users/me/avatar`, `/reviews/upload`, `/stories`; stored in R2 |
| **Messages (in‑app)** | Yes | No | Optional | Buyer–seller chat | `messages` table; `POST /messages` |
| **Purchase history** | Yes | No | Required (to buy) | Orders, fulfilment | `orders`, `order_items` |
| **Payment info (wallet)** | Yes | No | Optional | Wallet balance/cashback, payouts | `payments`, `wallet_transactions` (no card data collected; top‑ups reviewed by admin) |
| **Other user content** | Yes | No | Optional | Reviews, ratings, questions, cargo requests, shop profile | `reviews`, `questions`, `cargo_orders`, seller `shop_*` |
| **Push token (device/FCM)** | Yes | Yes (Google/Firebase) | Optional | Push notifications | `users.fcm_token`; `firebase_messaging` |
| **Advertising ID / device identifiers** | Yes (by SDK) | **Yes (Yandex)** | — | In‑app ads | `yandex_mobileads` SDK (see ADS audit) |
| **App interactions** | Yes | No | — | App functionality (cart, favorites, views) | `cart_items`, `favorites`, product `views` |

## Not collected (verified — no SDK present)
- No dedicated analytics SDK (no `firebase_analytics`, no Google Analytics, no Facebook SDK) — grep of `pubspec.yaml`/`lib` shows none.
- No health/fitness, contacts, calendar, SMS, call logs, browsing history.
- No credit/debit **card numbers** are collected in the app (wallet top‑ups are manual/admin‑reviewed).

## Suggested Play Console answers
- Does your app collect or share any of the required user data types? **Yes**.
- Is all data encrypted in transit? **Yes**.
- Do you provide a way to request data deletion? **Yes** (in‑app + `https://<domain>/delete-account`).
- Data types to mark **collected**: Name, Email, Phone, User IDs, Address, Location (approx + precise), Photos, In‑app messages, Purchase history, Wallet/financial info, Other UGC, Push token, App interactions, Device/advertising IDs.
- Data types to mark **shared**: Device/Advertising IDs (Yandex Ads), Push token (Firebase/Google). Mark others "collected, not shared".

## Retention / deletion behavior (evidence: `account_deletion.go`)
- Deleted/removed on account deletion: cart, favorites, addresses, follows, stories, messages, notifications, reviews, review likes, questions, cargo requests, listings not tied to orders (+ their R2 images), avatar; user row **anonymized** (name/email/phone/password/avatar/bio/shop/location cleared, login blocked).
- **Retained (anonymized)**: orders, order_items, payments, wallet_transactions — legitimate legal/accounting/fraud‑prevention retention, disclosed in Privacy Policy §10–11.

**EXTERNAL ACTION REQUIRED:** enter these answers in Play Console; they are declarations, not code.
