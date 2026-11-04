module fuzzy.membership;

import std.exception : enforce;
import std.math : isFinite, exp, pow, abs;
import fuzzy.degree : Degree;

private void ordered(double a, double b) pure
{
    enforce(isFinite(a) && isFinite(b) && a < b, "membership bounds must be finite and increasing");
}

/** Triangular membership function with zero outside (left, right) and one at middle. */
struct Triangle
{
    private double left, middle, right;
    this(double left, double middle, double right) pure
    {
        enforce(isFinite(left) && isFinite(middle) && isFinite(right) && left < middle && middle < right,
            "triangle parameters must satisfy left < middle < right");
        this.left = left; this.middle = middle; this.right = right;
    }
    Degree opCall(double x) const pure
    {
        if (x <= left || x >= right) return Degree.zero;
        if (x == middle) return Degree.one;
        return Degree((x < middle) ? (x-left)/(middle-left) : (right-x)/(right-middle));
    }
}

/** Trapezoidal membership function with a closed plateau at one. */
struct Trapezoid
{
    private double left, plateauLeft, plateauRight, right;
    this(double left, double plateauLeft, double plateauRight, double right) pure
    {
        enforce(isFinite(left) && isFinite(plateauLeft) && isFinite(plateauRight) && isFinite(right) &&
            left < plateauLeft && plateauLeft <= plateauRight && plateauRight < right,
            "trapezoid parameters must satisfy left < plateauLeft <= plateauRight < right");
        this.left = left; this.plateauLeft = plateauLeft;
        this.plateauRight = plateauRight; this.right = right;
    }
    Degree opCall(double x) const pure
    {
        if (x <= left || x >= right) return Degree.zero;
        if (x >= plateauLeft && x <= plateauRight) return Degree.one;
        return Degree(x < plateauLeft ? (x-left)/(plateauLeft-left) : (right-x)/(right-plateauRight));
    }
}

/** Monotone rising ramp from zero at left to one at right. */
struct RisingRamp
{
    private double left, right;
    this(double left, double right) pure { ordered(left, right); this.left=left; this.right=right; }
    Degree opCall(double x) const pure
    {
        if (x <= left) return Degree.zero;
        if (x >= right) return Degree.one;
        return Degree((x-left)/(right-left));
    }
}

/** Monotone falling ramp from one at left to zero at right. */
struct FallingRamp
{
    private double left, right;
    this(double left, double right) pure { ordered(left, right); this.left=left; this.right=right; }
    Degree opCall(double x) const pure
    {
        if (x <= left) return Degree.one;
        if (x >= right) return Degree.zero;
        return Degree((right-x)/(right-left));
    }
}

alias LeftShoulder = FallingRamp;
alias RightShoulder = RisingRamp;

/** Factory functions for the human-facing API. */
auto triangle(double left, double middle, double right) pure
{
    return Triangle(left, middle, right);
}

auto trapezoid(double left, double plateauLeft, double plateauRight, double right) pure
{
    return Trapezoid(left, plateauLeft, plateauRight, right);
}

auto risingRamp(double left, double right) pure
{
    return RisingRamp(left, right);
}

auto fallingRamp(double left, double right) pure
{
    return FallingRamp(left, right);
}

alias risingShoulder = risingRamp;
alias fallingShoulder = fallingRamp;

/** Gaussian membership function centered at `center` with positive `sigma`. */
struct Gaussian
{
    private double center, sigma;
    this(double center, double sigma) pure
    {
        enforce(isFinite(center) && isFinite(sigma) && sigma > 0.0,
            "gaussian center must be finite and sigma must be positive and finite");
        this.center = center;
        this.sigma = sigma;
    }
    Degree opCall(double x) const pure
    {
        auto z = (x - center) / sigma;
        return Degree(exp(-0.5 * z * z));
    }
}

/** Logistic sigmoid membership function. */
struct Sigmoid
{
    private double center, slope;
    this(double center, double slope) pure
    {
        enforce(isFinite(center) && isFinite(slope) && slope != 0.0,
            "sigmoid center must be finite and slope must be finite and non-zero");
        this.center = center;
        this.slope = slope;
    }
    Degree opCall(double x) const pure
    {
        return Degree(1.0 / (1.0 + exp(-slope * (x - center))));
    }
}

/** Generalized bell membership function with positive width and slope. */
struct GeneralizedBell
{
    private double center, width, slope;
    this(double center, double width, double slope) pure
    {
        enforce(isFinite(center) && isFinite(width) && isFinite(slope) && width > 0.0 && slope > 0.0,
            "generalized bell requires finite center and positive width and slope");
        this.center = center;
        this.width = width;
        this.slope = slope;
    }
    Degree opCall(double x) const pure
    {
        auto ratio = (x - center) / width;
        return Degree(1.0 / (1.0 + pow(abs(ratio), 2.0 * slope)));
    }
}

auto gaussian(double center, double sigma) pure
{
    return Gaussian(center, sigma);
}

auto sigmoid(double center, double slope) pure
{
    return Sigmoid(center, slope);
}

auto generalizedBell(double center, double width, double slope) pure
{
    return GeneralizedBell(center, width, slope);
}

unittest
{
    auto t = Triangle(0, 5, 10);
    assert(t(0).value == 0);
    assert(t(5).value == 1);
    assert(t(10).value == 0);
    auto p = Trapezoid(0, 2, 8, 10);
    assert(p(2).value == 1 && p(5).value == 1 && p(8).value == 1);
    assert(RisingRamp(0, 10)(5).value == 0.5);
    assert(FallingRamp(0, 10)(5).value == 0.5);
    assert(Gaussian(0, 1)(0).value == 1.0);
    assert(abs(Sigmoid(0, 1)(0).value - 0.5) < 1e-15);
    assert(GeneralizedBell(0, 1, 1)(0).value == 1.0);
}

unittest
{
    auto gaussian = Gaussian(3.0, 2.0);
    assert(gaussian(1.0).value == gaussian(5.0).value);
    assert(gaussian(3.0).value > gaussian(2.0).value);
    assert(gaussian(2.0).value > gaussian(1.0).value);

    auto rising = Sigmoid(0.0, 1.0);
    auto falling = Sigmoid(0.0, -1.0);
    assert(rising(-1.0).value < rising(0.0).value);
    assert(rising(0.0).value < rising(1.0).value);
    assert(falling(-1.0).value > falling(0.0).value);
    assert(falling(0.0).value > falling(1.0).value);
}

// CTFE contract: fixed membership functions must be evaluable at compile time.
enum ctfeTriangle = Triangle(0.0, 5.0, 10.0);
static assert(ctfeTriangle(0.0).value == 0.0);
static assert(ctfeTriangle(5.0).value == 1.0);
static assert(ctfeTriangle(10.0).value == 0.0);
enum ctfeGaussian = Gaussian(0.0, 1.0);
static assert(ctfeGaussian(0.0).value == 1.0);
enum ctfeSigmoid = Sigmoid(0.0, 1.0);
static assert(abs(ctfeSigmoid(0.0).value - 0.5) < 1e-15);
