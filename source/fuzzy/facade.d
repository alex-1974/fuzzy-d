module fuzzy.facade;

import std.exception : enforce;
import fuzzy.degree : Degree;
import fuzzy.inference : ExpressionZeroOrderSugeno, PreparedZeroOrderSugeno, SugenoResult;
import fuzzy.ir : NormalizedExpression;
import fuzzy.membership : Triangle, Trapezoid, RisingRamp, FallingRamp, Gaussian, Sigmoid, GeneralizedBell;
import fuzzy.model : EditableModel, InputVector, PreparedModel, VariableId, TermId;
import fuzzy.operators : OperatorFamily;

/** Named, sparse consumer input values. */
struct InputValues
{
    private double[string] values;
    private bool[string] present;

    InputValues set(string name, double value)
    {
        auto result = this;
        result.values[name] = value;
        result.present[name] = true;
        return result;
    }

    InputValues missing(string name)
    {
        auto result = this;
        result.values.remove(name);
        result.present[name] = false;
        return result;
    }
}

/** Start a named input set. */
InputValues inputs() pure { return InputValues.init; }

/** Named consumer-facing inference result. */
struct NamedResult
{
    private SugenoResult result;
    private string outputName;

    @property bool hasValue() const pure nothrow @safe @nogc { return result.hasValue; }
    @property double value() const pure nothrow @safe @nogc { return result.value; }
    @property string output() const pure nothrow @safe @nogc { return outputName; }
    @property auto trace() const { return result.trace; }
}

/** Built model with named-input evaluation. */
final class FuzzyModel
{
    private EditableModel model;
    private ExpressionZeroOrderSugeno rules;
    private string outputName;
    private VariableId[] variableIds;
    private string[] variableNames;
    private NormalizedExpression[] expressions;
    private double[] consequents;

    this(EditableModel model, ExpressionZeroOrderSugeno rules,
         string outputName, VariableId[] variableIds, string[] variableNames,
         NormalizedExpression[] expressions, double[] consequents)
    {
        this.model = model;
        this.rules = rules;
        this.outputName = outputName;
        this.variableIds = variableIds;
        this.variableNames = variableNames;
        this.expressions = expressions;
        this.consequents = consequents;
    }

    NamedResult evaluate(InputValues input) const
    {
        double[] values = new double[variableIds.length];
        bool[] present = new bool[variableIds.length];
        foreach (i, name; variableNames)
        {
            if (name in input.present && input.present[name])
            {
                values[i] = input.values[name];
                present[i] = true;
            }
        }
        auto result = rules.evaluate(model, InputVector(values, present));
        return NamedResult(result, outputName);
    }

    /** Prepare the underlying model for repeated named evaluation. */
    PreparedFuzzyModel prepare() const
    {
        auto preparedRules = new PreparedZeroOrderSugeno;
        foreach (i, expression; expressions)
        {
            auto editableExpression = cast(NormalizedExpression) expression;
            preparedRules.addRule("rule", editableExpression, model, consequents[i]);
        }
        return new PreparedFuzzyModel(model.prepare(), preparedRules, outputName, variableIds.dup, variableNames.dup);
    }
}

/** Prepared named-input facade. */
final class PreparedFuzzyModel
{
    private PreparedModel model;
    private PreparedZeroOrderSugeno rules;
    private string outputName;
    private NormalizedExpression[] expressions;
    private double[] consequents;
    private VariableId[] variableIds;
    private string[] variableNames;

    this(PreparedModel model, PreparedZeroOrderSugeno rules,
         string outputName, VariableId[] variableIds, string[] variableNames)
    {
        this.model = model;
        this.rules = rules;
        this.outputName = outputName;
        this.variableIds = variableIds;
        this.variableNames = variableNames;
    }

    NamedResult evaluate(InputValues input) const
    {
        double[] values = new double[variableIds.length];
        bool[] present = new bool[variableIds.length];
        foreach (i, name; variableNames)
        {
            if (name in input.present && input.present[name])
            {
                values[i] = input.values[name];
                present[i] = true;
            }
        }
        return NamedResult(rules.evaluate(model, InputVector(values, present)), outputName);
    }

    /**
     * Evaluate the prepared model on caller-owned, fully present values.
     * Values follow the declaration order exposed by `inputName` and no
     * named-input map or rule trace is constructed.
     */
    double evaluateValue(const double[] values)
    {
        enforce(values.length == variableIds.length,
            "numeric input count does not match prepared model");
        return rules.evaluateValue(model, values);
    }

    /** Create a prepared facade with worker-local mutable evaluation caches. */
    PreparedFuzzyModel cloneForWorker()
    {
        return new PreparedFuzzyModel(model, rules.cloneForWorker(), outputName,
            variableIds.dup, variableNames.dup);
    }

    @property size_t inputCount() const pure nothrow @safe @nogc
    {
        return variableNames.length;
    }

    string inputName(size_t index) const
    {
        enforce(index < variableNames.length, "prepared input index is invalid");
        return variableNames[index];
    }
}

/** Fluent builder for the human-facing Type-1 model API. */
final class FuzzyModelBuilder
{
    private EditableModel model;
    private ExpressionZeroOrderSugeno rules;
    private string[string] variables;
    private string[] variableOrder;
    private TermId[string] terms;
    private string currentVariable;
    private string outputName;
    private OperatorFamily operatorFamily = OperatorFamily.godel;
    private NormalizedExpression[] expressions;
    private double[] consequents;

    this()
    {
        model = new EditableModel;
        rules = new ExpressionZeroOrderSugeno;
    }

    FuzzyModelBuilder input(string name)
    {
        auto id = model.addVariable(name);
        variables[name] = name;
        variableOrder ~= name;
        currentVariable = name;
        return this;
    }

    FuzzyModelBuilder term(string name, Degree delegate(double) evaluator)
    {
        enforce(currentVariable.length != 0, "define an input before its terms");
        terms[currentVariable ~ "\0" ~ name] = model.addTerm(
            model.variableByName(currentVariable), name, evaluator);
        return this;
    }

    FuzzyModelBuilder output(string name)
    {
        enforce(name.length != 0, "output name must not be empty");
        outputName = name;
        return this;
    }

    /** Select the AND/OR semantics for subsequently defined rules. */
    FuzzyModelBuilder operators(OperatorFamily family)
    {
        operatorFamily = family;
        return this;
    }

    RuleDraft rule(string name)
    {
        return new RuleDraft(this, name);
    }

    FuzzyModel build()
    {
        enforce(outputName.length != 0, "define an output before building");
        enforce(rules.ruleCount != 0, "define at least one rule before building");
        VariableId[] ids;
        string[] names;
        foreach (name; variableOrder)
        {
            ids ~= model.variableByName(name);
            names ~= name;
        }
        return new FuzzyModel(model, rules, outputName, ids, names, expressions, consequents);
    }

    private TermId termId(string variable, string name) const
    {
        auto key = variable ~ "\0" ~ name;
        enforce(key in terms, "unknown variable term");
        return terms[key];
    }
}

/** Fluent rule draft: `.when(...).then(...)`. */
final class RuleDraft
{
    private FuzzyModelBuilder builder;
    private string name;
    private string variable;
    private string term;
    private NormalizedExpression expression;
    private bool hasExpression;

    this(FuzzyModelBuilder builder, string name) { this.builder = builder; this.name = name; }

    RuleDraft when(string variable, string term)
    {
        this.variable = variable;
        this.term = term;
        this.hasExpression = false;
        return this;
    }

    RuleDraft whenAll(string firstVariable, string firstTerm,
                      string secondVariable, string secondTerm)
    {
        auto first = builder.termId(firstVariable, firstTerm);
        auto second = builder.termId(secondVariable, secondTerm);
        auto firstNode = expression.addTerm(first);
        auto secondNode = expression.addTerm(second);
        expression.setRoot(expression.addAllOf(firstNode, secondNode));
        hasExpression = true;
        return this;
    }

    RuleDraft whenAny(string firstVariable, string firstTerm,
                      string secondVariable, string secondTerm)
    {
        auto first = builder.termId(firstVariable, firstTerm);
        auto second = builder.termId(secondVariable, secondTerm);
        auto firstNode = expression.addTerm(first);
        auto secondNode = expression.addTerm(second);
        expression.setRoot(expression.addAnyOf(firstNode, secondNode));
        hasExpression = true;
        return this;
    }

    RuleDraft whenNot(string variable, string term)
    {
        auto node = expression.addTerm(builder.termId(variable, term));
        expression.setRoot(expression.addNot(node));
        hasExpression = true;
        return this;
    }

    RuleDraft whenVery(string variable, string term)
    {
        auto node = expression.addTerm(builder.termId(variable, term));
        expression.setRoot(expression.addVery(node));
        hasExpression = true;
        return this;
    }

    RuleDraft whenMoreOrLess(string variable, string term)
    {
        auto node = expression.addTerm(builder.termId(variable, term));
        expression.setRoot(expression.addMoreOrLess(node));
        hasExpression = true;
        return this;
    }

    FuzzyModelBuilder then(string output, double consequent)
    {
        enforce(output == builder.outputName, "rule output must match the model output");
        if (!hasExpression)
            expression.setRoot(expression.addTerm(builder.termId(variable, term)));
        expression.setOperatorFamily(builder.operatorFamily);
        builder.rules.addRule(name, expression, consequent);
        builder.expressions ~= expression;
        builder.consequents ~= consequent;
        return builder;
    }
}
