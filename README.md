# Total Error: What Classifier Validation Establishes About Exposure Comparisons

Start with the research quantity: a person's exposure, a difference between
groups, or a regression coefficient. For a user comparison with weights `a` and
a browsing matrix `C`, the target is `θ = a'Cy = w'y`, where `w = C'a` gives the
domain weights. Exposure shares first normalize the rows of `C`; regression
coefficients supply `a` from the fixed design matrix.

If `e` contains domain prediction errors, the comparison's error is `w'e`.
Under a stated prediction-error process, its bias is `w'b`, its variance is
`w'Σw`, and its mean squared error is `(w'b)² + w'Σw`. The full covariance `Σ`
allows errors across domains to be correlated. Shared classifier failures can
therefore link even users who visit different sites. Reusing one label across
many visits creates an additional source of dependence across users.

The [paper](ms/main.pdf) characterizes the sharp range of a comparison given
exact confusion counts and shows when those counts suffice. It distinguishes
prediction-error covariance from uncertainty due to a randomized label audit.
An audit can provide simultaneous finite-sample bounds, but projecting its count
summaries can lose substantial information about weighted errors. Direct
weighted-error estimation is the relevant comparison. These constructions use
established quantification, survey-sampling, and statistical-auditing tools.

The bundled browsing benchmark includes seven scanner outcomes, twelve demographic
coefficients, visit totals and shares, and three imposed error fractions. It is a
stress test with deliberately generated mistakes, not an evaluation of a trained
classifier. One contrast compares three audit intervals on common
samples. The [data documentation](data/README.md) states the analytic frame,
transformations, redistribution provenance, and limits of the reference labels.

The [historical simulation](docs/sim_total_error.md) retains the original continuous-data
example. Exact finite-enumeration tests verify binary-label propagation, sharp
bounds, hypergeometric inversion, simultaneous audit coverage, and design-unbiased
estimation. The rare-error example uses exact binomial probabilities.

The companion [fewlab](https://github.com/finite-sample/fewlab) project uses the
same mapping to choose which reusable labels to acquire. A probability sample
of verified labels can correct a frozen classifier's contribution to a total or
coefficient without assuming that the classifier is calibrated. The note derives
that connection and distinguishes label-sampling uncertainty from prediction
uncertainty.

## Provenance

The argument about unequal browsing volumes and costly errors on popular domains
appears in **“Browsing Data: Concerns and Solutions”** in Suriyan Laohaprapanon
and Gaurav Sood's *Domain Knowledge* manuscript. The relevant text is present in
[commit `850644c`, June 14, 2020](https://github.com/themains/domain_knowledge/blob/850644c06d19a3d787a444443472367dd1bd3046/ms/domain_knowledge.tex#L180-L200).
That repository begins in October 2018; the earliest explicit manuscript treatment
verified here is June 2020. The standalone `total_error` note and simulation
were committed in June 2023. A present-day provenance merge links the
original June 2020 commit and its ancestors from `domain_knowledge`, preserving
their original identities and dates. The imported history records work in that
source repository; it does not backdate the creation of `total_error` or its
current revisions.

The current revision corrects the conditioning of the error rates, states the
scope of the simulation, and develops shared-error covariance, group contrasts,
and the connection to probability sampling of labels. These revisions are later
work; the earlier manuscript establishes the provenance of the original argument.

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
`amsthm`, and Latin Modern fonts. Install missing R packages with:

```r
install.packages(c("MASS", "Matrix", "digest", "rmarkdown", "knitr", "lintr"))
```

```sh
make check
```

This verifies bundled data hashes, runs all exact mathematical tests and R linting,
regenerates both benchmark studies (1,000 audit repetitions per design), the exact
rare-error example, all numerical LaTeX inputs and figures, and the historical
simulation, then checks bibliography syntax, compiles the PDF, and checks
whitespace. No sibling repository, network data download, or fitted model is
required. Run from the repository root.

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
