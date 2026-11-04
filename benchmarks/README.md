# fuzzy-d benchmarks

This development harness compares direct expression evaluation with prepared
evaluation at 10, 100 and 1000 rules. It covers single-term and two-term
antecedents under both Gödel and Product operators. The repeated-term workload
exercises the prepared plan's term-value cache.
It also includes a small named-input facade case representative of Dunia's
consumer style; this measures the complete convenience API, including input
mapping and result/trace construction. The same case reports the prepared
numeric facade path, which reuses a caller-owned ordered value buffer.
The Dunia case also reports runtime GC bytes observed during the numeric loop;
this is evidence for the selected workload, not a universal `@nogc` claim for
user-supplied membership delegates.
The thermostat case is the canonical general-purpose consumer workload used by
the consumer smoke test and compares prepared named versus prepared numeric
evaluation.
The prepared fast path is intended for fully present numeric inputs; callers
that need missing-input detection or rule traces use the regular `evaluate`
overload.

Run from the repository root:

    dub run --root=benchmarks --compiler=ldc2 --build=release --force

The harness reports wall-clock nanoseconds, preparation time and result sinks
to prevent the compiler from removing the measured work. The 1000-rule case
uses fewer iterations to keep the run bounded; trace evaluation uses one tenth
of the normal iteration count and reports that count explicitly. It is
exploratory evidence, not yet a release threshold. Results must be recorded together with compiler,
CPU, build mode, workload and iteration count; a single local run is not a
portable performance contract.
Each rule-set case reports both snapshot preparation and full prepared-plan
construction. Its approximate break-even count uses the full plan cost: the
number of repeated evaluations needed to amortize preparation. It is only
meaningful for the measured model and compiler configuration.
