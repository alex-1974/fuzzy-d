# Contributing

Development normally targets the develop branch. Open short-lived topic branches and use pull requests; main is reserved for qualified releases.

Before architecture, public API, numerical, CI, quality or repository-standard changes, review the canonical d-geospatial-workspace documents through local .workspace/ when available. AGENTS.md identifies those documents.

Run (using compilers installed locally):

    dub test --compiler=dmd --force
    dub test --compiler=ldc2 --force
    dub run --root=tests/consumer --compiler=dmd --force

Any public numerical behavior should be documented with domain, failure cases and tests for boundary values and applicable algebraic laws. Performance claims need representative measurements; do not assume that compile-time specialization is faster without evidence.

Historical fuzzyD is an idea reference only. Do not copy code without an explicit provenance and licence review.
