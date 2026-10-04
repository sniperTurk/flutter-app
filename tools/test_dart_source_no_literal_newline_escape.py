from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]

# Narrow legacy regression guard. The lexer in offline_dart_lint.py is the
# authoritative check because a replaced physical newline removes the ^ anchor.
class DartSourceNoLiteralNewlineEscapeTest(unittest.TestCase):
    def test_no_literal_newline_escape_between_dart_declarations(self):
        offenders = []
        pattern = re.compile(r'(?m)^\\n(?=\s*(?://|/\\*|[A-Za-z_@}]))')
        for path in sorted((ROOT / 'lib').rglob('*.dart')):
            text = path.read_text(encoding='utf-8')
            if pattern.search(text):
                offenders.append(str(path.relative_to(ROOT)))
        self.assertEqual(offenders, [], 'literal \\n leaked between Dart declarations: ' + ', '.join(offenders))

if __name__ == '__main__':
    unittest.main()
