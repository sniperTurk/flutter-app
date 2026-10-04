# V270 CHANGELOG

- Continued from v269; did not restart the project.
- Hardened `tools/write_lockfile_provenance.py` at the release trust boundary.
- Writer now rejects symlinked `pubspec.yaml`, `pubspec.lock`, and provenance output.
- Provenance output is staged beside the destination, flushed/fsynced, then atomically installed with `os.replace`; partial/truncated output is not intentionally committed.
- Filesystem inspection/write failures return clean fail-closed errors.
- Added regression coverage for symlink input/output rejection and replacement of an existing regular provenance file.
- Targeted lockfile provenance tests: 14/14 passed.
- Full offline Python suite: see run result; no Flutter/iOS claim is made from these tests.
- Real `pubspec.lock` + provenance pair is still absent, so real iOS release/build gate remains blocked.
