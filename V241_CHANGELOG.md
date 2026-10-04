# V241 Change Log

- Sight Height side-photo point placement now uses the actual `BoxFit.contain` rendered image rectangle.
- Taps in letterbox/pillarbox space are rejected instead of being accepted as measurement coordinates.
- Dragged calibration/axis points are clamped to the visible photo bounds, not the full 260px viewport.
- The decoded side-photo dimensions are retained to compute the rendered image rectangle deterministically.
- Added offline regression coverage for photo-bound coordinate safety.

Validation note: this environment still requires the pinned Flutter SDK/Xcode path for real Dart/Swift/iOS build validation. Offline source-contract tests are not a substitute for compilation.
