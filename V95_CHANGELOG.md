# V95 change log

- Fixed a real fail-closed bootstrap bug: the hash-pinned `Deprecated==1.2.18` wheel is tagged `py2.py3-none-any`, while v94 incorrectly required every verified wheel filename to end in `-py3-none-any.whl`.
- Wheel selection now uses the acceptance-policy SHA-256 as the artifact identity and accepts any `.whl` whose PyPI metadata hash matches exactly. The downloaded bytes are still re-hashed before installation and installation remains `--no-index --no-deps`.
- Added an offline regression test proving the `py2.py3-none-any` case is accepted and a wrong-hash wheel is rejected.
- Added that regression test to iOS CI before any network bootstrap step.
- No Flutter/Dart/iOS execution result is claimed by this change log.
