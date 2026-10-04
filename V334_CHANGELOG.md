# V334

- `bootstrap_reference_validator.py`: the V333 trusted-origin check accepted non-default ports (e.g. `https://pypi.org:8443/`). The trusted PyPI hosts are only trusted on the default HTTPS port; an invalid port is now rejected instead of raising. Redirect targets use the same check.
- Added a regression test. Wheel SHA-256 verification is unchanged and remains mandatory.
