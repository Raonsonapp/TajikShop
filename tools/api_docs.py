#!/usr/bin/env python3
"""Санади API-ро аз `routes.go` МЕСОЗАД.

ЧАРО ХУДКОР, НА БО ДАСТ:

Санади бо даст навишташудаи 150 масир рӯзи дуюм кӯҳна мешавад. Касе
масир илова мекунад ва санадро фаромӯш мекунад — ва он гоҳ санад бадтар
аз набудан аст, чунки касе ба он бовар мекунад.

Ин скрипт манбаи ягона дорад: худи `routes.go`. Агар он бо санад мувофиқ
наояд, CI меафтад.

Истифода:
    python3 tools/api_docs.py            # санадро месозад
    python3 tools/api_docs.py --check    # мувофиқатро месанҷад (барои CI)
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROUTES = os.path.join(ROOT, "backend/internal/routes/routes.go")
OUT = os.path.join(ROOT, "docs/API.md")

# Гурӯҳбандӣ аз рӯи префикси масир — то санад хонданӣ бошад, на рӯйхати
# 150-сатра.
GROUPS = [
    ("auth", "Вуруд ва ҳисоб", ("/auth", "/users/me/password")),
    ("sso", "SSO бо Raonson", ("/sso",)),
    ("user", "Корбар ва профил", ("/users",)),
    ("seller", "Фурӯшанда", ("/seller",)),
    ("product", "Маҳсулот", ("/products", "/variants", "/brands", "/catalog")),
    ("review", "Баҳо ва савол", ("/reviews", "/questions")),
    ("cart", "Сабад ва фармоиш", ("/cart", "/orders")),
    ("payment", "Пардохт", ("/payments",)),
    ("rfq", "Дархости нарх (RFQ)", ("/rfqs", "/quotes")),
    ("supplier", "Таъминкунанда", ("/suppliers", "/shops")),
    ("other", "Дигар", ("/favorites", "/addresses", "/stories", "/messages",
                        "/notifications", "/wallet", "/coupons", "/cargo",
                        "/reports", "/categories", "/settings", "/verification")),
    ("admin", "Админ", ("/admin",)),
    ("public", "Оммавӣ (бе токен)", ("/privacy", "/terms", "/delete-account",
                                     "/account", "/health")),
]

ROUTE_RE = re.compile(
    r'\b(?:api|r)\.(GET|POST|PUT|PATCH|DELETE)\(\s*"([^"]+)"\s*,?\s*(.*?)\)\s*$',
    re.M)


def parse():
    src = open(ROUTES, encoding="utf-8").read()
    # Шарҳҳоро мебарорем, то масири шарҳдодашуда ҳисоб нашавад.
    src = re.sub(r"//[^\n]*", "", src)

    out = []
    for m in ROUTE_RE.finditer(src):
        method, path, rest = m.group(1), m.group(2), m.group(3)
        auth = []
        if "middleware.Auth()" in rest:
            auth.append("токен")
        if "middleware.AdminOnly()" in rest:
            auth.append("админ")
        if "middleware.SellerOnly()" in rest:
            auth.append("фурӯшанда")
        audited = "middleware.AuditAdmin()" in rest
        # Охирин аргумент — handler.
        handler = rest.split(",")[-1].strip() if rest else ""
        out.append({
            "method": method, "path": path,
            "auth": auth, "audited": audited, "handler": handler,
        })
    return out


def group_of(path):
    for key, _, prefixes in GROUPS:
        for p in prefixes:
            if path.startswith(p):
                return key
    return "other"


def render(routes):
    by = {k: [] for k, _, _ in GROUPS}
    for r in routes:
        by[group_of(r["path"])].append(r)

    lines = [
        "# API — TajikShop",
        "",
        "> ⚠️ Ин файл ХУДКОР сохта мешавад: `python3 tools/api_docs.py`",
        ">",
        "> Онро бо даст таҳрир накунед — манбаъ `backend/internal/routes/routes.go`",
        "> аст. CI мувофиқатро месанҷад, пас масири нав бе навкунии санад",
        "> намегузарад.",
        "",
        f"**Ҳамагӣ масирҳо:** {len(routes)}",
        "",
        "## Пояи суроға",
        "",
        "```",
        "https://mahmadmurodov-tajikshop.hf.space/api/v1",
        "```",
        "",
        "## Шакли ҷавоб",
        "",
        "Ҳамаи ҷавобҳо дар як пӯшиш:",
        "",
        "```json",
        '{ "success": true,  "data": ... }',
        '{ "success": false, "error": "матни хато" }',
        "```",
        "",
        "Хатои сохтор дошта (масалан ҳангоми сохтани фармоиш) майдонҳои",
        "иловагӣ дорад:",
        "",
        "```json",
        '{ "success": false, "error": "...", "issues": [',
        '  { "product_id": "...", "title": "...", "code": "not_enough",',
        '    "available": 3, "min_qty": 1 } ] }',
        "```",
        "",
        "## Сутуни «Иҷозат»",
        "",
        "| Нишона | Маъно |",
        "|---|---|",
        "| — | бе токен, оммавӣ |",
        "| токен | `Authorization: Bearer <access_token>` |",
        "| фурӯшанда | токен + фурӯшандаи ТАСДИҚШУДА (дар база санҷида мешавад) |",
        "| админ | токен + `role='admin'` |",
        "| 📝 | амал ба дафтари админ сабт мешавад |",
        "",
        "## Idempotency",
        "",
        "Ду масир такрорро бас мекунанд — зеркунии дукаратаи тугма ё",
        "такрори шабака ду фармоиш/пардохт намесозад:",
        "",
        "```",
        "POST /orders/checkout     Idempotency-Key: <калиди ягона>",
        "POST /payments/start      Idempotency-Key: <калиди ягона>",
        "```",
        "",
        "Калид бояд барои ҳар КӮШИШ як бор сохта шавад ва дар такрорҳо",
        "ҲАМОН монад. Агар он дар ҳар зеркунӣ нав шавад, муҳофизат маъно",
        "надорад.",
        "",
    ]

    for key, title, _ in GROUPS:
        rs = by[key]
        if not rs:
            continue
        lines += [f"## {title}", "", "| Метод | Масир | Иҷозат |", "|---|---|---|"]
        for r in sorted(rs, key=lambda x: (x["path"], x["method"])):
            auth = " + ".join(r["auth"]) if r["auth"] else "—"
            if r["audited"]:
                auth += " 📝"
            lines.append(f"| `{r['method']}` | `{r['path']}` | {auth} |")
        lines.append("")

    lines += [
        "## Он чизе, ки ин санад НАМЕГӮЯД",
        "",
        "Рӯирост, то касе ба он бештар аз лозим бовар накунад:",
        "",
        "- шакли дақиқи JSON-и ҳар масир (он аз код хонда мешавад);",
        "- маҳдудияти суръат (rate limit) — он ҳанӯз нопурра аст;",
        "- версиякунонии API — ҳоло танҳо `v1` ҳаст ва тағйири",
        "  мувофиқатшиканандаи расмӣ набуд.",
        "",
    ]
    return "\n".join(lines) + "\n"


def main():
    routes = parse()
    if len(routes) < 100:
        print(f"❌ танҳо {len(routes)} масир ёфт шуд — regex шояд вайрон аст")
        return 1
    text = render(routes)

    if "--check" in sys.argv:
        if not os.path.exists(OUT):
            print(f"❌ {OUT} нест — `python3 tools/api_docs.py` -ро иҷро кунед")
            return 1
        cur = open(OUT, encoding="utf-8").read()
        if cur != text:
            print("❌ docs/API.md бо routes.go мувофиқ намеояд.")
            print("   `python3 tools/api_docs.py` -ро иҷро кунед ва коммит кунед.")
            return 1
        print(f"✅ docs/API.md мувофиқ аст ({len(routes)} масир)")
        return 0

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    open(OUT, "w", encoding="utf-8").write(text)
    print(f"✅ {OUT} сохта шуд ({len(routes)} масир)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
