# V96 change log

- Hardened the independent G1/G7 validator bootstrap after a real offline execution exposed an unhandled `urllib` traceback.
- PyPI metadata fetch failures, malformed metadata, wheel download failures, and local pip-install failures now terminate through the bootstrap's explicit fail-closed error path instead of leaking an implementation traceback.
- Wheel downloads now require an HTTPS artifact URL and validate filename metadata before touching the filesystem; partial files are removed on transfer failure.
- Added offline regression tests for network failure and HTTPS-only wheel download metadata. Existing hash-identity regression tests remain in place.
- Verified locally in this environment: Python compile checks pass and all four offline bootstrap regression tests pass. The actual PyPI bootstrap remains blocked here by DNS/network access, so no G1/G7 numerical comparison is claimed.
- No Flutter/Dart/iOS build or test result is claimed by this change log.
