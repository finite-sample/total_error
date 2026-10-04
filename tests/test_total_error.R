source("sim_total_error.R")

assert_equal <- function(actual, expected, tolerance = 1e-10) {
  comparison <- all.equal(
    unname(actual), unname(expected),
    tolerance = tolerance, check.attributes = FALSE
  )
  stopifnot(isTRUE(comparison))
}

# Enumerating every prediction vector checks moments without simulation error.
truth <- c(0, 1, 0)
visits <- rbind(c(3, 2, 0), c(3, 0, 4), c(0, 2, 4))
fpr <- 0.1
fnr <- 0.07
probability <- ifelse(truth == 1, 1 - fnr, fpr)
predictions <- as.matrix(expand.grid(rep(list(0:1), length(truth))))
mass <- apply(predictions, 1, function(p) {
  prod(ifelse(p == 1, probability, 1 - probability))
})
total <- drop(visits %*% truth)
volume <- rowSums(visits)
predicted <- predictions %*% t(visits)
errors <- sweep(predicted, 2, total)
mean_error <- drop(crossprod(mass, errors))
assert_equal(sum(mass), 1)
assert_equal(mean_error, expected_bias(total, volume, fpr, fnr))
corrected <- sweep(predicted, 2, fpr * volume) / (1 - fpr - fnr)
assert_equal(drop(crossprod(mass, corrected)), total)
assert_equal(
  adjust_total(drop(crossprod(mass, predicted)), volume, fpr, fnr), total
)
centered <- sweep(errors, 2, mean_error)
covariance <- crossprod(centered, centered * mass)
assert_equal(
  covariance,
  visits %*% diag(probability * (1 - probability)) %*% t(visits)
)
stopifnot(covariance[1, 2] > 0)
contrast <- c(1, -1, 0)
domain_weights <- drop(crossprod(contrast, visits))
assert_equal(
  drop(t(contrast) %*% covariance %*% contrast),
  sum(domain_weights^2 * probability * (1 - probability))
)
assert_equal(domain_weights[1], 0)

# Regression errors must retain the same shared-label covariance.
x <- cbind(1, c(-1, 0, 2))
a <- solve(crossprod(x), t(x))
coefficient_errors <- errors %*% t(a)
coefficient_mean <- drop(crossprod(mass, coefficient_errors))
assert_equal(coefficient_mean, drop(a %*% mean_error))
coefficient_centered <- sweep(coefficient_errors, 2, coefficient_mean)
assert_equal(
  crossprod(coefficient_centered, coefficient_centered * mass),
  a %*% covariance %*% t(a)
)

# The general identity also holds when errors across domains are dependent.
joint_mass <- rep(0, nrow(predictions))
joint_mass[c(1, nrow(predictions))] <- c(0.6, 0.4)
entity_error <- sweep(predictions, 2, truth)
entity_mean <- drop(crossprod(joint_mass, entity_error))
entity_centered <- sweep(entity_error, 2, entity_mean)
sigma <- crossprod(entity_centered, entity_centered * joint_mass)
user_mean <- drop(crossprod(joint_mass, errors))
user_centered <- sweep(errors, 2, user_mean)
assert_equal(
  crossprod(user_centered, user_centered * joint_mass),
  visits %*% sigma %*% t(visits)
)

# Enumerate label samples for the frozen-proxy difference estimator.
inclusion <- c(0.4, 1, 0.6)
proxy <- c(0.8, 0.3, 0.9)
w <- drop(crossprod(c(1, -0.5, 0.25), visits))
sample_mass <- apply(predictions, 1, function(selected) {
  prod(ifelse(selected == 1, inclusion, 1 - inclusion))
})
residual_contribution <- w * (truth - proxy)
estimate <- drop(predictions %*% (residual_contribution / inclusion)) +
  sum(w * proxy)
target <- sum(w * truth)
design_variance <- sum((1 - inclusion) / inclusion * residual_contribution^2)
assert_equal(sum(sample_mass * estimate), target)
assert_equal(sum(sample_mass * (estimate - target)^2), design_variance)
variance_contributions <- (1 - inclusion) / inclusion^2 *
  residual_contribution^2
variance_estimates <- drop(predictions %*% variance_contributions)
assert_equal(sum(sample_mass * variance_estimates), design_variance)

# Equal error rates do not remove bias when true prevalence is not one half.
assert_equal(expected_bias(10, 100, 0.1, 0.1), 8)
assert_equal(adjust_total(c(0, 10), c(20, 20), 0, 0), c(0, 10))
singular <- try(adjust_total(5, 10, 0.5, 0.5), silent = TRUE)
stopifnot(inherits(singular, "try-error"))
assert_equal(total_correlation(0.9, 0.1, rep(100, 20)), 0.9)
assert_equal(total_correlation(0.9, 0, 5:1000), 0.9)

simulation <- simulate_exposure()
stopifnot(
  nrow(simulation$totals) == 1000,
  sum(simulation$counts) == nrow(simulation$observations),
  all(is.finite(as.matrix(simulation$observations))),
  all(simulation$counts >= 5 & simulation$counts <= 1000)
)
assert_equal(
  simulation$totals$constant - 0.1 * simulation$counts,
  simulation$totals$unbiased
)
assert_equal(
  simulation$results$observation_correlation[1],
  simulation$results$observation_correlation[2]
)
assert_equal(
  simulation$results$mean_correlation[1],
  simulation$results$mean_correlation[2]
)
assert_equal(simulation$results$total_correlation[3], 0.5383029, 1e-6)
assert_equal(simulation$results$observation_correlation[3], 0.9000409, 1e-6)
cat("All algebra, covariance, and reproduction checks passed.\n")
