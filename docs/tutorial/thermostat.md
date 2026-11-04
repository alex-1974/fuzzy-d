# Room thermostat

This is the canonical small consumer model for fuzzy-d. It uses temperature
error and temperature trend to produce a heating value in `[0, 1]`.

```d
import fuzzy;

auto thermostat = new FuzzyModelBuilder;
thermostat.input("temperatureError")
    .term("cold", (double x) => risingRamp(0, 10)(x))
    .term("comfortable", (double x) => triangle(-2, 0, 2)(x))
    .term("hot", (double x) => fallingRamp(-10, 0)(x))
    .input("temperatureTrend")
    .term("falling", (double x) => fallingRamp(-5, 0)(x))
    .term("stable", (double x) => triangle(-2, 0, 2)(x))
    .term("rising", (double x) => risingRamp(0, 5)(x))
    .output("heating")
    .rule("cold and falling")
    .whenAll("temperatureError", "cold", "temperatureTrend", "falling")
    .then("heating", 1.0)
    .rule("cold and stable")
    .whenAll("temperatureError", "cold", "temperatureTrend", "stable")
    .then("heating", 0.7)
    .rule("cold and rising")
    .whenAll("temperatureError", "cold", "temperatureTrend", "rising")
    .then("heating", 0.4)
    .rule("comfortable")
    .when("temperatureError", "comfortable")
    .then("heating", 0.2)
    .rule("hot")
    .when("temperatureError", "hot")
    .then("heating", 0.0);

auto model = thermostat.build();
auto result = model.evaluate(
    inputs().set("temperatureError", 5).set("temperatureTrend", -2));
assert(result.hasValue);

// Prepare once for a repeated control loop.
auto prepared = model.prepare();
auto heating = prepared.evaluateValue([5.0, -2.0]);
```

The numeric call follows declaration order. Use named `evaluate` when inputs
may be missing or rule traces are needed.

