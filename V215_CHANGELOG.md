# V215 — lockfile adoption staging cleanup

Continues V214. `tools/adopt_verified_lockfile.py` now registers each freshly created staging file before copying into it. Previously a partial copy failure on the second file could leave an untracked temporary file in the project root. Added failure-injection regression that forces a partial second-stage write failure and verifies both temporary files are removed, existing project files remain untouched, and the error is returned cleanly. No changes to lockfile provenance or release gates.

Verified here: 249/249 Python offline tests, compileall, offline Dart lint (55 files, 0 issues), production G1/G7 gate CLOSED as intended, bash syntax and two workflow YAML parse. Flutter/Dart SDK, Xcode, Simulator, physical iPhone, xcarchive/IPA not run.
