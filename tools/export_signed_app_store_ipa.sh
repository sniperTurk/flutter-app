#!/usr/bin/env bash
# Export a real App Store-signed IPA from the validated archive.
# This gate never fabricates credentials or treats an unsigned archive as a deliverable.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$ROOT"

ARCHIVE="${1:-build/ios/archive/Runner.xcarchive}"
EXPORT_DIR="${2:-build/ios/appstore-export}"
SAFE_EXPORT_ROOT="$ROOT/build/ios"
SAFE_ARCHIVE_ROOT="$ROOT/build/ios/archive"
ARCHIVE_ABS="$(python3 - "$ARCHIVE" <<'PYARCHIVEPATH'
import os, sys
print(os.path.realpath(sys.argv[1]))
PYARCHIVEPATH
)"
# Canonicalize before any destructive cleanup. realpath semantics also resolve
# existing symlinked parent components, so an apparently in-tree path cannot
# redirect rm -rf outside the project build tree.
EXPORT_DIR_ABS="$(python3 - "$EXPORT_DIR" <<'PYEXPORTPATH'
import os, sys
print(os.path.realpath(sys.argv[1]))
PYEXPORTPATH
)"
TEAM_ID="${SNIPER_TURK_IOS_DEVELOPMENT_TEAM:-}"

[[ "$(uname -s)" == "Darwin" ]] || { echo "App Store IPA export requires macOS/Xcode." >&2; exit 1; }
command -v xcodebuild >/dev/null || { echo "xcodebuild is required." >&2; exit 1; }
command -v codesign >/dev/null || { echo "codesign is required." >&2; exit 1; }
[[ "$TEAM_ID" =~ ^[A-Z0-9]{10}$ ]] || { echo "SNIPER_TURK_IOS_DEVELOPMENT_TEAM must be a real 10-character Apple Team ID." >&2; exit 2; }
[[ -d "$ARCHIVE" ]] || { echo "Missing xcarchive: $ARCHIVE" >&2; exit 3; }
[[ "$ARCHIVE_ABS" == "$SAFE_ARCHIVE_ROOT"/* ]] && [[ ! -L "$ARCHIVE" ]] || {
  echo "Unsafe archive path: $ARCHIVE (resolved: $ARCHIVE_ABS); expected a non-symlink xcarchive below $SAFE_ARCHIVE_ROOT." >&2
  exit 9
}

# The archive entering this step must be the deliberately unsigned artifact that
# passed the v312 gate; signing happens only during Apple's export operation.
python3 tools/verify_ios_archive_signing_state.py --archive "$ARCHIVE" --bundle-id com.sniperturk.sniperTurk
SNIPER_TURK_IOS_DEVELOPMENT_TEAM="$TEAM_ID" python3 tools/generate_ios_export_options.py
[[ -s build/ios/ExportOptions.plist ]] || { echo "ExportOptions.plist was not generated." >&2; exit 4; }

[[ "$EXPORT_DIR_ABS" == "$SAFE_EXPORT_ROOT"/* ]] && [[ ! -L "$EXPORT_DIR_ABS" ]] || {
  echo "Unsafe export directory: $EXPORT_DIR (resolved: $EXPORT_DIR_ABS); expected a non-symlink path below $SAFE_EXPORT_ROOT." >&2
  exit 8
}
[[ "$EXPORT_DIR_ABS" != "$SAFE_ARCHIVE_ROOT" && "$EXPORT_DIR_ABS" != "$SAFE_ARCHIVE_ROOT"/* && "$ARCHIVE_ABS" != "$EXPORT_DIR_ABS"/* ]] || {
  echo "Unsafe export directory: $EXPORT_DIR (resolved: $EXPORT_DIR_ABS) overlaps the archive being exported: $ARCHIVE_ABS." >&2
  exit 8
}
rm -rf "$EXPORT_DIR_ABS"
mkdir -p "$EXPORT_DIR_ABS"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$EXPORT_DIR_ABS" \
  -exportOptionsPlist build/ios/ExportOptions.plist

IPA="$(find "$EXPORT_DIR_ABS" -maxdepth 1 -type f -name '*.ipa' -print -quit)"
[[ -n "$IPA" && -s "$IPA" ]] || { echo "xcodebuild completed without a non-empty IPA." >&2; exit 5; }

# Inspect the exported payload and prove it is actually signed. A successful
# xcodebuild exit alone is not sufficient evidence.
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
/usr/bin/unzip -q "$IPA" -d "$TMP"
APP="$(find "$TMP/Payload" -maxdepth 1 -type d -name '*.app' -print -quit)"
[[ -n "$APP" ]] || { echo "IPA contains no Payload/*.app." >&2; exit 6; }
codesign --verify --deep --strict --verbose=2 "$APP"
[[ -s "$APP/embedded.mobileprovision" ]] || { echo "Signed IPA has no embedded.mobileprovision." >&2; exit 7; }

# Prove that the signature and embedded profile belong to the explicitly
# configured Apple team and exact production bundle identifier.
python3 tools/verify_signed_app_store_ipa.py \
  --ipa "$IPA" \
  --team-id "$TEAM_ID" \
  --bundle-id com.sniperturk.sniperTurk

echo "SIGNED_APP_STORE_IPA_PASS ipa=$IPA"
