module app;

import std.exception : assertThrown;
import std.math : isNaN;
import fuzzy;
import fuzzy.errors : MissingInputException;
import fuzzy.inference : ExpressionZeroOrderSugeno, PreparedZeroOrderSugeno;
import fuzzy.ir : NormalizedExpression;
import fuzzy.model : EditableModel;
import fuzzy.multioutput : MultiOutputSugeno;

void main()
{
    static assert(fuzzyDevelopmentStatus == "pre-0.1");

    auto model = new EditableModel;
    auto temperature = model.addVariable("temperature");
    auto coldShape = FallingRamp(-10.0, 10.0);
    auto cold = model.addTerm(temperature, "cold", (double value) => coldShape(value));

    NormalizedExpression expression;
    expression.setRoot(expression.addTerm(cold));

    auto rules = new ExpressionZeroOrderSugeno;
    rules.addRule("cold-output", expression, 1.0);
    auto result = rules.evaluate(model, [0.0]);
    assert(result.hasValue);
    assert(result.trace[0].activation.value == 0.5);
    assert(result.value == 1.0);

    auto preparedExpression = expression.prepare(model);
    auto preparedRules = new PreparedZeroOrderSugeno;
    preparedRules.addRule("cold-output", preparedExpression, 1.0);
    auto preparedResult = preparedRules.evaluate(model.prepare(), [0.0]);
    assert(preparedResult.hasValue);
    assert(preparedResult.value == result.value);

    auto facadeShape = RisingRamp(0.0, 10.0);
    auto facade = new FuzzyModelBuilder;
    facade.input("level")
        .term("high", (double value) => facadeShape(value))
        .output("risk")
        .rule("high-level")
        .when("level", "high")
        .then("risk", 0.9);
    auto friendly = facade.build();
    auto friendlyResult = friendly.evaluate(inputs().set("level", 5.0));
    assert(friendlyResult.hasValue);
    assert(friendlyResult.output == "risk");
    assert(friendlyResult.value == 0.9);
    assert(friendly.prepare().evaluate(inputs().set("level", 5.0)).value == 0.9);
    auto preparedFriendly = friendly.prepare();
    assert(preparedFriendly.inputCount == 1);
    assert(preparedFriendly.inputName(0) == "level");
    assert(preparedFriendly.evaluateValue([5.0]) == 0.9);

    auto combinedShape = risingRamp(0.0, 10.0);
    auto combined = new FuzzyModelBuilder;
    combined.input("level")
        .term("high", (double value) => combinedShape(value))
        .input("support")
        .term("strong", (double value) => combinedShape(value))
        .output("finding")
        .rule("supported finding")
        .whenAll("level", "high", "support", "strong")
        .then("finding", 0.8);
    assert(combined.build().evaluate(
        inputs().set("level", 5.0).set("support", 5.0)
    ).value == 0.8);

    auto product = new FuzzyModelBuilder;
    product.operators(OperatorFamily.product)
        .input("a")
        .term("high", (double value) => combinedShape(value))
        .input("b")
        .term("high", (double value) => combinedShape(value))
        .output("score")
        .rule("product conjunction")
        .whenAll("a", "high", "b", "high")
        .then("score", 1.0);
    auto productResult = product.build().evaluate(
        inputs().set("a", 5.0).set("b", 5.0)
    );
    assert(productResult.trace[0].activation.value == 0.25);

    auto hedged = new FuzzyModelBuilder;
    hedged.input("temperature")
        .term("hot", (double value) => combinedShape(value))
        .output("risk")
        .rule("very hot")
        .whenVery("temperature", "hot")
        .then("risk", 1.0);
    auto hedgedResult = hedged.build().evaluate(inputs().set("temperature", 5.0));
    assert(hedgedResult.trace[0].activation.value == 0.25);

    // Canonical consumer example: a two-input room thermostat.
    auto thermostat = new FuzzyModelBuilder;
    thermostat.input("temperatureError")
        .term("cold", (double value) => risingRamp(0.0, 10.0)(value))
        .term("comfortable", (double value) => triangle(-2.0, 0.0, 2.0)(value))
        .term("hot", (double value) => fallingRamp(-10.0, 0.0)(value))
        .input("temperatureTrend")
        .term("falling", (double value) => fallingRamp(-5.0, 0.0)(value))
        .term("stable", (double value) => triangle(-2.0, 0.0, 2.0)(value))
        .term("rising", (double value) => risingRamp(0.0, 5.0)(value))
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
    auto thermostatModel = thermostat.build();
    auto thermostatResult = thermostatModel.evaluate(
        inputs().set("temperatureError", 5.0).set("temperatureTrend", -2.0));
    assert(thermostatResult.hasValue);
    assert(thermostatResult.output == "heating");
    assert(thermostatResult.value > 0.0 && thermostatResult.value <= 1.0);
    auto preparedThermostat = thermostatModel.prepare();
    assert(preparedThermostat.inputCount == 2);
    assert(preparedThermostat.inputName(0) == "temperatureError");
    assert(preparedThermostat.inputName(1) == "temperatureTrend");
    auto numericHeating = preparedThermostat.evaluateValue([5.0, -2.0]);
    assert(numericHeating == thermostatResult.value);
    assertThrown!MissingInputException(
        thermostatModel.evaluate(inputs().set("temperatureError", 5.0)));

    foreach (error; [-10.0, -2.0, -1.0, 0.0, 1.0, 2.0, 5.0, 10.0])
    foreach (trend; [-5.0, -2.0, -1.0, 0.0, 1.0, 2.0, 5.0])
    {
        auto named = thermostatModel.evaluate(inputs()
            .set("temperatureError", error)
            .set("temperatureTrend", trend));
        auto preparedNamed = preparedThermostat.evaluate(inputs()
            .set("temperatureError", error)
            .set("temperatureTrend", trend));
        auto numeric = preparedThermostat.evaluateValue([error, trend]);
        assert(named.hasValue == preparedNamed.hasValue);
        if (named.hasValue)
        {
            assert(named.value == preparedNamed.value);
            assert(numeric == named.value);
        }
        else
            assert(isNaN(numeric));
    }

    // Advanced multi-output path: one antecedent drives two outputs.
    auto multi = new MultiOutputSugeno;
    auto heating = multi.addOutput("heating");
    auto cooling = multi.addOutput("cooling");
    multi.addRule("cold response", expression, [1.0, 0.0]);
    auto multiResult = multi.evaluate(model, [0.0]);
    assert(heating.valid && cooling.valid);
    assert(multiResult.hasValue);
    assert(multiResult.values.length == 2);
    assert(multiResult.values[0] == 1.0);
    assert(multiResult.values[1] == 0.0);
}
