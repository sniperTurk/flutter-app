#!/usr/bin/env python3
"""Dependency-free Dart source hygiene checks used before Flutter is available.

This is intentionally not a Dart parser. It lexes comments and strings well
enough to reject a raw backslash token outside either. A literal ``\\n`` that
replaces a real source newline therefore cannot hide behind a line-start regex.

``structural_problems`` additionally reports the lexical errors that would stop
any Dart parser before it even reaches types or symbols: unbalanced or
mismatched ``{ } [ ] ( )``, unterminated single-line/triple-quoted strings,
unterminated ``${...}`` interpolation and unterminated (nestable) block
comments. It has no type or symbol knowledge and never replaces
``flutter analyze``.
"""
from __future__ import annotations

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
SCAN_NAMES = ("lib", "test", "integration_test")


def stray_backslashes(text: str) -> list[tuple[int, int]]:
    hits: list[tuple[int, int]] = []
    n = len(text)
    positions: list[tuple[int, int]] = []
    line = col = 1
    for ch in text:
        positions.append((line, col))
        if ch == "\n": line, col = line + 1, 1
        else: col += 1

    def string_at(i: int) -> tuple[int, bool, str] | None:
        raw = i + 1 < n and text[i] in "rR" and text[i + 1] in "'\""
        q = i + 1 if raw else i
        if q >= n or text[q] not in "'\"": return None
        quote = text[q]
        delim = quote * (3 if text.startswith(quote * 3, q) else 1)
        return q, raw, delim

    def scan_string(i: int) -> int:
        q, raw, delim = string_at(i)
        i = q + len(delim)
        while i < n:
            if text.startswith(delim, i): return i + len(delim)
            if not raw and text.startswith('${', i):
                i = scan_code(i + 2, stop_on_brace=True); continue
            # Dart also supports the simple $identifier interpolation form.
            # It contains no nested code tokens, so consume the identifier here
            # rather than letting its characters be mistaken for string content.
            if not raw and text[i] == '$' and i + 1 < n and (text[i + 1].isalpha() or text[i + 1] == '_'):
                i += 2
                while i < n and (text[i].isalnum() or text[i] == '_'):
                    i += 1
                continue
            if not raw and text[i] == "\\": i += min(2, n - i); continue
            i += 1
        return i

    def scan_code(i: int, stop_on_brace: bool = False) -> int:
        depth = 0
        while i < n:
            if text.startswith('//', i):
                j = text.find('\n', i + 2); i = n if j < 0 else j; continue
            if text.startswith('/*', i):
                i += 2; comment_depth = 1
                while i < n and comment_depth:
                    if text.startswith('/*', i): comment_depth += 1; i += 2
                    elif text.startswith('*/', i): comment_depth -= 1; i += 2
                    else: i += 1
                continue
            if string_at(i): i = scan_string(i); continue
            if stop_on_brace:
                if text[i] == '{': depth += 1
                elif text[i] == '}':
                    if depth == 0: return i + 1
                    depth -= 1
            if text[i] == "\\": hits.append(positions[i])
            i += 1
        return i

    scan_code(0)
    return hits


_OPEN_TO_CLOSE = {"{": "}", "[": "]", "(": ")"}
_CLOSERS = set(_OPEN_TO_CLOSE.values())


def _is_ident_char(ch: str) -> bool:
    return ch.isalnum() or ch in "_$"


def structural_problems(text: str) -> list[tuple[int, int, str]]:
    """Return ``(line, col, message)`` for lexical/structural Dart errors."""
    problems: list[tuple[int, int, str]] = []
    n = len(text)
    starts = [0] + [i + 1 for i, ch in enumerate(text) if ch == "\n"]

    def pos(i: int) -> tuple[int, int]:
        lo, hi = 0, len(starts) - 1
        while lo < hi:
            mid = (lo + hi + 1) // 2
            if starts[mid] <= i: lo = mid
            else: hi = mid - 1
        return lo + 1, i - starts[lo] + 1

    def report(i: int, message: str) -> None:
        line, col = pos(min(i, max(n - 1, 0)))
        problems.append((line, col, message))

    def string_prefix(i: int) -> tuple[int, bool] | None:
        """(index of opening quote, is_raw) when a string literal starts at i."""
        if text[i] in "'\"":
            return i, False
        if text[i] in "rR" and i + 1 < n and text[i + 1] in "'\"":
            if i > 0 and _is_ident_char(text[i - 1]):
                return None  # tail of an identifier, not a raw-string prefix
            return i + 1, True
        return None

    def scan_string(i: int) -> int:
        q, raw = string_prefix(i)  # type: ignore[misc]
        quote = text[q]
        triple = text.startswith(quote * 3, q)
        delim = quote * (3 if triple else 1)
        start = i
        i = q + len(delim)
        while i < n:
            if text.startswith(delim, i):
                return i + len(delim)
            ch = text[i]
            if not triple and ch == "\n":
                report(start, "unterminated string literal (reaches end of line)")
                return i
            if not raw and ch == "\\":
                i += min(2, n - i)
                continue
            if not raw and text.startswith("${", i):
                open_at = i
                i = scan_code(i + 2, in_interpolation=True, opened_at=open_at)
                continue
            if not raw and ch == "$" and i + 1 < n and (text[i + 1].isalpha() or text[i + 1] == "_"):
                i += 2
                while i < n and (text[i].isalnum() or text[i] == "_"):
                    i += 1
                continue
            i += 1
        report(start, ("unterminated triple-quoted string literal" if triple else "unterminated string literal") + " (reaches end of file)")
        return n

    def scan_code(i: int, in_interpolation: bool = False, opened_at: int = 0) -> int:
        stack: list[tuple[str, int]] = []
        while i < n:
            ch = text[i]
            if text.startswith("//", i):
                j = text.find("\n", i + 2)
                i = n if j < 0 else j
                continue
            if text.startswith("/*", i):
                start, depth = i, 1
                i += 2
                while i < n and depth:
                    if text.startswith("/*", i): depth += 1; i += 2
                    elif text.startswith("*/", i): depth -= 1; i += 2
                    else: i += 1
                if depth:
                    report(start, "unterminated block comment (reaches end of file)")
                continue
            if string_prefix(i):
                i = scan_string(i)
                continue
            if ch in _OPEN_TO_CLOSE:
                stack.append((ch, i))
            elif ch in _CLOSERS:
                if in_interpolation and ch == "}" and not stack:
                    return i + 1
                if not stack:
                    report(i, f"stray closing '{ch}' with no matching opener")
                else:
                    opener, at = stack.pop()
                    if _OPEN_TO_CLOSE[opener] != ch:
                        oline, _ = pos(at)
                        report(i, f"mismatched '{ch}' closes '{opener}' opened on line {oline}")
            i += 1
        for opener, at in stack:
            report(at, f"unclosed '{opener}' (reaches end of file)")
        if in_interpolation:
            report(opened_at, "unterminated string interpolation '${' (reaches end of file)")
        return n

    scan_code(0)
    return sorted(problems)


def scan(root: Path = ROOT) -> list[str]:
    problems: list[str] = []
    scan_dirs = tuple(root / name for name in SCAN_NAMES)
    for base in scan_dirs:
        if not base.exists():
            continue
        for path in sorted(base.rglob("*.dart")):
            text = path.read_text(encoding="utf-8")
            rel = path.relative_to(root)
            for line, col in stray_backslashes(text):
                problems.append(f"{rel}:{line}:{col}: stray backslash outside Dart string/comment")
            for line, col, message in structural_problems(text):
                problems.append(f"{rel}:{line}:{col}: {message}")
    return problems


def main() -> int:
    scan_dirs = tuple(ROOT / name for name in SCAN_NAMES)
    files = sum(1 for base in scan_dirs if base.exists() for _ in base.rglob("*.dart"))
    problems = scan()
    if problems:
        print("OFFLINE DART LINT FAILED", file=sys.stderr)
        print("\n".join(problems), file=sys.stderr)
        return 1
    print(f"OFFLINE DART LINT PASS: {files} Dart files, 0 issues")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
