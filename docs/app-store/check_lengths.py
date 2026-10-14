#!/usr/bin/env python3
"""Check App Store metadata drafts in 01-magaza-metinleri.md against limits.

Limits (Apple App Store Connect help, 2026-10-11):
  name 30 chars, subtitle 30 chars, promotional text 170 chars,
  description 4000 chars, keywords 100 bytes, what's new 4000 chars.
Exit code 1 when a usable draft exceeds a limit or a stated count is wrong.
Rows explicitly marked "too long" are reported but not counted as failures.

Since 2026-10-14 (owner chose name and subtitle): exactly one name and one
subtitle row per language must be marked SEÇİLDİ / CHOSEN, and the keywords
of that language must not repeat a word of the chosen name or subtitle
(Apple already indexes those words).
"""
from __future__ import annotations
import re, sys
from pathlib import Path

DOC = Path(__file__).with_name("01-magaza-metinleri.md")
BLOCK_LIMITS = [  # (heading prefix, limit, unit)
    (("Tanıtım metni", "Promotional text"), 170, "chars"),
    (("Açıklama", "Description"), 4000, "chars"),
    (("Anahtar kelimeler", "Keywords"), 100, "bytes"),
    (("Yenilikler", "What's New"), 4000, "chars"),
]
TABLE_HEADINGS = ("Ad önerileri", "Alt başlık önerileri", "Name options", "Subtitle options")


def name_words(text: str) -> set[str]:
    """Lower-cased words, Turkish dotted/dotless I handled."""
    text = text.replace("İ", "i").replace("I", "ı") if any(
        ch in text for ch in "çğıöşüÇĞİÖŞÜ") else text
    return {w for w in re.split(r"[^\w]+", text.lower()) if w}


def main() -> int:
    text = DOC.read_text(encoding="utf-8")
    heading, failures = "", 0
    in_block, buf = False, []
    lang = ""
    chosen: dict[str, dict[str, str]] = {}
    keywords: dict[str, str] = {}
    for line in text.splitlines():
        if line.startswith("```"):
            if in_block:
                body = "\n".join(buf)
                for prefixes, limit, unit in BLOCK_LIMITS:
                    if heading.startswith(prefixes):
                        n = len(body.encode("utf-8")) if unit == "bytes" else len(body)
                        ok = n <= limit
                        failures += not ok
                        print(f"{'OK ' if ok else 'FAIL'} {heading}: {n}/{limit} {unit}")
                        if unit == "bytes":
                            words = body.split(",")
                            if any(w != w.strip() or not w for w in words):
                                print("FAIL keywords: spaces or empty items")
                                failures += 1
                            keywords[lang] = body
                            if len(set(words)) != len(words):
                                print("FAIL keywords: duplicates")
                                failures += 1
                buf = []
            in_block = not in_block
            continue
        if in_block:
            buf.append(line)
            continue
        if line.startswith("### "):
            heading = line[4:].strip()
            continue
        if line.startswith(("# ", "## ")):
            heading = ""
            if line.startswith("## "):
                lang = line[3:].strip()
            continue
        if heading.startswith(TABLE_HEADINGS):
            m = re.match(r"\|[^|]*\|\s*`([^`]+)`\s*\|\s*(\d+)(.*)\|", line)
            if m:
                value, stated, rest = m.group(1), int(m.group(2)), m.group(3)
                n = len(value)
                marked_long = "too long" in rest.lower() or "uzun" in rest.lower()
                bad_count = n != stated
                over = n > 30 and not marked_long
                failures += bad_count or over
                tag = "FAIL" if bad_count or over else ("NOTE" if n > 30 else "OK ")
                print(f"{tag} {heading} '{value}': {n}/30 (stated {stated})")
                if "SEÇİLDİ" in rest or "CHOSEN" in rest:
                    kind = "name" if heading.startswith(("Ad ", "Name")) else "subtitle"
                    if kind in chosen.setdefault(lang, {}):
                        print(f"FAIL {lang}: more than one chosen {kind}")
                        failures += 1
                    chosen[lang][kind] = value
    for lang_name, picked in chosen.items():
        if set(picked) != {"name", "subtitle"}:
            print(f"FAIL {lang_name}: chosen name and subtitle both required")
            failures += 1
        kw = keywords.get(lang_name)
        if kw is None:
            print(f"FAIL {lang_name}: no keywords block")
            failures += 1
            continue
        taken = name_words(" ".join(picked.values()))
        repeated = sorted(set(w.strip().lower() for w in kw.split(",")) & taken)
        if repeated:
            print(f"FAIL {lang_name} keywords repeat name/subtitle words: {repeated}")
            failures += 1
        else:
            print(f"OK  {lang_name} keywords repeat no name/subtitle word")
    if not chosen:
        print("FAIL no chosen name/subtitle rows")
        failures += 1
    print("FAILED" if failures else "ALL OK")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
