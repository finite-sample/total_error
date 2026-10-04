source("R/audit_bounds.R")
source("R/audit_design.R")
source("R/browsing_data.R")
source("analysis/verify_data.R")
args <- commandArgs(trailingOnly = TRUE)
replications <- if (length(args)) as.integer(args[1]) else 1000L
stopifnot(is.finite(replications), replications > 0)
set.seed(20261005)
panel <- read_browsing()
truth <- panel$labels[, "fb_pixel"]
weights <- panel$influences$shares["gender_Female", ]
predictions <- place_errors(truth, 0.05)
target <- sum(weights * truth)
results <- list()
row <- 0L
for (budget in c(250, 1000, 2000)) {
  for (head_fraction in c(0, 0.5)) {
    design <- audit_design(predictions, weights, budget, head_fraction)
    for (draw in seq_len(replications)) {
      sampled <- draw_audit(design)
      estimate <- direct_audit(
        predictions, weights, sampled, truth[sampled],
        design$strata
      )
      for (method in c("count", "normal", "hoeffding")) {
        limits <- estimate[[method]]
        row <- row + 1L
        results[[row]] <- data.frame(
          budget = budget, head_fraction = head_fraction, draw = draw,
          method = method, target = target, estimate = estimate$estimate,
          lower = limits[1], upper = limits[2],
          covered = limits[1] <= target & limits[2] >= target,
          certified = limits[1] > 0 | limits[2] < 0,
          width = diff(limits)
        )
      }
    }
  }
}
results <- do.call(rbind, results)
rownames(results) <- NULL
dir.create("results", showWarnings = FALSE)
suffix <- if (replications < 1000) "_pilot" else ""
write.csv(results, paste0("results/audit_draws", suffix, ".csv"), row.names = FALSE)
summary <- do.call(rbind, lapply(split(
  results,
  interaction(results$budget, results$head_fraction, results$method, drop = TRUE)
), function(x) {
  coverage <- mean(x$covered)
  data.frame(
    budget = x$budget[1], head_fraction = x$head_fraction[1],
    method = x$method[1], replications = nrow(x), coverage = coverage,
    coverage_mcse = sqrt(coverage * (1 - coverage) / nrow(x)),
    coverage_lower = binom.test(sum(x$covered), nrow(x))$conf.int[1],
    coverage_upper = binom.test(sum(x$covered), nrow(x))$conf.int[2],
    mean_width = mean(x$width), certification = mean(x$certified),
    mean_error = mean(x$estimate - x$target),
    error_mcse = sd(x$estimate - x$target) / sqrt(nrow(x))
  )
}))
rownames(summary) <- NULL
write.csv(summary, paste0("results/audit_summary", suffix, ".csv"), row.names = FALSE)
print(summary)
