"""Audit 2026-10-15b (pre-TestFlight): no secret is committed and every
compile-time UI flag in lib/ defaults to off.

Offline: reads `git ls-files` and the working tree only; no network, no
Flutter. Ids: SEC-1 (secrets), FLG-1 (flags).
"""
from __future__ import annotations

import re
import shutil
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SELF = Path(__file__).resolve()

# Patterns are assembled from pieces so this file never matches itself.
_SECRET_PATTERNS = {
    'Google API key': re.compile('AI' + r'za[0-9A-Za-z_\-]{35}'),
    'Anthropic key': re.compile('sk-' + r'ant-[A-Za-z0-9_\-]{10,}'),
    'OpenAI key': re.compile(r'\bsk-' + r'(?:proj-)?[A-Za-z0-9]{20,}'),
    'GitHub token': re.compile('gh' + r'[pousr]_[A-Za-z0-9]{30,}'),
    'GitHub fine-grained token': re.compile('github' + r'_pat_[A-Za-z0-9_]{20,}'),
    'PEM private key': re.compile('-----BEGIN ' + r'[A-Z ]*PRIVATE KEY-----'),
    'AWS access key': re.compile('AK' + r'IA[0-9A-Z]{16}'),
}

# Signing material and service-config files that must never be tracked.
_FORBIDDEN_SUFFIXES = (
    '.p8', '.p12', '.pfx', '.mobileprovision', '.provisionprofile',
    '.pem', '.key', '.jks', '.keystore', '.cer', '.certSigningRequest',
)
_FORBIDDEN_NAMES = ('GoogleService-Info.plist', 'google-services.json', '.env')

# Long base64-looking runs inside plist / xcconfig (embedded certs/keys).
_BASE64_RUN = re.compile(r'[A-Za-z0-9+/]{80,}={0,2}')

# Flags present on main at d86dfff (before this audit range). A flag added
# after the 2026-10-15 "delete, do not hide" rule is reported as FLG-1.
_FLAGS_AT_BASE = {
    'PROFILE_BACKUP_BUTTONS', 'SCOPE_LISTEDE_YOK', 'RIFLE_LISTEDE_YOK',
    'AMMO_BC_BANDS_TYPED', 'AMMO_LISTEDE_YOK', 'PCP_AMMO_BRAND',
    'PROFILE_AMMO_LENGTH', 'WELCOME_RESTORE', 'SHOT_SAMPLE_PREVIEW',
    'SHOT_TABLE_SWITCH', 'GOOGLE_MAPS_ENABLED', 'WIND_OBSERVATION',
    'PRO_TUBE_PRESSURE',
}

# The only --dart-define names a release/TestFlight build may pass. A UI flag
# turned on in a release workflow would ship a hidden feature.
# APP_BUILD_NUMBER (2026-10-17): the TestFlight build number for the
# "uygulamaSurumu" of a product report; a number, not a UI flag.
_ALLOWED_RELEASE_DEFINES = {
    'METNO_CONTACT', 'GOOGLE_MAPS_ENABLED', 'GOOGLE_MAPS_IOS_API_KEY',
    'APP_BUILD_NUMBER',
}

_BOOL_FLAG = re.compile(
    r'bool\.fromEnvironment\(\s*[\'"]([A-Z0-9_]+)[\'"]\s*(?:,\s*defaultValue\s*:\s*([a-z]+)\s*)?,?\s*\)',
    re.S,
)
_ANY_BOOL_FLAG = re.compile(r'bool\.fromEnvironment\(')
_STRING_ENV = re.compile(
    r'String\.fromEnvironment\(\s*[\'"]([A-Z0-9_]+)[\'"]\s*(?:,\s*defaultValue\s*:\s*([^)]*?))?,?\s*\)',
    re.S,
)
_DART_DEFINE = re.compile(r'--dart-define=([A-Z0-9_]+)=')


def _have_git() -> bool:
    if shutil.which('git') is None:
        return False
    r = subprocess.run(['git', 'rev-parse', '--is-inside-work-tree'], cwd=ROOT,
                       capture_output=True, text=True)
    return r.returncode == 0


def _tracked() -> list[Path]:
    out = subprocess.run(['git', 'ls-files', '-z'], cwd=ROOT, check=True,
                         capture_output=True).stdout
    return [ROOT / p for p in out.decode('utf-8').split('\0') if p]


def _text(p: Path) -> str | None:
    try:
        data = p.read_bytes()
    except (OSError, IsADirectoryError):
        return None
    if b'\0' in data[:8192]:
        return None  # binary
    return data.decode('utf-8', errors='replace')


def _lib_dart() -> dict[Path, str]:
    return {p: p.read_text(encoding='utf-8') for p in sorted((ROOT / 'lib').rglob('*.dart'))}


@unittest.skipUnless(_have_git(), 'git not available')
class Sec1NoSecretCommitted(unittest.TestCase):
    """SEC-1: no API key, token or signing material in tracked files."""

    def test_no_secret_pattern_in_tracked_text_files(self):
        hits = []
        for p in _tracked():
            if p.resolve() == SELF:
                continue
            src = _text(p)
            if src is None:
                continue
            for name, pat in _SECRET_PATTERNS.items():
                for m in pat.finditer(src):
                    line = src.count('\n', 0, m.start()) + 1
                    hits.append(f'{p.relative_to(ROOT)}:{line}: {name}')
        self.assertEqual(hits, [], 'secret-like text committed')

    def test_no_signing_or_service_config_file_tracked(self):
        bad = [str(p.relative_to(ROOT)) for p in _tracked()
               if p.name.endswith(_FORBIDDEN_SUFFIXES) or p.name in _FORBIDDEN_NAMES]
        self.assertEqual(bad, [])

    def test_no_base64_blob_in_plist_or_xcconfig(self):
        hits = []
        for p in _tracked():
            if p.suffix not in ('.plist', '.xcconfig', '.entitlements'):
                continue
            src = _text(p) or ''
            if _BASE64_RUN.search(src):
                hits.append(str(p.relative_to(ROOT)))
        self.assertEqual(hits, [])

    def test_workflow_keys_come_only_from_secrets(self):
        wf = ROOT / '.github' / 'workflows'
        for p in sorted(wf.glob('*.yml')):
            src = p.read_text(encoding='utf-8')
            for m in re.finditer(r'^\s*(GOOGLE_MAPS_IOS_API_KEY|ASC_KEY_P8|ASC_KEY_ID|'
                                 r'ASC_ISSUER_ID|APPETIZE_API_TOKEN|ANTHROPIC_API_KEY)\s*:\s*(.+)$',
                                 src, re.M):
                with self.subTest(file=p.name, var=m.group(1)):
                    self.assertRegex(m.group(2).strip(),
                                     r'^\$\{\{\s*secrets\.[A-Z0-9_]+\s*\}\}$')

    def test_no_anthropic_client_or_key_in_app_code(self):
        # docs/specs/2026-10-15-claude-urun-bul-design.md: the Anthropic key
        # lives only on the owner's server, never in the app.
        for p, src in _lib_dart().items():
            with self.subTest(file=str(p.relative_to(ROOT))):
                self.assertNotIn('api.anthropic.com', src)
                self.assertNotIn('x-api-key', src.lower())
                self.assertNotIn('ANTHROPIC_API_KEY', src)

    def test_string_env_has_no_secret_default(self):
        for p, src in _lib_dart().items():
            for m in _STRING_ENV.finditer(src):
                default = (m.group(2) or '').strip()
                with self.subTest(file=str(p.relative_to(ROOT)), name=m.group(1)):
                    self.assertIn(default, ('', "''", '""'))


class Flg1FlagsDefaultOff(unittest.TestCase):
    """FLG-1: every bool.fromEnvironment in lib/ defaults to false."""

    def _flags(self) -> list[tuple[str, str, str | None]]:
        found = []
        for p, src in _lib_dart().items():
            total = len(_ANY_BOOL_FLAG.findall(src))
            parsed = list(_BOOL_FLAG.finditer(src))
            self.assertEqual(len(parsed), total,
                             f'{p.relative_to(ROOT)}: unparsed bool.fromEnvironment')
            for m in parsed:
                found.append((str(p.relative_to(ROOT)), m.group(1), m.group(2)))
        return found

    def test_flags_found(self):
        # 14 at the audit; PCP_AMMO_BRAND and PRO_TUBE_PRESSURE (two reads)
        # were deleted on 2026-10-16 and PROFILE_AMMO_LENGTH on 2026-10-17
        # (owner: delete, do not hide; Mermi uzunluğu back on Profil);
        # AMMO_LISTEDE_YOK on 2026-10-17 ("Diğer marka" replaces it).
        self.assertGreaterEqual(len(self._flags()), 9)

    def test_every_bool_flag_defaults_false(self):
        for path, name, default in self._flags():
            with self.subTest(path=path, flag=name):
                self.assertIn(default, (None, 'false'))

    def test_release_workflows_turn_on_no_ui_flag(self):
        wf = ROOT / '.github' / 'workflows'
        for name in ('ios-testflight.yml', 'ios-ci.yml'):
            src = (wf / name).read_text(encoding='utf-8')
            defines = set(_DART_DEFINE.findall(src))
            with self.subTest(workflow=name):
                self.assertLessEqual(defines, _ALLOWED_RELEASE_DEFINES)

    # FLG-1 (= HDF-1, fixed by fix/hdf1-ruzgar-rehberi-sil): WIND_GUIDE_LINK,
    # added in #317 after the 2026-10-15 "delete, do not hide" rule, is gone.
    def test_no_new_flag_after_delete_not_hide_rule(self):
        names = {name for _, name, _ in self._flags()}
        self.assertLessEqual(names, _FLAGS_AT_BASE)


if __name__ == '__main__':
    unittest.main()
