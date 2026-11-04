module benchmark_app;

import std.datetime.stopwatch : StopWatch, AutoStart;
import std.conv : to;
import std.math : isNaN;
import std.stdio : writefln;
import core.memory : GC;
import fuzzy;
import fuzzy.inference : ExpressionZeroOrderSugeno, PreparedZeroOrderSugeno;
import fuzzy.ir : NormalizedExpression;
import fuzzy.model : EditableModel, TermId;
import fuzzy.operators : OperatorFamily;
import fuzzy.facade : FuzzyModelBuilder, inputs;

struct BenchmarkResult
{
    size_t rules;
    size_t iterations;
    size_t traceIterations;
    long directNanos;
    long preparedNanos;
    long preparationNanos;
    long preparedTraceNanos;
    double breakEvenEvaluations;
    double directSink = 0.0;
    double preparedSink = 0.0;
}

BenchmarkResult runCase(size_t ruleCount, size_t iterations,
                        OperatorFamily family, bool composite)
{
    auto model = new EditableModel;
    auto x = model.addVariable("x");
    auto shape = risingRamp(0.0, 1.0);
    auto direct = new ExpressionZeroOrderSugeno;
    auto prepared = new PreparedZeroOrderSugeno;

    TermId[] termIds;
    auto uniqueTerms = ruleCount / 2 + ruleCount % 2;
    foreach (i; 0 .. uniqueTerms)
    {
        auto term = model.addTerm(x, "term" ~ to!string(i),
            (double value) => shape(value));
        termIds ~= term;
    }
    foreach (i; 0 .. ruleCount)
    {
        NormalizedExpression expression;
        auto first = expression.addTerm(termIds[i % uniqueTerms]);
        if (composite)
        {
            auto second = expression.addTerm(termIds[(i + 1) % uniqueTerms]);
            expression.setRoot(expression.addAllOf(first, second));
        }
        else
            expression.setRoot(first);
        expression.setOperatorFamily(family);
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

    result.traceIterations = iterations / 10 + 1;
    auto traceWatch = StopWatch(AutoStart.yes);
    foreach (i; 0 .. result.traceIterations)
    {
        input[0] = cast(double)(i % 99 + 1) / 100.0;
        auto traced = prepared.evaluate(preparedModel, input);
        if (traced.hasValue) result.preparedTraceNanos += cast(long)(traced.trace.length);
    }
    result.preparedTraceNanos = traceWatch.peek.total!"nsecs";

    auto preparationWatch = StopWatch(AutoStart.yes);
    foreach (i; 0 .. 1000)
    {
        auto snapshot = model.prepare();
        assert(snapshot.termCount == uniqueTerms);
    }
    result.preparationNanos = preparationWatch.peek.total!"nsecs";
    auto directPerEvaluation = cast(double) result.directNanos / iterations;
    auto preparedPerEvaluation = cast(double) result.preparedNanos / iterations;
    auto preparationCost = cast(double) result.preparationNanos / 1000.0;
    result.breakEvenEvaluations = directPerEvaluation > preparedPerEvaluation ?
        preparationCost / (directPerEvaluation - preparedPerEvaluation) : double.infinity;
    return result;
}

void runDuniaCase(size_t iterations)
{
    auto shape = risingRamp(0.0, 100.0);
    auto builder = new FuzzyModelBuilder;
    builder.input("temperature")
        .term("high", (double value) => shape(value))
        .input("load")
        .term("high", (double value) => shape(value))
        .output("risk")
        .rule("temperature and load")
        .whenAll("temperature", "high", "load", "high")
        .then("risk", 1.0);
    auto model = builder.build();
    auto prepared = model.prepare();
    double directSink = 0.0;
    double preparedSink = 0.0;
    auto directWatch = StopWatch(AutoStart.yes);
    foreach (i; 0 .. iterations)
    {
        auto value = model.evaluate(inputs()
            .set("temperature", cast(double)(i % 100))
            .set("load", cast(double)((i * 3) % 100))).value;
        if (!isNaN(value)) directSink += value;
    }
    auto directNanos = directWatch.peek.total!"nsecs";
    auto preparedWatch = StopWatch(AutoStart.yes);
    foreach (i; 0 .. iterations)
    {
        auto value = prepared.evaluate(inputs()
            .set("temperature", cast(double)(i % 100))
            .set("load", cast(double)((i * 3) % 100))).value;
        if (!isNaN(value)) preparedSink += value;
    }
    auto preparedNanos = preparedWatch.peek.total!"nsecs";
    double numericSink = 0.0;
    auto numericInput = [0.0, 0.0];
    auto allocatedBefore = GC.allocatedInCurrentThread();
    auto numericWatch = StopWatch(AutoStart.yes);
    foreach (i; 0 .. iterations)
    {
        numericInput[0] = cast(double)(i % 100);
        numericInput[1] = cast(double)((i * 3) % 100);
        auto value = prepared.evaluateValue(numericInput);
        if (!isNaN(value)) numericSink += value;
    }
    auto numericNanos = numericWatch.peek.total!"nsecs";
    auto allocatedBytes = GC.allocatedInCurrentThread() - allocatedBefore;
    writefln("dunia facade iterations=%s direct_ns=%s prepared_named_ns=%s prepared_numeric_ns=%s numeric_allocated_bytes=%s sinks=%s/%s/%s",
        iterations, directNanos, preparedNanos, numericNanos,
        allocatedBytes, directSink, preparedSink, numericSink);
}

void main()
{
    foreach (spec; [[10UL, 100_000UL], [100UL, 100_000UL], [1000UL, 10_000UL]])
    {
        foreach (family; [OperatorFamily.godel, OperatorFamily.product])
        foreach (composite; [false, true])
        {
        auto result = runCase(spec[0], spec[1], family, composite);
        writefln("family=%s shape=%s rules=%s iterations=%s trace_iterations=%s direct_ns=%s prepared_ns=%s trace_ns=%s prepare_1000_ns=%s break_even=%s",
            family, composite ? "binary" : "term",
            result.rules, result.iterations, result.traceIterations, result.directNanos,
            result.preparedNanos, result.preparedTraceNanos, result.preparationNanos,
            result.breakEvenEvaluations);
        writefln("  sinks direct=%s prepared=%s",
            result.directSink, result.preparedSink);
        }
    }
    runDuniaCase(100_000);
}
