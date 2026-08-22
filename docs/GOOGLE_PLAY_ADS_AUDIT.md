# Google Play — Ads Audit (TajikShop)

## SDK in use (verified)
- **Yandex Mobile Ads** — `yandex_mobileads: ^8.2.0` in `pubspec.yaml`.
- Integration: `lib/core/ads/ad_service.dart`, `lib/core/ads/ad_config.dart`, `lib/shared/widgets/inline_ad.dart`.
- No AdMob / AppLovin / Facebook Audience Network present (removed earlier; grep confirms only `yandex_mobileads`).

## Ad formats actually implemented
| Format | Where | Code |
|---|---|---|
| Banner (sticky) | Bottom of main scaffold | `AdBanner` (`BannerAdSize.sticky`) in `main_scaffold.dart` |
| Inline banner (MREC‑like block) | Home feed | `AdMrec` (`BannerAdSize.inline`) in `home_screen.dart` |
| Interstitial | Every 4th product open (frequency‑capped) | `AdService.maybeShowInterstitial()` in `product_detail_screen.dart` |

No rewarded, native, or app‑open ads are used.

## Current configuration
- `AdConfig.useDemoAds = true` → app currently uses **Yandex official demo ad unit IDs** (`demo-banner-yandex`, `demo-interstitial-yandex`). Demo ads do **not** generate revenue.
- For production revenue: set real Yandex ad unit IDs in `ad_config.dart` and `useDemoAds=false`. **EXTERNAL ACTION REQUIRED** (Yandex Partner account — see chat history; `partner.yandex.ru`).

## Data the SDK may access/share
- Yandex Mobile Ads may read **device identifiers and the advertising ID** to request and measure ads, and may enable **personalized advertising**. This is why Data Safety marks *Device/Advertising IDs → collected & shared*.
- On Android 13+, the ad SDK contributes the `com.google.android.gms.permission.AD_ID` permission via manifest merge (expected for ads).
- The app does **not** currently call Yandex consent APIs (`setUserConsent`). If you distribute to EEA/UK users, you should set user consent before loading ads. **RECOMMENDED (external/optional).**

## Play Console declarations (must match reality)
- **Ads** (App content → Ads): **Yes, my app contains ads.**
- Ad formats: **Banner, Interstitial** (do not tick rewarded/native/app‑open).
- Data safety: mark **Device or other IDs** as *Collected* and *Shared* (Yandex Ads), purpose *Advertising or marketing*.
- Content rating questionnaire: answer **Yes** to "contains ads".
- Families policy: app is **not** child‑directed (general audience), so it is not subject to the Families ad‑SDK self‑certification requirement, but ads must remain appropriate for the target age.

## Verdict
The app genuinely contains ads (Yandex). Declaring "contains ads" in Play Console will match reality. No code change required for compliance; only accurate declarations + (for revenue) real ad unit IDs.
