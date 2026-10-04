# Research development plan

Objective: a submission-quality Political Analysis methods note, with an executable
replication package. Journal acceptance is not a verifiable deliverable; a coherent
contribution, correct results, a serious comparison with existing work, and complete
reproducibility are.

## Evidence already seen

Before this extension, the 2023 normal-pair simulation had been reproduced and the
2020 manuscript recovered. The fewlab manuscript and public browsing-extract schema
have been read. The seven label columns' ranges and prevalences have been inspected.
No results of the new bounds or auditing experiments were inspected before this
plan. This is a development plan, not a registered or blinded analysis.

## Proposed contribution and competing explanations

Question: what does validation of reusable binary domain labels establish about a
fixed user-level exposure contrast? The estimand is theta = w'y for known signed
weights induced by a browsing matrix and a fixed user comparison. Labels, browsing
weights, and model predictions are fixed. Auditing randomness comes solely from a
specified probability sample of domains, not a hypothetical population of users.

1. Derive sharp extrema conditional on an entire population confusion matrix.
   Demonstrate that identical confusion counts permit materially different signs.
   Call the interval the convex hull of the identified set; binary assignments
   need not attain every point between its endpoints.
2. Invert stratum-specific hypergeometric distributions from a without-replacement
   audit, incorporate the known locations of audited errors, and project the
   simultaneous count region onto every fixed linear contrast. State finite-sample
   coverage and all sampling assumptions; distinguish sharp projections from a
   conservative Bonferroni confidence region.
3. Evaluate width and certification, as well as coverage. Wide intervals may be
   the correct answer. Compare to ordinary design-based difference estimation,
   not only to a classifier used without any validation.
4. Explain covariance from label reuse with explicit connection to shift-share
   inference. Do not claim C Sigma C' or Horvitz--Thompson corrections as new.
5. Distinguish many domains from many independent, nonrare errors. Test a rare-error
   example in which an oracle normal interval fails despite diffuse variance shares.

## Evaluation

- Exhaustive small populations: sharp endpoints, boundary cases, observed audited
  labels, and exact simultaneous coverage over all admissible samples.
- Public fixed browsing matrix from fewlab, pinned to its committed source.
  Seven binary outcomes: indicator of a positive recorded scanner measure, including
  dichotomization of the two count-valued columns. Counts are nonnegative; missing
  values cannot be converted to zero. These scanner measurements are benchmark
  labels, not a claim of error-free measurement of actual tracking.
- Evaluate all non-intercept demographic coefficients for both visit totals and
  visit shares. The benchmark frame includes only domains with recorded labels;
  inference does not extend to excluded domains or to the US population.
- Imposed predictions: false-positive and false-negative fractions 0.01, 0.05, 0.10;
  compare uniform placement and contrast-directed extreme placement holding the
  confusion counts fixed. These are stress tests, not measured errors of a trained
  classifier. Report all outcomes and contrasts, not a selected favorable one.
- Primary audit illustration: Facebook-pixel indicator and female coefficient of
  visit shares, chosen here before inspecting its coefficient. Budgets 250, 1000,
  2000; classifier error fractions 0.05 in both true classes. Compare predicted-label
  SRS strata and a prespecified influence head plus random tail. Record certainty
  assignments and inclusion probabilities; do not apply hypergeometric inversion
  to unequal-probability or adaptively selected tail samples.
- Monte Carlo coverage should include Monte Carlo standard errors and intervals.
  Any small pilot is labeled development output. Final repetitions and independent
  seeds must be stated in generated metadata.

## Positioning and review

Independent read-only review identified close work in shift-share inference,
multiaccuracy, design-based supervised learning, prediction-powered inference,
quantification, and misclassification sensitivity analysis. These must be addressed
before making a novelty claim. Sorting bounds and hypergeometric inversion use
established tools; the contribution must be assessed for the validation problem
and inferential consequence, not advertised as a new general probability theorem.

Completion requires the new theory, implementation, benchmark, full-text
prior-work comparison, independent review, and a clean rebuild of the replication
package. The dated development entries below record additions made during review.

## Provenance correction during implementation

The candidate fewlab extract is committed locally at e360f65 but the immutable
GitHub URL returned HTTP 404. It must not be described as already publicly
redistributed. Local analysis may proceed; publishing its microdata is pending the
author's decision. Raw files are ignored by Git. Public-data access or an approved
redistribution is required before the replication objective can be completed.

The author subsequently authorized redistribution on October 4, 2026. The exact
extract is bundled with hashes and the source license; replication no longer
requires a download from the unavailable original branch.

## Audit implementation choices before running audit outcomes

The certainty head uses half of each labeling budget and ranks absolute influence
for the prespecified female/share contrast. The remaining budget is allocated
proportionally to the predicted-label tail strata. All other methods use exactly
the same sampled labels. Comparisons are (i) count projection, (ii) the ordinary
stratified difference estimator with a Wald interval, and (iii) a conservative
Hoeffding interval for the same difference estimator, valid without replacement.
The last is an established nonasymptotic baseline. Count projection is not expected
to be uniformly efficient: it discards error-weight association information inside
strata. A constructed dispersed-weight case will illustrate that limitation.

After the 50-draw development pilot, the direct Hoeffding intervals exceeded the
logical binary-label support. Their intersection with the exact support conditional
on audited labels is now reported. This preserves coverage and removes impossible
values. Pilot results are not used for manuscript numerical claims. The final run
uses 1,000 repetitions per design/budget, with all methods compared on common draws.

## Constructive refinement following independent review

After the initial audit results were seen, independent review recommended a direct
test of the within-stratum dispersion characterization. The additional experiment
uses the same fixed primary outcome, coefficient, and prediction vector. Before
running it, we specify 1, 5, and 25 rank bins of signed influence, crossed with
predicted label; ties break by the fixed domain order. For each partition, report
exact-count identification width and 1,000 repeated count-based audit intervals
with the same budget of 1,000. Allocation is proportional with at least two
observations per noncensus stratum. There is no certainty head in this comparison.
This is a declared follow-up, not part of the original prospective plan. It tests
whether finer summaries reduce ambiguity and whether that gain survives having
to estimate more counts from a fixed audit budget.

## Completed revision and verification

The paper includes the three proved identification/audit propositions, explicit
prior-work positioning, the independent-error rare-event counterexample, all 504
browsing comparisons, 6,000 primary audit draws, and 3,000 refinement audit draws.
Independent read-only review found no remaining mathematical correctness blocker;
its interpretation, allocation, and demographic-coding corrections are incorporated.

The full `make check` passed locally and in an isolated copy with results and
exhibits removed. The isolated build regenerated the scientific results and the
same manuscript text without the sibling fewlab checkout or network downloads.
All 13 PDF pages were inspected; the final LaTeX log has no layout or reference
warnings. This establishes a reproducible methods-note draft, not journal acceptance
or novelty of the general audit machinery. The empirical scope remains imposed
errors on a fixed benchmark, with one coefficient used for the audit illustration.
