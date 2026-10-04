Total Error: Using ML to Measure Total Exposure
================
Gaurav Sood

Small systematic errors can distort totals when people contribute
different numbers of observations. This notebook retains the June 2023
simulation’s seed, random draws, and original bias specification, and
adds two comparisons using the same draws. The underlying argument
appears in the June 2020 [Domain Knowledge
manuscript](https://github.com/themains/domain_knowledge/blob/850644c06d19a3d787a444443472367dd1bd3046/ms/domain_knowledge.tex#L180-L200).

## Design

For each of 1,000 respondents, draw an observation count uniformly from
the integers 5 through 1,000. Draw independent bivariate normal pairs
with zero means, unit variances, and correlation 0.9. Let the first
component be the true measure and the second an unbiased proxy. Compare
three proxies:

- No added bias.
- A constant addition of 0.1 to every proxy observation.
- The original addition of 0.1 times the respondent’s sample standard
  deviation of the true measure.

The [R source](../R/sim_total_error.R) generates the draws and
summaries. These are continuous, centered measurements, not binary
labels, visit counts, or durations. Each respondent has independent
draws; the simulation does not reproduce the shared domain labels in
browsing data. It isolates accumulation of bias.

## Results

``` r
display <- results
display$model <- c("No added bias", "Constant bias", "Original SD-scaled bias")
knitr::kable(display, digits = 3, col.names = c(
  "Proxy", "Observation correlation", "Mean correlation",
  "Total correlation", "Mean total error"
))
```

| Proxy | Observation correlation | Mean correlation | Total correlation | Mean total error |
|:---|---:|---:|---:|---:|
| No added bias | 0.9 | 0.903 | 0.893 | 0.139 |
| Constant bias | 0.9 | 0.903 | 0.537 | 51.236 |
| Original SD-scaled bias | 0.9 | 0.901 | 0.538 | 51.239 |

In the original specification, the observation-level correlation is
0.900 and the correlation of respondent totals is 0.538. The mean signed
error in totals (proxy minus truth) is 51.239. These are descriptive
results from one seeded simulation, not estimates from observed browsing
data.

Adding the same constant to every observation leaves the correlations of
observations and respondent means exactly unchanged. Totals acquire a
shift proportional to the number of observations, which varies across
respondents. The original SD-scaled addition is only approximately
constant, so its mean correlation need not be exactly unchanged.

## Why the correlation falls in this design

Let $N$ be independent of the zero-mean pairs $(Y, Z)$, each with unit
variance and correlation $\rho$. Write $S=\sum_{r=1}^N Y_r$ and
$\widehat S=\sum_{r=1}^N(Z_r+b)$. Then

$$\operatorname{Corr}(S,\widehat S)
=\frac{\rho}{\sqrt{1+b^2\operatorname{Var}(N)/E[N]}}.$$

For the constant-bias design, the population correlation is 0.553,
compared with 0.537 in this finite simulation. If everyone contributes
the same number of observations, the added bias does not change this
correlation, although it still biases every total. The formula depends
on the zero means and independence assumptions; it is not a universal
description of exposure totals.

## Correction and its limits

When the constant bias is known, subtracting $bN_i$ removes the added
bias exactly. The original specification instead requires $0.1N_i s_i$,
where $s_i$ is the respondent’s sample standard deviation of the true
measure. That is an oracle correction: the simulation supplies truth
that would usually be unavailable in an application. Neither correction
removes the remaining random prediction errors.

For binary domain labels, a different correction applies. Under common
false-positive and false-negative probabilities $\alpha$ and $\beta$
that remain valid conditional on browsing weights, predicted exposure
satisfies

$$E[\widehat T_i\mid C,y]
=\alpha V_i+(1-\alpha-\beta)T_i.$$

Here $V_i$ is all visits and $T_i$ is visits to truly positive domains.
Thus $(\widehat T_i-\alpha V_i)/(1-\alpha-\beta)$ is unbiased when the
rates are known and their sum is not one. Estimating the rates adds
uncertainty; transferring unweighted validation rates to
browsing-weighted totals requires evidence. See the
[note](../ms/main.pdf) for definitions, shared domain errors, and
implications for group differences.

## Reproduction

Run `make check` to test the algebra, regenerate this document and the
paper’s numerical inputs, and compile the paper. The finite-enumeration
tests check the binary correction and covariance without relying on
Monte Carlo tolerances.

``` r
session <- trimws(capture.output(sessionInfo()), which = "right")
cat("```text\n", paste(session, collapse = "\n"), "\n```\n", sep = "")
```

``` text
R version 4.6.0 (2026-04-24)
Platform: aarch64-apple-darwin23
Running under: macOS 27.0.1

Matrix products: default
BLAS:   /Library/Frameworks/R.framework/Versions/4.6/Resources/lib/libRblas.0.dylib
LAPACK: /Library/Frameworks/R.framework/Versions/4.6/Resources/lib/libRlapack.dylib;  LAPACK version 3.12.1

locale:
[1] C.UTF-8/C.UTF-8/C.UTF-8/C/C.UTF-8/C.UTF-8

time zone: America/Los_Angeles
tzcode source: internal

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base

loaded via a namespace (and not attached):
 [1] MASS_7.3-65     compiler_4.6.0  fastmap_1.2.0   cli_3.6.6
 [5] tools_4.6.0     htmltools_0.5.9 otel_0.2.0      yaml_2.3.12
 [9] rmarkdown_2.32  knitr_1.51      xfun_0.59       digest_0.6.39
[13] rlang_1.3.0     evaluate_1.0.5
```
