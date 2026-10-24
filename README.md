# One Label, Many Records: Shared Prediction Error in Regression

The [paper](ms/main.pdf) studies predictions reused across records and across
constructed variables. Distinct item labels `y` generate record-level measures
`T = Cy`; predictions `q` give `S = Cq`. One item mistake can therefore enter
many outcomes, several covariates, and multiple reported estimates.

The paper follows the problem through regression. An aggregate outcome produces
coefficient error linear in item mistakes. An aggregate covariate changes the
regression's numerator and denominator, and constructed variables sharing labels
also share errors in their cross-products. A common item error can create
dependence across records even when errors on distinct items are independent.
The paper distinguishes coefficient bias, the variance of an estimator, and
confidence-interval coverage.

The baseline target is the coefficient that complete labels would produce in
the observed panel. An existing probability audit of items gives unbiased linear
and quadratic regression moments and an unbiased joint covariance estimator.
The code in `R/audit_regression.R` implements that calculation for independent
Bernoulli item verification. Delta standard errors additionally require a
well-behaved denominator, a joint normal approximation, and consistent variance
estimation. These are separate from the exact finite-population moment identities.
The paper also describes how score-based population interpretations and estimated
calibration require different assumptions.

A simulation covers aggregates used as outcomes, covariates, and on both sides of
a regression. It varies record count, diffuse versus concentrated loadings, and
the number of items. Each design has 1,000 repetitions of item predictions and
verification. Results report coefficient bias, empirical standard deviation,
mean estimated SE, and coverage. Item correction reduces bias in these examples,
but normal intervals can under-cover with influential or few items. The simulation
includes an oracle covariance comparator to separate variance estimation from
linearization and nonnormality.

Two browsing illustrations provide empirical context. The observed June 2022
YouGov person-domain matrix shows reuse and visit concentration. Deliberately
imposed errors illustrate confusion-count bounds and regression sensitivity;
they do not estimate a trained classifier's accuracy. A separate comparison uses
actual Piedomains predictions and alternate adult-domain classifications to
measure disagreement and changes in visit-weighted shares. Neither classifier
is treated as verified truth. The [data documentation](data/README.md) defines
the frames and transformations.

The literature discussion connects predicted covariates and outcomes, generated
regressors, measurement error, shared-source inference, survey estimation, and
prediction-powered inference. The paper applies those ideas to the item-level
construction rather than claiming a new general regression estimator. The
companion [fewlab](https://github.com/finite-sample/fewlab) project concerns
which reusable labels to acquire; this analysis takes the collected predictions
and validation design as given.

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
audit repetitions per design), the regression-inference simulations, the exact
rare-error example, all numerical
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
when those counts must be estimated. That audit comparison uses one outcome and
imposed prediction vector. The paper does not claim that count
projection improves on modern weighted-audit methods or that these stress tests
establish a classifier's real-world performance.
