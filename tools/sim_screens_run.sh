#!/usr/bin/env bash
# Screenshot tour on a booted iOS Simulator (macOS + Xcode only).
#
#   tools/sim_screens_run.sh <udid> <prebuilt Runner.app> <out dir>
#
# SIM_SCREENS_TEST picks another tour (default integration_test/sim_screens_test.dart).
#
# 1. Installs the prebuilt app once and grants location BEFORE the test runs,
#    so no permission dialog covers the pages (flutter test installs over it
#    with `simctl install`, which keeps the grant).
# 2. Runs integration_test/sim_screens_test.dart. The test prints
#    `SIMSCREEN:<name>` and holds the frame; this script saves the Simulator
#    screen to <out>/screens/<name>.png each time.
# Writes <out>/status.txt and logs. Exit code = the flutter test exit code.
set -uo pipefail

UDID="$1"
APP="$2"
OUT="$3"
BUNDLE_ID="com.sniperturk.sniperTurk"
TEST="${SIM_SCREENS_TEST:-integration_test/sim_screens_test.dart}"
LIMIT_SECONDS="${SIM_SCREENS_LIMIT_SECONDS:-1500}"

mkdir -p "$OUT/screens"
STATUS="$OUT/status.txt"
LOG="$OUT/flutter-test.log"
DEVLOG="$OUT/device.log"
: > "$STATUS"

note() { echo "$*" | tee -a "$STATUS"; }

xcrun simctl privacy "$UDID" grant location "$BUNDLE_ID" > /dev/null 2>&1
xcrun simctl install "$UDID" "$APP" > "$OUT/install.log" 2>&1
note "install: $?"
xcrun simctl privacy "$UDID" grant location "$BUNDLE_ID" >> "$OUT/install.log" 2>&1
note "grant location: $?"
xcrun simctl privacy "$UDID" grant location-always "$BUNDLE_ID" >> "$OUT/install.log" 2>&1
note "grant location-always: $?"
# Ankara, so Hava Durumu has a position for the live weather.
xcrun simctl location "$UDID" set 39.9334,32.8597 >> "$OUT/install.log" 2>&1
note "simulated location: $?"
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged \
  --batteryLevel 100 --wifiBars 3 --cellularBars 4 > /dev/null 2>&1

xcrun simctl spawn "$UDID" log stream --style compact \
  --predicate 'process == "Runner"' > "$DEVLOG" 2>&1 &
LOG_PID=$!

: > "$LOG"
# met.no needs a contact (a repository variable, not a secret).
flutter test "$TEST" -d "$UDID" --reporter=expanded \
  --dart-define=METNO_CONTACT="${METNO_CONTACT:-}" > "$LOG" 2>&1 &
TEST_PID=$!

capture_new() {
  local name
  for name in $(grep -ho 'SIMSCREEN:[0-9A-Za-z_]*' "$LOG" "$DEVLOG" 2>/dev/null \
      | cut -d: -f2 | sort -u); do
    if [[ ! -f "$OUT/screens/$name.png" ]]; then
      xcrun simctl io "$UDID" screenshot "$OUT/screens/$name.png" > /dev/null 2>&1 \
        || echo "screenshot failed: $name" >> "$STATUS"
    fi
  done
}

START=$(date +%s)
TIMED_OUT=0
while kill -0 "$TEST_PID" 2> /dev/null; do
  capture_new
  if (( $(date +%s) - START > LIMIT_SECONDS )); then
    TIMED_OUT=1
    xcrun simctl io "$UDID" screenshot "$OUT/screens/zz_TIMEOUT.png" > /dev/null 2>&1
    pkill -f flutter_tools > /dev/null 2>&1
    kill "$TEST_PID" > /dev/null 2>&1
    break
  fi
  sleep 0.5
done
wait "$TEST_PID"
RC=$?
capture_new
kill "$LOG_PID" > /dev/null 2>&1

(( TIMED_OUT )) && note "flutter test: TIMEOUT after ${LIMIT_SECONDS}s"
note "flutter test exit: $RC"
note "screenshots: $(find "$OUT/screens" -name '*.png' | wc -l | tr -d ' ')"
grep -ho 'SIMSTEP_FAIL:.*' "$LOG" | sort -u | sed 's/^/failed step: /' >> "$STATUS"
cat "$STATUS"
exit "$RC"
