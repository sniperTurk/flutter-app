# V309 — Reproducible iOS signing configuration

V304 correctly refused to destroy an existing iOS scaffold containing manual signing/capability edits, but its changelog left the production path explicit: supported settings should be reproducible after clean Flutter scaffold generation.

V309 implements the first supported setting, Apple Development Team, without inventing or committing an account-specific Team ID:

- adds `tools/configure_ios_signing.py`;
- validates a 10-character uppercase alphanumeric Apple Team ID;
- atomically and idempotently applies the team to every generated `CODE_SIGN_STYLE = Automatic` build setting;
- `bootstrap_ios_scaffold.sh` invokes it only when `SNIPER_TURK_IOS_DEVELOPMENT_TEAM` is explicitly supplied by the release environment;
- invalid input fails closed and leaves the project unchanged;
- regression tests lock ordering, validation, idempotence and full Automatic-setting coverage.

This does **not** claim a signed archive, Simulator run or physical-device run. Those still require the pinned Flutter toolchain, Xcode and an authorized Apple signing environment.
