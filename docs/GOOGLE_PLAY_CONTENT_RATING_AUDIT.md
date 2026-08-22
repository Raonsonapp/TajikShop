# Google Play — Content Rating Questionnaire Audit (TajikShop)

Answer the Play Console content‑rating questionnaire **truthfully** as below. Category to select: **Utility / Productivity / Communication / Other → "Shopping"** (choose the questionnaire's e‑commerce/utility category; TajikShop is a marketplace, not a game).

## Feature reality (evidence)
- Shopping / commercial marketplace: products, cart, orders, wallet — `orders`, `payments`, `wallet_transactions`.
- User‑generated content: reviews (+photos), questions, product listings, shop profiles, stories — `reviews`, `questions`, `products`, `stories`.
- User‑to‑user communication: in‑app chat — `messages`, `/chat`.
- Reporting/moderation: content reports — `reports`, `/admin/reports`.
- Ads: Yandex Mobile Ads.
- Location: optional device location.

## Suggested questionnaire answers
| Question | Answer | Why |
|---|---|---|
| Violence (realistic/cartoon) | **No** | None in app |
| Sexual content / nudity | **No** | Not part of app; UGC must comply with Terms |
| Profanity / crude humor | **No** | Not a feature |
| Controlled substances (drugs/alcohol/tobacco) references | **No** | Not a feature |
| Gambling (real/simulated) | **No** | Wallet/cashback is loyalty, **not** gambling; no wagering |
| User‑generated content / user interaction | **Yes** | Reviews, chat, listings, stories |
| Users can communicate / share content | **Yes** | Buyer–seller chat, reviews |
| Shares user location | **Yes** (optional) | Nearby shops / delivery |
| Digital purchases | **Yes** | Marketplace purchases / wallet |
| Contains ads | **Yes** | Yandex Mobile Ads |

## Expected outcome
A general‑audience marketplace with UGC + chat + ads typically rates around **PEGI 3 / ESRB Everyone / IARC "Everyone" or "Teen"** depending on the UGC/communication answers. Because it has user communication and ads, expect a low‑to‑moderate rating — **do not manipulate answers to lower it**. UGC + communication being "Yes" is required and truthful.

## Moderation note (supports UGC policy)
The app has a **reporting** system (`reports` table, `POST /reports`, admin resolve) and admin removal of products/reviews, plus Terms prohibiting illegal/offensive content. This supports Google Play's UGC policy expectations (a way to report + moderation). Consider adding user **block** in chat as a future enhancement (not currently implemented).

**EXTERNAL ACTION REQUIRED:** complete the questionnaire in Play Console with the answers above.
