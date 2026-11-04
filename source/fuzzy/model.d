module fuzzy.model;

import fuzzy.degree : Degree;
import fuzzy.errors : ValidationException;

private void require(bool condition, string message)
{
    if (!condition)
        throw new ValidationException(message);
}

/** Stable identifier of an input variable within one editable model. */
struct VariableId
{
    size_t value = size_t.max;
    @property bool valid() const pure nothrow @safe @nogc { return value != size_t.max; }
}

/** Stable identifier of a term within one editable model. */
struct TermId
{
    size_t value = size_t.max;
    @property bool valid() const pure nothrow @safe @nogc { return value != size_t.max; }
}

/** A runtime-defined fuzzy input variable. */
struct Variable
{
    VariableId id;
    string name;
}

/** Runtime-defined term and its membership evaluator. */
struct DynamicTerm
{
    TermId id;
    VariableId variable;
    string name;
    Degree delegate(double) evaluator;

    Degree opCall(double input) const
    {
        require(evaluator !is null, "dynamic term has no membership evaluator");
        return evaluator(input);
    }
}

/** Input values plus explicit availability, so missing is not confused with zero. */
struct InputVector
{
    const(double)[] values;
    const(bool)[] present;

    this(const(double)[] values) pure
    {
        this.values = values;
        // An empty mask denotes that every supplied value is present.
        this.present = null;
    }

    this(const(double)[] values, const(bool)[] present)
    {
        require(values.length == present.length, "input values and presence mask must have equal length");
        this.values = values;
        this.present = present;
    }

    bool available(VariableId id) const pure nothrow @safe @nogc
    {
        return id.valid && id.value < values.length &&
            (present.length == 0 || present[id.value]);
    }

    double value(VariableId id) const
    {
        require(available(id), "input value is missing for variable");
        return values[id.value];
    }
}

/** Mutable model container for runtime editing before preparation. */
final class EditableModel
{
    private Variable[] variables;
    private DynamicTerm[] terms;

    VariableId addVariable(string name)
    {
        require(name.length != 0, "variable name must not be empty");
        foreach (v; variables)
            require(v.name != name, "variable name must be unique");
        auto id = VariableId(variables.length);
        variables ~= Variable(id, name);
        return id;
    }

    TermId addTerm(VariableId variable, string name, Degree delegate(double) evaluator)
    {
        require(variable.valid && variable.value < variables.length, "term variable is invalid");
        require(name.length != 0, "term name must not be empty");
        require(evaluator !is null, "term evaluator must not be null");
        foreach (term; terms)
            require(term.variable != variable || term.name != name, "term name must be unique per variable");
        auto id = TermId(terms.length);
        DynamicTerm term;
        term.id = id;
        term.variable = variable;
        term.name = name;
        term.evaluator = evaluator;
        terms ~= term;
        return id;
    }

    @property size_t variableCount() const pure nothrow @safe @nogc { return variables.length; }
    @property size_t termCount() const pure nothrow @safe @nogc { return terms.length; }

    Variable variable(VariableId id) const
    {
        require(id.valid && id.value < variables.length, "variable id is invalid");
        return variables[id.value];
    }

    VariableId variableByName(string name) const
    {
        foreach (variable; variables)
            if (variable.name == name)
                return variable.id;
        throw new ValidationException("unknown variable name");
    }

    DynamicTerm term(TermId id) const
    {
        require(id.valid && id.value < terms.length, "term id is invalid");
        return terms[id.value];
    }

    /** Freeze the current variables and terms for prepared evaluation. */
    PreparedModel prepare() const
    {
        PreparedModel result;
        result.variables = variables.dup;
        result.terms = terms.dup;
        return result;
    }
}

/** Immutable snapshot of an editable model for repeated evaluation. */
struct PreparedModel
{
    private Variable[] variables;
    private DynamicTerm[] terms;

    Variable variable(VariableId id) const
    {
        require(id.valid && id.value < variables.length, "prepared variable id is invalid");
        return variables[id.value];
    }

    DynamicTerm term(TermId id) const
    {
        require(id.valid && id.value < terms.length, "prepared term id is invalid");
        return terms[id.value];
    }
}

unittest
{
    import fuzzy.membership : Triangle;

    auto model = new EditableModel;
    auto temperature = model.addVariable("temperature");
    auto coldShape = Triangle(-10.0, 0.0, 10.0);
    auto cold = model.addTerm(temperature, "cold", (double x) => coldShape(x));

    assert(model.variableCount == 1);
    assert(model.termCount == 1);
    assert(model.variable(temperature).name == "temperature");
    assert(model.term(cold)(0.0).value == 1.0);
    auto prepared = model.prepare();
    assert(prepared.term(cold)(0.0).value == 1.0);
}

unittest
{
    import std.exception : assertThrown;
    import fuzzy.errors : MissingInputException, ValidationException;
    import fuzzy.membership : RisingRamp;

    auto model = new EditableModel;
    auto x = model.addVariable("x");
    auto y = model.addVariable("y");
    auto xShape = RisingRamp(0.0, 10.0);
    auto yShape = RisingRamp(0.0, 10.0);
    auto xTerm = model.addTerm(x, "x-high", (double value) => xShape(value));
    auto yTerm = model.addTerm(y, "y-high", (double value) => yShape(value));

    assert(xTerm.valid && yTerm.valid);
    assertThrown!ValidationException(model.addVariable("x"));

    import fuzzy.ir : NormalizedExpression;
    NormalizedExpression expression;
    auto xNode = expression.addTerm(xTerm);
    auto yNode = expression.addTerm(yTerm);
    expression.setRoot(expression.addAllOf(xNode, yNode));
    assertThrown!MissingInputException(expression.evaluate(model, [5.0]));
    assert(expression.evaluate(model, [5.0, 5.0]).value == 0.5);
    assert(!InputVector([0.0, 0.0], [true, false]).available(y));
    assert(InputVector([0.0, 0.0], [true, true]).available(y));
}
