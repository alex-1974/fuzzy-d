module app;

import fuzzy;

void main()
{
    auto model = new FuzzyModelBuilder;
    model.input("roomTemperature")
        .term("comfortable", (double value) => triangle(18.0, 22.0, 26.0)(value))
        .term("hot", (double value) => risingRamp(23.0, 32.0)(value))
        .input("occupancy")
        .term("occupied", (double value) => risingRamp(0.0, 1.0)(value))
        .output("fanSpeed")
        .rule("occupied and hot")
        .whenAll("roomTemperature", "hot", "occupancy", "occupied")
        .then("fanSpeed", 1.0)
        .rule("comfortable")
        .when("roomTemperature", "comfortable")
        .then("fanSpeed", 0.1);

    auto prepared = model.build().prepare();
    auto speed = prepared.evaluateValue([30.0, 1.0]);
    assert(speed > 0.1 && speed <= 1.0);
}
