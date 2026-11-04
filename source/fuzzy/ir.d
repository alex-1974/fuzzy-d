module fuzzy.ir;

import std.exception : enforce;
import fuzzy.degree : Degree;
import fuzzy.errors : MissingInputException;
import fuzzy.model : EditableModel, InputVector, PreparedModel, TermId, VariableId;
import fuzzy.operators : OperatorFamily, fuzzyAnd, fuzzyOr, fuzzyNot;
import fuzzy.hedge : very, moreOrLess, complement;

/** Node kinds in the normalized Type-1 antecedent expression. */
enum ExpressionKind { term, allOf, anyOf, notOf, very, moreOrLess, complement }

/** Data-only expression node; child references are indices into the same array. */
struct ExpressionNode
{
    ExpressionKind kind;
    TermId term;
    size_t left = size_t.max;
    size_t right = size_t.max;
}

/** Normalized expression graph for deterministic runtime evaluation. */
struct NormalizedExpression
{
    private ExpressionNode[] nodes;
    private size_t root = size_t.max;
    private OperatorFamily operatorFamily = OperatorFamily.godel;

    /** Select the explicit operator family used by this expression. */
    void setOperatorFamily(OperatorFamily family) pure
    {
        operatorFamily = family;
    }

    @property OperatorFamily operators() const pure nothrow @safe @nogc
    {
        return operatorFamily;
    }

    size_t addTerm(TermId term)
    {
        auto index = nodes.length;
        nodes ~= ExpressionNode(ExpressionKind.term, term);
        return index;
    }

    size_t addAllOf(size_t left, size_t right)
    {
        validateChild(left); validateChild(right);
        auto index = nodes.length;
        nodes ~= ExpressionNode(ExpressionKind.allOf, TermId.init, left, right);
        return index;
    }

    size_t addAnyOf(size_t left, size_t right)
    {
        validateChild(left); validateChild(right);
        auto index = nodes.length;
        nodes ~= ExpressionNode(ExpressionKind.anyOf, TermId.init, left, right);
        return index;
    }

    size_t addNot(size_t child)
    {
        validateChild(child);
        auto index = nodes.length;
        nodes ~= ExpressionNode(ExpressionKind.notOf, TermId.init, child);
        return index;
    }

    size_t addVery(size_t child) { return addMapped(ExpressionKind.very, child); }
    size_t addMoreOrLess(size_t child) { return addMapped(ExpressionKind.moreOrLess, child); }
    size_t addComplement(size_t child) { return addMapped(ExpressionKind.complement, child); }

    private size_t addMapped(ExpressionKind kind, size_t child)
    {
        validateChild(child);
        auto index = nodes.length;
        nodes ~= ExpressionNode(kind, TermId.init, child);
        return index;
    }

    void setRoot(size_t root)
    {
        validateChild(root);
        this.root = root;
    }

    /** Validate and freeze this expression graph for repeated evaluation. */
    PreparedExpression prepare() const
    {
        enforce(root != size_t.max, "expression has no root");
        PreparedExpression prepared;
        prepared.nodes = nodes.dup;
        prepared.root = root;
        prepared.operatorFamily = operatorFamily;
        return prepared;
    }

    /** Validate graph references against a model, then create a prepared plan. */
    PreparedExpression prepare(const EditableModel model) const
    {
        validate(model);
        return prepare();
    }

    /** Validate all structural and term references before evaluation. */
    void validate(const EditableModel model) const
    {
        enforce(root != size_t.max, "expression has no root");
        validateNode(model, root);
    }

    Degree evaluate(const EditableModel model, const double[] inputs) const
    {
        return evaluate(model, InputVector(inputs));
    }

    Degree evaluate(const EditableModel model, const InputVector inputs) const
    {
        enforce(root != size_t.max, "expression has no root");
        return evaluateNode(model, inputs, root);
    }

    @property size_t nodeCount() const pure nothrow @safe @nogc { return nodes.length; }

    private void validateChild(size_t index) const
    {
        enforce(index < nodes.length, "expression child index is invalid");
    }

    private void validateNode(const EditableModel model, size_t index) const
    {
        validateChild(index);
        auto node = nodes[index];
        final switch (node.kind)
        {
            case ExpressionKind.term:
                model.term(node.term);
                break;
            case ExpressionKind.allOf:
            case ExpressionKind.anyOf:
                validateNode(model, node.left);
                validateNode(model, node.right);
                break;
            case ExpressionKind.notOf:
                validateNode(model, node.left);
                break;
            case ExpressionKind.very:
            case ExpressionKind.moreOrLess:
            case ExpressionKind.complement:
                validateNode(model, node.left);
                break;
        }
    }

    private Degree evaluateNode(const EditableModel model, const InputVector inputs, size_t index) const
    {
        enforce(index < nodes.length, "expression node index is invalid");
        auto node = nodes[index];
        final switch (node.kind)
        {
            case ExpressionKind.term:
                auto term = model.term(node.term);
                if (!inputs.available(term.variable))
                    throw new MissingInputException("input value is missing for term variable");
                return term(inputs.value(term.variable));
            case ExpressionKind.allOf:
                return fuzzyAnd(operatorFamily, evaluateNode(model, inputs, node.left), evaluateNode(model, inputs, node.right));
            case ExpressionKind.anyOf:
                return fuzzyOr(operatorFamily, evaluateNode(model, inputs, node.left), evaluateNode(model, inputs, node.right));
            case ExpressionKind.notOf:
                return fuzzyNot(operatorFamily, evaluateNode(model, inputs, node.left));
            case ExpressionKind.very:
                return very(evaluateNode(model, inputs, node.left));
            case ExpressionKind.moreOrLess:
                return moreOrLess(evaluateNode(model, inputs, node.left));
            case ExpressionKind.complement:
                return complement(evaluateNode(model, inputs, node.left));
        }
    }
}

/** Immutable expression graph produced from a normalized editable expression. */
struct PreparedExpression
{
    private ExpressionNode[] nodes;
    private size_t root = size_t.max;
    private OperatorFamily operatorFamily = OperatorFamily.godel;

    @property OperatorFamily operators() const pure nothrow @safe @nogc
    {
        return operatorFamily;
    }

    Degree evaluate(const EditableModel model, const double[] inputs) const
    {
        return evaluate(model, InputVector(inputs));
    }

    Degree evaluate(const PreparedModel model, const double[] inputs) const
    {
        return evaluate(model, InputVector(inputs.dup));
    }

    Degree evaluate(const PreparedModel model, const InputVector inputs) const
    {
        enforce(root != size_t.max, "prepared expression has no root");
        return evaluateNode(model, inputs, root);
    }

    Degree evaluate(const EditableModel model, const InputVector inputs) const
    {
        enforce(root != size_t.max, "prepared expression has no root");
        return evaluateNode(model, inputs, root);
    }

    @property size_t nodeCount() const pure nothrow @safe @nogc { return nodes.length; }

    private Degree evaluateNode(const EditableModel model, const InputVector inputs, size_t index) const
    {
        enforce(index < nodes.length, "prepared expression node index is invalid");
        auto node = nodes[index];
        final switch (node.kind)
        {
            case ExpressionKind.term:
                auto term = model.term(node.term);
                if (!inputs.available(term.variable))
                    throw new MissingInputException("input value is missing for term variable");
                return term(inputs.value(term.variable));
            case ExpressionKind.allOf:
                return fuzzyAnd(operatorFamily, evaluateNode(model, inputs, node.left), evaluateNode(model, inputs, node.right));
            case ExpressionKind.anyOf:
                return fuzzyOr(operatorFamily, evaluateNode(model, inputs, node.left), evaluateNode(model, inputs, node.right));
            case ExpressionKind.notOf:
                return fuzzyNot(operatorFamily, evaluateNode(model, inputs, node.left));
            case ExpressionKind.very:
                return very(evaluateNode(model, inputs, node.left));
            case ExpressionKind.moreOrLess:
                return moreOrLess(evaluateNode(model, inputs, node.left));
            case ExpressionKind.complement:
                return complement(evaluateNode(model, inputs, node.left));
        }
    }

    private Degree evaluateNode(const PreparedModel model, const InputVector inputs, size_t index) const
    {
        enforce(index < nodes.length, "prepared expression node index is invalid");
        auto node = nodes[index];
        final switch (node.kind)
        {
            case ExpressionKind.term:
                auto term = model.term(node.term);
                if (!inputs.available(term.variable))
                    throw new MissingInputException("input value is missing for term variable");
                return term(inputs.value(term.variable));
            case ExpressionKind.allOf:
                return fuzzyAnd(operatorFamily, evaluateNode(model, inputs, node.left), evaluateNode(model, inputs, node.right));
            case ExpressionKind.anyOf:
                return fuzzyOr(operatorFamily, evaluateNode(model, inputs, node.left), evaluateNode(model, inputs, node.right));
            case ExpressionKind.notOf:
                return fuzzyNot(operatorFamily, evaluateNode(model, inputs, node.left));
            case ExpressionKind.very:
                return very(evaluateNode(model, inputs, node.left));
            case ExpressionKind.moreOrLess:
                return moreOrLess(evaluateNode(model, inputs, node.left));
            case ExpressionKind.complement:
                return complement(evaluateNode(model, inputs, node.left));
        }
    }
}

unittest
{
    import fuzzy.membership : RisingRamp, FallingRamp;
    auto model = new EditableModel;
    auto x = model.addVariable("x");
    auto lowShape = FallingRamp(0.0, 10.0);
    auto highShape = RisingRamp(0.0, 10.0);
    auto low = model.addTerm(x, "low", (double value) => lowShape(value));
    auto high = model.addTerm(x, "high", (double value) => highShape(value));

    NormalizedExpression expression;
    auto lowNode = expression.addTerm(low);
    auto highNode = expression.addTerm(high);
    auto either = expression.addAnyOf(lowNode, highNode);
    expression.setRoot(either);

    assert(expression.nodeCount == 3);
    assert(expression.evaluate(model, [2.0]).value == 0.8);

    auto prepared = expression.prepare(model);
    assert(prepared.nodeCount == expression.nodeCount);
    assert(prepared.evaluate(model, [2.0]).value == expression.evaluate(model, [2.0]).value);
    auto preparedModel = model.prepare();
    assert(prepared.evaluate(preparedModel, [2.0]).value == expression.evaluate(model, [2.0]).value);
    expression.setOperatorFamily(OperatorFamily.product);
    assert(expression.evaluate(model, [2.0]).value == 0.84);
    auto productPrepared = expression.prepare(model);
    assert(productPrepared.evaluate(preparedModel, [2.0]).value == 0.84);
    import std.exception : assertThrown;
    import fuzzy.errors : MissingInputException;
    assertThrown!MissingInputException(expression.evaluate(model, []));
}

unittest
{
    auto model = new EditableModel;
    NormalizedExpression invalid;
    invalid.setRoot(invalid.addTerm(TermId(99)));
    import std.exception : assertThrown;
    assertThrown!Exception(invalid.prepare(model));
}
