module app;

import fuzzy;
import fuzzy.inference : ExpressionZeroOrderSugeno, PreparedZeroOrderSugeno;
import fuzzy.ir : NormalizedExpression;
import fuzzy.model : EditableModel;

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
}
