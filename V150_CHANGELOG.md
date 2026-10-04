# V150

- Added `tools/claude_bootstrap_and_verify.sh`, a fail-closed Claude Code entry point that can install/check out the exact Flutter version pinned in `.fvmrc` when Flutter is absent and network access is available.
- The bootstrap uses an isolated user SDK directory, verifies the resolved Flutter version, generates `pubspec.lock` only through the real Flutter resolver when missing, and then delegates to the existing analyze/test/regression/iOS verification chain.
- Updated `CLAUDE.md` so Claude Code is instructed to use the bootstrap entry point instead of stopping at “Flutter is not installed” when its environment permits installation.
- Added regression coverage for SDK pinning, explicit lockfile bootstrap, fail-closed behavior, and Claude instruction wiring.
- No Flutter analyze/test/iOS success is claimed in this build environment because Flutter is not installed here.
