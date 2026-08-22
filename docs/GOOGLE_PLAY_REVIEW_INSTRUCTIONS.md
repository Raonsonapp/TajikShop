# Google Play — Reviewer Instructions (TajikShop)

Provide these in Play Console → App content → **App access** (and store‑listing notes).

## Login / access
- The app **requires an account** for most actions (cart, orders, chat, profile, deletion).
- Registration is open: **Profile/Splash → Register** with name + email (or phone) + password. Reviewers can self‑register.
- If a ready test account is preferred, create one and enter its credentials in Play Console → **App access** (do **not** hardcode credentials in the app or repo).
  - Suggested: create `reviewer@tajikshop.app` / a strong password via the in‑app Register screen, then paste into Play Console App access.

## How to test core shopping
1. Register / log in.
2. Home → browse categories, "Машҳуртарин", "Тахфифҳо", search.
3. Open a product → add to cart → open cart → checkout (choose wallet or delivery/cash).
4. Profile → Orders → view order + status tabs.

## How to test seller features (optional)
1. Profile → "Фурӯшанда шав" (Become seller) → submit verification.
2. Seller approval is admin‑gated; for review, an admin can approve, or note that seller features require approval.
3. Seller dashboard: add product, edit (price/discount/delivery/size), view sales chart, "Фармоишҳои фурӯш".

## How to test account deletion (Play requirement)
- **In‑app:** Profile → Settings → **Ҳазфи ҳисоб** → confirm → account deleted, user logged out.
- **Web:** open `https://<YOUR-DOMAIN>/delete-account` → submit email → request recorded.

## Privacy Policy / Terms
- In‑app: Profile → Settings → **Сиёсати махфият** / **Шартҳои истифода** (open web pages).
- Web: `https://<YOUR-DOMAIN>/privacy`, `https://<YOUR-DOMAIN>/terms`.

## Non‑obvious features
- **Cargo** (China→TJ/RU delivery): Home → "Карго аз Хитой" card → warehouse address, tariffs, cost calculator, delivery request, tracking.
- **Wallet/cashback**: Profile → Wallet.
- **Chat**: product → "Паём ба фурӯшанда"; inbox via the header message icon.
- Ads (Yandex) appear as banner (bottom), a feed block, and occasional interstitial.

## Restricted areas
- **Admin panel** (Profile → Admin) is restricted to admin role and is not needed for review.

`<YOUR-DOMAIN>` = the public host that serves the backend (currently `https://mahmadmurodov-tajikshop.hf.space`). Confirm it is reachable before submission.
