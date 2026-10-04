# V312

- Added a fail-closed archive signing-state verifier to the iOS production CI path.
- The unsigned App Store archive gate now proves Runner.app has no embedded provisioning profile and is not codesigned before it is uploaded as an unsigned artifact.
- Added regression coverage for unsigned acceptance, signed rejection, and embedded-profile rejection.
- This does not claim a signed App Store build; owner credentials/Xcode execution remain required for that evidence.
