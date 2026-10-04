# V115 Changelog

- Added an explicit destructive-action confirmation before a profile is permanently deleted from persistent storage.
- Cancelling the dialog leaves both UI state and persisted profile data untouched; storage removal only starts after explicit confirmation.
- The delete dialog names the profile and states that deletion cannot be undone, reducing accidental loss of configured ballistic profiles.
- Production G1/G7 gate remains closed; no unvalidated aerodynamic result was enabled.
- Flutter/Dart/Xcode are unavailable in this execution environment, so Flutter analyze/test and iOS build/simulator/device status are not claimed as passing.
