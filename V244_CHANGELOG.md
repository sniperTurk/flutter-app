# V244

- Sight Height `valid` save boundary now re-verifies both photo evidence files.
- Evidence must still exist, decode successfully, satisfy production resolution/orientation rules, and live inside app-owned `sight_height` storage.
- Arbitrary, stale, deleted, corrupt, or invalid-orientation paths fail closed before measurement persistence or profile mutation.
- Added production regression coverage in `tools/test_v244_sight_height_evidence_revalidation.py`.
- This does not claim Flutter/Xcode/device validation; those remain blocked until the pinned Flutter toolchain and iOS runtime are available.
