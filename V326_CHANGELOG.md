# V326 — Signed IPA ZIP extraction path safety

- Hardened `tools/verify_signed_app_store_ipa.py` against ZIP path traversal.
- IPA members are validated before extraction; absolute, parent-traversal, and backslash paths fail closed.
- Added `tools/test_v326_signed_ipa_zip_path_safety.py` proving traversal is rejected without writing outside the temporary extraction root and normal IPA paths still extract.
- No real Apple signing/build claim is made; macOS/Xcode/device validation remains outstanding.
