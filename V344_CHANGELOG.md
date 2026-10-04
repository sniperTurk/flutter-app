# V344

Ballistics/DOPE formula audit (see `validation/FORMULA_AUDIT.md`).

- No formula error found in the production path: vacuum zero/drop/time, MOA/MRAD, energy, unit conversions and atmosphere all verified numerically.
- Quantified the real limitation: the vacuum baseline omits air drag and under-reads drop by roughly 16-45 % at 100-800 m. The in-app footnote now says "yaklaşık %20-45" instead of the vague "küçük çıkar".
- Added a test that the BC->retardation convention reproduces the published 2.08551e-04 (fps) constant.
- The G1/G7 production gate remains CLOSED; no drag DOPE is exposed. Flutter/Dart code was not executed here.
