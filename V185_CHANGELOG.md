# V185 — resilient pinned Flutter bootstrap

- Continued from V184; no project restart.
- Added `tools/install_pinned_flutter.py`, an official Flutter archive fallback for environments where GitHub access is blocked.
- The fallback selects the exact stable version pinned in `.fvmrc`, selects the host architecture, downloads from Flutter's official Google-hosted release archive, verifies the published SHA-256, and only then extracts the SDK.
- `tools/claude_bootstrap_and_verify.sh` now falls back to that verified archive when GitHub clone/fetch/checkout fails instead of stopping immediately.
- Added five dependency-free regression tests for exact stable-version and architecture selection plus fail-closed unsupported/missing cases.
- This environment has no outbound DNS/Flutter SDK, so the actual SDK download, Dart formatter, Flutter analyzer/tests, Xcode, Simulator and physical iPhone remain NOT RUN.
