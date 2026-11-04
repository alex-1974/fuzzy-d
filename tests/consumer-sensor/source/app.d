module app;

import fuzzy;

void main()
{
    auto model = new FuzzyModelBuilder;
    model.input("vibration")
        .term("high", (double value) => risingRamp(2.0, 8.0)(value))
        .input("temperature")
        .term("high", (double value) => risingRamp(60.0, 90.0)(value))
        .output("maintenanceRisk")
        .rule("combined evidence")
        .whenAll("vibration", "high", "temperature", "high")
        .then("maintenanceRisk", 0.95)
        .rule("vibration only")
        .when("vibration", "high")
        .then("maintenanceRisk", 0.35);

    auto result = model.build().evaluate(
        inputs().set("vibration", 7.0).set("temperature", 80.0));
    assert(result.hasValue);
    assert(result.output == "maintenanceRisk");
    assert(result.value > 0.35 && result.value <= 0.95);
}
