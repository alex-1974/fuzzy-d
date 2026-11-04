module fuzzy.compiletime;

import fuzzy.degree : Degree;
import fuzzy.operators : OperatorFamily;

/** A rule whose antecedent and constant consequent are known at compile time. */
struct FixedSugenoRule(alias Antecedent, double Consequent)
{
    enum consequent = Consequent;
    /** Evaluate this rule's compile-time-known antecedent. */
    static Degree activation(double input) pure
    {
        return Antecedent(input);
    }
}

/** Result of a fixed-model evaluation with an explicit no-result state. */
struct FixedSugenoResult
{
    bool hasValue;
    double value = 0.0;
    double totalActivation = 0.0;
}

/**
 * Compile-time-specialized zero-order Sugeno evaluator.
 *
 * The rule pack is expanded with `static foreach`; no runtime rule container
 * or delegate dispatch is required for a fixed model.
 */
struct FixedSugeno(Rules...)
{
    /** Evaluate and preserve the explicit no-result state. */
    static FixedSugenoResult evaluateResult(double input) pure
    {
        FixedSugenoResult result;
        static foreach (Rule; Rules)
        {
            {
                auto activationValue = Rule.activation(input).value;
                result.totalActivation += activationValue;
                result.value += activationValue * Rule.consequent;
            }
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

    /** Evaluate and return NaN when no rule is activated. */
    static double evaluate(double input) pure
    {
        return evaluateResult(input).value;
    }
}

/** Compile-time Sugeno evaluator with an explicit operator-family contract. */
struct FixedSugenoWithOperators(OperatorFamily Family, Rules...)
{
    /** Evaluate a fixed rule pack under the selected operator family. */
    static FixedSugenoResult evaluateResult(double input) pure
    {
        FixedSugenoResult result;
        static foreach (Rule; Rules)
        {
            {
                auto activationValue = Rule.activation(input).value;
                result.totalActivation += activationValue;
                result.value += activationValue * Rule.consequent;
            }
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

    /** Evaluate and return NaN when no rule is activated. */
    static double evaluate(double input) pure
    {
        return evaluateResult(input).value;
    }
}

unittest
{
    import fuzzy.membership : FallingRamp, RisingRamp;
    enum low = FallingRamp(0.0, 10.0);
    enum high = RisingRamp(0.0, 10.0);
    alias LowRule = FixedSugenoRule!(low, 10.0);
    alias HighRule = FixedSugenoRule!(high, 20.0);
    alias Model = FixedSugeno!(LowRule, HighRule);

    assert(Model.evaluate(0.25) == 10.25);
    static assert(Model.evaluate(5.0) == 15.0);
    auto result = Model.evaluateResult(5.0);
    assert(result.hasValue && result.totalActivation == 1.0);
}

unittest
{
    import fuzzy.expression : AllOf, Term, VeryOf;
    import fuzzy.membership : FallingRamp, RisingRamp;

    enum lowShape = FallingRamp(0.0, 10.0);
    enum highShape = RisingRamp(0.0, 10.0);
    enum lowTerm = Term!lowShape.init;
    enum highTerm = Term!highShape.init;
    enum combined = AllOf!(typeof(lowTerm), typeof(highTerm))(lowTerm, highTerm);
    enum emphasized = VeryOf!(typeof(combined))(combined);

    alias CombinedRule = FixedSugenoRule!(emphasized, 42.0);
    alias CombinedModel = FixedSugeno!(CombinedRule);

    static assert(CombinedModel.evaluate(5.0) == 42.0);
}

unittest
{
    import fuzzy.expression : AnyOfWith, Term;
    import fuzzy.membership : FallingRamp, RisingRamp;

    enum lowShape = FallingRamp(0.0, 10.0);
    enum highShape = RisingRamp(0.0, 10.0);
    enum lowTerm = Term!lowShape.init;
    enum highTerm = Term!highShape.init;
    enum combined = AnyOfWith!(OperatorFamily.product, typeof(lowTerm), typeof(highTerm))(lowTerm, highTerm);
    alias Rule = FixedSugenoRule!(combined, 42.0);
    alias ProductModel = FixedSugenoWithOperators!(OperatorFamily.product, Rule);

    static assert(ProductModel.evaluate(2.0) == 42.0);
}
