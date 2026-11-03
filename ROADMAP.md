# fuzzy-d roadmap

Status: pre-release planning. Scope is a reusable fuzzy-logic/inference library, independent of OSM and geospatial code.

## M0 — Initialization and design (in progress)

- Repository layout, DUB identity, LICENSE, CI and consumer smoke.
- Establish shared semantic model: variables, membership functions, terms, rules, operators, outputs.
- Specify error handling, missing-input semantics, numeric domains and the meaning of a membership degree.
- Document static versus dynamic execution parity and API design decisions.

## M1 — Numerical and logical core

- Validated degree values and explicit invalid-input behavior.
- Piecewise-linear membership functions (triangle, trapezoid, shoulders) and focused unit/law tests.
- T-norm, S-norm, negation and parameter validation.
- CTFE/attribute compile probes where claimed.

## M2 — Editable model and dynamic inference

- Runtime model builder and validation; rule add/change/remove.
- Zero-order Sugeno as the first targeted inference family.
- Structured evidence for active rules and outputs; distinguish absent from false input.
- Save/load format only after the model contract is stable.

## M3 — Prepared runtime evaluation

- Normalize/prepare model into an immutable, reusable execution plan.
- Share common membership evaluations and precompute invariant parameters.
- Repeated-evaluation tests, preparation amortization and allocation/performance characterization.

## M4 — Compile-time specialization

- Consume the same model semantics in a compile-time-known representation.
- Specialize known operators, constants and rule dependencies.
- Differential test prepared versus compiled paths over boundary and representative inputs.

## M5 — Consumer qualification and pre-release gates

- Dunia validation use case plus independent sensor/regulation examples.
- DMD/LDC compiler matrix, consumer docs, negative/error and numerical tests.
- Benchmark representative workloads and review public API before feature/API freeze.
- Release only after the full workspace gate; no date or version commitment yet.

Deferred: Type-2 fuzzy systems, neuro-fuzzy learning, visual rule editors, and unrestricted DSL interpreters.
