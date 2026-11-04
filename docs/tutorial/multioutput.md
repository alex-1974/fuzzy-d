# Multiple outputs

Advanced consumers can evaluate several constant outputs from the same fuzzy
rules. This is useful when one observation drives related decisions such as
heating and cooling.

```d
import fuzzy;
import fuzzy.ir : NormalizedExpression;
import fuzzy.model : EditableModel;
import fuzzy.multioutput : PreparedMultiOutputSugeno;

auto model = new EditableModel;
auto x = model.addVariable("signal");
auto active = model.addTerm(x, "active",
    (double value) => risingRamp(0.0, 10.0)(value));

NormalizedExpression expression;
expression.setRoot(expression.addTerm(active));

auto rules = new PreparedMultiOutputSugeno;
rules.addOutput("heating");
rules.addOutput("cooling");
rules.addRule("active response", expression, model, [1.0, 0.0]);

auto output = [0.0, 0.0];
auto hasValue = rules.evaluateInto(model.prepare(), [5.0], output);
assert(hasValue);
assert(output[0] == 1.0 && output[1] == 0.0);
```

The output vector follows output declaration order. For repeated evaluation,
reuse the output buffer. A no-result evaluation returns `false` and fills the
buffer with `NaN` values.

