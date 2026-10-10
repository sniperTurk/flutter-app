"""Read-only App Store Connect dump (no writes)."""
import json, os, time, urllib.request, urllib.error
import jwt

kid, iss = os.environ["ASC_KEY_ID"], os.environ["ASC_ISSUER_ID"]
tok = jwt.encode({"iss": iss, "iat": int(time.time()), "exp": int(time.time()) + 1100,
                  "aud": "appstoreconnect-v1"}, os.environ["ASC_KEY_P8"], algorithm="ES256", headers={"kid": kid})
BASE = "https://api.appstoreconnect.apple.com"

def get(path):
    req = urllib.request.Request(BASE + path, headers={"Authorization": f"Bearer {tok}"})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        return {"_error": e.code, "_body": e.read().decode()[:800]}

APP = "6819483788"
out = {}
infos = get(f"/v1/apps/{APP}/appInfos")
info = infos["data"][0]["id"]
ar = get(f"/v1/appInfos/{info}/ageRatingDeclaration")
out["ageRating"] = ar.get("data", ar)
out["builds"] = [{"id": b["id"], **{k: b["attributes"].get(k) for k in ("version", "processingState", "uploadedDate")}}
                 for b in get(f"/v1/builds?filter[app]={APP}&sort=-uploadedDate&limit=3").get("data", [])]
pp = get(f"/v1/apps/{APP}/appPricePoints?filter[territory]=USA&limit=3")
out["pricePoints"] = [{"id": p["id"], **p["attributes"]} for p in pp.get("data", [])] if "data" in pp else pp
out["territories"] = len(get("/v1/territories?limit=200").get("data", []))
cats = get("/v1/appCategories?filter[platforms]=IOS&limit=50")
out["categories"] = [c["id"] for c in cats.get("data", [])]
os.makedirs("ci-logs", exist_ok=True)
json.dump(out, open("ci-logs/asc.json", "w"), indent=1, ensure_ascii=False)
