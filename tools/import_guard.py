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

files, decl_prov, decl_l10n = {}, {}, {}
for dp, _, ns in os.walk(LIB):
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

print(f"checked={len(files)} problems={bad}")
sys.exit(1 if bad else 0)
