#!/usr/bin/env python3
"""Compatibility entry point for the canonical py-ballisticcalc fixture validator.

The original v262 validator described an obsolete ``vectors`` fixture shape.
Production reference generation and the Dart comparator now use the canonical
``cases``/``points`` schema enforced by ``validate_py_ballisticcalc_fixture``.
Keeping two independent contracts is unsafe, so this legacy command delegates
to the canonical validator and cannot accept the obsolete schema anymore.
"""
from pathlib import Path
import sys

from validate_py_ballisticcalc_fixture import validate


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit('usage: validate_ballistic_reference_vectors.py FIXTURE.json')
    errors = validate(Path(sys.argv[1]))
    if errors:
        print('\n'.join('ERROR: ' + error for error in errors))
        raise SystemExit(1)
    print('PASS: canonical py-ballisticcalc fixture contract satisfied')


if __name__ == '__main__':
    main()
