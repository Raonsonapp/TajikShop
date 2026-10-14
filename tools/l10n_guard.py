#!/usr/bin/env python3
"""Муҳофиз аз номҳои такрории `extension ... on AppL10n`.

ЧАРО ИН АБЗОР ҲАСТ

Ман матнҳои нави расониданро илова кардам ва `deliveryTime` номидам.
Ҳамон ном аллакай дар `ProfileL10n` буд, ва Dart хатои ТАРТИБ дод:

    error • A member named 'deliveryTime' is defined in
    'extension CheckoutL10n on AppL10n' and
    'extension DeliveryL10n on AppL10n', and neither is more specific

Ин хато билдро мешиканад, вале дар ин муҳит Flutter SDK нест — пас он
танҳо баъди 90 сонияи CI маълум мешуд. Ҳоло дар як сония маълум
мешавад.

МУҲИМ: такрор танҳо вақте хато аст, ки ду `extension` ДАР ЯК файл
import шаванд. Вале санҷидани он мураккабтар аст, ва ҳар такрор
барои хонанда ҳам нофаҳмист — пас ҳар такрор хато ҳисоб мешавад.

Иҷро: `python3 tools/l10n_guard.py`
"""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
L10N_DIRS = [
    os.path.join(ROOT, "lib", "core", "l10n"),
    os.path.join(ROOT, "lib", "core"),
]

# `String get name =>`  ё  `String name(` ё `List<String> get name =>`
MEMBER = re.compile(
    r"^\s*(?:String|int|bool|double|List<String>|Map<String\?, String>)\s+"
    r"(?:get\s+)?([a-zA-Z_]\w*)\s*(?:=>|\(|\{)"
)
EXT = re.compile(r"^\s*extension\s+(\w+)\s+on\s+AppL10n\b")
CLS = re.compile(r"^\s*class\s+AppL10n\b")


def scan(path):
    """Номҳои аъзо дар `extension ... on AppL10n` ё худи `class AppL10n`."""
    out = {}
    scope = None
    for i, line in enumerate(open(path, encoding="utf-8"), 1):
        if EXT.match(line):
            scope = EXT.match(line).group(1)
            continue
        if CLS.match(line):
            scope = "AppL10n"
            continue
        if scope is None:
            continue
        m = MEMBER.match(line)
        if not m:
            continue
        name = m.group(1)
        # Усулҳои хусусӣ (`_sp`, `_dl`) бо ҳам бархӯрд намекунанд.
        if name.startswith("_"):
            continue
        out[name] = (scope, i)
    return out


def main():
    seen = {}      # name -> [(scope, file, line), ...]
    files = set()
    for d in L10N_DIRS:
        if not os.path.isdir(d):
            continue
        for dp, _, fn in os.walk(d):
            for n in fn:
                if n.endswith(".dart"):
                    files.add(os.path.join(dp, n))

    for p in sorted(files):
        for name, (scope, line) in scan(p).items():
            seen.setdefault(name, []).append(
                (scope, os.path.relpath(p, ROOT), line))

    dupes = {k: v for k, v in seen.items() if len(v) > 1}
    for name, places in sorted(dupes.items()):
        print(f"❌ «{name}» дар {len(places)} ҷо:")
        for scope, f, line in places:
            print(f"     {scope:22s} {f}:{line}")

    total = sum(len(scan(p)) for p in files)
    print(f"l10n: {len(files)} файл, {total} матн, такрор {len(dupes)}")
    return 1 if dupes else 0


if __name__ == "__main__":
    sys.exit(main())
