#!/usr/bin/env bash
# Real-device release smoke gate. This script intentionally cannot turn a
# simulator or source-only check into "physical iPhone PASS" evidence.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

[[ "$(uname -s)" == "Darwin" ]] || { echo "Physical iPhone testing requires macOS." >&2; exit 1; }
command -v flutter >/dev/null || { echo "flutter is required." >&2; exit 1; }
command -v xcrun >/dev/null || { echo "xcrun/Xcode is required." >&2; exit 1; }
[[ -s pubspec.lock ]] || { echo "pubspec.lock must be committed before physical-device testing." >&2; exit 1; }

REQUESTED_ID="${1:-${IPHONE_DEVICE_ID:-}}"
DEVICES_JSON="$(mktemp)"
trap 'rm -f "$DEVICES_JSON"' EXIT
flutter devices --machine > "$DEVICES_JSON"
if [[ -n "$REQUESTED_ID" ]]; then
  DEVICE_ID="$(python3 tools/select_physical_ios_device.py --device-id "$REQUESTED_ID" < "$DEVICES_JSON")"
else
  DEVICE_ID="$(python3 tools/select_physical_ios_device.py < "$DEVICES_JSON")"
fi

# Prove that Xcode also sees the same hardware target. Flutter discovery alone
# is not enough evidence for the native iOS toolchain used by the test build.
xcrun devicectl list devices | grep -F -- "$DEVICE_ID" >/dev/null || {
  echo "Xcode devicectl does not report the selected physical iPhone: $DEVICE_ID" >&2
  exit 1
}

python3 tools/verify_flutter_toolchain.py
# A physical-device PASS must use the exact dependency graph that was reviewed
# and committed. `flutter pub get` is still required to create package config,
# but it must never silently rewrite pubspec.lock and then test different deps.
BEFORE_LOCK_SHA="$(shasum -a 256 pubspec.lock | awk '{print $1}')"
flutter pub get
AFTER_LOCK_SHA="$(shasum -a 256 pubspec.lock | awk '{print $1}')"
[[ "$BEFORE_LOCK_SHA" == "$AFTER_LOCK_SHA" ]] || {
  echo "flutter pub get changed pubspec.lock; review and commit pinned resolver output before physical-device testing." >&2
  git --no-pager diff -- pubspec.lock 2>/dev/null || true
  exit 1
}
# This is the production navigation/persistence smoke suite, executed on real
# hardware. Signing/provisioning failures remain hard failures and must never be
# converted to a source-only PASS.
flutter test integration_test/app_launch_test.dart -d "$DEVICE_ID" --reporter=expanded

echo "PHYSICAL_IPHONE_TEST_PASS device_id=$DEVICE_ID"
