# V197

- Fixed an asynchronous unit-preference race in Balistik / DOPE: imperial conversion now parses and validates the complete SI form before mutating any controller.
- A parse failure can no longer leave a partially converted form labelled as metric.
- Decimal-comma input is accepted by the delayed unit conversion path, matching the normal solve parser.
- Added regression guards for atomic conversion ordering, locale decimal parsing, and metric-state commit ordering.
- No claim is made for Dart/Flutter/Xcode execution in this environment.
