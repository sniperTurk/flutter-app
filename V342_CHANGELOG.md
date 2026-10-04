# V342

- Hardened `ProfileCodec` so persisted/imported profile values must obey the same production bounds as UI-created profiles.
- Profile names now fail closed above the shared 80-character limit.
- Muzzle velocity, zero range, sight height, and optional PCP pressure now fail closed above `ProductionLimits`; sight height preserves the UI's exclusive 300 mm ceiling.
- Added an offline regression contract proving the persistence codec references the shared limits.
- No claim of Flutter/iOS runtime validation: those toolchains remain unavailable in this environment.
