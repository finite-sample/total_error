source("R/audit_bounds.R")

same <- function(actual, expected) {
  stopifnot(isTRUE(all.equal(unname(actual), unname(expected),
              tolerance = 1e-10
            )))
}

binary_vectors <- function(n) {
  as.matrix(expand.grid(rep(list(0:1), n)))
}

# Compare binary search with direct inversion, and check coverage for each K.
for (population in 0:15) {
  for (sampled in 0:population) {
    for (alpha in c(0.05, 0.2)) {
      intervals <- matrix(NA_real_, sampled + 1, 2)
      for (errors in 0:sampled) {
        candidates <- 0:population
        left <- phyper(errors, candidates, population - candidates, sampled)
        right <- phyper(errors - 1, candidates, population - candidates,
          sampled,
          lower.tail = FALSE
        )
        accepted <- candidates[left >= alpha / 2 & right >= alpha / 2]
        limits <- count_interval(population, sampled, errors, alpha)
        same(limits, range(accepted))
        intervals[errors + 1, ] <- limits
      }
      for (total_errors in 0:population) {
        mass <- dhyper(
          0:sampled, total_errors,
          population - total_errors, sampled
        )
        covered <- intervals[, 1] <= total_errors &
          intervals[, 2] >= total_errors
        stopifnot(sum(mass[covered]) >= 1 - alpha - 1e-12)
      }
    }
  }
}

# Sharpness includes signed weights, ties, empty strata, and all/no errors.
configurations <- binary_vectors(4)
weight_sets <- list(c(-3, -1, 2, 5), rep(1, 4), rep(0, 4), c(1, -1, 1, -1))
for (row in seq_len(nrow(configurations))) {
  predictions <- configurations[row, ]
  fp <- drop((1 - configurations) %*% predictions)
  fn <- drop(configurations %*% (1 - predictions))
  counts <- unique(data.frame(fp = fp, fn = fn))
  for (weights in weight_sets) {
    targets <- drop(configurations %*% weights)
    for (case in seq_len(nrow(counts))) {
      compatible <- fp == counts$fp[case] & fn == counts$fn[case]
      limits <- confusion_bounds(
        predictions, weights,
        counts$fp[case], counts$fn[case]
      )
      same(limits, range(targets[compatible]))
    }
  }
}

# Signed prefix sums need optimization over counts, not only interval endpoints.
weights <- c(-5, -2, 1, 6)
for (lower in 0:4) {
  for (upper in lower:4) {
    eligible <- rowSums(configurations) >= lower &
      rowSums(configurations) <= upper
    same(
      subset_sum_bounds(weights, lower, upper),
      range(drop(configurations[eligible, , drop = FALSE] %*% weights))
    )
  }
}

# Exhaust all populations and all stratified samples; audit intervals share a
# single count event and must cover all contrasts jointly, not only marginally.
predictions <- c(0, 0, 0, 1, 1, 1)
truths <- binary_vectors(6)
samples <- as.matrix(expand.grid(1:3, 4:6))
weight_matrix <- cbind(c(-3, 2, 0, -1, 5, 1), rep(1, 6), c(1, -1, 1, -1, 1, -1))
for (row in seq_len(nrow(truths))) {
  truth <- truths[row, ]
  targets <- drop(crossprod(weight_matrix, truth))
  for (level in c(0.5, 0.95)) {
    simultaneous <- logical(nrow(samples))
    for (draw in seq_len(nrow(samples))) {
      sampled <- samples[draw, ]
      audit <- audit_counts(predictions, sampled, truth[sampled], level = level)
      limits <- apply(weight_matrix, 2, function(w) project_audit(audit, w))
      simultaneous[draw] <- all(limits[1, ] <= targets &
                                  limits[2, ] >= targets)
      # Enumerate the label vectors consistent with all audit evidence.
      compatible <- apply(truths[, sampled, drop = FALSE], 1, function(y) {
        all(y == truth[sampled])
      })
      for (name in names(audit$groups)) {
        index <- audit$groups[[name]]
        mistakes <- rowSums(abs(sweep(
          truths[, index, drop = FALSE],
          2, predictions[index]
        )))
        bounds <- audit$counts[[name]]
        compatible <- compatible & mistakes >= bounds["lower"] &
          mistakes <= bounds["upper"]
      }
      admissible_targets <- truths[compatible, , drop = FALSE] %*% weight_matrix
      for (column in seq_len(ncol(weight_matrix))) {
        same(limits[, column], range(admissible_targets[, column]))
      }
    }
    stopifnot(mean(simultaneous) >= level - 1e-12)
  }
  census <- audit_counts(predictions, seq_along(truth), truth)
  same(project_audit(census, weight_matrix[, 1]), rep(targets[1], 2))
}

# No audit remains informative only through the binary support restriction.
empty <- audit_counts(predictions, integer(), numeric())
same(
  project_audit(empty, weight_matrix[, 1]),
  c(sum(pmin(weight_matrix[, 1], 0)), sum(pmax(weight_matrix[, 1], 0)))
)
for (expression in list(
  quote(count_interval(10, 11, 0)),
  quote(count_interval(10, 5, 6)),
  quote(count_interval(10, 5, 0, alpha = 0)),
  quote(confusion_bounds(c(0, 1), c(1, 2), 2, 0)),
  quote(audit_counts(c(0, 1), c(1, 1), c(0, 0))),
  quote(audit_counts(c(0, 1), 1, NA_real_))
)) {
  stopifnot(inherits(try(eval(expression), silent = TRUE), "try-error"))
}
cat("Sharpness, exact count coverage, joint audit coverage, and edge cases pass.\n")
