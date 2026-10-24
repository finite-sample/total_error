bounds <- read.csv("data/results/browsing_bounds.csv")
metadata <- read.csv("data/results/browsing_metadata.csv")
covariate_example <- read.csv("data/results/browsing_covariate.csv")
cookie_example <- subset(covariate_example, outcome == "third_party_cookies")
stopifnot(nrow(cookie_example) == 1)
overlap <- read.csv("data/results/browsing_overlap.csv")
joint <- read.csv("data/results/browsing_joint.csv")
audit <- read.csv("data/results/audit_summary.csv")
rare <- read.csv("data/results/rare_errors.csv")
adult <- read.csv("data/results/adult_comparison.csv")
adult_head <- read.csv("data/results/adult_head_sensitivity.csv")
dir.create("tabs", showWarnings = FALSE)
dir.create("figs", showWarnings = FALSE)
number <- function(x, digits = 0) formatC(x, format = "f", digits = digits, big.mark = ",")
focal <- subset(bounds, outcome == "fb_pixel" & scale == "shares" &
                  coefficient == "gender_Female" & error_fraction == 0.01)
small <- subset(audit, budget == 250 & head_fraction == 0 & method == "normal")
large <- subset(audit, budget == 2000 & head_fraction == 0.5 & method == "normal")
adult_focal <- subset(adult, reference == "bitdefender_porn")
stopifnot(nrow(adult_focal) == 1)
overlap_value <- function(coefficient, field) {
  x <- overlap[overlap$scale == "shares" &
                 overlap$coefficient == coefficient, ]
  stopifnot(nrow(x) == 1)
  x[[field]]
}
macros <- c(
  BenchmarkUsers = number(metadata$users), BenchmarkDomains = number(metadata$domains),
  BenchmarkRecords = number(metadata$records), BenchmarkVisits = number(metadata$visits),
  BenchmarkContrasts = number(metadata$coefficients * metadata$outcomes),
  LargestDomainUsers = number(metadata$largest_domain_users),
  LargestDomainVisitShare = number(100 * metadata$largest_domain_visit_share, 1),
  TopOnePercentDomainVisitShare = number(
    100 * metadata$top_one_percent_domain_visit_share, 1
  ),
  CompleteCovariateCoefficient = number(cookie_example$complete_label_coefficient, 3),
  ImposedCovariateCoefficient = number(cookie_example$imposed_prediction_coefficient, 3),
  MeanShareVarianceRatio = number(overlap_value("mean", "variance_ratio"), 1),
  FemaleShareVarianceRatio = number(overlap_value("gender_Female", "variance_ratio"), 2),
  BlackShareVarianceRatio = number(overlap_value("race_Black", "variance_ratio"), 2),
  MeanShareLargestItem = number(
    100 * overlap_value("mean", "largest_item_variance_share"), 1
  ),
  GroupErrorCorrelation = number(joint$prediction_error_correlation, 3),
  GroupDifferenceVarianceFraction = number(
    100 * joint$difference_variance_fraction, 2
  ),
  FocalTruth = number(100 * focal$target, 3),
  FocalRealizedError = number(100 * abs(focal$uniform_estimate - focal$target), 3),
  FocalLower = number(100 * focal$bound_lower, 2),
  FocalUpper = number(100 * focal$bound_upper, 2),
  FocalAdverseLower = number(100 * focal$adverse_lower, 2),
  FocalAdverseUpper = number(100 * focal$adverse_upper, 2),
  SmallAuditCoverage = number(100 * small$coverage, 1),
  SmallAuditCoverageLower = number(100 * small$coverage_lower, 1),
  SmallAuditCoverageUpper = number(100 * small$coverage_upper, 1),
  LargeAuditCoverage = number(100 * large$coverage, 1),
  LargeAuditWidth = number(100 * large$mean_width, 2),
  RareNormalCoverage = number(100 * rare$oracle_normal_coverage[rare$domains == 10000], 2),
  AdultDomains = number(64074), AdultVisits = number(6236834),
  AdultFocalDomains = number(adult_focal$domains),
  AdultFocalCoverage = number(100 * adult_focal$visit_coverage, 1),
  AdultFocalAgreement = number(100 * adult_focal$domain_agreement, 1),
  AdultFocalProxyDomains = number(100 * adult_focal$proxy_domain_share, 2),
  AdultFocalReferenceDomains = number(100 * adult_focal$reference_domain_share, 2),
  AdultFocalProxy = number(100 * adult_focal$proxy_visit_share, 2),
  AdultFocalReference = number(100 * adult_focal$reference_visit_share, 2),
  AdultFocalDifference = number(-100 * adult_focal$observed_difference, 2),
  AdultFocalProxyOnly = number(adult_focal$proxy_only),
  AdultFocalReferenceOnly = number(adult_focal$reference_only),
  AdultFocalLargest = number(100 * adult_focal$largest_predicted_negative_visit_share, 1),
  AdultFocalLower = number(100 * adult_focal$bound_lower, 2),
  AdultFocalUpper = number(100 * adult_focal$bound_upper, 2)
)
writeLines(
  sprintf("\\newcommand{\\%s}{%s}", names(macros), macros),
  "tabs/research_results.tex"
)
labels <- c(
  ddg_join_ads = "Advertising trackers", third_party_cookies = "Third-party cookies",
  canvas_fingerprinting = "Canvas fingerprinting", session_recording = "Session recording",
  key_logging = "Key logging", fb_pixel = "Facebook pixel", google_analytics = "Google Analytics"
)
selected <- subset(bounds, scale == "shares" & error_fraction == 0.01)
rows <- vapply(names(labels), function(outcome) {
  x <- selected[selected$outcome == outcome, ]
  sprintf(
    "%s & %d/%d & %.2f & %.1f \\\\", labels[outcome],
    sum(x$sign_certified), nrow(x),
    100 * median(abs(x$uniform_estimate - x$target)),
    100 * median(x$bound_upper - x$bound_lower)
  )
}, character(1))
writeLines(
  c(
    "\\begin{tabular}{lrrr}", "\\toprule",
    paste0("Scanner outcome & Sign identified & Median realized ",
           "error (pp) & Median bound width (pp) \\\\"),
    "\\midrule", rows, "\\bottomrule", "\\end{tabular}"
  ),
  "tabs/browsing_table.tex"
)
covariate_rows <- vapply(seq_len(nrow(covariate_example)), function(i) {
  x <- covariate_example[i, ]
  sprintf(
    "%s & %.3f & %.3f \\\\", labels[x$outcome],
    x$complete_label_coefficient, x$imposed_prediction_coefficient
  )
}, character(1))
writeLines(
  c(
    "\\begin{tabular}{lrr}", "\\toprule",
    "Outcome & Recorded labels & Imposed errors \\\\",
    "\\midrule", covariate_rows, "\\bottomrule", "\\end{tabular}"
  ),
  "tabs/covariate_table.tex"
)
adult_rows <- vapply(seq_len(nrow(adult)), function(i) {
  x <- adult[i, ]
  sprintf(
    "%s & %s & %.1f & %.1f & %.2f/%.2f & %.2f/%.2f & [%.2f, %.2f] \\\\",
    x$label, number(x$domains), 100 * x$visit_coverage,
    100 * x$domain_agreement,
    100 * x$proxy_domain_share, 100 * x$reference_domain_share,
    100 * x$proxy_visit_share, 100 * x$reference_visit_share,
    100 * x$bound_lower,
    100 * x$bound_upper
  )
}, character(1))
writeLines(
  c(
    "\\begin{tabular}{lrrrrrr}", "\\toprule",
    paste0(
      "Reference & Domains & Visits (\\%) & Agree (\\%) & ",
      "Domain + (\\%) & Visit + (\\%) & Count range (\\%) \\\\"
    ),
    "\\midrule", adult_rows, "\\bottomrule", "\\end{tabular}"
  ),
  "tabs/adult_table.tex"
)
head_rows <- vapply(seq_len(nrow(adult_head)), function(i) {
  x <- adult_head[i, ]
  sprintf(
    "%s & %s & %.1f & [%.2f, %.2f] & %.2f \\\\",
    adult$label[match(x$reference, adult$reference)],
    number(x$domains_retained), 100 * x$visit_share_retained,
    100 * x$bound_lower, 100 * x$bound_upper,
    100 * x$bound_width
  )
}, character(1))
writeLines(
  c(
    "\\begin{tabular}{lrrrr}", "\\toprule",
    "Provider & Domains retained & Visits retained (\\%) & Count range (\\%) & Width (pp) \\\\",
    "\\midrule", head_rows, "\\bottomrule", "\\end{tabular}"
  ),
  "tabs/adult_head_table.tex"
)
method_names <- c(
  count = "Count projection", normal = "Direct normal",
  hoeffding = "Direct Hoeffding"
)
rows <- character()
for (head in c(0, 0.5)) {
  for (audit_budget in c(250, 1000, 2000)) {
    for (method in names(method_names)) {
      keep <- audit$head_fraction == head & audit$budget == audit_budget &
        audit$method == method
      x <- audit[keep, ]
      stopifnot(nrow(x) == 1)
      rows <- c(rows, sprintf(
        "%s & %s & %s & %.1f & %.1f (%.2f) & %.1f & %.1f \\\\",
        if (head == 0) "Random" else "Half certainty", number(audit_budget), method_names[method],
        100 * x$coverage, 100 * x$mean_width, 100 * x$width_mcse,
        100 * x$correct_sign, 100 * x$wrong_sign
      ))
    }
  }
}
writeLines(
  c(
    "\\begin{tabular}{lrlrrrr}", "\\toprule",
    paste0("Design & Budget & Interval & Coverage (\\%) & ",
           "Width (pp; MCSE) & Correct sign (\\%) & Wrong sign (\\%) \\\\"),
    "\\midrule", rows, "\\bottomrule", "\\end{tabular}"
  ),
  "tabs/audit_table.tex"
)
# Common axes compare interval width and coverage across the six audit designs.
pdf("figs/audit_comparison.pdf", width = 6.5, height = 4.3, family = "Helvetica")
par(
  mfrow = c(1, 2), mar = c(4.2, 8, 2.2, 0.6), mgp = c(2.7, 0.7, 0),
  cex = 0.85, las = 1
)
normal <- subset(audit, method == "normal")
y <- seq_len(nrow(normal))
row_labels <- paste(
  ifelse(normal$head_fraction == 0, "Random", "Half certainty"),
  number(normal$budget)
)
plot(100 * normal$mean_width, y,
  xlim = c(0, 70), ylim = c(0.5, 6.5),
  yaxt = "n", ylab = "", xlab = "Mean interval width (pp)", pch = 16,
  main = "Interval width"
)
axis(2, at = y, labels = row_labels, cex.axis = 0.75)
for (method in c("count", "hoeffding")) {
  x <- audit[audit$method == method, ]
  match_rows <- match(paste(normal$budget, normal$head_fraction), paste(x$budget, x$head_fraction))
  points(100 * x$mean_width[match_rows], y, pch = if (method == "count") 1 else 2)
}
legend("topright",
  legend = c("Count", "Normal", "Hoeffding"), pch = c(1, 16, 2),
  bty = "n", cex = 0.8
)
par(mar = c(4.2, 1, 2.2, 0.6))
plot(100 * normal$coverage, y,
  xlim = c(90, 100), ylim = c(0.5, 6.5),
  yaxt = "n", ylab = "", xlab = "Coverage (%)", pch = 16,
  main = "Normal interval coverage"
)
abline(v = 95, lty = 2, col = "gray45")
segments(100 * normal$coverage_lower, y, 100 * normal$coverage_upper, y)
points(100 * normal$coverage, y, pch = 16)
dev.off()
writeLines(
  trimws(capture.output(sessionInfo()), which = "right"),
  "docs/session_info.txt"
)
refinement <- read.csv("data/results/refinement_summary.csv")
rows <- vapply(seq_len(nrow(refinement)), function(i) {
  x <- refinement[i, ]
  sprintf("%d & %.1f & %.1f (%.2f) & %.1f \\\\", x$strata,
          100 * x$known_width, 100 * x$mean_width,
          100 * x$width_mcse, 100 * x$coverage)
}, character(1))
writeLines(c("\\begin{tabular}{rrrr}", "\\toprule",
             "Strata & Exact-count width (pp) & Audit width (pp; MCSE) & Coverage (\\%) \\\\",
             "\\midrule", rows, "\\bottomrule", "\\end{tabular}"),
           "tabs/refinement_table.tex")
