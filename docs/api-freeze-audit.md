# Pre-0.1 API freeze audit

Status: reviewed 2026-11-04; not yet a 0.1.0 compatibility promise.

## Freeze candidates

The following package-root surface is the candidate human-facing API:

- `Degree` and the membership factories/types;
- hedges and `OperatorFamily`;
- `FuzzyModelBuilder`, `FuzzyModel`, `PreparedFuzzyModel`;
- `InputValues`, `inputs()` and `NamedResult`;
- `PreparedFuzzyModel.evaluateValue`, `inputCount`, `inputName` and
  `cloneForWorker`;
- compile-time fixed Sugeno helpers;
- `MultiOutputSugeno`, `PreparedMultiOutputSugeno` and caller-owned
  `evaluateInto` for advanced consumers.

Names and semantics above should not change without an explicit pre-0.1
breaking-change note.

## Deliberately advanced or unstable

These modules remain outside the package-root contract:

- `fuzzy.model`;
- `fuzzy.ir`;
- `fuzzy.inference`;
- `fuzzy.expression`.

Their implementation types may change while the facade contracts are refined.
The optional trusted/static `@nogc` executor is not part of the current API.

## Value and failure contracts reviewed

- `Degree.init` is an invalid sentinel; valid degrees are finite and in
  `[0, 1]`.
- Missing inputs are not converted to zero and raise
  `MissingInputException` on the diagnostic path.
- `evaluateValue` requires a fully present ordered numeric input vector.
- No activated rule is represented by `hasValue == false` and NaN where a
  scalar numeric result is returned.
- Numeric cross-path comparisons use tolerance, not bitwise equality.
- Prepared worker clones isolate mutable caches; callers own input/output
  buffers and must provide one mutable buffer per concurrent evaluation.

## Remaining pre-0.1 decisions

1. Decide whether Multi-Output belongs in the initial stable facade or remains
   advanced-module-only.
2. Decide whether `cloneForWorker` is sufficient or whether a cache-free
   thread-safe executor is required by a real consumer.
3. Define the supported compiler floor and run the full release matrix; the
   currently observed local baseline is recorded in `toolchain-support.md`.
4. Add a concise migration note if any of the freeze candidates change before
   0.1.0.

