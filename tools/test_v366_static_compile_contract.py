"""V366: static guards for defects that Flutter would reject but Python cannot compile.

These are source-text checks only; they do NOT replace flutter analyze/test.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]


def dart_files(*bases):
    for base in bases:
        yield from sorted((ROOT / base).rglob('*.dart'))


class StaticCompileContract(unittest.TestCase):
    def test_shouldRepaint_overrides_use_covariant(self):
        # Narrowing the parameter type of an override without `covariant` is a compile error.
        bad = []
        for p in dart_files('lib'):
            for m in re.finditer(r'bool shouldRepaint\((?!covariant )(\w+)\s', p.read_text(encoding='utf-8')):
                if m.group(1) != 'CustomPainter':
                    bad.append(p.relative_to(ROOT).as_posix())
        self.assertEqual([], bad)

    def test_test_host_installs_the_services_scope_above_the_navigator(self):
        text = (ROOT / 'test/support/tool_fakes.dart').read_text(encoding='utf-8')
        host = text[text.index('Widget host('):]
        self.assertIn('builder: (context, c) => ToolsServicesScope(', host)
        self.assertIn('home: child,', host)

    def test_objective_dialog_owns_and_disposes_its_controller(self):
        text = (ROOT / 'lib/features/tools/sight_height_screen.dart').read_text(encoding='utf-8')
        self.assertIn('class _ObjectiveDiameterDialog extends StatefulWidget', text)
        self.assertNotIn('controller.dispose();\n    return value;', text)

    def test_typed_data_import_next_to_services_is_marked(self):
        text = (ROOT / 'lib/features/tools/sight_height_screen.dart').read_text(encoding='utf-8')
        self.assertIn("// ignore: unnecessary_import\nimport 'dart:typed_data';", text)

    def test_generated_art_silences_const_lints_explicitly(self):
        text = (ROOT / 'lib/ui/sight_height_art.dart').read_text(encoding='utf-8')
        self.assertIn('ignore_for_file: prefer_const_constructors', text)

    def test_tools_hub_widget_test_matches_the_seven_v1_tools(self):
        text = (ROOT / 'test/menzil_shell_test.dart').read_text(encoding='utf-8')
        self.assertNotIn("'Kronograf', 'Pusula', 'Su terazisi'", text)

    def test_bootstrap_workflow_timeout_matches_ios_ci(self):
        wf = (ROOT / '.github/workflows/bootstrap-lockfile.yml').read_text(encoding='utf-8')
        self.assertIn('timeout-minutes: 30', wf)


if __name__ == '__main__':
    unittest.main()
