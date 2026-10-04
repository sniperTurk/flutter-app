# V322 — Flutter bootstrap destination safety

- Hardened `tools/claude_bootstrap_and_verify.sh` so `SNIPER_TURK_FLUTTER_HOME` cannot point at an existing non-Flutter directory that is then deleted after a failed clone/update fallback.
- Existing SDK targets must not be symlinks, must be git checkouts, and must identify the official Flutter GitHub origin before destructive replacement is possible.
- Added a behavioral regression test proving v321 deleted a sentinel file in this scenario and v322 preserves it while failing closed.
