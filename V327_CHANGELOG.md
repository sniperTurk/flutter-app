# V327 changelog

- Hardened `tools/install_pinned_flutter.py` against destructive final-component destination symlinks.
- The installer now rejects a destination that is itself a symlink before resolving or deleting it, while still allowing legitimate symlinked parent/workspace paths.
- Added regression coverage proving an external SDK directory/sentinel survives a malicious destination symlink and proving symlinked parents remain supported.
- Real Flutter/Xcode/iOS execution remains unverified in this environment.
