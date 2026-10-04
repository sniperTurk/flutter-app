# V363 CHANGELOG

Baseline: V362 M2 Menzil design integration.

## Fixed
- Tools > Sight Height subtitle no longer claims the removed front-photo flow.
- The subtitle now describes the two supported independent paths: physical measurement or side photo.
- Added a source-contract regression test preventing `yan ve ön fotoğraf` from returning.

## Preserved
- V362 M2 Sight Height physical/photo implementation.
- Compass true-north fail-closed behavior.
- Level circle + X/Y tubes.
- Ballistic solver and `validation/acceptance.json` unchanged.
- Production G1/G7 gate remains CLOSED until its acceptance evidence exists.

## Verification
See final V363 delivery report. Flutter/iOS checks remain NOT RUN unless explicitly reported otherwise.
