/**
Package root of fuzzy-d.

This pre-release scaffold intentionally does not export a fuzzy-inference API.
Numerical and model interfaces will be introduced only with their documented
contracts and tests.
*/
module fuzzy;

/** Development marker (not a released semantic version).

    Examples:
    ---
    import fuzzy;
    static assert(fuzzyDevelopmentStatus == "pre-0.1");
    ---
*/
enum string fuzzyDevelopmentStatus = "pre-0.1";

unittest
{
    static assert(fuzzyDevelopmentStatus == "pre-0.1");
}
