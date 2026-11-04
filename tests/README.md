# Tests

The package-root unittest validates a minimal import/CTFE claim. The consumer fixture is a separate DUB project depending on fuzzy-d by a relative path; it prevents package import regressions.

The current unit and consumer tests cover membership-function boundaries,
invalid parameters, algebraic laws of selected operators, explicit
missing-input semantics, direct/prepared/compile-time Sugeno parity, and the
external public-API path. Future numerical tests should extend the shared
conformance corpus rather than create independent semantics for each execution
mode.

Independent public-API consumers also cover sensor fusion
(`tests/consumer-sensor`) and fan control (`tests/consumer-fan`). They are
deliberately unrelated to GIS or OSM data.

Run:

    dub test --compiler=dmd --force
    dub run --root=tests/consumer --compiler=dmd --force
