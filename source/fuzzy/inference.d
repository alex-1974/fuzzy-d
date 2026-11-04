module fuzzy.inference;

import std.exception : enforce;
import std.math : isNaN;
import fuzzy.degree : Degree;
import fuzzy.ir : NormalizedExpression, PreparedExpression;
import fuzzy.model : EditableModel, InputVector, PreparedModel, VariableId, TermId;

/** Stable identifier of a rule within one rule set. */
struct RuleId
{
    size_t value = size_t.max;
    @property bool valid() const pure nothrow @safe @nogc { return value != size_t.max; }
}

/** A zero-order Sugeno rule with a constant consequent. */
struct ZeroOrderRule
{
    RuleId id;
    string name;
    Degree delegate(const double[]) antecedent;
    double consequent;

    Degree activation(const double[] inputs) const
    {
        enforce(antecedent !is null, "rule has no antecedent evaluator");
        return antecedent(inputs);
    }
}

/** Explainable contribution of one rule to a Sugeno result. */
struct RuleTrace
{
    RuleId rule;
    Degree activation;
    double consequent;
}

/** Result of Sugeno evaluation; `hasValue` distinguishes no activation from zero. */
struct SugenoResult
{
    bool hasValue;
    double value = 0.0;
    double totalActivation = 0.0;
    RuleTrace[] trace;
}

/** Mutable rule set for the first runtime inference family. */
final class ZeroOrderSugeno
{
    private ZeroOrderRule[] rules;

    RuleId addRule(string name, Degree delegate(const double[]) antecedent, double consequent)
    {
        enforce(name.length != 0, "rule name must not be empty");
        enforce(antecedent !is null, "rule antecedent must not be null");
        auto id = RuleId(rules.length);
        ZeroOrderRule rule;
        rule.id = id;
        rule.name = name;
        rule.antecedent = antecedent;
        rule.consequent = consequent;
        rules ~= rule;
        return id;
    }

    SugenoResult evaluate(const double[] inputs) const
    {
        SugenoResult result;
        foreach (rule; rules)
        {
            auto activation = rule.activation(inputs);
            result.totalActivation += activation.value;
            result.trace ~= RuleTrace(rule.id, activation, rule.consequent);
            result.value += activation.value * rule.consequent;
        }
        if (result.totalActivation == 0.0)
        {
            result.value = double.nan;
            return result;
        }
        result.value /= result.totalActivation;
        result.hasValue = true;
        return result;
    }
}

/** Prepared zero-order rule backed by a frozen expression graph. */
struct PreparedSugenoRule
{
    RuleId id;
    string name;
    PreparedExpression antecedent;
    double consequent;
    bool directTerm;
    VariableId variable;
    Degree delegate(double) evaluator;
    TermId termId;
}

/** Reusable prepared Sugeno evaluator. */
final class PreparedZeroOrderSugeno
{
    private PreparedSugenoRule[] rules;
    private double[] termCache;
    private size_t[] termCacheGeneration;
    private size_t generation;

    RuleId addRule(string name, PreparedExpression antecedent, double consequent)
    {
        enforce(name.length != 0, "prepared rule name must not be empty");
        enforce(antecedent.nodeCount != 0, "prepared rule antecedent must not be empty");
        auto id = RuleId(rules.length);
        PreparedSugenoRule rule;
        rule.id = id;
        rule.name = name;
        rule.antecedent = antecedent;
        rule.consequent = consequent;
        if (antecedent.hasBoundSingleTerm)
        {
            rule.directTerm = true;
            rule.variable = antecedent.boundVariableId;
            rule.evaluator = antecedent.boundTermEvaluator;
            rule.termId = antecedent.boundTermId;
            if (termCache.length <= rule.termId.value)
            {
                termCache.length = rule.termId.value + 1;
                termCacheGeneration.length = rule.termId.value + 1;
            }
        }
        rules ~= rule;
        return id;
    }

    /** Validate and prepare an editable expression while adding the rule. */
    RuleId addRule(string name, NormalizedExpression antecedent,
                   const EditableModel model, double consequent)
    {
        return addRule(name, antecedent.prepare(model), consequent);
    }

    SugenoResult evaluate(const EditableModel model, const double[] inputs) const
    {
        SugenoResult result;
        foreach (rule; rules)
        {
            auto activation = rule.antecedent.evaluate(model, inputs);
            result.totalActivation += activation.value;
            result.trace ~= RuleTrace(rule.id, activation, rule.consequent);
            result.value += activation.value * rule.consequent;
        }
        if (result.totalActivation == 0.0)
        {
            result.value = double.nan;
            return result;
        }
        result.value /= result.totalActivation;
        result.hasValue = true;
        return result;
    }

    SugenoResult evaluate(const PreparedModel model, const double[] inputs) const
    {
        return evaluate(model, InputVector(inputs));
    }

    SugenoResult evaluate(const PreparedModel model, const InputVector inputs) const
    {
        SugenoResult result;
        foreach (rule; rules)
        {
            auto activation = rule.antecedent.evaluate(model, inputs);
            result.totalActivation += activation.value;
            result.trace ~= RuleTrace(rule.id, activation, rule.consequent);
            result.value += activation.value * rule.consequent;
        }
        if (result.totalActivation == 0.0)
        {
            result.value = double.nan;
            return result;
        }
        result.value /= result.totalActivation;
        result.hasValue = true;
        return result;
    }

    /** Prepared evaluation without trace construction. */
    double evaluateValue(const PreparedModel model, const double[] inputs)
    {
        double numerator = 0.0;
        double denominator = 0.0;
        ++generation;
        foreach (rule; rules)
        {
            double activation;
            if (rule.directTerm)
            {
                if (termCacheGeneration[rule.termId.value] != generation)
                {
                    termCache[rule.termId.value] = rule.evaluator(inputs[rule.variable.value]).value;
                    termCacheGeneration[rule.termId.value] = generation;
                }
                activation = termCache[rule.termId.value];
            }
            else
                activation = rule.antecedent.evaluate(model, inputs).value;
            numerator += activation * rule.consequent;
            denominator += activation;
        }
        return denominator == 0.0 ? double.nan : numerator / denominator;
    }
}

/** Runtime rule using the normalized expression API instead of a delegate. */
struct ExpressionSugenoRule
{
    RuleId id;
    string name;
    NormalizedExpression antecedent;
    double consequent;
}

/** Editable expression-based zero-order Sugeno rule set. */
final class ExpressionZeroOrderSugeno
{
    private ExpressionSugenoRule[] rules;

    RuleId addRule(string name, NormalizedExpression antecedent, double consequent)
    {
        enforce(name.length != 0, "expression rule name must not be empty");
        enforce(antecedent.nodeCount != 0, "expression rule antecedent must not be empty");
        auto id = RuleId(rules.length);
        ExpressionSugenoRule rule;
        rule.id = id;
        rule.name = name;
        rule.antecedent = antecedent;
        rule.consequent = consequent;
        rules ~= rule;
        return id;
    }

    SugenoResult evaluate(const EditableModel model, const double[] inputs) const
    {
        return evaluate(model, InputVector(inputs));
    }

    SugenoResult evaluate(const EditableModel model, const InputVector inputs) const
    {
        SugenoResult result;
        foreach (rule; rules)
        {
            auto activation = rule.antecedent.evaluate(model, inputs);
            result.totalActivation += activation.value;
            result.trace ~= RuleTrace(rule.id, activation, rule.consequent);
            result.value += activation.value * rule.consequent;
        }
        if (result.totalActivation == 0.0)
        {
            result.value = double.nan;
            return result;
        }
        result.value /= result.totalActivation;
        result.hasValue = true;
        return result;
    }

    /** Evaluate without allocating or collecting a rule trace. */
    double evaluateValue(const EditableModel model, const double[] inputs) const
    {
        double numerator = 0.0;
        double denominator = 0.0;
        foreach (rule; rules)
        {
            auto activation = rule.antecedent.evaluate(model, inputs).value;
            numerator += activation * rule.consequent;
            denominator += activation;
        }
        return denominator == 0.0 ? double.nan : numerator / denominator;
    }

    @property size_t ruleCount() const pure nothrow @safe @nogc { return rules.length; }
}

unittest
{
    auto rules = new ZeroOrderSugeno;
    auto first = rules.addRule("low", (const double[] inputs) => Degree(inputs[0]), 10.0);
    auto second = rules.addRule("high", (const double[] inputs) => Degree(1.0 - inputs[0]), 20.0);
    auto result = rules.evaluate([0.25]);

    assert(first.valid && second.valid);
    assert(result.hasValue);
    assert(result.trace.length == 2);
    assert(result.totalActivation == 1.0);
    assert(result.value == 17.5);
}

unittest
{
    import fuzzy.membership : RisingRamp;
    import fuzzy.ir : NormalizedExpression;

    auto model = new EditableModel;
    auto x = model.addVariable("x");
    auto shape = RisingRamp(0.0, 10.0);
    auto term = model.addTerm(x, "high", (double value) => shape(value));

    NormalizedExpression expression;
    expression.setRoot(expression.addTerm(term));

    auto rules = new ExpressionZeroOrderSugeno;
    auto id = rules.addRule("high-output", expression, 42.0);
    auto result = rules.evaluate(model, [5.0]);

    assert(id.valid);
    assert(result.hasValue);
    assert(result.value == 42.0);
}

unittest
{
    import fuzzy.membership : RisingRamp, FallingRamp;
    import fuzzy.ir : NormalizedExpression;

    auto model = new EditableModel;
    auto x = model.addVariable("x");
    auto lowShape = FallingRamp(0.0, 10.0);
    auto highShape = RisingRamp(0.0, 10.0);
    auto low = model.addTerm(x, "low", (double value) => lowShape(value));
    auto high = model.addTerm(x, "high", (double value) => highShape(value));

    NormalizedExpression lowExpression;
    lowExpression.setRoot(lowExpression.addTerm(low));
    NormalizedExpression highExpression;
    highExpression.setRoot(highExpression.addTerm(high));

    auto prepared = new PreparedZeroOrderSugeno;
    prepared.addRule("low", lowExpression.prepare(), 10.0);
    prepared.addRule("high", highExpression.prepare(), 20.0);
    auto result = prepared.evaluate(model, [0.25]);

    assert(result.hasValue);
    assert(result.value == 10.25);
    assert(result.trace.length == 2);
    auto snapshotResult = prepared.evaluate(model.prepare(), [0.25]);
    assert(snapshotResult.value == result.value);
}

unittest
{
    import fuzzy.membership : RisingRamp, FallingRamp;
    import fuzzy.ir : NormalizedExpression;

    auto model = new EditableModel;
    auto x = model.addVariable("x");
    auto lowShape = FallingRamp(0.0, 10.0);
    auto highShape = RisingRamp(0.0, 10.0);
    auto low = model.addTerm(x, "low", (double value) => lowShape(value));
    auto high = model.addTerm(x, "high", (double value) => highShape(value));

    auto direct = new ZeroOrderSugeno;
    import fuzzy.compiletime : FixedSugeno, FixedSugenoRule;
    direct.addRule("low", (const double[] inputs) => model.term(low)(inputs[0]), 10.0);
    direct.addRule("high", (const double[] inputs) => model.term(high)(inputs[0]), 20.0);

    NormalizedExpression lowExpression;
    lowExpression.setRoot(lowExpression.addTerm(low));
    NormalizedExpression highExpression;
    highExpression.setRoot(highExpression.addTerm(high));
    auto prepared = new PreparedZeroOrderSugeno;
    prepared.addRule("low", lowExpression.prepare(), 10.0);
    prepared.addRule("high", highExpression.prepare(), 20.0);

    enum fixedLowShape = FallingRamp(0.0, 10.0);
    enum fixedHighShape = RisingRamp(0.0, 10.0);
    alias FixedLowRule = FixedSugenoRule!(fixedLowShape, 10.0);
    alias FixedHighRule = FixedSugenoRule!(fixedHighShape, 20.0);
    alias FixedModel = FixedSugeno!(FixedLowRule, FixedHighRule);

    foreach (input; [0.0, 0.25, 2.5, 5.0, 10.0])
    {
        auto directResult = direct.evaluate([input]);
        auto preparedResult = prepared.evaluate(model, [input]);
        assert(directResult.hasValue == preparedResult.hasValue);
        assert(directResult.totalActivation == preparedResult.totalActivation);
        assert(directResult.value == preparedResult.value);
        assert(FixedModel.evaluate(input) == directResult.value);
        assert(directResult.trace.length == preparedResult.trace.length);
        foreach (i; 0 .. directResult.trace.length)
        {
            assert(directResult.trace[i].rule == preparedResult.trace[i].rule);
            assert(directResult.trace[i].activation.value == preparedResult.trace[i].activation.value);
            assert(directResult.trace[i].consequent == preparedResult.trace[i].consequent);
        }
    }
}

unittest
{
    auto rules = new ZeroOrderSugeno;
    rules.addRule("inactive", (const double[]) => Degree.zero, 42.0);
    auto result = rules.evaluate([]);
    assert(!result.hasValue);
    assert(isNaN(result.value));
}
