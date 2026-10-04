#!/usr/bin/env bash
# Apply the exact formatting the CI gate (`dart format --set-exit-if-changed`)
# enforces. Run once on a machine with the pinned Flutter/Dart SDK, review the
# diff, and commit it. The offline tooling cannot format Dart code: the SDK's
# formatter is the only authority, so this is intentionally not reimplemented.
set -euo pipefail
cd "$(dirname "$0")/.."
command -v dart >/dev/null 2>&1 || { echo "dart not found; install the Flutter SDK pinned in .fvmrc" >&2; exit 2; }
dart format lib test integration_test tools
git --no-pager diff --stat 2>/dev/null || true
echo "Formatted. Review and commit, then rerun tools/claude_flutter_verify.sh."
