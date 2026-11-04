module fuzzy.multioutput;

import std.exception : enforce;
import std.math : abs;
import fuzzy.degree : Degree;
import fuzzy.ir : NormalizedExpression, PreparedExpression;
import fuzzy.model : EditableModel, PreparedModel;

/** Stable identifier of an output in a multi-output rule set. */
struct OutputId
{
    size_t value = size_t.max;
    @property bool valid() const pure nothrow @safe @nogc { return value != size_t.max; }
}

/** Named output definition. */
struct OutputDefinition
{
    OutputId id;
    string name;
}

/** A constant consequent vector, ordered by OutputId. */
struct MultiOutputRule
{
    string name;
    NormalizedExpression antecedent;
    double[] consequents;
}

/** Result of multi-output Sugeno evaluation. */
struct MultiOutputResult
{
    bool hasValue;
    double[] values;
    double totalActivation = 0.0;
}

/** Expression-based zero-order Sugeno evaluator for multiple outputs. */
final class MultiOutputSugeno
{
    private OutputDefinition[] outputs;
    private MultiOutputRule[] rules;

    OutputId addOutput(string name)
    {
        enforce(name.length != 0, "output name must not be empty");
        foreach (output; outputs)
            enforce(output.name != name, "output name must be unique");
        auto id = OutputId(outputs.length);
        outputs ~= OutputDefinition(id, name);
        return id;
    }

    void addRule(string name, NormalizedExpression antecedent, double[] consequents)
    {
        enforce(name.length != 0, "multi-output rule name must not be empty");
        enforce(antecedent.nodeCount != 0, "multi-output rule antecedent must not be empty");
        enforce(consequents.length == outputs.length, "consequent count must match output count");
        MultiOutputRule rule;
        rule.name = name;
        rule.antecedent = antecedent;
        rule.consequents = consequents.dup;
        rules ~= rule;
    }

    MultiOutputResult evaluate(const EditableModel model, const double[] inputs) const
    {
        MultiOutputResult result;
        result.values = new double[outputs.length];
        result.values[] = 0.0;
        foreach (rule; rules)
        {
            auto activation = rule.antecedent.evaluate(model, inputs);
            result.totalActivation += activation.value;
            foreach (i, consequent; rule.consequents)
                result.values[i] += activation.value * consequent;
        }
        if (result.totalActivation == 0.0)
        {
            result.values[] = double.nan;
            return result;
        }
        foreach (i; 0 .. result.values.length)
            result.values[i] /= result.totalActivation;
        result.hasValue = true;
        return result;
    }

    /**
     * Evaluate into caller-owned output storage.
     *
     * Returns false when no rule is activated and fills `outputs` with NaN,
     * matching `MultiOutputResult`'s no-result semantics. The output buffer is
     * reused and must have exactly `outputCount` elements.
     */
    bool evaluateInto(const EditableModel model, const double[] inputs,
                      double[] outputs) const
    {
        enforce(outputs.length == outputCount, "multi-output buffer length must match output count");
        outputs[] = 0.0;
        double totalActivation = 0.0;
        foreach (rule; rules)
        {
            auto activation = rule.antecedent.evaluate(model, inputs);
            totalActivation += activation.value;
            foreach (i, consequent; rule.consequents)
                outputs[i] += activation.value * consequent;
        }
        if (totalActivation == 0.0)
        {
            outputs[] = double.nan;
            return false;
        }
        outputs[] /= totalActivation;
        return true;
    }

    @property size_t outputCount() const pure nothrow @safe @nogc { return outputs.length; }
    @property size_t ruleCount() const pure nothrow @safe @nogc { return rules.length; }
}

/** Prepared multi-output Sugeno evaluator for repeated fully-present inputs. */
final class PreparedMultiOutputSugeno
{
    private OutputDefinition[] outputs;
    private PreparedMultiOutputRule[] rules;

    OutputId addOutput(string name)
    {
        enforce(name.length != 0, "prepared output name must not be empty");
        foreach (output; outputs)
            enforce(output.name != name, "prepared output name must be unique");
        auto id = OutputId(outputs.length);
        outputs ~= OutputDefinition(id, name);
        return id;
    }

    void addRule(string name, NormalizedExpression antecedent,
                 const EditableModel model, const double[] consequents)
    {
        enforce(name.length != 0, "prepared multi-output rule name must not be empty");
        enforce(consequents.length == outputs.length, "consequent count must match output count");
        PreparedMultiOutputRule rule;
        rule.name = name;
        rule.antecedent = antecedent.prepare(model);
        rule.consequents = consequents.dup;
        rules ~= rule;
    }

    bool evaluateInto(const PreparedModel model, const double[] inputs,
                      double[] outputs) const
    {
        enforce(outputs.length == this.outputs.length,
            "prepared multi-output buffer length must match output count");
        outputs[] = 0.0;
        double totalActivation = 0.0;
        foreach (rule; rules)
        {
            auto activation = rule.antecedent.evaluateValue(model, inputs);
            totalActivation += activation;
            foreach (i, consequent; rule.consequents)
                outputs[i] += activation * consequent;
        }
        if (totalActivation == 0.0)
        {
            outputs[] = double.nan;
            return false;
        }
        outputs[] /= totalActivation;
        return true;
    }

    @property size_t outputCount() const pure nothrow @safe @nogc { return outputs.length; }
    @property size_t ruleCount() const pure nothrow @safe @nogc { return rules.length; }
}

private struct PreparedMultiOutputRule
{
    string name;
    PreparedExpression antecedent;
    double[] consequents;
}

unittest
{
    import fuzzy.membership : RisingRamp;

    auto model = new EditableModel;
    auto x = model.addVariable("x");
    auto shape = RisingRamp(0.0, 10.0);
    auto term = model.addTerm(x, "high", (double value) => shape(value));
    NormalizedExpression expression;
    expression.setRoot(expression.addTerm(term));

    auto rules = new MultiOutputSugeno;
    auto quality = rules.addOutput("quality");
    auto confidence = rules.addOutput("confidence");
    rules.addRule("high", expression, [0.8, 0.4]);

    auto result = rules.evaluate(model, [5.0]);
    assert(quality.valid && confidence.valid);
    assert(result.hasValue);
    assert(result.values.length == 2);
    assert(abs(result.values[0] - 0.8) < 1e-12);
    assert(abs(result.values[1] - 0.4) < 1e-12);

    auto outputBuffer = [0.0, 0.0];
    assert(rules.evaluateInto(model, [5.0], outputBuffer));
    assert(outputBuffer[0] == result.values[0]);
    assert(outputBuffer[1] == result.values[1]);
}

unittest
{
    import fuzzy.membership : RisingRamp;

    auto model = new EditableModel;
    auto x = model.addVariable("x");
    auto shape = RisingRamp(0.0, 10.0);
    auto term = model.addTerm(x, "high", (double value) => shape(value));
    NormalizedExpression expression;
    expression.setRoot(expression.addTerm(term));
    auto rules = new PreparedMultiOutputSugeno;
    rules.addOutput("a");
    rules.addOutput("b");
    rules.addRule("high", expression, model, [0.8, 0.4]);
    auto values = [0.0, 0.0];
    assert(rules.evaluateInto(model.prepare(), [5.0], values));
    assert(values[0] == 0.8 && values[1] == 0.4);
}
