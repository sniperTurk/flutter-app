# V175 — iOS platform persistence smoke hardening

- Continued from V174; no project reset.
- Strengthened the production iOS integration smoke flow after profile creation.
- The test now reads the real `SharedPreferences` plugin store and proves both the serialized profile document and reconciled active-profile id were persisted before entering DOPE.
- Added an offline regression contract that locks the platform-backed persistence assertions and their ordering.
- This does **not** claim an iOS runtime pass; the current environment has no Flutter/Xcode/Simulator execution.
