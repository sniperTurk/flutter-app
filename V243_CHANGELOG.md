# V243

- Sight Height `valid` saves now fail closed unless both persistent front and side photo evidence paths are present.
- This closes a production integrity gap where manual numeric entry plus confirmation could previously create a `valid` photo-method measurement without the required two-photo evidence.
- Existing perspective and explicit-user-confirmation gates remain mandatory.
- Added production regression contracts for the two-photo evidence gate.
- Flutter/iOS compilation remains unverified until the pinned Flutter SDK and Xcode are available.
