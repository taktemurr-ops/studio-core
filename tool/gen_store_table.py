#!/usr/bin/env python3
"""tool/stores.json -> lib/app/services/store_table.dart (elle düzenlemeyin).

Kullanım: python3 tool/gen_store_table.py   (test/store_backend_test.dart
üretilmiş dosyanın JSON ile aynı olduğunu denetler.)
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADS = {"admob": "AdProvider.admob", "petal": "AdProvider.petal", "none": "AdProvider.none"}


def camel(s):
    p = s.split("_")
    return p[0] + "".join(x.title() for x in p[1:])


def render():
    t = json.load(open(os.path.join(ROOT, "tool", "stores.json"), encoding="utf-8"))
    out = [
        "// ÜRETİLDİ: tool/gen_store_table.py, kaynak tool/stores.json. Elle düzenlemeyin.",
        "part of 'store_backend.dart';",
        "",
        "/// Mağaza kimlikleri (`--dart-define=STORE=<id>`).",
        "enum StoreKind { %s }" % ", ".join(s["id"] for s in t["stores"]),
        "",
        "/// Uygulama içi satın alma sağlayıcısı.",
        "enum IapProvider { %s }" % ", ".join(sorted({camel(s["iap"]) for s in t["stores"]})),
        "",
        "const Map<StoreKind, StoreSpec> storeTable = {",
    ]
    for s in t["stores"]:
        out.append(
            "  StoreKind.%s: StoreSpec(kind: StoreKind.%s, name: %s, ads: %s, iap: IapProvider.%s, gms: %s, "
            "storePage: %s, artifactSuffix: %s, plugin: %s),"
            % (s["id"], s["id"], json.dumps(s["name"]), ADS[s["ads"]], camel(s["iap"]),
               "true" if s["gms"] else "false", json.dumps(s["store_page"]).replace("$", "\\$"),
               json.dumps(s["artifact_suffix"]), json.dumps(s["plugin"]["package"]) if s["plugin"] else "null")
        )
    out.append("};")
    return "\n".join(out) + "\n"


if __name__ == "__main__":
    p = os.path.join(ROOT, "lib", "app", "services", "store_table.dart")
    open(p, "w", encoding="utf-8").write(render())
    print("yazıldı:", p)
