assert_close <- function(actual, expected, tolerance = 1e-10) {
  stopifnot(isTRUE(all.equal(
    unname(actual), unname(expected),
    tolerance = tolerance, check.attributes = FALSE
  )))
}

visits <- rbind(
  c(2, 0, 1), c(1, 1, 0), c(0, 2, 1), c(0, 1, 3), c(1, 2, 0)
)
controls <- cbind(1, c(-2, -1, 0, 1, 2))
outcome <- c(1, 3, 2, 0, 4)
labels <- c(1, 0, 1)
predictions <- c(1, 1, 0)
projection <- diag(nrow(visits)) -
  controls %*% solve(crossprod(controls), t(controls))
truth <- drop(visits %*% labels)
surrogate <- drop(visits %*% predictions)
error <- surrogate - truth
denominator <- rowSums(visits)
share_truth <- truth / denominator
share_surrogate <- surrogate / denominator
share_error <- drop((visits / denominator) %*%
                      (predictions - labels))
assert_close(share_surrogate - share_truth, share_error)
stopifnot(any(abs(error - share_error) > 0.01))
residual_truth <- drop(projection %*% truth)
residual_error <- drop(projection %*% error)
truth_coefficient <- sum(residual_truth * outcome) /
  sum(residual_truth^2)
proxy_coefficient <- sum((residual_truth + residual_error) * outcome) /
  sum((residual_truth + residual_error)^2)
residual_outcome <- drop(projection %*% outcome) -
  truth_coefficient * residual_truth
assert_close(sum(residual_truth * residual_outcome), 0)
assert_close(
  proxy_coefficient - truth_coefficient,
  (sum(residual_error * residual_outcome) - truth_coefficient *
     (sum(residual_truth * residual_error) + sum(residual_error^2))) /
    sum((residual_truth + residual_error)^2)
)
stopifnot(truth_coefficient < 0, proxy_coefficient > 0)

# Enumerate an independent domain audit to check both corrected moments.
linear_weights <- drop(crossprod(visits, projection %*% outcome))
quadratic_weights <- crossprod(visits, projection %*% visits)
residual_labels <- labels - predictions
inclusion <- c(0.4, 0.7, 0.6)
pair_inclusion <- outer(inclusion, inclusion)
diag(pair_inclusion) <- inclusion
draws <- as.matrix(expand.grid(rep(list(0:1), length(labels))))
mass <- apply(draws, 1, function(selected) {
  prod(ifelse(selected == 1, inclusion, 1 - inclusion))
})
estimates <- t(apply(draws, 1, function(selected) {
  sampled_residual <- selected * residual_labels
  corrected_residual <- sampled_residual / inclusion
  numerator <- sum(predictions * linear_weights) +
    sum(corrected_residual * linear_weights)
  quadratic_correction <- sum(
    outer(sampled_residual, sampled_residual) *
      quadratic_weights / pair_inclusion
  )
  denominator <- drop(crossprod(
    predictions, quadratic_weights %*% predictions
  )) + 2 * sum(corrected_residual * drop(
    quadratic_weights %*% predictions
  )) + quadratic_correction
  c(numerator = numerator, denominator = denominator)
}))
true_numerator <- sum(labels * linear_weights)
true_denominator <- drop(crossprod(
  labels, quadratic_weights %*% labels
))
assert_close(sum(mass), 1)
assert_close(drop(crossprod(mass, estimates)), c(
  numerator = true_numerator, denominator = true_denominator
))
assert_close(truth_coefficient, true_numerator / true_denominator)
ratio_expectation <- sum(mass * estimates[, 1] / estimates[, 2])
stopifnot(abs(ratio_expectation - truth_coefficient) > 0.01)

# Independent item mistakes still induce dependent user-level errors.
flip_probability <- 0.2
prediction_probability <- ifelse(labels == 1, 1 - flip_probability,
                                 flip_probability)
prediction_mass <- apply(draws, 1, function(q) {
  prod(ifelse(q == 1, prediction_probability,
              1 - prediction_probability))
})
error_draws <- sweep(draws, 2, labels)
score <- apply(draws, 1, function(q) {
  sum(q * linear_weights) - truth_coefficient *
    drop(crossprod(q, quadratic_weights %*% q))
})
bias <- ifelse(labels == 1, -flip_probability, flip_probability)
variance <- rep(flip_probability * (1 - flip_probability), length(labels))
expected_score <- sum(bias * (linear_weights - 2 * truth_coefficient *
                                drop(quadratic_weights %*% labels))) -
  truth_coefficient * (drop(crossprod(
    bias, quadratic_weights %*% bias
  )) + sum(diag(quadratic_weights) * variance))
assert_close(sum(prediction_mass * score), expected_score)
mean_weights <- rep(1 / nrow(visits), nrow(visits))
item_weights <- drop(crossprod(visits, mean_weights))
actual_variance <- sum(variance * item_weights^2)
independent_row_variance <- sum(mean_weights^2 *
                                  drop((visits^2) %*% variance))
drawn_error <- drop(error_draws %*% item_weights)
assert_close(sum(prediction_mass *
                   (drawn_error - sum(prediction_mass * drawn_error))^2),
             actual_variance)
assert_close(actual_variance / independent_row_variance,
             sum(item_weights^2) /
               sum(mean_weights^2 * rowSums(visits^2)))
cat("Aggregated-covariate regression and audit moment checks passed.\n")
