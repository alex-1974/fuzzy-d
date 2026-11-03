# Architecture — working design

Status: proposal, not an API freeze. The domain semantics are shared across execution mechanisms.

## Boundary

fuzzy-d handles fuzzy membership, operators, rule models, inference and execution planning. It does not own geospatial features, OSM tags, spatial graphs, sensor access or visualization.

## Semantic model

- Inputs are named/typed variables with explicitly defined domains and units where applicable.
- Terms associate membership functions and parameters with variables.
- Rules have antecedent expressions and inference-family-specific consequents.
- A membership degree is a grade of membership, not a probability.
- Missing/unavailable values must not be silently treated as false or zero.
- Invalid models are rejected at model-validation/preparation boundaries.
- Outputs may retain provenance of activated rules to explain a result.

## Execution paths

1. Editable: a mutable model builder for experimenting with sets, terms and rules.
2. Prepared: validated, immutable plan evaluated repeatedly at runtime with cached constants and shared expression evaluation.
3. Compiled: known model specialized during D compilation; numerical and logical semantics must match the prepared path.

Rule data, normalization, diagnostics and supported operators must have one semantic authority. Do not let separate evaluators drift into independent fuzzy dialects.

## First inference target

Zero-order Takagi–Sugeno rules with documented antecedent operators and weighted-average output. Empty activation needs an explicit failure/no-result contract; it must never masquerade as a valid zero output.

## Optimization targets

- Precompute membership slopes and common subexpressions where semantics permit.
- Avoid rule evaluation when its outputs or dependencies are irrelevant.
- Reuse prepared plans and caller-owned scratch buffers for repeated evaluations.
- Compile-time specialization may reduce indirect dispatch; avoid unconditional code explosion or numerical re-association.
- Test numerical equivalence under an explicitly documented comparison tolerance.

Open design questions: numeric type and .init semantics, policy for NaN/infinity, grouping of correlated evidence, and deterministic ordering of rule aggregation. These are not silently decided by the scaffold.

See ROADMAP.md for milestone sequencing.
