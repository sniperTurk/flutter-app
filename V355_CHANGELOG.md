# V355 — Dart acceptance physical-domain parity

- Hardened the official Dart reference-vector comparator so it independently rejects non-physical fixture values instead of relying on the Python preflight validator.
- Requires positive BC, muzzle velocity, projectile mass, zero range, sight height, reference range, reference velocity, and reference time-of-flight.
- Requires positive atmospheric pressure and humidity within 0..100%.
- Requires strictly increasing reference ranges and unique non-empty case IDs.
- Added source-contract regression coverage for these fail-closed checks.
- No acceptance tolerance, reference vector, solver equation, UI activation, or production-gate state was changed.
