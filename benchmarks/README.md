# fuzzy-d benchmarks

This development harness compares direct expression evaluation with prepared
evaluation on a representative 100-rule model.

Run from the repository root:

    dub run --root=benchmarks --compiler=ldc2 --build=release --force

The harness reports wall-clock nanoseconds and a result sink to prevent the
compiler from removing the measured work. It is exploratory evidence, not yet
a release threshold.
