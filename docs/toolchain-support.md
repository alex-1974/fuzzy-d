# Toolchain support

## Current verified baseline

The local qualification environment currently provides:

| Tool | Version | Verified |
| --- | --- | --- |
| DMD | 2.111.0 | library, consumer, release build |
| LDC | 1.42.0 / DMD frontend 2.112.1 | library, consumer, release build |
| DUB | 1.40.0 | all local commands |

The repository CI additionally declares the release matrix in
`.github/workflows/release-gate.yml`:

- DMD 2.111.0, 2.112.1, 2.113.0;
- LDC 1.41.0, 1.42.0, 1.43.0.

Until every matrix entry has passed in CI, the local versions above are the
observed baseline, not the complete support claim.

## Required checks

Each supported compiler must pass:

1. package unittests;
2. external consumer smoke test;
3. release build;
4. Ddoc build for DMD;
5. representative benchmark harness in the release gate.

Performance numbers are compiler- and machine-specific. Compiler support does
not imply identical performance or identical optimizer decisions.

