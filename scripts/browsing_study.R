source("R/audit_bounds.R")
source("R/browsing_data.R")
source("scripts/verify_data.R")
set.seed(20261004)
panel <- read_browsing()
results <- list()
row <- 0L
for (outcome in colnames(panel$labels)) {
  truth <- panel$labels[, outcome]
  for (rate in c(0.01, 0.05, 0.10)) {
    predictions <- place_errors(truth, rate)
    fp <- sum(predictions == 1 & truth == 0)
    fn <- sum(predictions == 0 & truth == 1)
    for (scale in names(panel$influences)) {
      influence <- panel$influences[[scale]]
      for (coefficient in rownames(influence)[-1]) {
        weights <- influence[coefficient, ]
        target <- sum(weights * truth)
        estimate <- sum(weights * predictions)
        limits <- confusion_bounds(predictions, weights, fp, fn)
        lower_predictions <- place_errors(truth, rate, weights, "lower")
        upper_predictions <- place_errors(truth, rate, weights, "upper")
        lower_estimate <- sum(weights * lower_predictions)
        upper_estimate <- sum(weights * upper_predictions)
        stopifnot(
          limits[1] <= target + 1e-12,
          limits[2] >= target - 1e-12,
          sum(lower_predictions != truth) == fp + fn,
          sum(upper_predictions != truth) == fp + fn
        )
        row <- row + 1L
        results[[row]] <- data.frame(
          outcome = outcome, scale = scale, coefficient = coefficient,
          error_fraction = rate, false_positives = fp, false_negatives = fn,
          target = target, uniform_estimate = estimate,
          bound_lower = limits[1], bound_upper = limits[2],
          adverse_lower = lower_estimate, adverse_upper = upper_estimate,
          sign_certified = limits[1] > 0 | limits[2] < 0,
          reversal_possible = lower_estimate * target < 0 |
            upper_estimate * target < 0
        )
      }
    }
  }
}
results <- do.call(rbind, results)
rownames(results) <- NULL
dir.create("data/results", showWarnings = FALSE)
write.csv(results, "data/results/browsing_bounds.csv", row.names = FALSE)
metadata <- data.frame(
  users = nrow(panel$design), domains = nrow(panel$labels),
  records = length(panel$counts@x), visits = sum(panel$counts),
  coefficients = ncol(panel$design) - 1, outcomes = ncol(panel$labels),
  seed = 20261004
)
write.csv(metadata, "data/results/browsing_metadata.csv", row.names = FALSE)

# Compare item-level variance with a calculation that discards shared domains.
projection <- solve(crossprod(panel$design), t(panel$design))
overlap <- list()
for (scale in c("counts", "shares")) {
  incidence <- panel[[scale]]
  for (coefficient in c("mean", colnames(panel$design)[-1])) {
    weights <- if (coefficient == "mean") {
      rep(1 / nrow(incidence), nrow(incidence))
    } else {
      as.numeric(projection[coefficient, ])
    }
    item_weights <- as.numeric(crossprod(incidence, weights))
    item_variance <- sum(item_weights^2)
    independent_row_variance <- sum(
      weights^2 * Matrix::rowSums(incidence^2)
    )
    overlap[[length(overlap) + 1L]] <- data.frame(
      scale = scale, coefficient = coefficient,
      variance_ratio = item_variance / independent_row_variance,
      largest_item_variance_share = max(item_weights^2) / item_variance
    )
  }
}
write.csv(do.call(rbind, overlap), "data/results/browsing_overlap.csv",
          row.names = FALSE)
print(aggregate(
  cbind(sign_certified, reversal_possible) ~ scale + error_fraction,
  results, mean
))
