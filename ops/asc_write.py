"""Writes the App Store listing for version 1.0 (no submission)."""
import hashlib, json, os, re, time, urllib.request, urllib.error
import jwt

kid, iss = os.environ["ASC_KEY_ID"], os.environ["ASC_ISSUER_ID"]
KEY = os.environ["ASC_KEY_P8"]
BASE = "https://api.appstoreconnect.apple.com"
APP = "6819483788"
LOG = []

def tok():
    return jwt.encode({"iss": iss, "iat": int(time.time()), "exp": int(time.time()) + 1100,
                       "aud": "appstoreconnect-v1"}, KEY, algorithm="ES256", headers={"kid": kid})

def call(method, path, body=None, ok_log=True):
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(BASE + path, data=data, method=method,
                                 headers={"Authorization": f"Bearer {tok()}", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            raw = r.read()
            res = json.loads(raw) if raw else {}
            if ok_log:
                LOG.append(f"OK {method} {path} {r.status}")
            return res
    except urllib.error.HTTPError as e:
        txt = e.read().decode()[:1500]
        LOG.append(f"ERR {method} {path} {e.code} {txt}")
        return {"_error": e.code, "_body": txt}

text = open("ops/store_text.md", encoding="utf-8").read()
subtitle = re.search(r"Alt başlık \(30\): (.+)", text).group(1).strip()
promo = re.search(r"Tanıtım metni \(170\): (.+)", text).group(1).strip()
keywords = re.search(r"Anahtar kelimeler \(100\): (.+)", text).group(1).strip()
description = text.split("Açıklama:\n", 1)[1].strip()
assert len(subtitle) <= 30 and len(promo) <= 170 and len(keywords) <= 100 and len(description) <= 4000

# 1. App: content rights (Google Maps tiles are licensed third-party content).
call("PATCH", f"/v1/apps/{APP}", {"data": {"type": "apps", "id": APP,
     "attributes": {"contentRightsDeclaration": "USES_THIRD_PARTY_CONTENT"}}})

# 2. App info: categories, subtitle, age rating.
info = call("GET", f"/v1/apps/{APP}/appInfos")["data"][0]["id"]
call("PATCH", f"/v1/appInfos/{info}", {"data": {"type": "appInfos", "id": info, "relationships": {
    "primaryCategory": {"data": {"type": "appCategories", "id": "SPORTS"}},
    "secondaryCategory": {"data": {"type": "appCategories", "id": "UTILITIES"}}}}})
for loc in call("GET", f"/v1/appInfos/{info}/appInfoLocalizations")["data"]:
    if loc["attributes"]["locale"] == "tr":
        call("PATCH", f"/v1/appInfoLocalizations/{loc['id']}", {"data": {"type": "appInfoLocalizations",
             "id": loc["id"], "attributes": {"subtitle": subtitle}}})
enum_none = ["alcoholTobaccoOrDrugUseOrReferences", "contests", "gamblingSimulated", "medicalOrTreatmentInformation",
             "profanityOrCrudeHumor", "sexualContentGraphicAndNudity", "sexualContentOrNudity", "horrorOrFearThemes",
             "matureOrSuggestiveThemes", "violenceCartoonOrFantasy", "violenceRealisticProlongedGraphicOrSadistic",
             "violenceRealistic"]
bools_false = ["advertising", "gambling", "healthOrWellnessTopics", "lootBox", "messagingAndChat",
               "parentalControls", "ageAssurance", "unrestrictedWebAccess", "userGeneratedContent"]
attrs = {k: "NONE" for k in enum_none}
attrs.update({k: False for k in bools_false})
# The whole app is about rifles: weapons are referenced throughout.
attrs["gunsOrOtherWeapons"] = "FREQUENT_OR_INTENSE"
r = call("PATCH", f"/v1/ageRatingDeclarations/{info}", {"data": {"type": "ageRatingDeclarations", "id": info,
         "attributes": attrs}})
if "_error" in r:
    # Retry dropping attributes the API rejects, one by one.
    for _ in range(12):
        m = re.search(r"'(\w+)'|/data/attributes/(\w+)", r.get("_body", ""))
        bad = next((g for g in (m.groups() if m else []) if g), None)
        if not bad or bad not in attrs:
            break
        attrs.pop(bad)
        r = call("PATCH", f"/v1/ageRatingDeclarations/{info}", {"data": {"type": "ageRatingDeclarations",
                 "id": info, "attributes": attrs}})
        if "_error" not in r:
            break

# 3. Version: copyright, build, localization.
ver = next(v for v in call("GET", f"/v1/apps/{APP}/appStoreVersions?limit=5")["data"]
           if v["attributes"]["appStoreState"] == "PREPARE_FOR_SUBMISSION")
vid = ver["id"]
builds = call("GET", f"/v1/builds?filter[app]={APP}&filter[processingState]=VALID&sort=-uploadedDate&limit=1")["data"]
build = builds[0]
LOG.append(f"build {build['attributes']['version']} {build['id']}")
call("PATCH", f"/v1/appStoreVersions/{vid}", {"data": {"type": "appStoreVersions", "id": vid,
     "attributes": {"copyright": "2026 SNIPER TÜRK", "releaseType": "AFTER_APPROVAL"},
     "relationships": {"build": {"data": {"type": "builds", "id": build["id"]}}}}})
loc = next(l for l in call("GET", f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations")["data"]
           if l["attributes"]["locale"] == "tr")
call("PATCH", f"/v1/appStoreVersionLocalizations/{loc['id']}", {"data": {"type": "appStoreVersionLocalizations",
     "id": loc["id"], "attributes": {"description": description, "keywords": keywords, "promotionalText": promo,
     "supportUrl": "https://sniperturk.github.io/flutter-app/support.html"}}})

# 4. Screenshots (6.9" iPhone set), replacing any earlier upload.
sets = call("GET", f"/v1/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets")["data"]
sset = next((s for s in sets if s["attributes"]["screenshotDisplayType"] == "APP_IPHONE_67"), None)
if sset:
    for shot in call("GET", f"/v1/appScreenshotSets/{sset['id']}/appScreenshots")["data"]:
        call("DELETE", f"/v1/appScreenshots/{shot['id']}")
else:
    sset = call("POST", "/v1/appScreenshotSets", {"data": {"type": "appScreenshotSets",
                "attributes": {"screenshotDisplayType": "APP_IPHONE_67"}, "relationships": {
                "appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": loc["id"]}}}}})["data"]
for name in ["1-hedef", "2-tablo", "3-pro", "5-pro-ruzgar", "4-hava", "6-araclar"]:
    path = f"shots/{name}.png"
    blob = open(path, "rb").read()
    res = call("POST", "/v1/appScreenshots", {"data": {"type": "appScreenshots",
               "attributes": {"fileName": f"{name}.png", "fileSize": len(blob)}, "relationships": {
               "appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": sset["id"]}}}}})
    if "_error" in res:
        continue
    sid = res["data"]["id"]
    for op in res["data"]["attributes"]["uploadOperations"]:
        chunk = blob[op["offset"]:op["offset"] + op["length"]]
        hdrs = {h["name"]: h["value"] for h in op["requestHeaders"]}
        req = urllib.request.Request(op["url"], data=chunk, method=op["method"], headers=hdrs)
        with urllib.request.urlopen(req, timeout=120) as r:
            LOG.append(f"upload {name} part {r.status}")
    call("PATCH", f"/v1/appScreenshots/{sid}", {"data": {"type": "appScreenshots", "id": sid,
         "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(blob).hexdigest()}}})

# 5. Price: free. Availability: every territory.
free = call("GET", f"/v1/apps/{APP}/appPricePoints?filter[territory]=USA&limit=1")["data"][0]["id"]
call("POST", "/v1/appPriceSchedules", {"data": {"type": "appPriceSchedules", "relationships": {
     "app": {"data": {"type": "apps", "id": APP}},
     "baseTerritory": {"data": {"type": "territories", "id": "USA"}},
     "manualPrices": {"data": [{"type": "appPrices", "id": "${price1}"}]}}},
     "included": [{"type": "appPrices", "id": "${price1}", "attributes": {"startDate": None},
                   "relationships": {"appPricePoint": {"data": {"type": "appPricePoints", "id": free}}}}]})
terr = [t["id"] for t in call("GET", "/v1/territories?limit=200")["data"]]
call("POST", "/v2/appAvailabilities", {"data": {"type": "appAvailabilities", "attributes": {
     "availableInNewTerritories": True}, "relationships": {"app": {"data": {"type": "apps", "id": APP}},
     "territoryAvailabilities": {"data": [{"type": "territoryAvailabilities", "id": f"${{t{i}}}"} for i in range(len(terr))]}}},
     "included": [{"type": "territoryAvailabilities", "id": f"${{t{i}}}", "attributes": {"available": True},
                   "relationships": {"territory": {"data": {"type": "territories", "id": t}}}} for i, t in enumerate(terr)]})

os.makedirs("ci-logs", exist_ok=True)
open("ci-logs/write.log", "w").write("\n".join(LOG))
print("\n".join(LOG))
