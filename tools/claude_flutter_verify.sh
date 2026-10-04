#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
EXPECTED_FLUTTER="$(python3 - <<'PY'
import json
from pathlib import Path
print(json.loads(Path('.fvmrc').read_text())['flutter'])
PY
)"

fail() { printf 'VERIFY BLOCKED: %s\n' "$*" >&2; exit 2; }
step() { printf '\n==> %s\n' "$*"; }

step "Offline source and production gates"
python3 -m compileall -q tools
python3 tools/offline_dart_lint.py
python3 -m unittest discover -s tools -p 'test_*.py' -v
python3 tools/verify_production_gate.py

command -v flutter >/dev/null 2>&1 || fail "Flutter SDK not found. Install Flutter ${EXPECTED_FLUTTER} (or use FVM), then rerun tools/claude_flutter_verify.sh."
command -v dart >/dev/null 2>&1 || fail "Dart executable not found in PATH."

step "Toolchain"
FLUTTER_VERSION="$(flutter --version --machine 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin)["frameworkVersion"])' 2>/dev/null || true)"
[[ "$FLUTTER_VERSION" == "$EXPECTED_FLUTTER" ]] || fail "Expected Flutter ${EXPECTED_FLUTTER}, found ${FLUTTER_VERSION:-unknown}."
flutter --version
dart --version

step "Dependency lockfile"
if [[ ! -s pubspec.lock ]]; then
  if [[ "${SNIPER_TURK_BOOTSTRAP_LOCKFILE:-0}" == "1" ]]; then
    flutter pub get
    test -s pubspec.lock || fail "flutter pub get did not create pubspec.lock."
    python3 tools/write_lockfile_provenance.py --flutter-version "$EXPECTED_FLUTTER" \
      || fail "generated pubspec.lock provenance could not be verified."
    python3 tools/verify_lockfile_provenance.py \
      || fail "generated pubspec.lock failed provenance verification."
    printf 'pubspec.lock and verified lockfile-provenance.txt were generated. Review both before release CI.\n'
  else
    fail "pubspec.lock is missing. For first-time bootstrap run SNIPER_TURK_BOOTSTRAP_LOCKFILE=1 tools/claude_flutter_verify.sh, review the generated lockfile, then commit it."
  fi
else
  BEFORE="$(shasum -a 256 pubspec.lock | awk '{print $1}')"
  flutter pub get
  AFTER="$(shasum -a 256 pubspec.lock | awk '{print $1}')"
  [[ "$BEFORE" == "$AFTER" ]] || fail "flutter pub get changed pubspec.lock; review and commit resolver output before treating verification as passed."
  # A stable lockfile is not sufficient release evidence: it must also be the
  # exact pair generated for the current pubspec by pinned Flutter 3.47.2.
  # Keep local verification aligned with iOS CI instead of accepting a stale,
  # hand-edited, or differently-resolved lockfile/provenance pair.
  python3 tools/verify_lockfile_provenance.py \
    || fail "committed pubspec.lock provenance is missing, stale, or invalid."
fi

step "Formatting"
dart format --output=none --set-exit-if-changed lib test integration_test tools

step "Static analysis"
flutter analyze --fatal-infos --fatal-warnings

step "Flutter unit/widget tests"
flutter test --coverage --reporter=expanded

if [[ "$(uname -s)" == "Darwin" ]] && command -v xcodebuild >/dev/null 2>&1; then
  step "Xcode"
  xcodebuild -version
  step "Pinned iOS scaffold"
  tools/bootstrap_ios_scaffold.sh
  step "iOS Simulator build"
  flutter build ios --simulator --debug
  printf '\nCORE VERIFY PASS: analyze/tests and iOS Simulator build passed.\n'
else
  printf '\nCORE VERIFY PASS: flutter analyze and flutter test passed.\n'
  printf 'iOS VERIFY NOT RUN: macOS + Xcode are required for the iOS build/Simulator portion.\n'
fi
