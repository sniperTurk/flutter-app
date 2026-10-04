from pathlib import Path
import importlib.util
import tempfile
import unittest

MODULE_PATH = Path(__file__).with_name('offline_dart_lint.py')
spec = importlib.util.spec_from_file_location('offline_dart_lint', MODULE_PATH)
lint = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lint)


class OfflineDartLintTest(unittest.TestCase):
    def test_rejects_literal_newline_escape_outside_string(self):
        self.assertEqual(lint.stray_backslashes("final a = 1;\\nfinal b = 2;"), [(1, 13)])

    def test_rejects_backslash_even_without_line_start_anchor(self):
        self.assertTrue(lint.stray_backslashes("}\\nclass Next {}"))

    def test_allows_normal_escaped_string(self):
        self.assertEqual(lint.stray_backslashes(r"final s = 'line\\nnext';"), [])

    def test_allows_raw_string_backslash(self):
        self.assertEqual(lint.stray_backslashes(r"final s = r'\\n';"), [])

    def test_allows_backslash_in_comments(self):
        self.assertEqual(lint.stray_backslashes("// \\n/* \\ */\nfinal x = 1;"), [])

    def test_allows_simple_identifier_interpolation(self):
        self.assertEqual(lint.stray_backslashes('final s = "value: $name";'), [])

    def test_scan_honors_explicit_root(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / 'lib').mkdir()
            bad = root / 'lib' / 'bad.dart'
            bad.write_text('final a = 1;\\nfinal b = 2;', encoding='utf-8')
            problems = lint.scan(root)
            self.assertEqual(len(problems), 1)
            self.assertTrue(problems[0].startswith('lib/bad.dart:1:'))

    def test_real_source_newline_replacement_is_detected(self):
        path = lint.ROOT / 'lib' / 'features' / 'catalog' / 'catalog_screen.dart'
        text = path.read_text(encoding='utf-8')
        marker = "    final details = <String>[\n"
        self.assertIn(marker, text)
        corrupted = text.replace(marker, "    final details = <String>[\\n", 1)
        self.assertTrue(lint.stray_backslashes(corrupted))

    def test_real_tree_is_clean(self):
        self.assertEqual(lint.scan(), [])


def _messages(src: str) -> list[str]:
    return [m for _, _, m in lint.structural_problems(src)]


class OfflineDartStructuralLintTest(unittest.TestCase):
    """Delimiter / string / comment structure (v178).

    v167 replaced the v166 lexer with a stray-backslash-only checker, so a
    deleted closing brace or an unterminated string passed the whole offline
    chain and only surfaced in a real ``flutter analyze``. These tests pin the
    structural checks back in, with both true positives and the legal Dart
    constructs that must never be flagged.
    """

    # --- must be clean -------------------------------------------------
    def test_clean_class_has_no_problems(self):
        src = "class A {\n  final int x;\n  A(this.x);\n  int f(List<int> xs) => xs.fold(0, (a, b) => a + b) + x;\n}\n"
        self.assertEqual(lint.structural_problems(src), [])

    def test_delimiters_inside_strings_and_comments_are_ignored(self):
        src = "// { [ (\n/* } ] ) */\nfinal s = '{[(';\nfinal t = \"}])\";\n"
        self.assertEqual(lint.structural_problems(src), [])

    def test_nested_block_comments_are_legal(self):
        self.assertEqual(lint.structural_problems("/* a /* b */ c */\nint x = 1;\n"), [])

    def test_interpolation_with_nested_braces_and_strings(self):
        src = "final a = 'x ${ {'k': 1}['k'] } y ${b.map((e) => '${e}').join(\",\")} z $c';\n"
        self.assertEqual(lint.structural_problems(src), [])

    def test_triple_quoted_multiline_string_with_quotes_inside(self):
        src = "const s = '''\nline 'one'\nline \"two\" ${1 + 2}\n''';\nint x = 1;\n"
        self.assertEqual(lint.structural_problems(src), [])

    def test_raw_strings_do_not_interpolate_or_escape(self):
        src = "final a = r'${ not interpolation \\';\nfinal b = r\"{\";\n"
        self.assertEqual(lint.structural_problems(src), [])

    def test_escaped_quote_and_escaped_dollar(self):
        src = "final a = 'don\\'t ${1} \\${literal}';\n"
        self.assertEqual(lint.structural_problems(src), [])

    def test_identifier_ending_in_r_is_not_a_raw_string_prefix(self):
        self.assertEqual(lint.structural_problems("final bar = 'a\\nb';\n"), [])

    # --- must be flagged -----------------------------------------------
    def test_unclosed_brace_reports_its_opening_line(self):
        problems = lint.structural_problems("int a = 1;\nclass A {\n  int b;\n")
        self.assertEqual([(l, m) for l, _, m in problems], [(2, "unclosed '{' (reaches end of file)")])

    def test_stray_closer(self):
        self.assertTrue(any("stray closing '}'" in m for m in _messages("int x = 1;\n}\n")))

    def test_mismatched_delimiter(self):
        msgs = _messages("final xs = [1, 2, 3);\n")
        self.assertTrue(any("mismatched ')' closes '['" in m for m in msgs), msgs)

    def test_unterminated_single_line_string(self):
        problems = lint.structural_problems("final a = 1;\nfinal s = 'oops;\nfinal b = 2;\n")
        self.assertEqual([(l, m) for l, _, m in problems], [(2, "unterminated string literal (reaches end of line)")])

    def test_unterminated_triple_quoted_string(self):
        self.assertTrue(any("unterminated triple-quoted" in m for m in _messages("const s = '''\nnever closed\n")))

    def test_unterminated_block_comment(self):
        self.assertTrue(any("unterminated block comment" in m for m in _messages("/* open\nint x = 1;\n")))

    def test_unterminated_interpolation(self):
        self.assertTrue(any("interpolation" in m for m in _messages("final s = '${a + ';\n")))

    def test_multiple_problems_are_all_reported_in_line_order(self):
        problems = lint.structural_problems("class A {\nfinal s = 'x;\n")
        lines = [l for l, _, _ in problems]
        self.assertEqual(lines, sorted(lines))
        self.assertGreaterEqual(len(problems), 2)

    # --- integration with scan() and the real tree ----------------------
    def test_scan_reports_structural_problems_with_relative_path(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / 'lib').mkdir()
            (root / 'lib' / 'broken.dart').write_text('class A {\n', encoding='utf-8')
            problems = lint.scan(root)
            self.assertEqual(len(problems), 1)
            self.assertTrue(problems[0].startswith('lib/broken.dart:1:9: unclosed'), problems)

    def test_deleting_a_real_closing_brace_is_detected(self):
        path = lint.ROOT / 'lib' / 'features' / 'catalog' / 'catalog_screen.dart'
        text = path.read_text(encoding='utf-8')
        cut = text.rindex('}')
        self.assertTrue(lint.structural_problems(text[:cut] + text[cut + 1:]))

    def test_deleting_a_real_closing_quote_is_detected(self):
        path = lint.ROOT / 'lib' / 'data' / 'catalog_integrity.dart'
        text = path.read_text(encoding='utf-8')
        marker = "'id is required'"
        self.assertIn(marker, text)
        self.assertTrue(lint.structural_problems(text.replace(marker, "'id is required", 1)))

    def test_every_real_dart_file_is_structurally_clean(self):
        offenders = []
        for name in lint.SCAN_NAMES:
            for path in sorted((lint.ROOT / name).rglob('*.dart')):
                problems = lint.structural_problems(path.read_text(encoding='utf-8'))
                if problems:
                    offenders.append(f"{path.relative_to(lint.ROOT)}: {problems[0]}")
        self.assertEqual(offenders, [])


if __name__ == '__main__':
    unittest.main()
