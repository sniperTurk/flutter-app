# v93 independent-validator dependency lock

- Closed a reproducibility gap in the G1/G7 external-reference pipeline: the top-level `py-ballisticcalc==2.2.10` wheel was hash-pinned, but its runtime dependencies were previously allowed to float.
- Acceptance policy now pins the Python 3.12 runtime dependency set used by the validator: `typing-extensions==4.15.0`, `Deprecated==1.2.18`, and `wrapt==1.17.3`.
- Validator bootstrap installs through an explicit constraints file, requires binary distributions, and then verifies the installed dependency versions before reporting success.
- Reference-vector generation independently re-checks those installed versions, so a changed/missing dependency fails closed before a fixture can be emitted.
- The fixture already embeds the complete acceptance policy, so vectors generated under a different dependency lock are rejected by the Dart comparator.
- This hardens reproducibility only. It does not claim that the independent vectors were generated here, that the Dart G1/G7 comparison passed, or that Flutter/iOS builds passed.
