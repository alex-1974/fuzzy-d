module fuzzy.degree;

import std.exception : enforce;
import std.math : isFinite;

/**
 * A validated Type-1 fuzzy membership degree in the closed interval [0, 1].
 *
 * `.init` is not a valid degree and is retained as a detectable invalid
 * sentinel. Use `Degree.zero` for a valid zero degree.
 */
struct Degree
{
    private double _value;

    /** Construct a degree, rejecting non-finite or out-of-range values. */
    this(double value) pure
    {
        enforce(isFinite(value) && value >= 0.0 && value <= 1.0,
            "fuzzy degree must be finite and in [0, 1]");
        _value = value;
    }

    @property double value() const pure nothrow @safe @nogc { return _value; }
    alias value this;

    static Degree zero() pure nothrow @safe @nogc
    {
        Degree result;
        result._value = 0.0;
        return result;
    }
    static Degree one() pure nothrow @safe @nogc
    {
        Degree result;
        result._value = 1.0;
        return result;
    }
}

unittest
{
    assert(Degree(0.0).value == 0.0);
    assert(Degree(1.0).value == 1.0);
    assert(Degree.one.value == 1.0);
    import std.exception : assertThrown;
    assertThrown!Exception(Degree(-0.01));
    assertThrown!Exception(Degree(1.01));
    import std.math : isNaN;
    assert(isNaN(Degree.init.value));
}
