# Consumer qualification

## Dunia inventory

The local Dunia-related checkout currently available at
`dunia-libs/dunia-vision-d` contains semantic image-interpretation contracts
for masks and candidate objects. It does not currently contain fuzzy-d rules,
membership parameters, inference outputs, or a production input-rate trace.

The planned `dunia-water-d` / water-uncertainty research is useful as a domain
and requirements source, but it is not yet a mature consumer model: the
problem space is still exploratory and the likely model is too complex to use
as a first public-API or performance contract.

Therefore the repository cannot yet claim qualification against a real Dunia
fuzzy workload. The benchmark's two-input risk example is a deliberately
small synthetic proxy, not a recovered Dunia model.

## Current proxy

The benchmark exercises:

- two named inputs;
- a two-term conjunction;
- repeated prepared evaluation;
- named prepared evaluation with trace construction;
- ordered numeric prepared evaluation with a caller-owned buffer;
- GC byte observation for the numeric loop;
- direct versus prepared result equality.

Run it with:

```sh
dub run --root=benchmarks --compiler=ldc2 --build=release --force
```

The output is machine- and compiler-specific evidence. It is not a public
latency guarantee.

## Admission criteria for a real Dunia corpus

Before making Dunia-specific performance claims, record:

1. the actual rule and term count per output;
2. operator family and inference/defuzzification semantics;
3. input dimensionality, units and missing-value frequency;
4. evaluation cadence and acceptable end-to-end latency budget;
5. representative input traces or a reproducible fixture corpus;
6. numerical equality/tolerance between direct, prepared and any compiled path;
7. preparation frequency and expected reuse count;
8. allocation observations under the consumer's release configuration.

Until these data exist, fuzzy-d should optimize and qualify its generic
representative families, while Dunia-specific thresholds remain open. Water
research may contribute candidate variables, uncertainty categories and
future model requirements, but it must not force premature Mamdani,
defuzzification, temporal or probabilistic abstractions into the stable core.

## Stable reference case

The current two-input risk case is intentionally the small reference contract:

- two normalized scalar inputs;
- two simple monotone membership terms;
- one binary antecedent;
- zero-order Sugeno output;
- named diagnostic evaluation and ordered numeric hot-path evaluation.

It is large enough to exercise the public API and prepared execution, while
remaining easy to audit and compare across compilers. A future water-specific
fixture should be admitted only after its semantics and expected outputs are
stable enough for regression use.

The repository's canonical consumer smoke test is a room thermostat with
temperature error and temperature trend as inputs and heating power as a
zero-order Sugeno output. It is intentionally independent of Dunia and water
research.

