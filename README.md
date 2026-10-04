# Total Error: Using ML to Measure Total Exposure Online

Small errors in domain labels can become large errors in people's total online
exposure. A domain's label is reused for every visit and every user, so mistakes
affect both bias and standard errors. Domain-level accuracy alone does not tell
us how well we measure totals, group differences, or regression coefficients.

Let `C` contain user-by-domain visits, and let `e` contain domain prediction
errors. The error in user totals is `Ce`. Conditional on the browsing matrix
and true labels, its expected value is `Cb` and its covariance is `C Σ C'`,
where `b` and `Σ` are the mean and covariance of the domain errors under a
specified prediction-error process. For a comparison with user weights `a`,
the relevant domain weights are `w = C'a`: its bias is `w'b` and its variance
is `w'Σw`.

The [note](total_error.pdf) develops these identities, distinguishes
false-positive rates from errors among predicted positives, and explains the
assumptions needed for corrections and uncertainty estimates. The
[simulation](sim_total_error.md) reproduces the original continuous-data
example and adds constant-bias and no-added-bias comparisons. It isolates bias
accumulation; it does not simulate shared domain labels. Exact finite-enumeration
tests separately verify the binary-label bias, covariance, and sampling correction.

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

## Reproduce

Requires R with `MASS`, `rmarkdown`, `knitr`, and `lintr`, Pandoc, and a LaTeX installation
with `latexmk`, `natbib`, `microtype`, `booktabs`, and Latin Modern fonts.
Install missing R packages with:

```r
install.packages(c("MASS", "rmarkdown", "knitr", "lintr"))
```

```sh
make check
```

This runs the algebra and historical-reproduction tests and R linting, regenerates the
simulation report and LaTeX numerical inputs, compiles `total_error.pdf`, and
checks whitespace. `make test` runs the tests alone; `make paper` regenerates
the report and PDF. Generated numerical inputs are committed under `generated/`
and should be rebuilt, not edited. The simulation report records the R session.
