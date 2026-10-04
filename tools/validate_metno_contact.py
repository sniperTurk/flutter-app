#!/usr/bin/env python3
"""Fail-closed validation of the MET Norway contact passed as --dart-define=METNO_CONTACT.

MET Norway's terms require an identifying User-Agent with real contact
information. This tool NEVER supplies a value: it only rejects an empty,
placeholder-looking or malformed one, so a release build cannot ship with the
weather service permanently disabled (ToolsConfig falls back to CONTACT_REQUIRED).
"""
from __future__ import annotations
import re
import sys

EMAIL = re.compile(r"^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$")
URL = re.compile(r"^https://[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+(/[^\s]*)?$")
PLACEHOLDER_HINTS = ("contact_required", "example.", "ornek@", "alanadi", "localhost", "your", "changeme", "test@")
MAX_LEN = 120


def validate(value: str) -> list[str]:
    errors: list[str] = []
    v = value or ""
    if not v.strip():
        return ["METNO_CONTACT is empty: set the repository variable METNO_CONTACT to a real e-mail or https:// website."]
    if v != v.strip() or any(c.isspace() or ord(c) < 32 or ord(c) > 126 for c in v):
        errors.append("METNO_CONTACT must be plain printable ASCII without whitespace (it becomes an HTTP header value).")
    if len(v) > MAX_LEN:
        errors.append(f"METNO_CONTACT longer than {MAX_LEN} characters.")
    low = v.lower()
    for hint in PLACEHOLDER_HINTS:
        if hint in low:
            errors.append(f"METNO_CONTACT looks like a placeholder ('{hint}').")
    if not (EMAIL.match(v) or URL.match(v)):
        errors.append("METNO_CONTACT must be an e-mail address or an https:// URL.")
    return errors


def main(argv: list[str]) -> int:
    value = argv[1] if len(argv) > 1 else ""
    errors = validate(value)
    for e in errors:
        print(f"ERROR: {e}", file=sys.stderr)
    if not errors:
        print("METNO_CONTACT format OK (value not echoed)")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
