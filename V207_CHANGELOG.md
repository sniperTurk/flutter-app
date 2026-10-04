# SNIPER TÜRK V1 — v207

Continues directly from verified v206.

## Production progress
- Added three missing current FX Airguns .25 / 6.35 mm PCP catalog records from the manufacturer's current rifle lineup: Leopard, Panthera MKII and Dynamic MKII.
- Leopard stores only manufacturer-published stable values used by the catalog: 6.35 mm availability, 890 cc bottle-version onboard air, 54 cc plenum and APB/interchangeable-liner barrel description.
- Panthera MKII and Dynamic MKII store the manufacturer-published 6.35 mm availability and 30 MOA extended rail / ARCA / M-LOK configuration; variant-dependent numeric values not exposed by the official static data sheet are deliberately left absent rather than guessed.
- Added regression coverage locking provenance, IDs and the no-invented-specs rule.

## Validation boundary
- The independent py-ballisticcalc bootstrap was attempted in this environment and failed closed at PyPI metadata retrieval because DNS/network access is unavailable. No G1/G7 production activation was made and no failed validation was counted as a pass.
- Real Dart/Flutter/Xcode/iOS execution remains NOT RUN in this environment.
