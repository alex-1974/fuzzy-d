module fuzzy.expression;

import fuzzy.degree : Degree;
import fuzzy.membership : RisingRamp, FallingRamp;
import fuzzy.hedge : very, complement, moreOrLess;
import fuzzy.operators : godelAnd, godelOr, standardNot;
import fuzzy.operators : OperatorFamily, fuzzyAnd, fuzzyOr, fuzzyNot;

/** A named compile-time membership term backed by a callable function object. */
struct Term(alias Membership)
{
    Degree opCall(double input) const pure
    {
        return Membership(input);
    }
}

/** Conjunction of two expressions evaluated against the same input. */
struct AllOf(A, B)
{
    private A left;
    private B right;

    this(A left, B right) pure
    {
        this.left = left;
        this.right = right;
    }

    Degree opCall(double input) const pure
    {
        return godelAnd(left(input), right(input));
    }
}

/** Operator-parametrized conjunction for compile-time-known expressions. */
struct AllOfWith(OperatorFamily Family, A, B)
{
    private A left;
    private B right;
    this(A left, B right) pure { this.left = left; this.right = right; }
    Degree opCall(double input) const pure
    {
        return fuzzyAnd(Family, left(input), right(input));
    }
}

/** Disjunction of two expressions evaluated against the same input. */
struct AnyOf(A, B)
{
    private A left;
    private B right;

    this(A left, B right) pure
    {
        this.left = left;
        this.right = right;
    }

    Degree opCall(double input) const pure
    {
        return godelOr(left(input), right(input));
    }
}

/** Operator-parametrized disjunction for compile-time-known expressions. */
struct AnyOfWith(OperatorFamily Family, A, B)
{
    private A left;
    private B right;
    this(A left, B right) pure { this.left = left; this.right = right; }
    Degree opCall(double input) const pure
    {
        return fuzzyOr(Family, left(input), right(input));
    }
}

/** Standard negation of an expression. */
struct NotOf(A)
{
    private A expression;

    this(A expression) pure { this.expression = expression; }

    Degree opCall(double input) const pure
    {
        return standardNot(expression(input));
    }
}

/** Operator-parametrized negation for compile-time-known expressions. */
struct NotOfWith(OperatorFamily Family, A)
{
    private A expression;
    this(A expression) pure { this.expression = expression; }
    Degree opCall(double input) const pure
    {
        return fuzzyNot(Family, expression(input));
    }
}

/** Apply a degree transformation to an expression. */
struct Mapped(A, alias Transform)
{
    private A expression;

    this(A expression) pure { this.expression = expression; }

    Degree opCall(double input) const pure
    {
        return Transform(expression(input));
    }
}

/** Convenience expression for the linguistic hedge `very`. */
alias VeryOf(A) = Mapped!(A, very);

/** Convenience expression for the linguistic hedge `more or less`. */
alias MoreOrLessOf(A) = Mapped!(A, moreOrLess);

/** Convenience expression for standard fuzzy negation. */
alias ComplementOf(A) = Mapped!(A, complement);

unittest
{
    enum lowRamp = RisingRamp(0.0, 10.0);
    enum highRamp = FallingRamp(0.0, 10.0);
    Term!lowRamp low;
    Term!highRamp high;
    auto both = AllOf!(typeof(low), typeof(high))(low, high);
    assert(both(5.0).value == 0.5);
    auto veryLow = VeryOf!(typeof(low))(low);
    assert(veryLow(5.0).value == 0.25);
    auto notHigh = ComplementOf!(typeof(high))(high);
    assert(notHigh(5.0).value == 0.5);
}

enum ctfeRamp = RisingRamp(0.0, 10.0);
enum ctfeTerm = Term!ctfeRamp.init;
enum ctfeHedged = VeryOf!(typeof(ctfeTerm))(ctfeTerm);
static assert(ctfeHedged(5.0).value == 0.25);
