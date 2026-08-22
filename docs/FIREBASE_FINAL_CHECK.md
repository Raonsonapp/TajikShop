# Firebase — Final Manual Check (TajikShop)

The app package was migrated to **`com.tajikshop.app`**. `android/app/google-services.json` was updated so the `package_name` matches the build (so the `google-services` Gradle plugin passes). **However, the Firebase project must have an Android app registered for `com.tajikshop.app`** or push/phone‑auth will not work under the new package.

This check **cannot be performed from the coding environment** (no Firebase Console access) → **EXTERNAL ACTION REQUIRED**.

## Repository facts (verified)
- `google-services.json` → `project_id: tajikshop`, `project_number: 940101388450`, `android_client_info.package_name: com.tajikshop.app`.
- Plugin applied: `com.google.gms.google-services` (in `android/app/build.gradle`), classpath `com.google.gms:google-services:4.4.1` (in `android/build.gradle`).
- SDKs: `firebase_core`, `firebase_messaging` (FCM push). Firebase **phone verification** used via `FirebaseHandler.VerifyPhone` (`FIREBASE_WEB_API_KEY` on backend).

## Manual checklist
1. Open **Firebase Console** → project **`tajikshop`** (number `940101388450`).
2. Project settings → **Your apps** → Android. Verify an Android app exists with package **`com.tajikshop.app`**. If only `com.example.tajikshop` exists, click **Add app → Android** and register **`com.tajikshop.app`**.
3. If Google Sign‑In / Play Integrity / Phone Auth needs it, add the app's **SHA‑1 / SHA‑256** (from Play App Signing → App integrity, or `keytool -list` on your upload key).
4. Verify **Authentication → Sign‑in method → Phone** is enabled (the app offers phone verification).
5. Verify **Cloud Messaging** is enabled (default) and a Server key / service account exists for backend sends (`FIREBASE_SERVICE_ACCOUNT` env on backend).
6. **Download the fresh `google-services.json`** for `com.tajikshop.app`.
7. Replace `android/app/google-services.json` with the downloaded file **only if** its `mobilesdk_app_id`/`api_key` differ (they will, for a newly‑registered app).
8. Commit the replaced file and rebuild.
9. Test on a device: install the release, confirm you receive a test push (order/status notification) and that phone verification works.

> Do not invent project IDs, app IDs, or API keys — use exactly what the console provides.
