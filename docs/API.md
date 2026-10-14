# API — TajikShop

> ⚠️ Ин файл ХУДКОР сохта мешавад: `python3 tools/api_docs.py`
>
> Онро бо даст таҳрир накунед — манбаъ `backend/internal/routes/routes.go`
> аст. CI мувофиқатро месанҷад, пас масири нав бе навкунии санад
> намегузарад.

**Ҳамагӣ масирҳо:** 152

## Пояи суроға

```
https://mahmadmurodov-tajikshop.hf.space/api/v1
```

## Шакли ҷавоб

Ҳамаи ҷавобҳо дар як пӯшиш:

```json
{ "success": true,  "data": ... }
{ "success": false, "error": "матни хато" }
```

Хатои сохтор дошта (масалан ҳангоми сохтани фармоиш) майдонҳои
иловагӣ дорад:

```json
{ "success": false, "error": "...", "issues": [
  { "product_id": "...", "title": "...", "code": "not_enough",
    "available": 3, "min_qty": 1 } ] }
```

## Сутуни «Иҷозат»

| Нишона | Маъно |
|---|---|
| — | бе токен, оммавӣ |
| токен | `Authorization: Bearer <access_token>` |
| фурӯшанда | токен + фурӯшандаи ТАСДИҚШУДА (дар база санҷида мешавад) |
| админ | токен + `role='admin'` |
| 📝 | амал ба дафтари админ сабт мешавад |

## Idempotency

Ду масир такрорро бас мекунанд — зеркунии дукаратаи тугма ё
такрори шабака ду фармоиш/пардохт намесозад:

```
POST /orders/checkout     Idempotency-Key: <калиди ягона>
POST /payments/start      Idempotency-Key: <калиди ягона>
```

Калид бояд барои ҳар КӮШИШ як бор сохта шавад ва дар такрорҳо
ҲАМОН монад. Агар он дар ҳар зеркунӣ нав шавад, муҳофизат маъно
надорад.

## Вуруд ва ҳисоб

| Метод | Масир | Иҷозат |
|---|---|---|
| `POST` | `/auth/login` | — |
| `POST` | `/auth/logout` | — |
| `POST` | `/auth/phone-verify` | — |
| `POST` | `/auth/refresh` | — |
| `POST` | `/auth/register` | — |
| `PUT` | `/users/me/password` | токен |

## SSO бо Raonson

| Метод | Масир | Иҷозат |
|---|---|---|
| `GET` | `/sso/apps` | — |
| `POST` | `/sso/code` | токен |
| `POST` | `/sso/exchange` | — |

## Корбар ва профил

| Метод | Масир | Иҷозат |
|---|---|---|
| `DELETE` | `/users/:id/follow` | токен |
| `POST` | `/users/:id/follow` | токен |
| `GET` | `/users/:id/followers` | токен |
| `GET` | `/users/:id/public` | — |
| `GET` | `/users/:id/rating` | — |
| `DELETE` | `/users/me` | токен |
| `GET` | `/users/me` | токен |
| `PUT` | `/users/me` | токен |
| `POST` | `/users/me/avatar` | токен |
| `POST` | `/users/me/become-seller` | токен |
| `POST` | `/users/me/fcm-token` | токен |
| `PUT` | `/users/me/location` | токен |
| `GET` | `/users/me/loyalty` | токен |
| `GET` | `/users/me/referral` | токен |
| `POST` | `/users/me/seller-verify` | токен |
| `PUT` | `/users/me/username` | токен |
| `GET` | `/users/me/verification` | токен |
| `POST` | `/users/me/verification` | токен |
| `GET` | `/users/username-available` | — |

## Фурӯшанда

| Метод | Масир | Иҷозат |
|---|---|---|
| `GET` | `/seller/orders` | токен + фурӯшанда |
| `POST` | `/seller/orders/:id/status` | токен + фурӯшанда |
| `POST` | `/seller/payments/confirm-sms` | токен + фурӯшанда |
| `GET` | `/seller/products/expiring` | токен + фурӯшанда |
| `GET` | `/seller/products/sold-out` | токен + фурӯшанда |
| `GET` | `/seller/sales-chart` | токен + фурӯшанда |
| `GET` | `/seller/stats` | токен |

## Маҳсулот

| Метод | Масир | Иҷозат |
|---|---|---|
| `GET` | `/brands` | — |
| `POST` | `/catalog/barcode` | токен + фурӯшанда |
| `GET` | `/catalog/barcode/:code` | — |
| `GET` | `/products` | — |
| `POST` | `/products` | токен + фурӯшанда |
| `DELETE` | `/products/:id` | токен + фурӯшанда |
| `GET` | `/products/:id` | — |
| `PUT` | `/products/:id` | токен + фурӯшанда |
| `POST` | `/products/:id/boost` | токен + фурӯшанда |
| `POST` | `/products/:id/images` | токен + фурӯшанда |
| `GET` | `/products/:id/questions` | — |
| `POST` | `/products/:id/questions` | токен |
| `POST` | `/products/:id/restock` | токен + фурӯшанда |
| `GET` | `/products/:id/tiers` | — |
| `PUT` | `/products/:id/tiers` | токен + фурӯшанда |
| `GET` | `/products/:id/variants` | — |
| `POST` | `/products/:id/variants` | токен + фурӯшанда |
| `GET` | `/products/barcode/:code` | — |
| `GET` | `/products/bestsellers` | — |
| `GET` | `/products/deals` | — |
| `GET` | `/products/flash` | — |
| `GET` | `/products/trending` | — |
| `DELETE` | `/variants/:id` | токен + фурӯшанда |

## Баҳо ва савол

| Метод | Масир | Иҷозат |
|---|---|---|
| `POST` | `/questions/:id/answer` | токен |
| `POST` | `/reviews` | токен |
| `POST` | `/reviews/:id/helpful` | токен |
| `GET` | `/reviews/product/:product_id` | — |
| `POST` | `/reviews/upload` | токен |

## Сабад ва фармоиш

| Метод | Масир | Иҷозат |
|---|---|---|
| `GET` | `/cart` | токен |
| `POST` | `/cart` | токен |
| `DELETE` | `/cart/:id` | токен |
| `PATCH` | `/cart/:id` | токен |
| `GET` | `/cart/sellers` | токен |
| `GET` | `/orders` | токен |
| `GET` | `/orders/:id` | токен |
| `POST` | `/orders/:id/cancel` | токен |
| `POST` | `/orders/:id/confirm` | токен |
| `POST` | `/orders/:id/payment-proof` | токен |
| `POST` | `/orders/:id/rate-seller` | токен |
| `GET` | `/orders/:id/return` | токен |
| `POST` | `/orders/:id/return` | токен |
| `GET` | `/orders/:id/timeline` | токен |
| `POST` | `/orders/checkout` | токен |

## Пардохт

| Метод | Масир | Иҷозат |
|---|---|---|
| `GET` | `/payments/:order_id/status` | токен |
| `POST` | `/payments/start` | токен |
| `POST` | `/payments/webhook/:provider` | — |

## Дархости нарх (RFQ)

| Метод | Масир | Иҷозат |
|---|---|---|
| `POST` | `/quotes/:id/accept` | токен |
| `POST` | `/quotes/:id/withdraw` | токен + фурӯшанда |
| `POST` | `/rfqs` | токен |
| `GET` | `/rfqs/:id` | токен |
| `POST` | `/rfqs/:id/close` | токен |
| `POST` | `/rfqs/:id/quotes` | токен + фурӯшанда |
| `GET` | `/rfqs/my` | токен |
| `GET` | `/rfqs/open` | токен + фурӯшанда |

## Таъминкунанда

| Метод | Масир | Иҷозат |
|---|---|---|
| `GET` | `/shops` | — |
| `GET` | `/suppliers` | — |
| `GET` | `/suppliers/:id` | — |

## Дигар

| Метод | Масир | Иҷозат |
|---|---|---|
| `GET` | `/addresses` | токен |
| `POST` | `/addresses` | токен |
| `DELETE` | `/addresses/:id` | токен |
| `PATCH` | `/addresses/:id/default` | токен |
| `GET` | `/cargo` | токен |
| `POST` | `/cargo` | токен |
| `GET` | `/cargo/info` | — |
| `GET` | `/categories` | — |
| `GET` | `/coupons/active` | токен |
| `GET` | `/coupons/validate` | токен |
| `GET` | `/favorites` | токен |
| `POST` | `/favorites` | токен |
| `DELETE` | `/favorites/:product_id` | токен |
| `GET` | `/messages` | токен |
| `POST` | `/messages` | токен |
| `GET` | `/messages/:user_id` | токен |
| `GET` | `/notifications` | токен |
| `POST` | `/notifications/read-all` | токен |
| `POST` | `/reports` | токен |
| `GET` | `/settings` | — |
| `POST` | `/stories` | токен |
| `GET` | `/stories/discover` | — |
| `GET` | `/stories/feed` | токен |
| `GET` | `/verification/info` | — |
| `GET` | `/wallet` | токен |
| `POST` | `/wallet/topup` | токен |

## Админ

| Метод | Масир | Иҷозат |
|---|---|---|
| `GET` | `/admin/audit` | токен + админ |
| `POST` | `/admin/brands` | токен + админ 📝 |
| `GET` | `/admin/cargo` | токен + админ 📝 |
| `PATCH` | `/admin/cargo/:id` | токен + админ 📝 |
| `POST` | `/admin/cargo/settings` | токен + админ 📝 |
| `POST` | `/admin/categories` | токен + админ 📝 |
| `GET` | `/admin/coupons` | токен + админ 📝 |
| `POST` | `/admin/coupons` | токен + админ 📝 |
| `GET` | `/admin/orders` | токен + админ 📝 |
| `PATCH` | `/admin/orders/:id/status` | токен + админ 📝 |
| `DELETE` | `/admin/products/:id` | токен + админ 📝 |
| `GET` | `/admin/reports` | токен + админ 📝 |
| `POST` | `/admin/reports/:id/resolve` | токен + админ 📝 |
| `GET` | `/admin/returns` | токен + админ 📝 |
| `POST` | `/admin/returns/:id/status` | токен + админ 📝 |
| `GET` | `/admin/seller-requests` | токен + админ 📝 |
| `POST` | `/admin/settings/cashback` | токен + админ 📝 |
| `POST` | `/admin/settings/commission` | токен + админ 📝 |
| `GET` | `/admin/stats` | токен + админ 📝 |
| `GET` | `/admin/users` | токен + админ 📝 |
| `GET` | `/admin/users/:id/audit` | токен + админ |
| `POST` | `/admin/users/:id/ban` | токен + админ 📝 |
| `POST` | `/admin/users/:id/reject-seller` | токен + админ 📝 |
| `POST` | `/admin/users/:id/unban` | токен + админ 📝 |
| `POST` | `/admin/users/:id/verify-seller` | токен + админ 📝 |
| `GET` | `/admin/verification-requests` | токен + админ 📝 |
| `POST` | `/admin/verification-requests/:id/decide` | токен + админ 📝 |
| `GET` | `/admin/wallet/pending` | токен + админ 📝 |
| `POST` | `/admin/wallet/tx/:id/approve` | токен + админ 📝 |
| `POST` | `/admin/wallet/tx/:id/reject` | токен + админ 📝 |

## Оммавӣ (бе токен)

| Метод | Масир | Иҷозат |
|---|---|---|
| `POST` | `/account/deletion-request` | — |
| `GET` | `/delete-account` | — |
| `GET` | `/privacy` | — |
| `GET` | `/terms` | — |

## Он чизе, ки ин санад НАМЕГӮЯД

Рӯирост, то касе ба он бештар аз лозим бовар накунад:

- шакли дақиқи JSON-и ҳар масир (он аз код хонда мешавад);
- маҳдудияти суръат (rate limit) — он ҳанӯз нопурра аст;
- версиякунонии API — ҳоло танҳо `v1` ҳаст ва тағйири
  мувофиқатшиканандаи расмӣ набуд.

