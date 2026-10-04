# V108 changelog

- Hardened the G1/G7 production gate verifier: acceptance policy is now parsed structurally as JSON rather than matched as formatting-sensitive text.
- The gate now fails closed on malformed/missing policy, non-boolean gate state, or a model set other than exactly G1 + G7.
- Added six offline regression tests covering valid policy, formatting independence, malformed JSON, accidental gate opening, experimental solver wiring, and removal of the rejection path.
- iOS CI now compiles and runs the new production-gate regression suite before any reference-vector/bootstrap work.
- Independent reference-vector generation remains pending: this environment could not reach PyPI, so no G1/G7 validation pass is claimed and the production gate remains closed.
