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


def attrs(items, keys):
    if "data" not in items:
        return items
    return [{"id": d["id"], **{k: d["attributes"].get(k) for k in keys}} for d in items["data"]]


out = {"apps": attrs(get("/v1/apps?limit=20"), ("name", "bundleId", "sku", "primaryLocale"))}
for app in ("6820670293", "6819483788"):
    a = {}
    a["versions"] = attrs(get(f"/v1/apps/{app}/appStoreVersions?limit=5"),
                          ("versionString", "platform", "appStoreState", "appVersionState", "releaseType", "createdDate"))
    subs = get(f"/v1/reviewSubmissions?filter[app]={app}&limit=10&include=items")
    a["reviewSubmissions"] = attrs(subs, ("state", "platform", "submittedDate"))
    if "included" in subs:
        a["submissionItems"] = [{"id": i["id"], "type": i["type"], **i.get("attributes", {})} for i in subs["included"]]
    a["builds"] = attrs(get(f"/v1/builds?filter[app]={app}&sort=-uploadedDate&limit=5"),
                        ("version", "processingState", "uploadedDate", "expired"))
    for v in a["versions"] if isinstance(a["versions"], list) else []:
        b = get(f"/v1/appStoreVersions/{v['id']}/build")
        v["build"] = (b.get("data") or {}).get("attributes", {}).get("version") if isinstance(b.get("data"), dict) else None
    out[app] = a
os.makedirs("ci-logs", exist_ok=True)
json.dump(out, open("ci-logs/asc.json", "w"), indent=1, ensure_ascii=False)
