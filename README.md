# fuzzy-d

fuzzy-d helps a D program turn imprecise measurements into understandable
decisions. You describe concepts such as “cold”, “comfortable” or “rising”,
combine them with readable rules, and receive a numeric result together with
optional rule explanations.

> Status: `0.1.0` released. The Type-1 core is stable for the documented API; later releases may add capabilities.

## What it does

The library supports the same model from experimentation through a repeated
production loop:

- Define membership concepts with triangles, trapezoids, ramps, Gaussians and
  related shapes.
- Write readable rules such as “if the temperature is cold, increase heating”.
- Evaluate by names while handling missing measurements explicitly.
- Prepare a model once for a fast repeated loop and use worker-local copies for
  parallel workers.
- Use compile-time models when a rule set is fixed in the program.

The canonical general-purpose consumer is a room thermostat. Dunia and water-
uncertainty research remain future domain consumers; this library has no GIS or
OSM dependencies.

## A small example

This example describes a simple risk decision from a temperature measurement:

    import fuzzy;
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

For a complete two-input example, see the [room thermostat tutorial](docs/tutorial/thermostat.md).

## When to prepare

Use the named form when inputs arrive as a sparse record or when you need rule
traces for diagnostics. If the model is evaluated repeatedly with all inputs
present, prepare it once and pass values in the declaration order:

    auto prepared = model.prepare();
    auto heating = prepared.evaluateValue([5.0, -2.0]);

The prepared numeric path is intended for the hot loop. It does not silently
turn missing values into zero; use named evaluation when missingness matters.

## Scope

fuzzy-d currently focuses on Type-1 fuzzy sets and zero-order Sugeno inference.
Multi-output evaluation and compile-time fixed models are available for advanced
uses. Mamdani inference, defuzzification and learning are not yet part of the
stable API.

Local commands:

    dub test --compiler=dmd --force
    dub test --compiler=ldc2 --force
    dub run --root=tests/consumer --compiler=dmd --build=release --force
    dub run --root=tests/consumer --compiler=ldc2 --build=release --force
    dub run --root=benchmarks --compiler=ldc2 --build=release --force

Or run the non-Ddoc qualification gates together:

    bash tools/qualify.sh

## Project documents

- [Roadmap](ROADMAP.md)
- [Architecture and boundaries](docs/architecture.md)
- [Consumer API](docs/api.md)
- [Accuracy and validation plan](docs/accuracy-and-validation.md)
- [Release qualification](docs/release-qualification.md)
- [Pre-0.1 API freeze audit](docs/api-freeze-audit.md)
- [Toolchain support](docs/toolchain-support.md)
- [0.1 migration note](docs/migration-0.1.md)
- [0.1.0 release checklist](docs/release-0.1-checklist.md)
- [Thermostat tutorial](docs/tutorial/thermostat.md)
- [Consumer qualification boundary](docs/consumer-qualification.md)
- [Contributing](CONTRIBUTING.md)

The [consumer API guide](docs/api.md) explains named inputs, preparation and
diagnostic traces. Missing measurements are always handled explicitly.

Development follows d-geospatial-workspace engineering practices when the canonical workspace documents are available locally. The repository remains independently buildable outside that workspace.

## Provenance

The earlier [fuzzyD](https://github.com/alex-1974/fuzzyD) repository is a historical source of ideas, not a code dependency. No historical code has been copied into fuzzy-d.

## License

MIT. See [LICENSE](LICENSE).
