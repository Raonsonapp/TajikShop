"""Ҳар рамзи маҳаллии истифодашуда бояд аз рӯи import-ҳо дастрас бошад.

Ду синфи хатои воқеӣ, ки CI пештар гирифт:
  • `xProvider` бе import (categoriesProvider);
  • `l.<name>`-и l10n бе import-и extension.
"""
import os, re, sys
ROOT = "/home/user/TajikShop"; LIB = os.path.join(ROOT, "lib")

def strip_comments(src):
    """Шарҳҳоро мебарорад — номи дар шарҳ зикршуда истифода нест."""
    src = re.sub(r"/\*.*?\*/", "", src, flags=re.S)
    return re.sub(r"//[^\n]*", "", src)

# ⚠️ На танҳо `lib/`: хатои `MissingPluginException` маҳз дар
# `integration_test/` буд ва муҳофиз онро умуман намедид.
SCAN_DIRS = [LIB, os.path.join(ROOT, "test"), os.path.join(ROOT, "integration_test")]

files, decl_prov, decl_l10n = {}, {}, {}
for _root in SCAN_DIRS:
  if not os.path.isdir(_root):
    continue
  for dp, _, ns in os.walk(_root):
      for n in ns:
          if not n.endswith(".dart"): continue
          p = os.path.join(dp, n); s = open(p, encoding="utf-8").read(); files[p] = s
          for m in re.finditer(r"^\s*(?:final|const)\s+(?:\w[\w<>,\s?]*\s+)?(\w*[Pp]rovider\w*)\s*=", s, re.M):
              decl_prov.setdefault(m.group(1), set()).add(p)
          for m in re.finditer(r"^\s*(?:String|int|double|bool|List<[^>]+>)\s+(?:get\s+)?(\w+)\s*(?:=>|\()", s, re.M):
              decl_l10n.setdefault(m.group(1), set()).add(p)


def res(cur, imp):
    if imp.startswith("package:tajikshop/"):
        return os.path.normpath(os.path.join(LIB, imp[len("package:tajikshop/"):]))
    if imp.startswith(("package:", "dart:")): return None
    return os.path.normpath(os.path.join(os.path.dirname(cur), imp))

bad = 0
for p, s in files.items():
    imports = {p}
    for m in re.finditer(r"""^\s*(?:import|export)\s+['"]([^'"]+)['"]""", s, re.M):
        r = res(p, m.group(1))
        if r: imports.add(r)
    for i in list(imports):                       # export-ҳои як зина
        t = files.get(i)
        if not t: continue
        for m in re.finditer(r"""^\s*export\s+['"]([^'"]+)['"]""", t, re.M):
            r = res(i, m.group(1))
            if r: imports.add(r)
    code = strip_comments(s)
    for m in re.finditer(r"\b(\w*[a-z]Provider)\b", code):
        n = m.group(1)
        if n in decl_prov and not (decl_prov[n] & imports):
            print(f"{p}: `{n}` бе import (дар {sorted(decl_prov[n])[0]})"); bad += 1
    for m in re.finditer(r"\bl\.(\w+)\b", code):
        n = m.group(1)
        if n in decl_l10n and not (decl_l10n[n] & imports):
            print(f"{p}: `l.{n}` бе import (дар {sorted(decl_l10n[n])[0]})"); bad += 1

# Номҳое, ки китобхонаи муайянро талаб мекунанд.
#
# `material.dart` онҳоро содир НАМЕКУНАД, вале `dart format` инро
# намебинад — синтаксис дуруст аст, танҳо ном номуайян. Маҳз ҳамин хато
# билди release-ро шикаст (`MissingPluginException`).
REQUIRED_IMPORTS = {
    "package:flutter/services.dart": [
        "MissingPluginException", "PlatformException", "MethodChannel",
        "Clipboard", "ClipboardData", "HapticFeedback", "SystemChrome",
        "SystemUiOverlayStyle", "DeviceOrientation", "TextInputFormatter",
        "FilteringTextInputFormatter", "LengthLimitingTextInputFormatter",
        "rootBundle",
    ],
    "dart:math": ["Random", "pi", "sqrt", "atan2", "min(", "max("],
    "dart:convert": ["jsonEncode", "jsonDecode", "utf8", "base64Url", "base64Encode"],
    "dart:io": ["File(", "Directory(", "Platform.", "SocketException"],
    "dart:async": [
        "StreamController", "Completer", "Timer(",
        # `runZonedGuarded` барои доштани хатоҳои async-и плагинҳои сеюм
        # лозим аст — бе import он ном номуайян аст.
        "runZonedGuarded", "runZoned", "unawaited(", "scheduleMicrotask",
    ],
}

# Номҳое, ки аз якчанд ҷо омада метавонанд — муҳофиз онҳоро намесанҷад,
# то хабари бардурӯғ надиҳад.
AMBIGUOUS = {
    # `min`/`max` метавонанд усули синфи худӣ бошанд.
    "min(", "max(",
    # `Timer` дар `flutter/scheduler.dart` ҳам ҳаст.
    "Timer(",
}

for p, s in files.items():
    code = strip_comments(s)
    for lib, names in REQUIRED_IMPORTS.items():
        if lib in s:
            continue
        # `dart:io` ва `dart:math` метавонанд тавассути `export` оянд.
        for name in names:
            if name in AMBIGUOUS:
                continue
            # `(?<![\w.$])` ҳатмист: бе он `MultipartFile.fromFile(` ба
            # `File(` мувофиқ меомад ва муҳофиз хабари бардурӯғ медод.
            pat = r"(?<![\w.$])" + re.escape(name)
            if not name[-1].isalnum():
                pass  # `File(` — ҳамчунон охираш `(` аст, қавс кифоя
            else:
                pat += r"\b"
            if re.search(pat, code):
                print(f"{p}: `{name}` бе import-и '{lib}'")
                bad += 1
                break

print(f"checked={len(files)} problems={bad}")
sys.exit(1 if bad else 0)
