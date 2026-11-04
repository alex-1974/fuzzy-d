# API and release qualification

This document records the current pre-0.1 contract. It is a qualification
checklist, not a promise that the API is already frozen for 1.0.

## Public surface

The supported human-facing entry point is:

```d
import fuzzy;
```

The package root exports degrees, membership functions, hedges, operators,
compile-time helpers, the fluent facade and multi-output types. Advanced IR,
model and inference implementation types require explicit imports from
`fuzzy.ir`, `fuzzy.model` and `fuzzy.inference`.

## Prepared-state contract

- Build and preparation are configuration operations; do them before the hot
  loop.
- A prepared evaluator does not retain caller input or output array references.
- Prepared plans are intended for read-only sharing between threads.
- Mutable caches in a prepared evaluator must not be concurrently evaluated by
  multiple threads; use one evaluator instance per concurrent worker until a
  thread-safe evaluator is introduced.
- Each concurrent call owns its own input/output buffers.

## Numeric and failure contract

- `evaluateValue` requires a fully present ordered numeric input vector.
- Named `evaluate` is the path for sparse inputs, missing-input diagnostics and
  rule traces.
- No activated rule is not numeric zero: it is `hasValue == false` and a NaN
  numeric result where applicable.
- Cross-path numerical comparisons use a documented tolerance; exact bitwise
  equality is not a public contract.

## Required qualification commands

```sh
dub test --compiler=dmd --force
dub test --compiler=ldc2 --force
dub run --root=tests/consumer --compiler=dmd --build=release --force
dub run --root=tests/consumer --compiler=ldc2 --build=release --force
dub run --root=benchmarks --compiler=ldc2 --build=release --force
```

The benchmark output must retain compiler, build mode, workload, iteration
count, preparation cost, break-even estimate and allocation observations.

