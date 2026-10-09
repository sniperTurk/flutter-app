from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import textwrap
import unittest

ROOT = Path(__file__).resolve().parents[1]
FILES = [
    'bootstrap_ios_scaffold.sh',
    'check_ios_manual_customizations.py',
    'configure_ios_info_plist.py',
    'configure_ios_signing.py',
    'configure_ios_google_maps.py',
    'configure_ios_branding.py',
]


class IosBootstrapRerunIdempotencyTests(unittest.TestCase):
    def test_same_reproducible_team_survives_full_bootstrap_rerun(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            tools = root / 'tools'
            tools.mkdir()
            for name in FILES:
                shutil.copy2(ROOT / 'tools' / name, tools / name)
            shutil.copytree(ROOT / 'branding', root / 'branding')
            (tools / 'verify_flutter_toolchain.py').write_text('raise SystemExit(0)\n', encoding='utf-8')
            (tools / 'configure_ios_privacy_manifest.rb').write_text('# fixture\n', encoding='utf-8')

            bindir = root / 'bin'
            bindir.mkdir()
            flutter = bindir / 'flutter'
            flutter.write_text(textwrap.dedent('''\
                #!/bin/sh
                set -eu
                [ "$1" = "create" ] || exit 0
                mkdir -p ios/Runner.xcodeproj ios/Runner.xcworkspace ios/Runner ios/Flutter
                cat > ios/Runner.xcodeproj/project.pbxproj <<'EOF'
                buildSettings = {
                  CODE_SIGN_STYLE = Automatic;
                  PRODUCT_BUNDLE_IDENTIFIER = com.sniperturk.sniperTurk;
                  IPHONEOS_DEPLOYMENT_TARGET = 15.0;
                };
                buildSettings = {
                  CODE_SIGN_STYLE = Automatic;
                  PRODUCT_BUNDLE_IDENTIFIER = com.sniperturk.sniperTurk;
                  IPHONEOS_DEPLOYMENT_TARGET = 15.0;
                };
                EOF
                printf workspace > ios/Runner.xcworkspace/contents.xcworkspacedata
                cat > ios/Runner/Info.plist <<'EOF'
                <?xml version="1.0" encoding="UTF-8"?>
                <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
                <plist version="1.0"><dict><key>CFBundleDisplayName</key><string>sniper_turk</string></dict></plist>
                EOF
                cat > ios/Runner/AppDelegate.swift <<'EOF'
                import Flutter
                import UIKit
                @main
                @objc class AppDelegate: FlutterAppDelegate {
                  override func application(
                    _ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
                  ) -> Bool {
                    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
                  }
                }
                EOF
                mkdir -p ios/Runner/Base.lproj
                printf '<view><color key="backgroundColor" red="1" green="1" blue="1" alpha="1" colorSpace="custom" customColorSpace="sRGB"/></view>' > ios/Runner/Base.lproj/LaunchScreen.storyboard
                printf debug > ios/Flutter/Debug.xcconfig
                printf release > ios/Flutter/Release.xcconfig
            '''), encoding='utf-8')
            flutter.chmod(0o755)

            ruby = bindir / 'ruby'
            ruby.write_text(textwrap.dedent('''\
                #!/bin/sh
                set -eu
                if [ "${1:-}" = "-e" ]; then exit 0; fi
                mkdir -p ios/Runner
                printf '{"NSPrivacyTracking":false}' > ios/Runner/PrivacyInfo.xcprivacy
            '''), encoding='utf-8')
            ruby.chmod(0o755)

            env = os.environ.copy()
            env['PATH'] = f"{bindir}:{env['PATH']}"
            env['SNIPER_TURK_IOS_DEVELOPMENT_TEAM'] = 'ABCDE12345'
            script = tools / 'bootstrap_ios_scaffold.sh'

            first = subprocess.run(['bash', str(script)], cwd=root, env=env, text=True, capture_output=True)
            self.assertEqual(0, first.returncode, first.stderr)
            pbx = root / 'ios/Runner.xcodeproj/project.pbxproj'
            self.assertEqual(2, pbx.read_text(encoding='utf-8').count('DEVELOPMENT_TEAM = ABCDE12345;'))

            second = subprocess.run(['bash', str(script)], cwd=root, env=env, text=True, capture_output=True)
            self.assertEqual(0, second.returncode, second.stderr)
            self.assertNotIn('refusing destructive refresh', second.stderr.lower())
            self.assertEqual(2, pbx.read_text(encoding='utf-8').count('DEVELOPMENT_TEAM = ABCDE12345;'))


if __name__ == '__main__':
    unittest.main()
