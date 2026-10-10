# App Store reference formulas (build 59, commit 0456485)

A frozen, byte-for-byte copy of `lib/core/` and `lib/models/domain.dart` as
they were in the build attached to App Store version 1.0 (TestFlight build 59,
`git show 0456485:lib/core/...`).

**Do not edit these files.** `test/formula_parity_app_store_test.dart` runs
the same shots through this copy and through the current `lib/core/` and
fails if any default result (G1/G7/GA, standard gravity, no custom drag
curve) moves. New, opt-in features (local gravity, other G functions, the
bullet's own drag curve) are checked separately by the same test so that the
App Store behaviour cannot change silently.

A formula change that is meant to change results must update this copy in
the same pull request, with the reason in the commit message.
