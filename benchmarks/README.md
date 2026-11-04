# fuzzy-d benchmarks

This development harness compares direct expression evaluation with prepared
evaluation at 10, 100 and 1000 rules. The workload uses repeated terms in
two-term antecedents, which exercises the prepared plan's term-value cache.
The prepared fast path is intended for fully present numeric inputs; callers
that need missing-input detection or rule traces use the regular `evaluate`
overload.

Run from the repository root:

    dub run --root=benchmarks --compiler=ldc2 --build=release --force

The harness reports wall-clock nanoseconds, preparation time and result sinks
to prevent the compiler from removing the measured work. The 1000-rule case
uses fewer iterations to keep the run bounded. It is exploratory evidence, not
yet a release threshold. Results must be recorded together with compiler,
CPU, build mode, workload and iteration count; a single local run is not a
portable performance contract.
