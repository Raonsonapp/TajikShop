# SSO — як ҳисоб барои Raonson ва TajikShop

Корбар дар як барнома ворид мешавад ва бе парол ба барномаи дигар мегузарад —
мисли Instagram / Facebook / WhatsApp, ки як ҳисоб доранд.

Ҳоло TajikShop **провайдери шахсият** (identity provider) аст: ҳисобҳо дар
базаи он мемонанд. Raonson ҳамон корбарро бе бақайдгирии нав мегирад.

Base URL: `https://mahmadmurodov-tajikshop.hf.space/api/v1`

## Он чи дар Raonson гузоштан лозим аст

| Танзим | Қимат |
|---|---|
| `TAJIKSHOP_API` | `https://mahmadmurodov-tajikshop.hf.space/api/v1` |
| `TAJIKSHOP_PARTNER_KEY` | **махфӣ** — ҳамон калид, ки дар Space гузошта шудааст |
| Схемаи худи Raonson | `raonson://sso?code=…` |

Калид дар ҳарду ҷо як хел бошад:

1. Дар Hugging Face Space → Settings → **Repository secrets** →
   `SSO_PARTNER_KEY`
2. Дар Raonson → ҳамон калид ҳамчун махфӣ (на дар код, на дар git)

Пас аз гузоштани калид, Raonson ҳангоми `POST /sso/exchange` онро дар
сарлавҳа мефиристад:

```
X-Partner-Key: <калид>
```

⚠️ То он даме ки `SSO_PARTNER_KEY` дар Space гузошта нашавад, сервер
кодро **бе калид** ҳам иваз мекунад (то SSO дар рӯзи аввал нашиканад) ва
дар лог огоҳӣ менависад. Калидро ҳатман гузоред: бе он ҳар кас, ки ягон
тавр кодро ба даст овард, сессия мегирад.

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
→ POST /sso/exchange
  X-Partner-Key: <калид>
  { "code": "dX7…_kQ", "app": "raonson" }

← { "success": true, "data": {
      "access_token":  "…",   // 24 соат
      "refresh_token": "…",   // 30 рӯз
      "user": { "id": "…", "name": "…", "email": "…", "role": "…",
                "avatar_url": "…", "is_seller": false, "is_verified": false,
                "email_verified": false }
  }}
```

- `is_verified` — галочкаи **фурӯшанда** (KYC/пардохт), **на** почта.
- `email_verified` — `true` танҳо агар TajikShop почтаро воқеан тасдиқ карда
  бошад. Ҳоло TajikShop ҷараёни тасдиқи почта **надорад** (на OTP, на линк;
  танҳо телефон тавассути Firebase тасдиқ мешавад), пас ин **ҳамеша
  `false`** аст. Шарик набояд ҳисоби мавҷударо танҳо аз рӯи почта пайваст
  кунад, вақте ки `email_verified=false`.
- `refresh_token` — сессияи **алоҳидаи** шарик (`client=raonson`). Он
  сессияи худи барномаи TajikShop-и корбарро намекушад ва баръакс.

Хатогиҳо: `401 "Код нодуруст ё мӯҳлаташ гузашт"`, `401 "Калиди шарик
нодуруст"`, `400 "Барномаи номаълум"`.

Токенҳоро мисли вуруди оддӣ нигоҳ доред ва пас аз 401 бо
`POST /auth/refresh {refresh_token}` нав кунед.

## 4. Сессияҳо ва `POST /auth/refresh`

Ҳар вуруд (барнома дар ҳар дастгоҳ, ҳар `/sso/exchange`) сатри худро дар
`auth_sessions` дорад (`client`: `app`, `raonson`, …). Вуруди нав ё exchange
дигар сессияҳоро **намекушад**.

```json
→ POST /auth/refresh { "refresh_token": "…" }
← { "success": true, "data": { "access_token": "…", "refresh_token": "…нав…" } }
```

- **Ротатсия:** ҳар навсозӣ `refresh_token`-и НАВ медиҳад — онро нигоҳ
  доред. Токени қаблӣ то он даме қабул мешавад, ки мизоҷ токени навро
  истифода барад (барои барномаҳои кӯҳна ва дархостҳои баробар); пас аз он
  мемирад. Токени аз ин ҳам кӯҳнатар → `401`.
- `POST /auth/logout {refresh_token}` — танҳо ҳамон сессия баста мешавад.
- Ивази парол (`PUT /users/me/password`), ҳазфи ҳисоб ва бан **ҳамаи**
  сессияҳоро мебанданд (Raonson ҳам `401` мегирад ва бояд аз нав пайваст
  кунад).
- `access_token` (24 соат) бе ҳолат аст — пас аз бастани сессия то
  анҷоми мӯҳлаташ кор мекунад.
- Мутобиқат: токени кӯҳнае, ки дар `users.refresh_token` буд, ҳангоми
  аввалин `/auth/refresh` ба сессияи `client=app` мегузарад (мӯҳлаташ ҳамон
  мемонад) — ҳеҷ корбар берун намешавад.

## 5. «Бо TajikShop ворид шавед» (як тугма аз Raonson)

```
Raonson                                  TajikShop (барнома)
  │ state = тасодуфӣ (≥ 8 аломат, [A-Za-z0-9._~-]), нигоҳ доред
  ├─ мекушояд: tajikshop://sso/authorize?app=raonson&state=<state> ─►
  │                                        │ ворид нест → вуруд → идома
  │                                        │ app дар /sso/apps санҷида мешавад
  │                                        │ «Ба Raonson ҳамчун <ном> идома медиҳед?»
  │                                        ├─ POST /sso/code {target_app:"raonson"}
  │ ◄── raonson://sso?code=<code>&state=<state> ──────────────────┘
  ├─ state-ро бо нигоҳдошта муқоиса кунед (якдафъаина)
  └─ POST /sso/exchange (ҳамон ҷараёни 3)
```

`state` бе тағйир баргардонида мешавад. Линки бо `app`-и номаълум, бо
`app=tajikshop` ё бо `state`-и шубҳанок (фосила, `&`, кӯтоҳтар аз 8)
нодида гирифта мешавад. Агар корбар «Бекор» пахш кунад, TajikShop Raonson-ро
намекушояд.

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

## Ҳолат

Ҳарду тараф тайёранд: TajikShop ҳам код медиҳад, ҳам коди воридшавандаро
қабул мекунад (`tajikshop://sso?code=…`, `app_links` + `intent-filter`).

Боқӣ дар тарафи Raonson:

- **Ҳисобҳои ҷудогона.** Агар Raonson базаи худро дошта бошад, ҳангоми
  аввалин `exchange` бояд корбарро аз рӯи `user.id`-и TajikShop ба ҳисоби
  худаш пайваст кунад (ё ҳамон ҳисобро истифода барад).
- **Чати пардохт.** Агар хоҳед, ки пардохт тавассути чати Raonson гузарад,
  схемаи чати Raonson лозим аст (масалан `raonson://chat?user=<id>`) — онро
  гӯед, ман тугмаашро дар TajikShop мегузорам.
