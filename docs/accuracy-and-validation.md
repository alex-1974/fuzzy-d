# Accuracy and validation

Status: validation plan with initial measured consumer and benchmark evidence.

## Baseline

- Tests for membership boundaries, parameter monotonicity and valid input domains.
- Operator identities, monotonicity, commutativity/associativity where mathematically applicable.
- Numerical behavior at 0, 1, near boundaries, infinities and NaN.
- Explicit distinction among unavailable input, a negative observation and zero rule activation.
- CTFE/attributes verified through compile tests before they are claimed in user docs.

## Inference

- Verify deterministic rule ordering and aggregation semantics.
- Differential comparison of editable, prepared and compiled engines on the same model/input corpus.
- Focus on cases with strong, weak, correlated and mutually contradictory antecedents.
- Check that added evidence does not strengthen a hypothesis contrary to stated model semantics.

## Performance qualification

Use representative models (e.g., 10/100/1000 rules) and measure editable evaluation, prepared evaluation, preparation cost, compiled evaluation, size and allocations.

Report compiler versions, flags, CPU, dataset, iterations, and observed distributions. Baselines and thresholds must come from actual runs, not invented performance targets.

## Release

No performance, attribute, CTFE or equivalence claims become release contracts
until tests are run and recorded. The current release qualification commands
and public API/threading assumptions are maintained in
`docs/release-qualification.md`.
