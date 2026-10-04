# V348 changelog

- Hardened the independent G1/G7 acceptance coverage before any external reference output exists.
- Corrected the generator comment that incorrectly described the 270 m/s PCP case as crossing the transonic regime; it is an intentionally subsonic G1 case.
- Added frozen `minimum_max_range_m_by_model` acceptance requirements: G1 >= 300 m and G7 >= 1500 m.
- Extended G7 reference sampling to 100, 300, 600, 1000 and 1500 m while retaining the G1 PCP sampling through 300 m.
- Updated both the Python fixture validator and Dart comparator to fail closed when a model/atmosphere case does not reach its predeclared minimum maximum range.
- Tolerances are unchanged. The production G1/G7 gate remains closed until the hash-pinned py-ballisticcalc vectors are generated and the Dart comparison passes.
