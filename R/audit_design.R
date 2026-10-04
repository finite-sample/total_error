source("R/audit_bounds.R")

audit_design <- function(predictions, weights, budget, head_fraction = 0,
                         strata = paste0("prediction_", predictions)) {
  check_predictions(predictions, weights)
  check_integer(budget, "budget", lower = 2, upper = length(predictions))
  if (length(head_fraction) != 1 || !is.finite(head_fraction) ||
        head_fraction < 0 || head_fraction >= 1) {
    stop("head_fraction must lie in [0, 1).")
  }
  head_size <- floor(budget * head_fraction)
  if (length(strata) != length(predictions) || anyNA(strata) ||
        any(strata == "certainty")) {
    stop("Provide one nonmissing stratum per domain; certainty is reserved.")
  }
  strata <- as.character(strata)
  if (head_size > 0) {
    head <- order(abs(weights), decreasing = TRUE)[seq_len(head_size)]
    strata[head] <- "certainty"
  }
  groups <- split(seq_along(predictions), strata)
  sizes <- lengths(groups)
  allocation <- sizes
  tail <- names(groups) != "certainty"
  remainder <- budget - head_size
  target <- remainder * sizes[tail] / sum(sizes[tail])
  minimum <- pmin(2, sizes[tail])
  if (remainder < sum(minimum)) {
    stop("Budget cannot support the certainty head and tail variance estimates.")
  }
  allocation[tail] <- pmax(minimum, floor(target))
  while (sum(allocation) != budget) {
    if (sum(allocation) < budget) {
      eligible <- names(target)[allocation[tail] < sizes[tail]]
      name <- eligible[which.max(target[eligible] - allocation[eligible])]
      allocation[name] <- allocation[name] + 1
    } else {
      eligible <- names(target)[allocation[tail] > minimum]
      name <- eligible[which.max(allocation[eligible] - target[eligible])]
      allocation[name] <- allocation[name] - 1
    }
  }
  stopifnot(sum(allocation) == budget, all(allocation <= sizes))
  list(strata = strata, groups = groups, allocation = allocation)
}

draw_audit <- function(design) {
  unlist(lapply(names(design$groups), function(name) {
    index <- design$groups[[name]]
    index[sample.int(length(index), design$allocation[name])]
  }), use.names = FALSE)
}

# Stratified difference estimator. The Hoeffding interval is finite-sample
# valid under SRSWOR; the Wald interval is a large-sample comparison only.
direct_audit <- function(predictions, weights, sampled, labels, strata,
                         level = 0.95) {
  audit <- audit_counts(predictions, sampled, labels, strata, level)
  residual <- rep(NA_real_, length(predictions))
  residual[sampled] <- weights[sampled] * (labels - predictions[sampled])
  estimate <- sum(weights * predictions)
  variance <- 0
  radius <- 0
  random <- vapply(
    audit$counts, function(x) x["sampled"] < x["population"],
    logical(1)
  )
  alpha <- (1 - level) / max(1, sum(random))
  for (name in names(audit$groups)) {
    index <- audit$groups[[name]]
    observed <- residual[index]
    observed <- observed[!is.na(observed)]
    population <- length(index)
    n <- length(observed)
    if (n == 0) stop("Direct estimation requires a sample in every stratum.")
    estimate <- estimate + population * mean(observed)
    if (n == population) next
    if (n < 2) {
      stop("Variance estimation requires two samples per random stratum.")
    }
    variance <- variance + population^2 * (1 - n / population) *
      var(observed) / n
    possible <- -(2 * predictions[index] - 1) * weights[index]
    span <- diff(range(c(0, possible)))
    radius <- radius + population * span * sqrt(log(2 / alpha) / (2 * n))
  }
  known <- rep(FALSE, length(weights))
  known[sampled] <- TRUE
  contribution <- sum(weights[sampled] * labels)
  support <- contribution + c(
    sum(pmin(weights[!known], 0)),
    sum(pmax(weights[!known], 0))
  )
  bounded <- estimate + c(-1, 1) * radius
  bounded <- c(max(bounded[1], support[1]), min(bounded[2], support[2]))
  list(
    estimate = estimate, se = sqrt(variance),
    normal = estimate + c(-1, 1) * qnorm((1 + level) / 2) * sqrt(variance),
    hoeffding = bounded,
    count = project_audit(audit, weights)
  )
}
