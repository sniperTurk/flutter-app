#!/usr/bin/env bash
set -euo pipefail

EXPECTED_FLUTTER="3.47.2"
ORG="com.sniperturk"
PROJECT="sniper_turk"

command -v flutter >/dev/null 2>&1 || { echo "flutter is required to generate the iOS scaffold" >&2; exit 2; }
# Use the same fail-closed verifier as release CI instead of reparsing
# `flutter --version --machine` here. This also validates the project .fvmrc
# pin and turns malformed/non-object machine JSON into a controlled failure.
python3 tools/verify_flutter_toolchain.py || {
  echo "Pinned Flutter toolchain verification failed; refusing to generate iOS scaffold" >&2
  exit 3
}
ACTUAL_FLUTTER="$EXPECTED_FLUTTER"

# Never trust a pre-existing partial/stale scaffold. `flutter create` updates an
# existing platform tree but does not provide a "no stale files remain" contract.
# Regenerate from an absent directory, but do it transactionally: if Flutter or
# any later metadata/privacy validation fails, restore the exact previous ios/
# tree instead of leaving the developer with a deleted or half-generated tree.
# Refuse a symlink rather than following/moving a substituted tree.
if [[ -L ios ]]; then
  echo "Refusing to replace a symlinked ios directory" >&2
  exit 9
fi

# A clean scaffold refresh must never silently destroy Xcode settings that are
# normally edited outside Flutter (signing, provisioning, entitlements, or
# target capabilities).  We cannot safely merge arbitrary pbxproj edits into a
# newly generated project, so fail closed before moving ios/.  Teams that need
# these settings must encode them in a reproducible post-generation configurator
# before bootstrap is allowed to replace the tree.
if [[ -f ios/Runner.xcodeproj/project.pbxproj ]]; then
  python3 tools/check_ios_manual_customizations.py ios/Runner.xcodeproj/project.pbxproj ios/Runner || {
    echo "Existing iOS scaffold contains manual signing/capability configuration; refusing destructive refresh" >&2
    exit 10
  }
fi
IOS_BACKUP=""
if [[ -e ios ]]; then
  IOS_BACKUP="$(mktemp -d "${TMPDIR:-/tmp}/sniper-turk-ios-backup.XXXXXX")/ios"
  mv -- ios "$IOS_BACKUP"
fi
rollback_ios() {
  status=$?
  if [[ $status -ne 0 ]]; then
    rm -rf -- ios
    if [[ -n "$IOS_BACKUP" && -e "$IOS_BACKUP" ]]; then
      mv -- "$IOS_BACKUP" ios
    fi
  elif [[ -n "$IOS_BACKUP" ]]; then
    rm -rf -- "$(dirname "$IOS_BACKUP")"
  fi
  exit "$status"
}
trap rollback_ios EXIT

# `flutter create .` runs its own dependency resolution and may rewrite the
# committed, provenance-verified pubspec.lock (and touch pubspec.yaml). The
# release preflight hashes both against lockfile-provenance.txt, so snapshot
# them and restore the committed lockfile; pubspec.yaml must never change.
DEP_SNAPSHOT="$(mktemp -d "${TMPDIR:-/tmp}/sniper-turk-deps.XXXXXX")"
[[ -f pubspec.yaml ]] && cp -p pubspec.yaml "$DEP_SNAPSHOT/pubspec.yaml"
[[ -f pubspec.lock ]] && cp -p pubspec.lock "$DEP_SNAPSHOT/pubspec.lock"

flutter create --platforms=ios --org "$ORG" --project-name "$PROJECT" .

[[ ! -f "$DEP_SNAPSHOT/pubspec.yaml" ]] || cmp -s pubspec.yaml "$DEP_SNAPSHOT/pubspec.yaml" || {
  echo "flutter create modified pubspec.yaml; refusing to continue" >&2
  cp -p "$DEP_SNAPSHOT/pubspec.yaml" pubspec.yaml
  exit 11
}
if [[ -f "$DEP_SNAPSHOT/pubspec.lock" ]] && ! cmp -s pubspec.lock "$DEP_SNAPSHOT/pubspec.lock"; then
  echo "flutter create rewrote pubspec.lock; restoring the committed lockfile" >&2
  cp -p "$DEP_SNAPSHOT/pubspec.lock" pubspec.lock
  flutter pub get --enforce-lockfile
fi
rm -rf -- "$DEP_SNAPSHOT"

required=(
  ios/Runner.xcodeproj/project.pbxproj
  ios/Runner.xcworkspace/contents.xcworkspacedata
  ios/Runner/Info.plist
  ios/Runner/AppDelegate.swift
  ios/Flutter/Debug.xcconfig
  ios/Flutter/Release.xcconfig
)
for path in "${required[@]}"; do
  [[ -f "$path" ]] || { echo "Missing generated iOS scaffold file: $path" >&2; exit 4; }
done

# Flutter's generated display name follows the package/project name. Apply the
# user-facing product name deterministically after scaffold generation.
python3 tools/configure_ios_info_plist.py ios/Runner/Info.plist

# Ship an app-owned privacy manifest in Runner.app. The archive gate is strict,
# so an embedded plugin manifest cannot substitute for this resource.
command -v ruby >/dev/null 2>&1 || { echo "ruby is required to wire the iOS privacy manifest" >&2; exit 6; }
ruby -e "require 'xcodeproj'" >/dev/null 2>&1 || { echo "Ruby xcodeproj gem is required to wire the iOS privacy manifest" >&2; exit 7; }
ruby tools/configure_ios_privacy_manifest.rb
[[ -f ios/Runner/PrivacyInfo.xcprivacy ]] || { echo "Runner privacy manifest was not installed" >&2; exit 8; }
python3 - <<'PYINFO'
import plistlib
with open("ios/Runner/Info.plist", "rb") as f:
    info = plistlib.load(f)
if info.get("CFBundleDisplayName") != "SNIPER TÜRK":
    raise SystemExit("Unexpected CFBundleDisplayName after iOS metadata configuration")
PYINFO

grep -q 'PRODUCT_BUNDLE_IDENTIFIER = com.sniperturk.sniperTurk;' ios/Runner.xcodeproj/project.pbxproj || {
  echo "Unexpected iOS bundle identifier after scaffold generation" >&2
  exit 5
}

# Signing identity is account-specific and must never be invented or committed.
# Release environments can provide it explicitly; when present, encode it into
# every generated Automatic code-sign build setting deterministically.
if [[ -n "${SNIPER_TURK_IOS_DEVELOPMENT_TEAM:-}" ]]; then
  python3 tools/configure_ios_signing.py ios/Runner.xcodeproj/project.pbxproj \
    --team "$SNIPER_TURK_IOS_DEVELOPMENT_TEAM"
fi

python3 - <<'PYDEPLOY'
import re
from pathlib import Path
text = Path("ios/Runner.xcodeproj/project.pbxproj").read_text(encoding="utf-8")
raw = re.findall(r"IPHONEOS_DEPLOYMENT_TARGET\s*=\s*([^;\s]+)\s*;", text)
if not raw:
    raise SystemExit("Missing iOS deployment target after scaffold generation")
for value in raw:
    m = re.fullmatch(r"(\d+)(?:\.(\d+))?", value)
    if not m or (int(m.group(1)), int(m.group(2) or 0)) < (15, 0):
        raise SystemExit(f"Unsupported iOS deployment target after scaffold generation: {value}")
PYDEPLOY

echo "iOS scaffold contract verified with Flutter $ACTUAL_FLUTTER"
