# fuzzy-d

Reusable fuzzy-logic foundations and inference for the D programming language.

> Status: pre-release Type-1 core. No published release exists yet; the API is still subject to change.

## Purpose

Build and evaluate fuzzy sets and rules using one coherent semantic model, with
editable, prepared and compile-time execution paths:

- Editable rules and membership functions at runtime, including model inspection and experimentation.
- Prepared runtime evaluation with reusable, allocation-conscious execution plans,
  ordered numeric hot paths and worker-local clones.
- Compile-time specialization of the same validated model for fixed production rule sets.
- Advanced multi-output Sugeno evaluation with caller-owned result buffers.

The canonical general-purpose consumer is a room thermostat. Dunia and water-
uncertainty research remain future domain consumers; this library has no GIS or
OSM dependencies.

## Getting started

The current pre-release core provides validated Type-1 degrees, membership functions, linguistic hedges, selectable basic operators, structured antecedent expressions, editable terms, normalized expressions and prepared zero-order Sugeno evaluation. The public API is still evolving and is not release-stable.

    import fuzzy;
    static assert(fuzzyDevelopmentStatus == "pre-0.1");

    auto cold = triangle(0.0, 10.0, 20.0);
    assert(cold(10.0).value == 1.0);

    auto builder = new FuzzyModelBuilder;
    builder.input("temperature")
        .term("cold", (double value) => cold(value))
        .output("risk")
        .rule("cold temperature")
        .when("temperature", "cold")
        .then("risk", 0.2);

    auto model = builder.build();
    auto result = model.evaluate(inputs().set("temperature", 10.0));
    assert(result.hasValue);
    assert(result.output == "risk");

Local commands:

    dub test --compiler=dmd --force
    dub test --compiler=ldc2 --force
    dub run --root=tests/consumer --compiler=dmd --force

## Project documents

- [Roadmap](ROADMAP.md)
- [Architecture and boundaries](docs/architecture.md)
- [Consumer API](docs/api.md)
- [Accuracy and validation plan](docs/accuracy-and-validation.md)
- [Release qualification](docs/release-qualification.md)
- [Thermostat tutorial](docs/tutorial/thermostat.md)
- [Consumer qualification boundary](docs/consumer-qualification.md)
- [Contributing](CONTRIBUTING.md)

The same normalized expression can be prepared for repeated evaluation or
specialized at compile time. Missing inputs use an explicit presence mask via
`InputVector`; a missing value is never silently converted to zero.

Development follows d-geospatial-workspace engineering practices when the canonical workspace documents are available locally. The repository remains independently buildable outside that workspace.

## Provenance

The earlier [fuzzyD](https://github.com/alex-1974/fuzzyD) repository is a historical source of ideas, not a code dependency. No historical code has been copied into fuzzy-d.

## License

MIT. See [LICENSE](LICENSE).
