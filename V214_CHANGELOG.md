# V214

- Continued from V213; no project restart.
- Hardened `ProfileCodec` against silent semantic data corruption.
- Missing legacy `angularUnit` still migrates to MRAD, but a present unknown/non-string unit now fails closed instead of silently becoming MRAD.
- Missing/null `pressureBar` remains valid for firearm/legacy profiles, but a present malformed/non-positive pressure now fails closed instead of silently becoming null.
- Added Flutter regressions and an offline source-contract guard.
- No claim is made that Flutter/Xcode tests ran in this environment.
