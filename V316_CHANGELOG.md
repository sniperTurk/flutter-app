# V316

- `check_ios_manual_customizations.py`: the v304 guard flagged any `DEVELOPMENT_TEAM` as manual customization, including the team that `configure_ios_signing.py` (v309) writes itself when `SNIPER_TURK_IOS_DEVELOPMENT_TEAM` is set. A second `bootstrap_ios_scaffold.sh` run on a tree it had generated therefore failed with exit 10 and could never refresh. Team entries equal to `SNIPER_TURK_IOS_DEVELOPMENT_TEAM` are now treated as reproducible; any other team, provisioning profile, entitlements file or capability is still rejected.
- Added two regression tests (same team allowed, different team rejected).
- Reviewed v304-v315 additions (Huben/Rossi/Reximex/Aselkon catalog rows, signing/export tools, ios-ci.yml). Catalog facts and Apple-side behavior could not be verified here: no network, no Flutter/Xcode.
