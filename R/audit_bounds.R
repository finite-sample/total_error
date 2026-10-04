check_integer <- function(value, name, lower = 0, upper = Inf) {
  if (!is.numeric(value) || length(value) != 1L || !is.finite(value) ||
        value != floor(value) || value < lower || value > upper) {
    stop(name, " must be a finite integer in the allowed range.")
  }
}

count_interval <- function(population, sampled, errors, alpha = 0.05) {
  check_integer(population, "population")
  check_integer(sampled, "sampled", upper = population)
  check_integer(errors, "errors", upper = sampled)
  if (!is.numeric(alpha) || length(alpha) != 1L || !is.finite(alpha) ||
        alpha <= 0 || alpha >= 1) {
    stop("alpha must lie strictly between zero and one.")
  }
  if (sampled == 0) {
    return(c(lower = 0, upper = population))
  }
  if (sampled == population) {
    return(c(lower = errors, upper = errors))
  }
  first <- errors
  last <- population - sampled + errors
  left <- first
  right <- last
  while (left < right) {
    middle <- floor((left + right) / 2)
    tail <- phyper(errors - 1, middle, population - middle, sampled,
      lower.tail = FALSE
    )
    if (tail >= alpha / 2) right <- middle else left <- middle + 1
  }
  lower <- left
  left <- first
  right <- last
  while (left < right) {
    middle <- ceiling((left + right) / 2)
    tail <- phyper(errors, middle, population - middle, sampled)
    if (tail >= alpha / 2) left <- middle else right <- middle - 1
  }
  c(lower = lower, upper = left)
}

subset_sum_bounds <- function(weights, lower, upper = lower) {
  if (!is.numeric(weights) || any(!is.finite(weights))) {
    stop("weights must be finite numeric values.")
  }
  check_integer(lower, "lower", upper = length(weights))
  check_integer(upper, "upper", lower = lower, upper = length(weights))
  indices <- seq.int(lower, upper) + 1L
  ordered <- sort(weights)
  smallest <- c(0, cumsum(ordered))
  largest <- c(0, cumsum(rev(ordered)))
  c(lower = min(smallest[indices]), upper = max(largest[indices]))
}

check_predictions <- function(predictions, weights) {
  if (!is.numeric(predictions) || anyNA(predictions) ||
        any(!predictions %in% 0:1)) {
    stop("predictions must be a numeric binary vector.")
  }
  if (!is.numeric(weights) || any(!is.finite(weights)) ||
        length(weights) != length(predictions)) {
    stop("weights must be finite and match predictions.")
  }
}

confusion_bounds <- function(predictions, weights, false_positives,
                             false_negatives) {
  check_predictions(predictions, weights)
  positive <- predictions == 1
  fp <- subset_sum_bounds(weights[positive], false_positives)
  fn <- subset_sum_bounds(-weights[!positive], false_negatives)
  error <- fp + fn
  estimate <- sum(weights * predictions)
  c(
    lower = unname(estimate - error["upper"]),
    upper = unname(estimate - error["lower"])
  )
}

# A simultaneous confidence region for error counts under stratified SRSWOR.
# A census stratum can encode a certainty head fixed before observing labels.
audit_counts <- function(predictions, sampled, labels, strata = predictions,
                         level = 0.95) {
  check_predictions(predictions, rep(0, length(predictions)))
  population <- length(predictions)
  if (!is.numeric(sampled) || anyNA(sampled) ||
        any(sampled != floor(sampled)) || anyDuplicated(sampled) ||
        any(sampled < 1 | sampled > population)) {
    stop("sampled must contain unique valid integer indices.")
  }
  if (!is.numeric(labels) || anyNA(labels) ||
        length(labels) != length(sampled) || any(!labels %in% 0:1)) {
    stop("labels must be binary and match the sampled indices.")
  }
  if (length(strata) != population || anyNA(strata)) {
    stop("strata must match predictions and have no missing values.")
  }
  if (!is.numeric(level) || length(level) != 1L || !is.finite(level) ||
        level <= 0 || level >= 1) {
    stop("level must lie strictly between zero and one.")
  }
  strata <- as.character(strata)
  groups <- split(seq_len(population), strata)
  observed <- rep(NA_real_, population)
  observed[sampled] <- abs(predictions[sampled] - labels)
  uncertain <- vapply(groups, function(index) {
    sum(!is.na(observed[index])) < length(index)
  }, logical(1))
  alpha <- (1 - level) / max(1, sum(uncertain))
  counts <- lapply(groups, function(index) {
    n <- sum(!is.na(observed[index]))
    x <- sum(observed[index], na.rm = TRUE)
    limits <- count_interval(length(index), n, x, alpha)
    c(
      population = length(index), sampled = n, errors = x,
      lower = unname(limits[1]), upper = unname(limits[2])
    )
  })
  list(
    predictions = predictions, observed = observed, groups = groups,
    counts = counts, level = level
  )
}

project_audit <- function(audit, weights) {
  check_predictions(audit$predictions, weights)
  signed <- (2 * audit$predictions - 1) * weights
  known <- !is.na(audit$observed)
  known_error <- sum(signed[known] * audit$observed[known])
  error_bounds <- c(lower = known_error, upper = known_error)
  for (name in names(audit$groups)) {
    index <- audit$groups[[name]]
    unknown <- index[!known[index]]
    counts <- audit$counts[[name]]
    error_bounds <- error_bounds + subset_sum_bounds(
      signed[unknown],
      counts["lower"] - counts["errors"],
      counts["upper"] - counts["errors"]
    )
  }
  estimate <- sum(weights * audit$predictions)
  c(
    lower = unname(estimate - error_bounds["upper"]),
    upper = unname(estimate - error_bounds["lower"])
  )
}
