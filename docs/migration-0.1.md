# Migration note for 0.1.0

No 0.1.0 release has been made yet. This note records the intended migration
boundary from the current pre-release line; it is not a promise that the
release will preserve every internal implementation detail.

## Recommended imports

Existing consumers should prefer:

```d
import fuzzy;
```

Use the fluent facade for ordinary named-input models. Prepare once for loops:

```d
auto prepared = model.prepare();
auto value = prepared.evaluateValue(orderedValues);
```

Use `cloneForWorker()` when the prepared evaluator is used by multiple worker
threads. Give each concurrent call its own input/output buffers.

## Stable semantic expectations

- Degrees are finite values in `[0, 1]`.
- Missing inputs are explicit and are not treated as zero.
- No activated rule is not a valid numeric zero.
- Named evaluation is the diagnostic/convenience path; ordered numeric
  evaluation is the fully-present hot path.
- Direct, prepared and compile-time paths are expected to preserve the same
  fuzzy semantics within documented numerical tolerances.

## Areas not covered by the 0.1 compatibility promise

The following remain advanced or implementation-facing:

- `fuzzy.model`, `fuzzy.ir`, `fuzzy.inference` and `fuzzy.expression` internals;
- the exact cache layout of prepared evaluators;
- a universal `@nogc` guarantee for user-supplied Membership delegates;
- Mamdani inference and defuzzification;
- a named multi-output facade.

Breaking changes to the candidate public facade before 0.1.0 must be recorded
in `CHANGELOG.md` with a migration example.

