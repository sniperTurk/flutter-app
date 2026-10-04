# V278

- App Store preflight now rejects symlink substitution of the `tools/`, `release/`, and `release/ios/` parent directories.
- This closes the parent-directory traversal gap left after v275-v277 leaf/iOS-tree symlink checks.
- Added regression coverage for all three parent-directory substitutions.
- Offline verification: 317 Python tests pass; Python compileall passes. Real Flutter/iOS build remains unverified in this environment.
