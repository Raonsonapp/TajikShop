#!/usr/bin/env python3
"""Муҳофиз аз `const`-и дорои даъвати усул.

    error • Methods can't be invoked in constant expressions
    error • Invalid constant value

ЧАРО ИН АБЗОР ҲАСТ

Ҳангоми локализатсия ман `'Матни тоҷикӣ'`-и аслиро ба
`AppL10n.of(context).something` иваз мекардам. Агар он матн дар
дохили `const` бошад — `const Text(...)`, ё `children: const [...]` —
ин хатои ТАРТИБ аст, на огоҳӣ. Flutter SDK дар ин муҳит нест, пас
ҳар хато 90 сонияи CI меарзид. Ман чунин хатоҳоро ШАШ бор ҷорӣ кардам.

Кӯшиши аввалини ман намудҳои виҷетро меҷуст (`const Text(`,
`const Row(`) — ва ду хатои охиринро НАГИРИФТ, зеро онҳо дар
`children: const [...]` буданд, на дар `const Widget(`.

Акнун ҷустуҷӯ аз тарафи ДИГАР меравад: ҳар даъвати усулро мегирем ва
ба ақиб мерафтем, то бубинем оё ягон қавси кушодаи атрофи он `const`
дорад. Ин ҳам `const X(`-ро мегирад, ҳам `const [`-ро, ҳам
`const {`-ро.

Иҷро: `python3 tools/const_guard.py`
"""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCAN = [os.path.join(ROOT, d) for d in ("lib", "test", "integration_test")]

OPEN, CLOSE = "([{", ")]}"

# Даъватҳое, ки дар `const` ҳеҷ гоҳ ҷоиз нестанд.
#
# `AppL10n.of(...)` сабаби асосист; `context.pal` ва `.of(context)`-и
# дигар ҳамон хатогиро медиҳанд.
CALL = re.compile(r"\b(?:AppL10n\.of|MediaQuery\.of|Theme\.of)\s*\(|"
                  r"\bcontext\.(?:pal|read|watch)\b|"
                  r"\bAppMotion\.(?:stagger|reduced)\s*\(")


def strip_noise(src):
    """Шарҳҳо ва сатрҳоро бо фосила иваз мекунад.

    Дарозӣ НИГОҲ ДОШТА мешавад, то ҷойгоҳҳо дуруст монанд — вагарна
    шумораи сатр дар гузориш хато мешавад.
    """
    out = []
    i, n = 0, len(src)
    while i < n:
        two = src[i:i + 2]
        if two == "//":
            j = src.find("\n", i)
            j = n if j < 0 else j
            out.append(" " * (j - i))
            i = j
        elif two == "/*":
            j = src.find("*/", i + 2)
            j = n if j < 0 else j + 2
            out.append("".join(c if c == "\n" else " " for c in src[i:j]))
            i = j
        elif src[i] in "'\"":
            q = src[i]
            # Сатри сеқавс.
            if src[i:i + 3] == q * 3:
                j = src.find(q * 3, i + 3)
                j = n if j < 0 else j + 3
            else:
                j = i + 1
                while j < n and src[j] != q:
                    if src[j] == "\\":
                        j += 1
                    elif src[j] == "\n":
                        break
                    j += 1
                j = min(j + 1, n)
            # Дохили сатр `$...` метавонад код бошад, вале `const`
            # дар он ҷо маъно надорад — пас онро низ мепӯшонем.
            out.append("".join(c if c == "\n" else " " for c in src[i:j]))
            i = j
        else:
            out.append(src[i])
            i += 1
    return "".join(out)


def const_before(src, pos):
    """Оё қавси кушодаи ҷойгоҳи `pos` бо `const` сар мешавад?"""
    before = src[max(0, pos - 80):pos].rstrip()
    # `const X(`, `const [`, `const {`, `const <Widget>[`
    return bool(re.search(r"\bconst\s*(?:[A-Za-z_]\w*(?:\.\w+)?)?"
                          r"\s*(?:<[^<>]*>)?\s*$", before))


def check(path):
    src = strip_noise(open(path, encoding="utf-8").read())
    # Барои ҳар ҷойгоҳ стеки қавсҳои кушодаро нигоҳ медорем.
    stack = []
    opens = {}            # pos -> стеки ҳамон лаҳза
    for i, ch in enumerate(src):
        if ch in OPEN:
            stack.append(i)
        elif ch in CLOSE and stack:
            stack.pop()
        opens[i] = tuple(stack)

    bad = []
    for m in CALL.finditer(src):
        for p in opens.get(m.start(), ()):
            if const_before(src, p):
                line = src[:m.start()].count("\n") + 1
                bad.append((line, m.group(0).strip(),
                            src[:p].count("\n") + 1))
                break
    return bad


def main():
    problems = 0
    files = 0
    for root in SCAN:
        if not os.path.isdir(root):
            continue
        for dp, _, fn in os.walk(root):
            for n in fn:
                if not n.endswith(".dart"):
                    continue
                p = os.path.join(dp, n)
                files += 1
                for line, call, cline in check(p):
                    rel = os.path.relpath(p, ROOT)
                    print(f"❌ {rel}:{line} — `{call}` дар `const`-и "
                          f"сатри {cline}")
                    problems += 1
    print(f"const: {files} файл, мушкилот {problems}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
