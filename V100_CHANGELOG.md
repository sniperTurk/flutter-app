# V100 change log

- Removed regenerated `tools/__pycache__/*.pyc` files from the release source. They had reappeared after the earlier package cleanup, proving the existing CI guard was too narrow.
- Replaced the `lib/` + `test/`-only temporary-file check with a repository-wide fail-closed source-hygiene gate (excluding `.git`). It rejects `__pycache__`, `.pyc`/`.pyo`, editor backups, and temporary files anywhere in the source tree, including `tools/`.
- This is packaging/release hygiene only. It does not claim a Flutter, iOS Simulator, device, or App Store build pass.
