# V193 — Catalog technical-detail and provenance UX

- Continued directly from V192; no project restart.
- Added tappable technical-detail sheets for rifle, ammunition, and scope catalog rows.
- Detail sheets expose the verified fields already stored in the catalog instead of forcing users to infer them from abbreviated list summaries.
- Provenance is now inspectable in the UI: source name and the full source-document/provenance note are shown, while unverified records remain explicitly labelled `Kaynak doğrulanmadı`.
- Scope detail rendering preserves strict lower-bound semantics (`>`) for manufacturer adjustment ranges; it does not silently present a lower bound as an exact value.
- The bottom sheet uses SafeArea + scrollable content for small iPhone screens.
- Added four offline regression tests for detail navigation, provenance visibility, lower-bound semantics, and small-screen scrollability.
- Offline suite: 199/199 PASS. Offline Dart lint: 53 files / 0 issues. Production G1/G7 gate: CLOSED. Shell syntax and both workflow YAML files: PASS.
- Flutter/Dart SDK, Xcode, Simulator, xcarchive and physical-iPhone execution remain NOT RUN / NOT VERIFIED in this Linux environment.
