# fuzzy-d

Reusable fuzzy-logic foundations and inference for the D programming language.

> Status: pre-release initialization. No production inference API or published release exists yet.

## Purpose

Build and evaluate fuzzy sets and rules using one coherent semantic model, with two future execution paths:

- Editable rules and membership functions at runtime, including model inspection and experimentation.
- Prepared runtime evaluation with reusable, allocation-conscious execution plans.
- Compile-time specialization of the same validated model for fixed production rule sets.

The initial consumer is a plausibility validator for OpenStreetMap data, but this library has no GIS or OSM dependencies.

## Getting started

The current repository only exposes a development-status marker. This is an intentionally minimal package/build smoke test; membership functions and inference follow in future milestones.

    import fuzzy;
    static assert(fuzzyDevelopmentStatus == "pre-0.1");

Local commands:

    dub test --compiler=dmd --force
    dub test --compiler=ldc2 --force
    dub run --root=tests/consumer --compiler=dmd --force

## Project documents

- [Roadmap](ROADMAP.md)
- [Architecture and boundaries](docs/architecture.md)
- [Accuracy and validation plan](docs/accuracy-and-validation.md)
- [Contributing](CONTRIBUTING.md)

Development follows d-geospatial-workspace engineering practices when the canonical workspace documents are available locally. The repository remains independently buildable outside that workspace.

## Provenance

The earlier [fuzzyD](https://github.com/alex-1974/fuzzyD) repository is a historical source of ideas, not a code dependency. No historical code has been copied into fuzzy-d.

## License

MIT. See [LICENSE](LICENSE).
