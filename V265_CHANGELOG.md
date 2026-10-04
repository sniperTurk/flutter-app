# V265

- Hardened the independent ballistic validator bootstrap against untrusted download origins.
- Wheel URLs supplied by package metadata must now use HTTPS and resolve to an explicit trusted PyPI artifact host (`pypi.org` or `files.pythonhosted.org`), with embedded credentials rejected.
- Existing SHA-256 artifact verification remains mandatory.
- Added regression tests for trusted-host and hash gates.
- This does not open the G1/G7 production gate; independent vectors still must be generated and compared.
