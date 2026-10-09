"""Read-only App Store Connect status dump (no writes)."""
import json, os, time, urllib.request, urllib.error
import jwt

kid, iss = os.environ["ASC_KEY_ID"], os.environ["ASC_ISSUER_ID"]
key = os.environ["ASC_KEY_P8"]
tok = jwt.encode({"iss": iss, "iat": int(time.time()), "exp": int(time.time()) + 1100,
                  "aud": "appstoreconnect-v1"}, key, algorithm="ES256", headers={"kid": kid})
BASE = "https://api.appstoreconnect.apple.com"

def get(path):
    req = urllib.request.Request(BASE + path, headers={"Authorization": f"Bearer {tok}"})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        return {"_error": e.code, "_body": e.read().decode()[:500]}

out = {}
apps = get("/v1/apps?filter[bundleId]=com.sniperturk.sniperTurk")
out["apps"] = [{"id": a["id"], **{k: a["attributes"].get(k) for k in ("name", "bundleId", "sku", "primaryLocale", "contentRightsDeclaration")}} for a in apps.get("data", [])]
if apps.get("data"):
    app = apps["data"][0]["id"]
    vers = get(f"/v1/apps/{app}/appStoreVersions?limit=5")
    out["versions"] = []
    for v in vers.get("data", []):
        vid = v["id"]
        entry = {"id": vid, **{k: v["attributes"].get(k) for k in ("versionString", "appStoreState", "appVersionState", "releaseType", "copyright", "platform")}}
        b = get(f"/v1/appStoreVersions/{vid}/build")
        entry["build"] = (b.get("data") or {}).get("attributes", {}).get("version") if isinstance(b.get("data"), dict) else None
        locs = get(f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations")
        entry["localizations"] = []
        for l in locs.get("data", []):
            at = l["attributes"]
            sets = get(f"/v1/appStoreVersionLocalizations/{l['id']}/appScreenshotSets?include=appScreenshots")
            entry["localizations"].append({
                "locale": at.get("locale"),
                "descriptionLen": len(at.get("description") or ""),
                "keywords": at.get("keywords"), "supportUrl": at.get("supportUrl"),
                "marketingUrl": at.get("marketingUrl"), "promotionalText": at.get("promotionalText"),
                "whatsNew": at.get("whatsNew"),
                "screenshotSets": [{"type": s["attributes"].get("screenshotDisplayType"),
                                     "count": len((s.get("relationships", {}).get("appScreenshots", {}) or {}).get("data", []) or [])}
                                    for s in sets.get("data", [])],
            })
        rd = get(f"/v1/appStoreVersions/{vid}/appStoreReviewDetail")
        entry["reviewDetail"] = (rd.get("data") or {}).get("attributes") if isinstance(rd.get("data"), dict) else rd.get("_error")
        if isinstance(entry["reviewDetail"], dict):
            entry["reviewDetail"] = {k: bool(v) for k, v in entry["reviewDetail"].items()}
        out["versions"].append(entry)
    infos = get(f"/v1/apps/{app}/appInfos?include=primaryCategory,ageRatingDeclaration")
    out["appInfos"] = []
    for i in infos.get("data", []):
        e = {"id": i["id"], "state": i["attributes"].get("appStoreState") or i["attributes"].get("state"),
             "ageRating": i["attributes"].get("appStoreAgeRating"),
             "primaryCategory": ((i.get("relationships", {}).get("primaryCategory", {}) or {}).get("data") or {}).get("id")}
        il = get(f"/v1/appInfos/{i['id']}/appInfoLocalizations")
        e["localizations"] = [{k: x["attributes"].get(k) for k in ("locale", "name", "subtitle", "privacyPolicyUrl")} for x in il.get("data", [])]
        out["appInfos"].append(e)
    builds = get(f"/v1/builds?filter[app]={app}&sort=-uploadedDate&limit=3")
    out["builds"] = [{k: b["attributes"].get(k) for k in ("version", "processingState", "usesNonExemptEncryption", "uploadedDate", "expired")} for b in builds.get("data", [])]
    out["priceSchedule"] = get(f"/v1/apps/{app}/appPriceSchedule?include=manualPrices").get("data", {}).get("id") if True else None
    av = get(f"/v2/appAvailabilities/{app}")
    out["availability"] = av.get("data", {}).get("attributes") if "data" in av else av
    subs = get(f"/v1/apps/{app}/subscriptionGroups")
    out["subscriptionGroups"] = len(subs.get("data", [])) if "data" in subs else subs
    agr = get(f"/v1/apps/{app}/inAppPurchasesV2?limit=5")
    out["iap"] = len(agr.get("data", [])) if "data" in agr else agr
os.makedirs("ci-logs", exist_ok=True)
json.dump(out, open("ci-logs/asc.json", "w"), indent=1, ensure_ascii=False)
print(json.dumps(out, indent=1, ensure_ascii=False)[:3000])
