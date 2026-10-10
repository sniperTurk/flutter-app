"""Attach the newest build, set review contact, optionally submit for review."""
import json, os, time, urllib.request, urllib.error
import jwt

kid, iss, KEY = os.environ["ASC_KEY_ID"], os.environ["ASC_ISSUER_ID"], os.environ["ASC_KEY_P8"]
BASE, APP, LOG = "https://api.appstoreconnect.apple.com", "6819483788", []

def tok():
    return jwt.encode({"iss": iss, "iat": int(time.time()), "exp": int(time.time()) + 1100,
                       "aud": "appstoreconnect-v1"}, KEY, algorithm="ES256", headers={"kid": kid})

def call(method, path, body=None):
    req = urllib.request.Request(BASE + path, data=None if body is None else json.dumps(body).encode(),
                                 method=method, headers={"Authorization": f"Bearer {tok()}",
                                                         "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            raw = r.read()
            LOG.append(f"OK {method} {path.split('?')[0]} {r.status}")
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        txt = e.read().decode()[:3000]
        LOG.append(f"ERR {method} {path.split('?')[0]} {e.code} {txt}")
        return {"_error": e.code, "_body": txt}

def main():
    ver = next(v for v in call("GET", f"/v1/apps/{APP}/appStoreVersions?limit=5")["data"]
               if v["attributes"]["appStoreState"] in ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED"))
    vid = ver["id"]
    # Newest uploaded build; wait while Apple processes it.
    for _ in range(40):
        b = call("GET", f"/v1/builds?filter[app]={APP}&sort=-uploadedDate&limit=1")["data"][0]
        state = b["attributes"]["processingState"]
        LOG.append(f"newest build {b['attributes']['version']} {state}")
        if state == "VALID":
            break
        time.sleep(30)
    if state == "VALID":
        call("PATCH", f"/v1/appStoreVersions/{vid}", {"data": {"type": "appStoreVersions", "id": vid,
             "relationships": {"build": {"data": {"type": "builds", "id": b["id"]}}}}})
    first, last, phone = (os.environ.get(k, "").strip() for k in ("REVIEW_FIRST", "REVIEW_LAST", "REVIEW_PHONE"))
    attrs = {"contactEmail": "Sekerbirol76@gmail.com", "demoAccountRequired": False,
             "notes": ("SNIPER TÜRK is a ballistic calculator for sport shooting and hunting with PCP air rifles "
                       "and firearms. No account or login is needed. To try it: Profil → create a profile from the "
                       "catalog, then open Hedef. Location is used only for the weather (MET Norway) when the user "
                       "asks; the map distance tool uses Google Maps. The app sells nothing and contains no ads.")}
    if first and last and phone:
        attrs.update({"contactFirstName": first, "contactLastName": last, "contactPhone": phone})
    rd = call("GET", f"/v1/appStoreVersions/{vid}/appStoreReviewDetail")
    if isinstance(rd.get("data"), dict):
        call("PATCH", f"/v1/appStoreReviewDetails/{rd['data']['id']}", {"data": {"type": "appStoreReviewDetails",
             "id": rd["data"]["id"], "attributes": attrs}})
    else:
        call("POST", "/v1/appStoreReviewDetails", {"data": {"type": "appStoreReviewDetails", "attributes": attrs,
             "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}}}})
    if open("ops/SUBMIT").read().strip() != "1" or not (first and last and phone):
        LOG.append("not submitting (SUBMIT flag off or contact missing)")
        return
    sub = call("POST", "/v1/reviewSubmissions", {"data": {"type": "reviewSubmissions",
               "attributes": {"platform": "IOS"}, "relationships": {"app": {"data": {"type": "apps", "id": APP}}}}})
    if "_error" in sub:
        open_subs = call("GET", f"/v1/reviewSubmissions?filter[app]={APP}&filter[state]=READY_FOR_REVIEW")
        if not open_subs.get("data"):
            return
        sid = open_subs["data"][0]["id"]
    else:
        sid = sub["data"]["id"]
    call("POST", "/v1/reviewSubmissionItems", {"data": {"type": "reviewSubmissionItems", "relationships": {
         "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sid}},
         "appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}}}})
    call("PATCH", f"/v1/reviewSubmissions/{sid}", {"data": {"type": "reviewSubmissions", "id": sid,
         "attributes": {"submitted": True}}})

try:
    main()
finally:
    os.makedirs("ci-logs", exist_ok=True)
    open("ci-logs/submit.log", "w").write("\n".join(LOG))
    print("\n".join(LOG))
