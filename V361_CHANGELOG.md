# V361 — M1 Rev 2 selective merge

Base: V360. M1 Rev 2 was reviewed as a secondary lineage and was not copied wholesale because it would regress V360 review fixes.

Merged:
- Compass keeps Turkish K/D/G/B + 16-point abbreviations and now exposes full Turkish spoken direction names for VoiceOver.
- Sight Height keeps V360 landscape enforcement, muzzle-device warning, inclined-scope front-objective guidance and 44 pt nudge controls; marking canvas now has an explicit VoiceOver label/hint and recommends manual caliper/profile entry when precise touch marking is impractical.
- Chronograph keeps V360 PCP start/end pressure and pressure-drop/per-shot metrics; when applying velocity to a matching profile, the user may optionally write the valid starting pressure to the profile.
- ToolProfileUpdate validates optional pressure updates through the same ProfileInput validation path used by profile editing.
- V360 bootstrap-lockfile SHA manifest workflow is retained unchanged.

Validation in this environment:
- Python unittest discovery: 520/520 PASS.
- Offline Dart lint: 97 files, 0 issues.
- Python compileall: PASS.
- Flutter analyze/test, real iOS build, Simulator, physical iPhone, Light/Dark visual QA, Dynamic Type and VoiceOver device QA: NOT RUN.
- Production gate remains CLOSED.
