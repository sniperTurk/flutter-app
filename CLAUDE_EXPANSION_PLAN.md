# SNIPER TÜRK V1 — Claude Expansion Brief

## Purpose

Extend the existing `sniperTurk/flutter-app` without restarting or replacing it.

This repository is already a Flutter/iOS-first ballistic companion with:
- PCP/firearm platform separation
- persistent rifle profiles
- ammunition and optics catalog architecture
- offline-first persistence
- atmospheric density foundation
- experimental RK4/G1/G7 work
- extensive regression/CI gates
- pinned Flutter 3.47.2
- existing iOS CI and App Store preflight

The goal of this document is to give Claude Code a project-specific expansion plan based on the repository's current state and lessons from open-source reference projects.

## Non-negotiable safety/product boundary

Keep the product positioned as an educational physics and ballistics simulation application.

Do not add features whose purpose is to optimize real-world weapon use, targeting, lethality, or operational firing instructions.

Prefer:
- physics education
- trajectory visualization
- numerical-method demonstrations
- atmospheric science
- unit conversion
- simulation experiments
- historical/scientific explanations
- reproducible software tests

Any existing production safety gate must remain fail-closed.

## Repository facts to preserve

- Project name: `sniper_turk`
- Flutter SDK pin: 3.47.2
- Existing `CLAUDE.md` is authoritative for verification.
- Existing CI must remain intact.
- Do not regenerate the project.
- Do not remove existing validation or provenance checks.
- Do not silently change `pubspec.lock`.
- Do not claim Flutter/Xcode/TestFlight/App Store success unless it actually ran.

Current top-level application structure includes:
`lib/core`, `lib/data`, `lib/features`, `lib/models`, `lib/services`, `lib/tools`, `lib/ui`.

## Reference projects to study

Use these only for architecture, algorithms, testing ideas, and API design. Do not copy proprietary assets, branding, UI, or unverified numerical data.

1. Ballistics Lab / bclibc
   https://github.com/ballistics-lab/bclibc
2. dart-bclibc
   https://github.com/ballistics-lab/dart-bclibc
3. py-ballisticcalc
   https://github.com/o-murphy/py-ballisticcalc
4. eBalistyka
   https://github.com/o-murphy/ebalistyka
5. BallisticCalculator1
   https://github.com/gehtsoft-usa/BallisticCalculator1

Before adopting any dependency or code, inspect its LICENSE and transitive dependencies.

## Existing project direction

The repository already contains a substantial numerical-ballistics foundation:
- deterministic moist-air density model
- standard drag reference data
- RK4 integrator
- Mach-indexed drag interpolation
- experimental G1/G7 trajectory solver
- independent py-ballisticcalc validation seam
- fail-closed production aerodynamic gate
- extensive regression tests

Do not bypass the production gate simply to expose more features.

## Target architecture

Keep the existing architecture and evolve it incrementally.

Preferred conceptual layers:

UI
  -> Feature/Application layer
  -> Domain simulation APIs
  -> Physics/numerical engine
  -> Persistence/reference-data adapters

The physics layer must remain independent of Flutter widgets.

Suggested future domain boundaries:

- core/units
- core/physics
- core/simulation
- core/numerics
- core/validation
- data/persistence
- features/simulator
- features/scenarios
- features/charts
- features/education
- features/settings

Do not move existing files merely for cosmetic architecture.

## Feature expansion

### 1. Simulation workspace

Create a dedicated simulation workspace that can show:
- input summary
- environment summary
- numerical model status
- trajectory visualization
- velocity/energy/altitude charts
- calculation status
- validation status

Every experimental result must be clearly labelled experimental/unvalidated where applicable.

### 2. Interactive physics laboratory

Add an educational sandbox where users can vary generic physics parameters and immediately see how the simulated trajectory changes.

Good educational parameters:
- initial velocity
- launch angle
- initial height
- gravity
- air density
- drag coefficient
- timestep
- simulation duration

The UI should explain what each parameter means.

### 3. Scenario comparison

Allow two educational simulations to be compared.

Show:
- input differences
- output differences
- overlaid charts
- numerical error/uncertainty where meaningful

Do not present comparison output as real-world firing advice.

### 4. Education module

Create short lessons:
- Newtonian motion
- gravity
- drag
- air density
- numerical integration
- interpolation
- coordinate systems
- unit conversion
- uncertainty
- model validation

Each lesson can contain:
- short explanation
- simple animation
- chart
- experiment

### 5. Visualization

Build reusable chart components for:
- position vs time
- altitude vs time
- speed vs time
- energy vs time
- acceleration vs time
- model-vs-reference error

Charts must be deterministic and testable.

### 6. Experiment persistence

Extend the existing offline-first persistence rather than adding an unrelated database.

Store:
- scenario name
- timestamp
- model version
- inputs
- environment
- solver configuration
- result summary
- notes

Use explicit schema versions and migrations.

### 7. Import/export

Support a versioned JSON format.

Future formats:
- CSV for educational data
- PDF for educational reports

Every exported record must include model/version metadata.

## Numerical-engine rules

1. Never silently substitute invalid numeric values.
2. Reject NaN and infinity.
3. Keep canonical SI units internally.
4. Convert units only at boundaries.
5. Validate timestep and solver configuration.
6. Preserve deterministic outputs.
7. Keep solver implementations behind interfaces.
8. Keep reference vectors immutable.
9. Keep production and experimental solvers separate.
10. Never weaken acceptance tolerances to make a failing reference test pass.

## Validation strategy

Every new numerical feature should include:

### Unit tests
- finite input validation
- invalid input rejection
- unit conversion
- mathematical invariants

### Regression tests
- frozen reference scenarios
- known output ranges
- deterministic repeatability

### Cross-implementation tests
When appropriate, compare the independent implementation with this repository.

A disagreement is a diagnostic failure, not permission to change the expected result.

## Performance

Long-running simulations must not block Flutter's UI isolate.

Use isolates/background execution where justified.

Cache only deterministic simulation results.

Cache keys must include all model-affecting inputs and model version.

## Localization

Keep Turkish and English localization ready.

Do not hard-code explanatory text inside physics/domain classes.

## Accessibility

All controls, charts and simulation states need semantic labels.

Support:
- text scaling
- screen readers
- keyboard navigation where applicable
- high-contrast friendly presentation

## Visual direction

Do not copy eBalistyka or other reference UI.

Create an original modern scientific interface:
- clean cards
- clear hierarchy
- readable charts
- compact technical summaries
- educational callouts
- light/dark themes

## Development workflow for Claude

Before changing code:

1. Read `CLAUDE.md`.
2. Read `README.md`.
3. Inspect current relevant feature files.
4. Identify existing tests and validation gates.
5. Write a short implementation plan.
6. Make the smallest coherent change.
7. Add tests.
8. Run the repository's authoritative verification command when the environment supports it.
9. Report exact commands and whether they actually passed.

Never report an unexecuted test as passing.

## First task

Do not implement the whole roadmap at once.

First produce a repository audit containing:

- current Flutter/Dart version
- existing feature map
- existing physics engine map
- existing persistence map
- existing validation map
- existing CI map
- current production gates
- current experimental gates
- dependency inventory
- files that would be touched for the simulation workspace
- risks and migration order

Then propose Phase 1.

## Phase 1 priority

Implement only the educational simulation foundation:

1. simulation domain contracts
2. deterministic generic physics scenario
3. reusable result model
4. chart data adapter
5. simulation workspace UI
6. educational explanation panel
7. persistence for saved experiments
8. unit/regression tests

Do not modify the existing production ballistic gate in Phase 1.

## Definition of done

A phase is complete only when:
- existing behavior remains intact
- new code has tests
- existing validation gates remain active
- no unverified numerical data is promoted to production
- no reference project branding/assets are copied
- localization is structured
- documentation is updated
- verification results are honestly reported

## Final instruction to Claude

Treat the existing repository as a mature project, not a blank Flutter template.

Preserve working code.

Prefer incremental, reversible changes.

Reuse existing validation infrastructure.

Expand the application into a high-quality educational physics/simulation platform without weakening the repository's current safety, provenance, numerical-validation, persistence, CI, or App Store gates.
