#!/usr/bin/env python3
"""Apply deterministic SNIPER TÜRK app metadata to a generated iOS Info.plist."""
from __future__ import annotations
import argparse, plistlib, sys
from pathlib import Path

DISPLAY_NAME = "SNIPER TÜRK"
USES_NON_EXEMPT_ENCRYPTION = False

# M1 (Menzil + Araçlar) permission purpose strings. Each key maps to a
# feature that really exists in lib/ (see tools/test_m1_tools_scope_contract.py).
USAGE_DESCRIPTIONS = {
    # Hava & Rüzgâr: coordinates are sent to the weather service to fetch
    # forecast data; they are not stored by the app.
    "NSLocationWhenInUseUsageDescription": (
        "Konumunuz yalnızca uygulama açıkken, bulunduğunuz yerin hava "
        "verisini almak (Hava Durumu) ve Coriolis için enlemi doldurmak "
        "amacıyla kullanılır. Konum kalıcı olarak saklanmaz."
    ),
    # ITMS-90683 (App Store Connect, build 49): the geolocator plugin binary
    # references the "always" authorization API, so Apple requires this key
    # even though the app only ever asks for when-in-use access. The text
    # says so honestly.
    "NSLocationAlwaysAndWhenInUseUsageDescription": (
        "Uygulama konumu arka planda kullanmaz. Konum yalnızca uygulama "
        "açıkken hava verisi ve Coriolis enlemi için kullanılır; kalıcı "
        "olarak saklanmaz."
    ),
    # Sight Height: photos stay in memory on the device.
    "NSCameraUsageDescription": (
        "Kamera yalnızca Sight Height ekranında dürbün yüksekliğini ölçmek için "
        "fotoğraf çekmekte kullanılır. Fotoğraflar kaydedilmez ve cihazdan çıkmaz."
    ),
    # Sight Height "Galeriden seç": the system photo picker (PHPicker) is used
    # with requestFullMetadata: false, so iOS shows no library permission
    # prompt and the app only receives the ONE photo the user selects. App Store
    # policy still wants the purpose string declared (image_picker README).
    "NSPhotoLibraryUsageDescription": (
        "Galeriden yalnızca seçtiğiniz tek fotoğraf, Sight Height ölçümü için "
        "kullanılır. Fotoğraf kaydedilmez ve cihazdan çıkmaz; kitaplığınıza "
        "yazılmaz."
    ),
    # Su Terazisi: raw accelerometer reads via CMMotionManager do not prompt;
    # the Motion & Fitness string is kept as a harmless, honest purpose text.
    "NSMotionUsageDescription": (
        "Hareket sensörü yalnızca Su Terazisi ekranında cihazın eğimini "
        "göstermek için kullanılır. Veri saklanmaz."
    ),
    # The app never records audio (CameraController is opened with
    # enableAudio: false). The camera plugin documents this key because its
    # binary references the audio capture APIs; the text says so honestly.
    "NSMicrophoneUsageDescription": (
        "Uygulama ses kaydetmez. Bu açıklama, kamera bileşeninin sistem "
        "gereksinimi nedeniyle bulunur."
    ),
}

# Sight Height's photo capture page asks for landscape via SystemChrome, which
# iOS ignores unless the orientation is also declared here. Set explicitly
# instead of relying on the `flutter create` template.
IPHONE_ORIENTATIONS = [
    "UIInterfaceOrientationPortrait",
    "UIInterfaceOrientationLandscapeLeft",
    "UIInterfaceOrientationLandscapeRight",
]
IPAD_ORIENTATIONS = [
    "UIInterfaceOrientationPortrait",
    "UIInterfaceOrientationPortraitUpsideDown",
    "UIInterfaceOrientationLandscapeLeft",
    "UIInterfaceOrientationLandscapeRight",
]

# Still retired: the app never WRITES to the photo library.
RETIRED_PERMISSIONS = ("NSPhotoLibraryAddUsageDescription",)


def configure(path: Path) -> None:
    if not path.is_file():
        raise FileNotFoundError(path)
    with path.open("rb") as f:
        data = plistlib.load(f)
    if not isinstance(data, dict):
        raise ValueError("Info.plist root must be a dictionary")
    data["CFBundleDisplayName"] = DISPLAY_NAME
    # SNIPER TÜRK does not ship custom/non-exempt cryptography. HTTPS/TLS used
    # by platform networking is exempt; declare this deterministically so the
    # archive does not depend on an App Store Connect export-compliance prompt.
    data["ITSAppUsesNonExemptEncryption"] = USES_NON_EXEMPT_ENCRYPTION
    for unused_permission in RETIRED_PERMISSIONS:
        data.pop(unused_permission, None)
    data.update(USAGE_DESCRIPTIONS)
    data["UISupportedInterfaceOrientations"] = list(IPHONE_ORIENTATIONS)
    if "UISupportedInterfaceOrientations~ipad" in data:
        data["UISupportedInterfaceOrientations~ipad"] = list(IPAD_ORIENTATIONS)
    with path.open("wb") as f:
        plistlib.dump(data, f, sort_keys=False)


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("plist", type=Path)
    args = p.parse_args()
    try:
        configure(args.plist)
    except (OSError, ValueError, plistlib.InvalidFileException) as exc:
        print(f"Failed to configure iOS Info.plist: {exc}", file=sys.stderr)
        return 1
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
