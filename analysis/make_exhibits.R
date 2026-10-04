bounds <- read.csv("results/browsing_bounds.csv")
metadata <- read.csv("results/browsing_metadata.csv")
audit <- read.csv("results/audit_summary.csv")
rare <- read.csv("results/rare_errors.csv")
dir.create("generated", showWarnings = FALSE)
number <- function(x, digits = 0) formatC(x, format = "f", digits = digits, big.mark = ",")
focal <- subset(bounds, outcome == "fb_pixel" & scale == "shares" &
                  coefficient == "gender_Female" & error_fraction == 0.01)
small <- subset(audit, budget == 250 & head_fraction == 0 & method == "normal")
large <- subset(audit, budget == 2000 & head_fraction == 0.5 & method == "normal")
macros <- c(
  BenchmarkUsers = number(metadata$users), BenchmarkDomains = number(metadata$domains),
  BenchmarkRecords = number(metadata$records), BenchmarkVisits = number(metadata$visits),
  BenchmarkContrasts = number(metadata$coefficients * metadata$outcomes),
  FocalTruth = number(100 * focal$target, 3),
  FocalLower = number(100 * focal$bound_lower, 2),
  FocalUpper = number(100 * focal$bound_upper, 2),
  FocalAdverseLower = number(100 * focal$adverse_lower, 2),
  FocalAdverseUpper = number(100 * focal$adverse_upper, 2),
  SmallAuditCoverage = number(100 * small$coverage, 1),
  SmallAuditCoverageLower = number(100 * small$coverage_lower, 1),
  SmallAuditCoverageUpper = number(100 * small$coverage_upper, 1),
  LargeAuditCoverage = number(100 * large$coverage, 1),
  LargeAuditWidth = number(100 * large$mean_width, 2),
  RareNormalCoverage = number(100 * rare$oracle_normal_coverage[rare$domains == 10000], 2)
)
writeLines(
  sprintf("\\newcommand{\\%s}{%s}", names(macros), macros),
  "generated/research_results.tex"
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
    "%s & %d/%d & %d/%d & %.1f \\\\", labels[outcome],
    sum(x$sign_certified), nrow(x), sum(x$reversal_possible), nrow(x),
    100 * median(x$bound_upper - x$bound_lower)
  )
}, character(1))
writeLines(
  c(
    "\\begin{tabular}{lrrr}", "\\toprule",
    "Scanner outcome & Sign identified & Reversal possible & Median width (pp) \\\\",
    "\\midrule", rows, "\\bottomrule", "\\end{tabular}"
  ),
  "generated/browsing_table.tex"
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
        "%s & %s & %s & %.1f & %.1f & %.1f \\\\",
        if (head == 0) "Random" else "Half certainty", number(audit_budget), method_names[method],
        100 * x$coverage, 100 * x$mean_width, 100 * x$certification
      ))
    }
  }
}
writeLines(
  c(
    "\\begin{tabular}{lr lrrr}", "\\toprule",
    "Design & Budget & Interval & Coverage (\\%) & Width (pp) & Sign (\\%) \\\\",
    "\\midrule", rows, "\\bottomrule", "\\end{tabular}"
  ),
  "generated/audit_table.tex"
)
# Common axes compare interval width and coverage across the six audit designs.
pdf("generated/audit_comparison.pdf", width = 6.5, height = 4.3, family = "Helvetica")
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
  "results/session_info.txt"
)
refinement <- read.csv("results/refinement_summary.csv")
rows <- vapply(seq_len(nrow(refinement)), function(i) {
  x <- refinement[i, ]
  sprintf("%d & %.1f & %.1f & %.1f \\\\", x$strata,
          100 * x$known_width, 100 * x$mean_width, 100 * x$coverage)
}, character(1))
writeLines(c("\\begin{tabular}{rrrr}", "\\toprule",
             "Strata & Exact-count width (pp) & Audit width (pp) & Coverage (\\%) \\\\",
             "\\midrule", rows, "\\bottomrule", "\\end{tabular}"),
           "generated/refinement_table.tex")
