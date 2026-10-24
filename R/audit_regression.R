audit_moments <- function(predictions, verified, inclusion, linear, quadratic) {
  items <- length(predictions)
  linear <- as.matrix(linear)
  stopifnot(
    length(verified) == items, length(inclusion) == items,
    nrow(linear) == items, ncol(linear) == length(quadratic),
    all(inclusion > 0 & inclusion <= 1),
    all(predictions %in% 0:1), all(verified[!is.na(verified)] %in% 0:1)
  )
  residual <- ifelse(is.na(verified), 0, verified - predictions)
  moments <- numeric(ncol(linear))
  contributions <- matrix(0, items, ncol(linear))
  pairs <- vector("list", ncol(linear))
  for (s in seq_len(ncol(linear))) {
    weights <- quadratic[[s]]
    stopifnot(
      all(dim(weights) == c(items, items)),
      max(abs(weights - t(weights))) < 1e-10
    )
    derivative <- linear[, s] + 2 * drop(weights %*% predictions)
    singleton <- (residual * derivative + diag(weights) * residual^2) / inclusion
    pairs[[s]] <- 2 * weights * tcrossprod(residual / inclusion)
    diag(pairs[[s]]) <- 0
    moments[s] <- sum(predictions * linear[, s]) +
      drop(crossprod(predictions, weights %*% predictions)) +
      sum(singleton) + sum(pairs[[s]]) / 2
    contributions[, s] <- singleton + rowSums(pairs[[s]])
  }
  covariance <- crossprod(contributions * sqrt(1 - inclusion))
  pair_weights <- tcrossprod(1 - inclusion)
  for (s in seq_len(ncol(linear))) {
    for (t in seq_len(ncol(linear))) {
      covariance[s, t] <- covariance[s, t] -
        sum(pair_weights * pairs[[s]] * pairs[[t]]) / 2
    }
  }
  list(moments = moments, covariance = covariance)
}

audit_moment_covariance <- function(predictions, labels, inclusion, linear, quadratic) {
  residual <- labels - predictions
  contributions <- matrix(0, length(labels), ncol(linear))
  pairs <- vector("list", ncol(linear))
  for (s in seq_len(ncol(linear))) {
    weights <- quadratic[[s]]
    derivative <- linear[, s] + 2 * drop(weights %*% predictions)
    singleton <- residual * derivative + diag(weights) * residual^2
    pairs[[s]] <- 2 * weights * tcrossprod(residual)
    diag(pairs[[s]]) <- 0
    contributions[, s] <- singleton + rowSums(pairs[[s]])
  }
  multiplier <- (1 - inclusion) / inclusion
  covariance <- crossprod(contributions * sqrt(multiplier))
  pair_weights <- tcrossprod(multiplier)
  for (s in seq_len(ncol(linear))) {
    for (t in seq_len(ncol(linear))) {
      covariance[s, t] <- covariance[s, t] +
        sum(pair_weights * pairs[[s]] * pairs[[t]]) / 2
    }
  }
  covariance
}

audit_ratio <- function(moments, covariance) {
  if (!all(is.finite(moments)) || moments[2] <= 0) {
    return(c(estimate = NA_real_, se = NA_real_))
  }
  gradient <- c(1 / moments[2], -moments[1] / moments[2]^2)
  variance <- drop(crossprod(gradient, covariance %*% gradient))
  c(
    estimate = moments[1] / moments[2],
    se = if (is.finite(variance) && variance >= 0) sqrt(variance) else NA_real_
  )
}
