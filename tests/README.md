# Tests

The package-root unittest validates a minimal import/CTFE claim. The consumer fixture is a separate DUB project depending on fuzzy-d by a relative path; it prevents package import regressions.

Future numerical tests must cover membership-function boundaries, invalid parameters, algebraic laws of selected operators, missing-input semantics and dynamic/prepared/compiled evaluation parity.

Run:

    dub test --compiler=dmd --force
    dub run --root=tests/consumer --compiler=dmd --force
