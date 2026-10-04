# V357

- Hardened independent py-ballisticcalc fixture publication: generation now writes a temporary file in `validation/`, disables non-standard NaN/Infinity JSON output, fsyncs it, runs the canonical fixture validator, and only then atomically replaces `py_ballisticcalc_vectors.json`.
- A failed generation/validation therefore cannot overwrite a previously valid local fixture with partial or malformed output.
- Added two regression guards for validation-before-replace and fail-closed temporary-file cleanup.
- No acceptance tolerance, solver equation, production-gate, or UI activation change.
