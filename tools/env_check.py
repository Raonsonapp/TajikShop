#!/usr/bin/env python3
"""Ҳар тағйирёбандаи муҳити хондашуда дар `.env.example` бошад.

ЧАРО ИН ЛОЗИМ АСТ:

Тағйирёбандаи нав дар код пайдо мешавад, вале дар намуна не. Касе
барномаро ба сервери нав мегузорад, онро намедонад, ва бахше хомӯшона
кор намекунад — масалан push ё боркунии расм. Хато дар ҳеҷ ҷо намоён
намешавад.

Инчунин баръакс санҷида мешавад: калиди дар намуна буда, вале дар код
НАХОНДАШУДА. Чунин калид корбарро фиреб медиҳад — ӯ онро мегузорад ва
интизор аст, ки чизе иваз шавад.

Истифода:
    python3 tools/env_check.py
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EXAMPLE = os.path.join(ROOT, "backend/.env.example")

# Калидҳое, ки берун аз конфиг хонда мешаванд (push, тестҳо).
EXTRA_OK = {
    # `push.Init()` онро мустақиман мехонад.
    "FIREBASE_SERVICE_ACCOUNT",
    # Танҳо дар тестҳо.
    "TAJIKSHOP_TEST_DB_URL",
}


def keys_in_code():
    """Ҳамаи `os.Getenv("X")`, `getEnv("X", ...)`, `mustEnv("X")`."""
    found = set()
    pat = re.compile(r'(?:os\.Getenv|getEnv|mustEnv)\(\s*"([A-Z0-9_]+)"')
    for dirpath, _, names in os.walk(os.path.join(ROOT, "backend")):
        for n in names:
            if not n.endswith(".go") or n.endswith("_test.go"):
                continue
            p = os.path.join(dirpath, n)
            src = open(p, encoding="utf-8").read()
            found |= set(pat.findall(src))
    return found


def keys_in_example():
    """Ҳамаи `KEY=` дар намуна, аз ҷумла сатрҳои шарҳдодашуда."""
    if not os.path.exists(EXAMPLE):
        return None
    txt = open(EXAMPLE, encoding="utf-8").read()
    # `# KEY=` низ ҳисоб мешавад — он ихтиёрӣ будани калидро мегӯяд.
    return set(re.findall(r"^#?\s*([A-Z0-9_]+)=", txt, re.M))


def main():
    code = keys_in_code()
    example = keys_in_example()
    if example is None:
        print(f"❌ {EXAMPLE} нест")
        return 1

    problems = 0

    missing = sorted(code - example)
    if missing:
        problems += len(missing)
        print("❌ дар код хонда мешавад, вале дар `.env.example` НЕСТ:")
        for k in missing:
            print(f"     {k}")
        print("   → бе он касе барномаро ба сервери нав мегузорад ва бахше")
        print("     хомӯшона кор намекунад")

    unused = sorted(example - code - EXTRA_OK)
    if unused:
        problems += len(unused)
        print("❌ дар намуна ҳаст, вале дар код НАХОНДА мешавад:")
        for k in unused:
            print(f"     {k}")
        print("   → чунин калид корбарро фиреб медиҳад: ӯ онро мегузорад")
        print("     ва интизор аст, ки чизе иваз шавад")

    # Арзиши ҳақиқӣ дар намуна набошад.
    txt = open(EXAMPLE, encoding="utf-8").read()
    for m in re.finditer(r"^([A-Z0-9_]+)=(.+)$", txt, re.M):
        key, val = m.group(1), m.group(2).strip()
        looks_real = (
            len(val) > 24
            and not val.startswith(("<", "http", "postgres"))
            and "<" not in val
            and not val.startswith("#")
        )
        if looks_real:
            problems += 1
            print(f"❌ `{key}` дар намуна арзиши ҳақиқӣ дорад?")
            print("   → намуна ба git меафтад ва абадӣ дар таърих мемонад")

    print(f"env: дар код {len(code)}, дар намуна {len(example)}, "
          f"мушкилот {problems}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
