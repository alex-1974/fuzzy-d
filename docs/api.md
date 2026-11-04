# Consumer API

The recommended entry point is:

```d
import fuzzy;
```

The normal workflow is:

```d
auto model = new FuzzyModelBuilder;

model.input("temperature")
    .term("cold", (double x) => triangle(0, 10, 20)(x))
    .output("risk")
    .rule("cold temperature")
    .when("temperature", "cold")
    .then("risk", 0.2);

auto result = model.build().evaluate(
    inputs().set("temperature", 8.0)
);
```

## Inputs

`InputValues` is named and sparse. A value of `0.0` is present when set
explicitly; `missing` removes its availability.

```d
auto observation = inputs()
    .set("angle", 110.0)
    .set("slope", 0.0)
    .missing("height");
```

## Rules

```d
.when("variable", "term")
.whenAll("variableA", "termA", "variableB", "termB")
.whenAny("variableA", "termA", "variableB", "termB")
.whenNot("variable", "term")
.whenVery("variable", "term")
.whenMoreOrLess("variable", "term")
```

Operator semantics can be selected on the builder:

```d
builder.operators(OperatorFamily.product);
```

The default is Gödel/min-max semantics.

## Results

```d
if (result.hasValue)
    auto risk = result.value;

foreach (trace; result.trace)
    writeln(trace.activation);
```

No activated rule is not treated as a valid numeric zero. Missing inputs raise
`MissingInputException` when they are required by an expression.

For a repeated production hot path, prepare the model once and pass values in
declaration order:

```d
auto prepared = model.build().prepare();
assert(prepared.inputName(0) == "temperature");
auto risk = prepared.evaluateValue([8.0]);
```

`evaluateValue` assumes all inputs are present, constructs no named-input map
or trace, and is intended for caller-owned numeric buffers. Use named
`evaluate` when input sparsity, missing-input diagnostics or rule traces are
needed.

The consumer test suite contains a complete room-thermostat example with
temperature error, temperature trend, multiple linguistic terms and prepared
numeric evaluation.

## Advanced modules

The following are intentionally not re-exported from the package root:

- `fuzzy.model`
- `fuzzy.ir`
- `fuzzy.inference`
- `fuzzy.expression`

They are available for advanced integrations, prepared-plan construction and
research work. The normal consumer should remain on the facade in `fuzzy`.

For advanced multi-output models, `fuzzy.multioutput` provides both the
allocation-producing `MultiOutputSugeno.evaluate` convenience method and
caller-owned `evaluateInto` methods. `PreparedMultiOutputSugeno` is the
repeated-evaluation path for fully present numeric inputs.
