# Architecture — working design

Status: working design with an initial Type-1 implementation; not an API freeze.

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

The repository now contains the first vertical slice of these paths:

- validated `Degree` values and stateless Type-1 membership functions;
- value-based expression templates suitable for CTFE;
- an editable runtime model with stable variable and term IDs;
- a normalized expression graph with model validation;
- a copied `PreparedExpression` graph for repeated evaluation;
- direct and prepared zero-order Sugeno evaluators with rule traces;
- differential tests comparing direct and prepared results.
- compile-time fixed Sugeno models with explicit no-result results;
- explicit Gödel and product operator families across runtime, prepared and
  compile-time expression paths;
- caller-owned `InputVector` values with an optional presence mask.
- a named consumer facade plus an ordered numeric prepared path for repeated
  fully-present evaluations;
- an advanced prepared multi-output path with caller-owned result storage;
- benchmark evidence for preparation amortization and measured numeric-path
  allocation behaviour.

The current implementation is deliberately narrower than the final design. The
editable model still accepts evaluator delegates, while the normalized graph is
the intended boundary for later preparation and compile-time specialization.
The numeric prepared path is allocation-free for the measured caller-owned
workload, but this is not an unconditional `@nogc` contract: arbitrary user
delegates and the exception-validating `Degree` constructor remain part of the
runtime API. A future `@nogc` executor requires an explicitly separate trusted
numeric representation.

Rule data, normalization, diagnostics and supported operators must have one semantic authority. Do not let separate evaluators drift into independent fuzzy dialects.

## First inference target

Zero-order Takagi–Sugeno rules with documented antecedent operators and weighted-average output. Empty activation needs an explicit failure/no-result contract; it must never masquerade as a valid zero output.

## Optimization targets

- Precompute membership slopes and common subexpressions where semantics permit.
- Avoid rule evaluation when its outputs or dependencies are irrelevant.
- Reuse prepared plans and caller-owned scratch buffers for repeated evaluations.
- Compile-time specialization may reduce indirect dispatch; avoid unconditional code explosion or numerical re-association.
- Test numerical equivalence under an explicitly documented comparison tolerance.

Remaining design questions include the final public numeric type policy,
Mamdani/defuzzification scope, grouping of correlated evidence, and the
generalized multi-output rule IR. `Degree.init`, NaN/Infinity validation,
missingness, operator selection and deterministic rule ordering are now covered
by the initial implementation and tests.

See ROADMAP.md for milestone sequencing.
