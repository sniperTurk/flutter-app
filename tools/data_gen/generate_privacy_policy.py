"""Gizlilik politikası: the in-app text comes from the app-store doc.

The Turkish policy between the `uygulama-metni` markers in
docs/app-store/03-gizlilik-politikasi.md is the single source. This script
writes lib/features/guide/privacy_policy_content.dart (Araçlar > Gizlilik
politikası) from it; tools/test_privacy_policy_sync.py checks the two agree.
Edit the doc, then run: python3 tools/data_gen/generate_privacy_policy.py
"""
import sys
import textwrap
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DOC = ROOT / "docs/app-store/03-gizlilik-politikasi.md"
OUT = ROOT / "lib/features/guide/privacy_policy_content.dart"
START = "<!-- uygulama-metni:başla -->"
END = "<!-- uygulama-metni:bitti -->"


def parse(doc_text: str):
    """Returns (heading, updated, [(section title, [paragraph, ...]), ...]).

    Paragraphs are blank-line separated blocks joined into one line; a block
    starting with "- " becomes a "• " bullet paragraph.
    """
    body = doc_text.split(START, 1)[1].split(END, 1)[0]
    blocks = [b.strip() for b in body.strip().split("\n\n") if b.strip()]
    heading = updated = None
    sections = []
    for block in blocks:
        if block.startswith("# "):
            heading = block[2:].strip()
            continue
        if block.startswith("## "):
            sections.append((block[3:].strip(), []))
            continue
        text = " ".join(line.strip() for line in block.splitlines())
        if text.startswith("- "):
            text = "• " + text[2:]
        if not sections:
            updated = text
        else:
            sections[-1][1].append(text)
    if heading is None or updated is None or not sections:
        raise SystemExit("03-gizlilik-politikasi.md: policy block is incomplete")
    return heading, updated, sections


def dart_str(text: str, indent: int, continuation: int = 0) -> str:
    """Adjacent string literals laid out the way `dart format` keeps them."""
    esc = text.replace("\\", "\\\\").replace("'", "\\'").replace("$", "\\$")
    width = 80 - indent - 3
    parts = textwrap.wrap(esc, width=width, drop_whitespace=False,
                          break_long_words=False, break_on_hyphens=False)
    first = " " * indent
    rest = " " * (indent + continuation)
    return "\n".join(f"{first if i == 0 else rest}'{p}'" for i, p in enumerate(parts))


def const_str(name: str, text: str) -> list[str]:
    """`static const String name = '...';` on one line when it fits."""
    one = f"  static const String {name} = {dart_str(text, 0)};"
    if len(one) <= 80 and "\n" not in one:
        return [one]
    return [f"  static const String {name} =", dart_str(text, 6) + ";"]


def dart(doc_text: str) -> str:
    heading, updated, sections = parse(doc_text)
    lines = [
        "/// Gizlilik politikası text (Araçlar > Gizlilik politikası).",
        "///",
        "/// GENERATED from the Turkish policy in",
        "/// docs/app-store/03-gizlilik-politikasi.md by",
        "/// tools/data_gen/generate_privacy_policy.py; do not edit by hand",
        "/// (tools/test_privacy_policy_sync.py compares the two). The text is",
        "/// built into the app so the policy opens offline (App Review",
        "/// 5.1.1(i)).",
        "class PrivacyPolicySection {",
        "  final String title;",
        "  final List<String> paragraphs;",
        "",
        "  const PrivacyPolicySection(this.title, this.paragraphs);",
        "}",
        "",
        "abstract final class PrivacyPolicyContent {",
        *const_str("heading", heading),
        "",
        *const_str("updated", updated),
        "",
        "  static const List<PrivacyPolicySection> sections = [",
    ]
    for title, paras in sections:
        lines.append(f"    PrivacyPolicySection({dart_str(title, 0)}, [")
        for p in paras:
            lines.append(dart_str(p, 6, 4) + ",")
        lines.append("    ]),")
    lines += ["  ];", "}", ""]
    return "\n".join(lines)


if __name__ == "__main__":
    OUT.write_text(dart(DOC.read_text(encoding="utf-8")), encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)}")
