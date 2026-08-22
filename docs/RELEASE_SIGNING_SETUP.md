# Release Signing Setup (TajikShop)

Per production/Play requirements, **signing secrets are NOT stored in source control**. The previously‑committed keystore + `key.properties` were removed from git and are now `.gitignore`d. The build reads them locally from `android/key.properties`, and CI reads them from **GitHub Secrets**.

> **Never commit** `*.jks` / `key.properties` / passwords. If the old committed key was ever public, treat it as compromised and use a **new** dedicated TajikShop key (below). TajikShop is not yet published, so changing the key now is safe.

## 1. Create a dedicated TajikShop upload key (do this on your machine)
```bash
keytool -genkeypair -v \
  -keystore tajikshop-release.jks \
  -alias tajikshop \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -dname "CN=TajikShop, O=TajikShop, L=Dushanbe, C=TJ"
```
Choose a **strong password** when prompted (keep it private; do not share it).

## 2a. Local builds
Put the file at `android/app/tajikshop-release.jks` and create `android/key.properties` (both are git‑ignored):
```
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=tajikshop
storeFile=tajikshop-release.jks
```
`android/app/build.gradle` auto‑detects `key.properties` and signs the release with it (falls back to debug if absent).

## 2b. CI builds (GitHub Actions → signed AAB)
Add these **repository secrets** (Settings → Secrets and variables → Actions):
| Secret | Value |
|---|---|
| `KEYSTORE_BASE64` | base64 of `tajikshop-release.jks` → `base64 -w0 tajikshop-release.jks` (macOS: `base64 -i tajikshop-release.jks | tr -d '\n'`) |
| `STORE_PASSWORD` | your store password |
| `KEY_PASSWORD` | your key password |
| `KEY_ALIAS` | `tajikshop` |

The workflow `.github/workflows/flutter_build.yml` writes `android/app/tajikshop-release.jks` + `android/key.properties` from these secrets before building; without them it builds **debug‑signed** (not for Play).

## 3. Keep the key safe
- Back up `tajikshop-release.jks` and its passwords securely (a lost upload key blocks future updates unless you enrol in Play App Signing key reset).
- Recommended: enable **Play App Signing** on first upload (Google manages the app signing key; you keep only the upload key).

## Status
- **EXTERNAL ACTION REQUIRED:** create the key + add the 4 secrets. Until then, CI release builds are debug‑signed.
