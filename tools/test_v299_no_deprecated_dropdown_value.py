import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

class DropdownValuePolicyTest(unittest.TestCase):
    def test_dropdown_button_form_field_does_not_use_deprecated_value(self):
        offenders = []
        pattern = re.compile(r'DropdownButtonFormField(?:<[^>]+>)?\s*\((.*?)\)', re.S)
        for path in (ROOT / 'lib').rglob('*.dart'):
            text = path.read_text(encoding='utf-8')
            for match in pattern.finditer(text):
                body = match.group(1)
                if re.search(r'(^|[,\n])\s*value\s*:', body):
                    line = text.count('\n', 0, match.start()) + 1
                    offenders.append(f'{path.relative_to(ROOT)}:{line}')
        self.assertEqual([], offenders, 'deprecated DropdownButtonFormField(value:) usage: ' + ', '.join(offenders))

    def test_dependent_dropdowns_are_keyed_because_initial_value_is_not_live(self):
        profiles = (ROOT / 'lib/features/profiles/profiles_screen.dart').read_text(encoding='utf-8')
        self.assertIn("key: ValueKey('profile-rifle-${platform.name}')", profiles)
        self.assertIn("key: ValueKey('profile-ammo-${rifle?.id}')", profiles)
        home = (ROOT / 'lib/features/home/home_screen.dart').read_text(encoding='utf-8')
        # Keyed on the active id AND a rollback epoch: a failed selection
        # must remount the field so it shows the still-active profile.
        self.assertIn("key: ValueKey(('active-profile', active?.id, _selectorEpoch))", home)
        self.assertIn("setState(() => _selectorEpoch++);", home)

if __name__ == '__main__':
    unittest.main()
