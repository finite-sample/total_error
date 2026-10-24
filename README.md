# Total Error: What Classifier Validation Establishes About Downstream Estimates

Start with the research quantity: a total, a difference between groups, or a
regression coefficient constructed from classified items. When the quantity is
linear in binary item labels `y`, its target is `θ = w'y`, where `w` records each
item's influence. The items can be documents, places, websites, or other objects
whose predicted labels are reused. The analysis conditions on fixed weights and
gives exact error formulas, bounds, and audit results for linear targets. It
also maps sums and proportions of predicted labels into downstream regressions
and explains what changes for nonlinear statistics.

If `e` contains item prediction errors, the estimate's error is `w'e`.
Under a stated prediction-error process, its bias is `w'b`, its variance is
`w'Σw`, and its mean squared error is `(w'b)² + w'Σw`. The full covariance `Σ`
allows errors across items to be correlated. Reusing one prediction in several
records also transmits its error to every estimate involving those records.
Under a repeated-prediction model, this can correlate aggregate errors across
records even when distinct item errors are independent. Correlation between
distinct item errors is a separate assumption, not a consequence of reuse.

When a sum or fixed-denominator proportion of predicted labels is used as a
regression covariate, its error is the corresponding sum of item errors. The
regression coefficient itself is nonlinear in those labels: the true covariate
appears in both its numerator and denominator. The paper derives that
coefficient error and the plug-in OLS score, distinguishes item-level from complete unit-level
validation, and gives probability-audit corrections for the numerator and
denominator separately. A general transformation can be evaluated over the
labels compatible with an audit, but the linear-target bounds do not
automatically transfer to every transformation.
The regression discussion situates this construction alongside
[Fong and Tyler](https://doi.org/10.1017/pan.2020.38),
[Battaglia and coauthors](https://szymon.info/assets/pdf/BCHS.pdf),
regression calibration, and prediction-powered inference. Battaglia and
coauthors already study classification followed by aggregation into a
regression index; the paper focuses on the implications of item reuse and
item-level validation. The reuse mechanism is also familiar from
[shift-share inference](https://www.princeton.edu/~mkolesar/papers/shift_share.pdf),
so the covariance algebra is not claimed as a new regression method.

The [paper](ms/main.pdf) characterizes the sharp range of a comparison given
exact confusion counts and shows when those counts suffice. It distinguishes
prediction-error covariance from uncertainty due to a randomized label audit.
An audit can provide simultaneous finite-sample bounds, but projecting its count
summaries can lose substantial information about weighted errors. Direct
weighted-error estimation is the relevant comparison. These constructions use
established quantification, survey-sampling, and statistical-auditing tools.
The note is a validation guide for declared estimates, not a new classifier or
regression estimator. Earlier work already treats [aggregate
prevalence](https://doi.org/10.1111/j.1540-5907.2009.00428.x) and
[weighted cost quantification](https://doi.org/10.1007/s10618-008-0097-y).

The bundled YouGov browsing benchmark is one application. A user comparison
with weights `a` and a browsing matrix `C` has `θ = a'Cy = w'y`, where `w = C'a`.
Exposure shares first normalize the rows of `C`; regression coefficients supply
`a` from the fixed design matrix. This benchmark includes seven scanner outcomes,
twelve demographic coefficients, visit totals and shares, and three imposed error
fractions. It is a stress test with deliberately generated mistakes, not an
evaluation of a trained classifier. One contrast compares three audit intervals
on common samples. A separate calculation uses the observed user-domain matrix
and stipulates independent, equal-variance domain errors. For the mean visit
share, the implied prediction-error variance is 323.4 times the value obtained
by discarding covariance across users; for signed demographic coefficients the
ratio can lie on either side of one. This is a design diagnostic, not an
uncertainty estimate for a fitted classifier. The [data documentation](data/README.md) states the analytic
frame, transformations, redistribution provenance, and limits of the reference
labels.

A second example uses actual Piedomains predictions and three alternate domain
classifications from the public [adult browsing study](https://github.com/soodoku/adult).
It compares domain agreement with visit-weighted shares and the range compatible
with directional disagreement counts. The alternate services are reference
classifications, not verified truth, so this example measures disagreement rather
than classifier accuracy. Missing categories are excluded separately for each
service. A sensitivity table retains the observed label pairs for the
highest-visit domains and recomputes the count-compatible range for the rest.

The [historical simulation](docs/sim_total_error.md) retains the original continuous-data
example. Exact finite-enumeration tests verify binary-label propagation, sharp
bounds, hypergeometric inversion, simultaneous audit coverage, and design-unbiased
estimation. The rare-error example uses exact binomial probabilities.

The companion [fewlab](https://github.com/finite-sample/fewlab) project uses the
same mapping to choose which reusable labels to acquire. A probability sample
of verified items can correct a frozen classifier's contribution to a linear
target without assuming that the classifier is calibrated. The note derives
that connection and distinguishes label-sampling uncertainty from prediction
uncertainty. A score plug-in `w'p` has a conditional-mean interpretation only
when its weighted conditional mean error is zero. Item-level conditional
probabilities suffice; ordinary calibration averaged over items does not.

## Provenance

The argument that classification errors can grow with browsing totals and that
mistakes on popular domains can be especially costly appears in Gaurav Sood's
[September 2018 *Prediction Errors* note](docs/prediction_errors_2018.pdf). An
[October 5, 2018 repository commit](https://github.com/themains/domain_knowledge/blob/d13046426ccc50d19bace522d789ee0aa678bd0f/README.md#L28-L38)
states both points and links to that note. The argument also appears in
**“Browsing Data: Concerns and Solutions”** in Suriyan Laohaprapanon and
Gaurav Sood's *Domain Knowledge* manuscript, present in
[commit `850644c`, June 14, 2020](https://github.com/themains/domain_knowledge/blob/850644c06d19a3d787a444443472367dd1bd3046/ms/domain_knowledge.tex#L180-L200).
The standalone `total_error` note and simulation were committed in June 2023.
A present-day provenance merge links the
original June 2020 commit and its ancestors from `domain_knowledge`, preserving
their original identities and dates. The imported history records work in that
source repository; it does not backdate the creation of `total_error` or its
current revisions.

The 2018 note establishes the early problem statement, but its use of
false-positive and false-negative rates does not state the conditioning
consistently. The current revision makes that conditioning explicit, states
the scope of the simulation, and develops the
sharp confusion-count bounds, shared-error covariance, group contrasts, and
probability audits. These formal results are later work.

Related background on population label prevalence is
[Vaz, Izbicki, and Stern (2019)](https://www.jmlr.org/papers/v20/18-456.html).
The connection is correction using classification error rates. That paper is not
treated here as establishing equivalence with the problem of person-specific
weighted exposure and shared errors.

See also: [Gathering Domain Knowledge](https://gojiberries.io/2022/05/15/gathering-domain-knowledge/).

## Layout

| Folder | Contents |
| --- | --- |
| `ms/` | Manuscript, bibliography, section sources, and compiled paper |
| `R/` | Reusable mathematical and data routines |
| `scripts/` | Analysis and exhibit-generation entry points |
| `data/` | Bundled inputs, provenance, and `results/` analysis outputs |
| `tabs/` | Generated LaTeX tables and numerical macros |
| `figs/` | Generated research figures |
| `docs/` | Historical simulation report and R session information |
| `tests/` | Exact mathematical and implementation checks |

LaTeX intermediates stay in ignored `ms/build/`. The root contains project
configuration and this README.

## Reproduce

Requires R with `MASS`, `Matrix`, `digest`, `rmarkdown`, `knitr`, and `lintr`,
Pandoc, and a LaTeX installation with `latexmk`, BibTeX, `natbib`, `microtype`, `booktabs`,
`amsthm`, and Latin Modern fonts. The full lint target also needs Python 3 with
`black`, `isort`, and `flake8`. Install missing R packages with:

```r
install.packages(c("MASS", "Matrix", "digest", "rmarkdown", "knitr", "lintr"))
```

```sh
python3 -m pip install black isort flake8
```

```sh
make check
```

This verifies bundled data hashes, runs all exact mathematical tests and R linting,
regenerates the imposed-error and observed-classifier studies (including 1,000
audit repetitions per design), the exact rare-error example, all numerical
LaTeX inputs and figures, and the historical
simulation, then checks bibliography syntax, compiles the PDF, and checks
whitespace. No sibling repository, network data download, or fitted model is
required. Run from the repository root.

Rebuilding the optional adult input from its pinned public source checkout
requires Python 3; the bundled extract is sufficient for `make check`.

- `make test`: exact correctness checks without regenerating the paper.
- `make analysis`: rebuild the scientific results under `data/results/`.
- `make exhibits`: rebuild the analyses, tables, numerical macros, and figure.
- `make report`: rebuild the historical simulation report and its numerical inputs.
- `make paper`: rebuild the analyses and compile the paper.
- `make manuscript`: compile `ms/main.pdf` from existing results.
- `make bibliography`: parse and check every entry, including uncited entries.
- `data/results/`: all contrasts, audit replicates and summaries, and metadata.
  `docs/session_info.txt` records the R session.
- `tabs/` and `figs/`: derived LaTeX numbers, tables, and figures; rebuild these
  rather than editing them.

The random seeds are fixed in each analysis script. Numerical claims in the paper
are generated from the results. Monte Carlo intervals quantify simulation error;
they are distinct from the intervals being evaluated. The recorded R session gives
the tested dependency versions. Exact bitwise equality across R versions is not
promised; the mathematical tests check the substantive identities and guarantees.

An additional analysis refines validation strata by signed influence at a fixed audit
budget. It distinguishes ambiguity with exactly known counts from uncertainty
when those counts must be estimated. The normal-interval illustration is limited
to one outcome and imposed prediction vector. The paper does not claim that count
projection improves on modern weighted-audit methods or that these stress tests
establish a classifier's real-world performance.
