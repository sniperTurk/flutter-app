# V151 changelog

- Continued from v150 without regenerating the project.
- Added the manufacturer-verified HATSAN Blitz 777 6.35 mm PCP catalog variant.
- Stored only fields unambiguously bound to the .25 configuration/current model: 19-shot magazine, 585 mm barrel, 700 cc air capacity, 905 mm overall length, 4 kg weight.
- Added `tools/test_hatsan_blitz_777_catalog_provenance.py` to lock identity, specs, provenance and uniqueness.
- Removed generated `__pycache__`/`.pyc` artifacts before packaging.
- Real Flutter analyze/test and iOS build remain unverified because Flutter/Xcode are unavailable in this execution environment.
