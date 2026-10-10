# SSO — як ҳисоб барои Raonson ва TajikShop

Корбар дар як барнома ворид мешавад ва бе парол ба барномаи дигар мегузарад —
мисли Instagram / Facebook / WhatsApp, ки як ҳисоб доранд.

Ҳоло TajikShop **провайдери шахсият** (identity provider) аст: ҳисобҳо дар
базаи он мемонанд. Raonson ҳамон корбарро бе бақайдгирии нав мегирад.

Base URL: `https://mahmadmurodov-tajikshop.hf.space/api/v1`

---

## Ҷараён

```
Барномаи A (корбар вориди он аст)        Барномаи B
  │
  ├─ POST /sso/code {target_app:"raonson"}
  │     ← {code, deep_link, expires_in}
  │
  ├─ мекушояд: raonson://sso?code=<code>  ──────────►
  │                                          │
  │                                          ├─ POST /sso/exchange {code, app:"raonson"}
  │                                          │     ← {access_token, refresh_token, user}
  │                                          │
  │                                          └─ корбар вориди B аст ✅
```

---

## 1. `GET /sso/apps` — оммавӣ

Рӯйхати барномаҳои шарик. Барнома аз ин ҷо мефаҳмад, ки ба куҷо гузаштан
мумкин аст ва агар барнома насб нашуда бошад, корбарро ба куҷо фиристад.

```json
{ "success": true, "data": [
  { "id": "raonson", "name": "Raonson", "scheme": "raonson",
    "package": "com.raonson.app",
    "fallback": "https://play.google.com/store/apps/details?id=com.raonson.app" },
  { "id": "tajikshop", "name": "TajikShop", "scheme": "tajikshop",
    "package": "com.tajikshop.app",
    "fallback": "https://play.google.com/store/apps/details?id=com.tajikshop.app" }
]}
```

Рӯйхат дар ҷадвали `settings` (калиди `sso_apps`) нигоҳ дошта мешавад, пас
барномаи нави Raonson бе релизи нав илова мешавад.

## 2. `POST /sso/code` — бо ворид (`Authorization: Bearer <access_token>`)

```json
→ { "target_app": "raonson" }

← { "success": true, "data": {
      "code": "dX7…_kQ",          // 43 аломат, base64url
      "expires_in": 120,
      "deep_link": "raonson://sso?code=dX7…_kQ",
      "fallback": "https://play.google.com/…",
      "app": { … }
  }}
```

## 3. `POST /sso/exchange` — оммавӣ (корбар ҳанӯз ворид нест)

```json
→ { "code": "dX7…_kQ", "app": "raonson" }

← { "success": true, "data": {
      "access_token":  "…",   // 24 соат
      "refresh_token": "…",   // 30 рӯз
      "user": { "id": "…", "name": "…", "email": "…", "role": "…",
                "avatar_url": "…", "is_seller": false, "is_verified": false }
  }}
```

Хатогиҳо: `401 "Код нодуруст ё мӯҳлаташ гузашт"`, `400 "Барномаи номаълум"`.

Токенҳоро мисли вуруди оддӣ нигоҳ доред ва пас аз 401 бо
`POST /auth/refresh {refresh_token}` нав кунед.

---

## Чаро код, на худи токен

Ин қарори бехатарист, на осонӣ:

| Хатар | Чӣ тавр пешгирӣ шуд |
|---|---|
| Токен дар URL мемонад (логи система, таърих, «recent apps») | Дар URL **код** меравад, на токен |
| Кодро дуздида, такрор истифода мебаранд | Як бор кор мекунад — `UPDATE … WHERE used_at IS NULL` дар як дархост |
| Коди кӯҳна баъдтар истифода мешавад | Пас аз **2 дақиқа** мемирад |
| Коди Raonson дар барномаи бегона | Код ба `target_app` баста аст |
| Касе базаро хонад ва сессия гирад | Дар база **ҳэши** код (SHA-256) мемонад, на худи код |

Такрори дархости `exchange` бо ҳамон код `401` мегирад — шарт дар худи
`UPDATE` аст, пас ду дархости баробар ҳам наметавонанд ҳарду сессия гиранд.

---

## Он чи дар тарафи Raonson бояд навишта шавад

1. **Қабули deep link** `raonson://sso?code=…` (Android `intent-filter`).
2. Пас аз гирифтани код → `POST /sso/exchange` → токенҳоро нигоҳ доштан.
3. Тугмаи «Ба TajikShop гузаред»: `POST /sso/code {target_app:"tajikshop"}`
   → кушодани `deep_link`; агар барнома насб набошад → `fallback`.

### Мисоли Android `intent-filter`

```xml
<intent-filter android:autoVerify="false">
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="raonson" android:host="sso"/>
</intent-filter>
```

---

## Он чи ҳанӯз карда нашудааст

- **Қабули deep link дар худи TajikShop.** Ҳоло TajikShop кодро дода
  метавонад, вале коди воридшавандаро қабул намекунад — барои он плагини
  deep link (`app_links`) ва `intent-filter` лозим аст. То он вақт роҳ
  якҷониба аст: TajikShop → Raonson.
- **Ҳисобҳои ҷудогона дар Raonson.** Агар Raonson базаи худро дошта бошад,
  ҳангоми аввалин `exchange` бояд корбарро аз рӯи `user.id`-и TajikShop ба
  ҳисоби худаш пайваст кунад (ё ҳамон ҳисобро истифода барад).
