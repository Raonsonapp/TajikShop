# Google Play — Final Submission Sheet (TajikShop)

Exact values to enter in Play Console. Replace `<DOMAIN>` with the live backend host (currently `mahmadmurodov-tajikshop.hf.space`) **after redeploying** the latest `main`.

| Field | Value |
|---|---|
| App name | **TajikShop** |
| Package name | **com.tajikshop.app** |
| Version (first upload) | versionName `1.0.0`, versionCode `1` |
| Privacy Policy URL | `https://<DOMAIN>/privacy` |
| Delete Account URL | `https://<DOMAIN>/delete-account` |
| Terms URL | `https://<DOMAIN>/terms` |
| Backend (production) | `https://<DOMAIN>/api/v1` |

## Data Safety (from actual code — see GOOGLE_PLAY_DATA_SAFETY_AUDIT.md)
- **Collected:** Name, Email, Phone, User IDs, Address, Location (approx + precise), Photos, In‑app messages, Purchase history, Wallet/financial info, Other UGC, Push token, App interactions, Device/Advertising IDs.
- **Shared:** Device/Advertising IDs (Yandex Ads), Push token (Firebase/Google).
- Encrypted in transit: **Yes**. Deletion method: **Yes** (in‑app + web).

## Ads
- **Contains ads: Yes** (Yandex Mobile Ads — banner + interstitial).

## Target Audience & Content
- Target age: **18 and over / adults** (general marketplace; payments, chat, ads). Not designed for children. Not in Designed for Families.

## Content Rating (answer truthfully)
- User‑generated content / user communication: **Yes** (reviews, chat, listings, stories).
- Shares location: **Yes** (optional). Digital purchases: **Yes**. Contains ads: **Yes**.
- Violence/sexual/profanity/drugs/gambling: **No**.

## Step‑by‑step
1. **Create app** in Play Console (or open the existing draft); set default language + app name **TajikShop**.
2. **Upload AAB**: build `flutter build appbundle --release` (signed — see RELEASE_SIGNING_SETUP.md) → upload to a track (Internal testing first).
3. **App content → Privacy policy**: `https://<DOMAIN>/privacy`.
4. **App content → App access**: provide a reviewer test account (register one via the app; enter credentials here — do not hardcode). See GOOGLE_PLAY_REVIEW_INSTRUCTIONS.md.
5. **App content → Ads**: **Yes, contains ads**.
6. **App content → Data safety**: enter the answers above.
7. **App content → Content rating**: complete the questionnaire truthfully.
8. **App content → Target audience**: 18+/adults; not child‑directed.
9. **App content → Account deletion**: URL `https://<DOMAIN>/delete-account` (and note in‑app deletion exists).
10. **Store listing**: title, short/full description, screenshots, feature graphic, icon.
11. **Review all warnings/errors** in the Publishing overview; resolve.
12. **Submit for review** (start with Internal testing → Closed → Production).

## Pre‑submission gates (must be true)
- [ ] Backend redeployed; `/health`, `/privacy`, `/terms`, `/delete-account`, `/api/v1/*` return 200 over HTTPS.
- [ ] Firebase app registered for `com.tajikshop.app`; fresh `google-services.json` in place (see FIREBASE_FINAL_CHECK.md).
- [ ] Signed AAB produced with the dedicated TajikShop key (secrets set).
- [ ] `com.tajikshop.app` is not already taken on Play.

Do not expect guaranteed approval — Google reviews independently.
