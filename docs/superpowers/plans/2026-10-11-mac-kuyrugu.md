# macOS kuyruğu (iOS CI / TestFlight) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** TestFlight never waits hours behind CI on the 5-slot macOS-15 pool; CI uses ~1 macOS slot per run instead of 3.

**Architecture:** Linux job `dart-checks` (format, analyze, flutter test, offline Python suite, change detection) gates the single automatic macOS job `verify` (release build, App Store preflight, simulator smoke). `wind-acceptance` moves to Linux, `ios-simulator` becomes manual-only. TestFlight gets its own concurrency group and a Linux pre-job that cancels PR iOS CI / sim-screens / Appetize runs.

**Tech Stack:** GitHub Actions YAML, bash, Python unittest (PyYAML).

**Spec:** task message 2026-10-11 (Mac kuyruğu), diagnosis numbers in the PR description.

## Global Constraints
- Job `verify` in `iOS CI` keeps its name and release meaning (lockfile gate + provenance + App Store preflight + archive).
- TestFlight signing/secret/upload steps unchanged; only trigger/concurrency/timeout and a separate Linux job.
- Existing `tools/test_*` text-order guards keep passing (first occurrences stay inside `verify`).

## Review Focus
- Docs/data-only PR: Linux checks run, macOS jobs are skipped (not failed).
- `git diff` base missing (new branch push, force push): macOS must run (fail-safe true).
- Hung simulator test: bounded to 2 × 10 min + step timeout 25 min.
- TestFlight dispatched while PR CI runs: PR runs cancelled, main push CI untouched.
- workflow_dispatch of iOS CI always runs macOS.

### Task 1: Guard test `tools/test_ci_mac_budget.py` (fails first)
### Task 2: ios-ci.yml restructure (dart-checks, verify needs it, wind on Linux, ios-simulator manual, smoke 2 attempts + step timeout)
### Task 3: ios-testflight.yml concurrency + timeout + free-mac-runners job; sim-screens manual only; appetize paths-ignore + timeout
### Task 4: Verify: unittest discover, YAML parse, push branch, workflow_dispatch run, PR
