"""Sets the 1.0 version to manual release (owner, 2026-10-10)."""
import json, os, time, urllib.request, urllib.error
import jwt
kid, iss, KEY = os.environ["ASC_KEY_ID"], os.environ["ASC_ISSUER_ID"], os.environ["ASC_KEY_P8"]
BASE, APP, LOG = "https://api.appstoreconnect.apple.com", "6819483788", []
def call(method, path, body=None):
    tok = jwt.encode({"iss": iss, "iat": int(time.time()), "exp": int(time.time()) + 1100,
                      "aud": "appstoreconnect-v1"}, KEY, algorithm="ES256", headers={"kid": kid})
    req = urllib.request.Request(BASE + path, data=None if body is None else json.dumps(body).encode(),
                                 method=method, headers={"Authorization": f"Bearer {tok}",
                                                         "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            raw = r.read(); LOG.append(f"OK {method} {path.split('?')[0]} {r.status}")
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        t = e.read().decode()[:2000]; LOG.append(f"ERR {method} {path} {e.code} {t}"); return {"_error": e.code}
try:
    for v in call("GET", f"/v1/apps/{APP}/appStoreVersions?limit=5")["data"]:
        a = v["attributes"]
        LOG.append(f"version {a['versionString']} state={a['appStoreState']} release={a['releaseType']}")
        if a["versionString"] == "1.0":
            call("PATCH", f"/v1/appStoreVersions/{v['id']}", {"data": {"type": "appStoreVersions",
                 "id": v["id"], "attributes": {"releaseType": "MANUAL"}}})
            after = call("GET", f"/v1/appStoreVersions/{v['id']}")
            if "data" in after:
                LOG.append(f"now release={after['data']['attributes']['releaseType']} state={after['data']['attributes']['appStoreState']}")
finally:
    os.makedirs("ci-logs", exist_ok=True); open("ci-logs/submit.log", "w").write("\n".join(LOG)); print("\n".join(LOG))
