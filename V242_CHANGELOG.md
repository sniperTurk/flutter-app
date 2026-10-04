# V242

- Sight Height camera/gallery images are copied into app-owned Documents storage before use, avoiding temporary `image_picker` paths.
- Persisted front/side photo paths are stored with `SightHeightMeasurement` evidence.
- Measurement codec remains backward compatible: older records without photo paths decode with null paths.
- Added fail-closed photo copy error handling and production regression contracts.
- Flutter/iOS compilation remains unverified until the pinned Flutter SDK and Xcode are available.
