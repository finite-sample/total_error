source("R/audit_bounds.R")
source("R/audit_design.R")
source("R/browsing_data.R")

same <- function(x, y) {
  stopifnot(isTRUE(all.equal(unname(x), unname(y), tolerance = 1e-10)))
}

predictions <- c(0, 0, 0, 0, 1, 1, 1, 1)
truth <- c(1, 0, 0, 1, 0, 1, 1, 0)
weights <- c(-4, -3, -2, -1, 1, 2, 3, 4)
for (head in c(FALSE, TRUE)) {
  budget <- if (head) 6 else 4
  design <- audit_design(predictions, weights, budget, if (head) 1 / 3 else 0)
  alternatives <- lapply(names(design$groups), function(name) {
    combn(design$groups[[name]], design$allocation[name], simplify = FALSE)
  })
  combinations <- expand.grid(lapply(alternatives, seq_along))
  estimates <- numeric(nrow(combinations))
  variance_estimates <- numeric(nrow(combinations))
  covered <- logical(nrow(combinations))
  for (i in seq_len(nrow(combinations))) {
    sampled <- unlist(lapply(seq_along(alternatives), function(j) {
      alternatives[[j]][[combinations[i, j]]]
    }))
    result <- direct_audit(
      predictions, weights, sampled, truth[sampled],
      design$strata
    )
    estimates[i] <- result$estimate
    variance_estimates[i] <- result$se^2
    covered[i] <- result$hoeffding[1] <= sum(weights * truth) &
      result$hoeffding[2] >= sum(weights * truth)
  }
  same(mean(estimates), sum(weights * truth))
  same(mean(variance_estimates), mean((estimates - mean(estimates))^2))
  stopifnot(mean(covered) >= 0.95)
}

# A single eligible numeric index must not be interpreted as a sequence by sample.
set.seed(45)
same(place_errors(c(1, 1, 0), 1), c(0, 0, 1))
for (rate in c(0, 0.25, 0.5, 1)) {
  for (direction in c("random", "lower", "upper")) {
    result <- place_errors(truth, rate, weights, direction)
    for (label in 0:1) {
      same(sum(result[truth == label] != label), floor(rate * sum(truth == label)))
    }
  }
}
cat("Audit allocation, unbiased estimation, variance, and error placement pass.\n")

# Reject designs that cannot estimate variance in every random stratum.
for (budget in 2:3) {
  failure <- tryCatch(
    {
      audit_design(c(0, 0, 1, 1), c(4, 1, 3, 2), budget, 0.5)
      FALSE
    },
    error = function(e) grepl("Budget cannot support", conditionMessage(e))
  )
  stopifnot(failure)
}
# Every feasible small allocation respects budget, census, and minimum sample.
for (size in 2:12) {
  for (positives in 0:size) {
    q <- as.integer(seq_len(size) <= positives)
    for (budget in 2:size) {
      for (fraction in c(0, 0.5, 0.9)) {
        design <- tryCatch(audit_design(q, seq_len(size), budget, fraction),
          error = function(e) NULL
        )
        if (is.null(design)) next
        stopifnot(
          sum(design$allocation) == budget,
          all(design$allocation <= lengths(design$groups)),
          all(design$allocation >= pmin(2, lengths(design$groups)))
        )
      }
    }
  }
}
