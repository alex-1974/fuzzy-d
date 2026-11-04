module benchmark_app;

import std.datetime.stopwatch : StopWatch, AutoStart;
import std.conv : to;
import std.math : isNaN;
import std.stdio : writefln;
import fuzzy;
import fuzzy.inference : ExpressionZeroOrderSugeno, PreparedZeroOrderSugeno;
import fuzzy.ir : NormalizedExpression;
import fuzzy.model : EditableModel;

struct BenchmarkResult
{
    size_t rules;
    size_t iterations;
    long directNanos;
    long preparedNanos;
    long preparationNanos;
    double directSink = 0.0;
    double preparedSink = 0.0;
}

BenchmarkResult runCase(size_t ruleCount, size_t iterations)
{
    auto model = new EditableModel;
    auto x = model.addVariable("x");
    auto shape = risingRamp(0.0, 1.0);
    auto direct = new ExpressionZeroOrderSugeno;
    auto prepared = new PreparedZeroOrderSugeno;

    NormalizedExpression[] expressions;
    auto uniqueTerms = ruleCount / 2 + ruleCount % 2;
    foreach (i; 0 .. uniqueTerms)
    {
        auto term = model.addTerm(x, "term" ~ to!string(i),
            (double value) => shape(value));
        NormalizedExpression expression;
        expression.setRoot(expression.addTerm(term));
        expressions ~= expression;
    }
    foreach (i; 0 .. ruleCount)
    {
        auto expression = expressions[i % uniqueTerms];
        direct.addRule("rule", expression, i);
        prepared.addRule("rule", expression, model, i);
    }

    auto input = [0.0];
    BenchmarkResult result;
    result.rules = ruleCount;
    result.iterations = iterations;

    auto directWatch = StopWatch(AutoStart.yes);
    foreach (i; 0 .. iterations)
    {
        input[0] = cast(double)(i % 99 + 1) / 100.0;
        auto value = direct.evaluateValue(model, input);
        if (!isNaN(value)) result.directSink += value;
    }
    result.directNanos = directWatch.peek.total!"nsecs";

    auto preparedModel = model.prepare();
    auto preparedWatch = StopWatch(AutoStart.yes);
    foreach (i; 0 .. iterations)
    {
        input[0] = cast(double)(i % 99 + 1) / 100.0;
        auto value = prepared.evaluateValue(preparedModel, input);
        if (!isNaN(value)) result.preparedSink += value;
    }
    result.preparedNanos = preparedWatch.peek.total!"nsecs";

    auto preparationWatch = StopWatch(AutoStart.yes);
    foreach (i; 0 .. 1000)
    {
        auto snapshot = model.prepare();
        assert(snapshot.termCount == ruleCount);
    }
    result.preparationNanos = preparationWatch.peek.total!"nsecs";
    return result;
}

void main()
{
    foreach (spec; [[10UL, 100_000UL], [100UL, 100_000UL], [1000UL, 10_000UL]])
    {
        auto result = runCase(spec[0], spec[1]);
        writefln("rules=%s iterations=%s direct_ns=%s prepared_ns=%s prepare_1000_ns=%s",
            result.rules, result.iterations, result.directNanos,
            result.preparedNanos, result.preparationNanos);
        writefln("  sinks direct=%s prepared=%s",
            result.directSink, result.preparedSink);
    }
}
