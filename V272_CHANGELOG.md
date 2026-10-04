# v272 — V1 scope reduction

Removed compass and spirit-level screens, home navigation cards and sensor plugin dependencies (`flutter_compass`, `sensors_plus`) from the active V1 source. Moved four obsolete field-tools tests to `archived_tests/removed_v1_features/`; these are retained as historical evidence, not run as active tests. Chronograph and Sight Height remain excluded per v271. No Flutter dependency resolution or iOS build was performed; a new lockfile is still required.
