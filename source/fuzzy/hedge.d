module fuzzy.hedge;

import std.exception : enforce;
import std.math : isFinite, pow, sqrt;
import fuzzy.degree : Degree;

/** Complement of a membership degree. */
Degree complement(Degree value) pure
{
    return Degree(1.0 - value.value);
}

/** General power hedge. Exponent must be finite and positive. */
Degree powerHedge(Degree value, double exponent) pure
{
    enforce(isFinite(exponent) && exponent > 0.0, "hedge exponent must be positive and finite");
    return Degree(pow(value.value, exponent));
}

/** Concentration hedge, conventionally called `very`. */
Degree very(Degree value) pure
{
    return Degree(value.value * value.value);
}

/** Dilation hedge, conventionally called `more or less`. */
Degree moreOrLess(Degree value) pure
{
    return Degree(sqrt(value.value));
}

unittest
{
    assert(complement(Degree(0.25)).value == 0.75);
    assert(very(Degree(0.5)).value == 0.25);
    assert(moreOrLess(Degree(0.25)).value == 0.5);
    assert(powerHedge(Degree(0.5), 3).value == 0.125);
    assert(complement(Degree.zero).value == 1.0);
    assert(complement(Degree.one).value == 0.0);
    assert(very(Degree.zero).value == 0.0);
    assert(very(Degree.one).value == 1.0);
    assert(moreOrLess(Degree.zero).value == 0.0);
    assert(moreOrLess(Degree.one).value == 1.0);
}

enum ctfeVery = very(Degree(0.5));
static assert(ctfeVery.value == 0.25);
