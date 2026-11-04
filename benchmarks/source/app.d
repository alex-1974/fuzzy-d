module benchmark_app;

import std.datetime.stopwatch : StopWatch, AutoStart;
import std.conv : to;
import std.stdio : writefln;
import fuzzy;
import fuzzy.inference : ExpressionZeroOrderSugeno, PreparedZeroOrderSugeno;
import fuzzy.ir : NormalizedExpression;
import fuzzy.model : EditableModel;

enum iterations = 100_000;

void main()
{
    auto model = new EditableModel;
    auto x = model.addVariable("x");
    auto shape = risingRamp(0.0, 1.0);
    auto direct = new ExpressionZeroOrderSugeno;
    auto prepared = new PreparedZeroOrderSugeno;

    foreach (i; 0 .. 100)
    {
        auto term = model.addTerm(x, "term" ~ to!string(i),
            (double value) => shape(value));
        NormalizedExpression expression;
        expression.setRoot(expression.addTerm(term));
        direct.addRule("rule", expression, i);
        prepared.addRule("rule", expression, model, i);
    }

    auto input = [0.0];

    double directSink = 0.0;
    auto directWatch = StopWatch(AutoStart.yes);
    foreach (i; 0 .. iterations)
    {
        input[0] = cast(double)(i % 99 + 1) / 100.0;
        auto result = direct.evaluate(model, input);
        if (result.hasValue) directSink += result.value;
    }
    auto directNanos = directWatch.peek.total!"nsecs";

    double preparedSink = 0.0;
    auto preparedModel = model.prepare();
    auto preparedWatch = StopWatch(AutoStart.yes);
    foreach (i; 0 .. iterations)
    {
        input[0] = cast(double)(i % 99 + 1) / 100.0;
        auto result = prepared.evaluate(preparedModel, input);
        if (result.hasValue) preparedSink += result.value;
    }
    auto preparedNanos = preparedWatch.peek.total!"nsecs";

    auto preparationWatch = StopWatch(AutoStart.yes);
    foreach (i; 0 .. 1000)
    {
        auto snapshot = model.prepare();
        // Keep the snapshot observable without including it in evaluation timing.
        assert(snapshot.termCount == 100);
    }
    auto preparationNanos = preparationWatch.peek.total!"nsecs";

    writefln("rules=%s iterations=%s", 100, iterations);
    writefln("direct_ns=%s sink=%s", directNanos, directSink);
    writefln("prepared_ns=%s sink=%s", preparedNanos, preparedSink);
    writefln("prepare_1000_ns=%s", preparationNanos);
}
