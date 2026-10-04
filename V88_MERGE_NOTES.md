# v88 controlled merge

Base: v87.

Merged from Claude audit package based on v78_fixed:
- ballistics_screen.dart null-safety fix and readable formatting
- profiles_screen.dart readable formatting
- drag_table.dart documentation correction
- four widget-behaviour test rewrites
- settings_screen.dart test injection required by the accessibility widget tests
- audit changelog retained for provenance

Explicitly preserved from v79-v87:
- aerodynamic solver duplicate-range completion fix and regression test
- all later G1/G7 independent-validation tooling, acceptance policy and CI files
- all catalog and other source changes already present in v87

No Flutter/Dart/iOS build or test result is claimed by this merge. The current environment does not provide flutter, dart or xcodebuild.
