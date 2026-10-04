# v118 — App Store privacy URL preflight hardening

- Hardened `tools/app_store_preflight.py` so a syntactically HTTPS but non-public privacy URL cannot satisfy the source release gate.
- The preflight now rejects localhost, private/non-global IPs, single-label hosts, credentials-in-URL, and reserved `.test` / `.invalid` / `.example` / `.localhost` domains.
- Added regression coverage for reserved/local/private privacy-policy hosts.
- This remains a source-only check: it does not claim DNS reachability, Xcode archive/signing, App Store Connect completion, Simulator, or physical-device validation.
