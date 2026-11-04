module fuzzy.operators;

import std.math : abs;
import fuzzy.degree : Degree;

/** Supported operator families for the initial Type-1 expression model. */
enum OperatorFamily { godel, product }

/** Evaluate conjunction under the selected operator family. */
Degree fuzzyAnd(OperatorFamily family, Degree a, Degree b) pure
{
    final switch (family)
    {
        case OperatorFamily.godel: return godelAnd(a, b);
        case OperatorFamily.product: return productAnd(a, b);
    }
}

/** Evaluate disjunction under the selected operator family. */
Degree fuzzyOr(OperatorFamily family, Degree a, Degree b) pure
{
    final switch (family)
    {
        case OperatorFamily.godel: return godelOr(a, b);
        case OperatorFamily.product: return probabilisticOr(a, b);
    }
}

/** Negation shared by the initial operator families. */
Degree fuzzyNot(OperatorFamily, Degree a) pure
{
    return standardNot(a);
}

/** Gödel (minimum) T-norm: fuzzy conjunction. */
Degree godelAnd(Degree a, Degree b) pure
{
    return Degree(a.value < b.value ? a.value : b.value);
}

/** Gödel (maximum) T-conorm: fuzzy disjunction. */
Degree godelOr(Degree a, Degree b) pure
{
    return Degree(a.value > b.value ? a.value : b.value);
}

/** Product T-norm: fuzzy conjunction. */
Degree productAnd(Degree a, Degree b) pure
{
    return Degree(a.value * b.value);
}

/** Probabilistic-sum T-conorm: fuzzy disjunction. */
Degree probabilisticOr(Degree a, Degree b) pure
{
    return Degree(a.value + b.value - a.value * b.value);
}

/** Standard fuzzy negation. */
Degree standardNot(Degree a) pure
{
    return Degree(1.0 - a.value);
}

unittest
{
    auto a = Degree(0.25);
    auto b = Degree(0.75);
    assert(godelAnd(a, b).value == 0.25);
    assert(godelOr(a, b).value == 0.75);
    assert(productAnd(a, b).value == 0.1875);
    assert(probabilisticOr(a, b).value == 0.8125);
    assert(standardNot(a).value == 0.75);
    assert(fuzzyAnd(OperatorFamily.godel, a, b).value == 0.25);
    assert(fuzzyAnd(OperatorFamily.product, a, b).value == 0.1875);
    assert(fuzzyOr(OperatorFamily.godel, a, b).value == 0.75);
    assert(fuzzyOr(OperatorFamily.product, a, b).value == 0.8125);
}

// Algebraic laws used by the initial Type-1 operator contract.
unittest
{
    auto a = Degree(0.2);
    auto b = Degree(0.4);
    auto c = Degree(0.8);
    assert(godelAnd(a, b).value == godelAnd(b, a).value);
    assert(godelOr(a, b).value == godelOr(b, a).value);
    assert(godelAnd(godelAnd(a, b), c).value == godelAnd(a, godelAnd(b, c)).value);
    assert(productAnd(productAnd(a, b), c).value == productAnd(a, productAnd(b, c)).value);
    assert(abs(standardNot(standardNot(a)).value - a.value) < 1e-15);
}

enum ctfeOperatorResult = productAnd(Degree(0.5), Degree(0.25));
static assert(ctfeOperatorResult.value == 0.125);
