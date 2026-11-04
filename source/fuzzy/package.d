/**
Package root of fuzzy-d.

The package root is the human-facing entry point. Internal IR, model and
inference implementation types remain available from their specialized modules
but are not re-exported here.
*/
module fuzzy;

public import fuzzy.degree;
public import fuzzy.compiletime;
public import fuzzy.errors;
public import fuzzy.facade;
public import fuzzy.hedge;
public import fuzzy.membership;
public import fuzzy.multioutput;
public import fuzzy.operators;

/** Released library version.

    Examples:
    ---
    import fuzzy;
    static assert(fuzzyDevelopmentStatus == "0.1.0");
    ---
*/
enum string fuzzyDevelopmentStatus = "0.1.0";

unittest
{
    static assert(fuzzyDevelopmentStatus == "0.1.0");
}
