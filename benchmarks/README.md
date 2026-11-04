# fuzzy-d benchmarks

This development harness compares direct expression evaluation with prepared
evaluation at 10, 100 and 1000 rules.

Run from the repository root:

    dub run --root=benchmarks --compiler=ldc2 --build=release --force

The harness reports wall-clock nanoseconds, preparation time and result sinks
to prevent the compiler from removing the measured work. The 1000-rule case
uses fewer iterations to keep the run bounded. It is exploratory evidence, not
yet a release threshold.
