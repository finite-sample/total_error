source("R/audit_regression.R")
labels <- c(0, 1, 0, 1)
predictions <- c(1, 1, 1, 0)
inclusion <- c(0.3, 0.5, 0.7, 0.6)
linear <- cbind(c(1, -2, 3, 0), c(0.2, 1, -1, 2))
quadratic <- list(
  matrix(c(1, 2, 0, 1, 2, 0, -1, 0, 0, -1, 2, 1, 1, 0, 1, 3), 4),
  crossprod(matrix(seq_len(12) / 10, 3, 4))
)
draws <- as.matrix(expand.grid(rep(list(0:1), length(labels))))
probabilities <- apply(draws, 1, function(selected) {
  prod(ifelse(selected == 1, inclusion, 1 - inclusion))
})
fits <- lapply(seq_len(nrow(draws)), function(i) {
  verified <- ifelse(draws[i, ] == 1, labels, NA_real_)
  audit_moments(predictions, verified, inclusion, linear, quadratic)
})
estimates <- t(vapply(fits, function(fit) fit$moments, numeric(2)))
truth <- vapply(seq_len(ncol(linear)), function(s) {
  sum(labels * linear[, s]) + drop(crossprod(labels, quadratic[[s]] %*% labels))
}, numeric(1))
stopifnot(max(abs(drop(crossprod(probabilities, estimates)) - truth)) < 1e-10)
centered <- sweep(estimates, 2, truth)
covariance <- crossprod(centered * sqrt(probabilities))
expected_covariance <- Reduce(`+`, lapply(seq_along(fits), function(i) {
  probabilities[i] * fits[[i]]$covariance
}))
oracle_covariance <- audit_moment_covariance(
  predictions, labels, inclusion, linear, quadratic
)
stopifnot(
  max(abs(covariance - expected_covariance)) < 1e-9,
  max(abs(covariance - oracle_covariance)) < 1e-9
)
complete <- audit_moments(predictions, labels, rep(1, 4), linear, quadratic)
stopifnot(
  max(abs(complete$moments - truth)) < 1e-10,
  max(abs(complete$covariance)) == 0
)
stopifnot(all(is.na(audit_ratio(c(1, -1), diag(2)))))
cat("Enumerated joint quadratic-moment covariance and audit SE checks passed.\n")
