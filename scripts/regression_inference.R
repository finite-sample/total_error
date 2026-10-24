source("R/audit_regression.R")
set.seed(20261025)
arguments <- commandArgs(trailingOnly = TRUE)
replications <- if (length(arguments)) as.integer(arguments[1]) else 1000L
stopifnot(replications > 1)

record_fit <- function(x, y, controls) {
  x <- stats::lm.fit(controls, x)$residuals
  y <- stats::lm.fit(controls, y)$residuals
  denominator <- sum(x^2)
  estimate <- sum(x * y) / denominator
  residual <- y - estimate * x
  c(estimate = estimate, se = sqrt(sum(x^2 * residual^2)) / denominator)
}

build_panel <- function(units, structure) {
  items <- if (structure == "Few items") 30L else 200L
  characteristic <- seq(-1, 1, length.out = units)
  controls <- cbind(1, sin(seq_len(units)))
  item_feature <- seq(-1.5, 1.5, length.out = items)
  labels <- as.numeric(item_feature > 0)
  popularity <- rep(1, items)
  if (structure == "Concentrated") {
    popularity[1] <- 3 * (items - 1)
    item_feature[1] <- 1.5
    labels[1] <- 1
  }
  probabilities <- exp(outer(characteristic, item_feature)) *
    matrix(popularity, units, items, byrow = TRUE)
  probabilities <- probabilities / rowSums(probabilities)
  counts <- t(vapply(seq_len(units), function(i) {
    drop(rmultinom(1, 80, probabilities[i, ]))
  }, numeric(items)))
  visits <- counts / rowSums(counts)
  durations <- visits * matrix(exp(cos(seq_len(items))), units, items, byrow = TRUE)
  durations <- durations / rowSums(durations)
  true_covariate <- drop(visits %*% labels)
  outcome <- 0.8 * true_covariate + 0.1 * characteristic +
    0.02 * cos(seq_len(units))
  list(
    visits = visits, durations = durations, labels = labels,
    controls = controls, characteristic = characteristic, outcome = outcome
  )
}

rows <- list()
position <- 0L
for (units in c(200L, 800L)) {
  for (structure in c("Diffuse", "Concentrated", "Few items")) {
    panel <- build_panel(units, structure)
    labels <- panel$labels
    inclusion <- rep(0.7, length(labels))
    residual_visits <- stats::lm.fit(panel$controls, panel$visits)$residuals
    residual_durations <- stats::lm.fit(panel$controls, panel$durations)$residuals
    residual_x <- stats::lm.fit(panel$controls, panel$characteristic)$residuals
    residual_y <- stats::lm.fit(panel$controls, panel$outcome)$residuals
    zero <- matrix(0, length(labels), length(labels))
    denominator_weights <- crossprod(residual_visits)
    shared_numerator <- crossprod(residual_visits, residual_durations)
    shared_numerator <- (shared_numerator + t(shared_numerator)) / 2
    outcome_weights <- drop(crossprod(panel$visits, residual_x)) / sum(residual_x^2)
    designs <- list(
      Outcome = list(
        linear = matrix(outcome_weights, ncol = 1), quadratic = list(zero)
      ),
      Covariate = list(
        linear = cbind(drop(crossprod(panel$visits, residual_y)), 0),
        quadratic = list(zero, denominator_weights)
      ),
      Both = list(
        linear = matrix(0, length(labels), 2),
        quadratic = list(shared_numerator, denominator_weights)
      )
    )
    targets <- vapply(designs, function(design) {
      moments <- vapply(seq_len(ncol(design$linear)), function(s) {
        sum(labels * design$linear[, s]) +
          drop(crossprod(labels, design$quadratic[[s]] %*% labels))
      }, numeric(1))
      if (length(moments) == 1) moments else moments[1] / moments[2]
    }, numeric(1))
    for (draw in seq_len(replications)) {
      predictions <- (labels + rbinom(length(labels), 1, 0.15)) %% 2
      verified <- ifelse(rbinom(length(labels), 1, inclusion) == 1, labels, NA_real_)
      predicted_visits <- drop(panel$visits %*% predictions)
      predicted_durations <- drop(panel$durations %*% predictions)
      naive <- list(
        Outcome = record_fit(panel$characteristic, predicted_visits, panel$controls),
        Covariate = record_fit(predicted_visits, panel$outcome, panel$controls),
        Both = record_fit(predicted_visits, predicted_durations, panel$controls)
      )
      for (role in names(designs)) {
        design <- designs[[role]]
        corrected <- audit_moments(
          predictions, verified, inclusion, design$linear, design$quadratic
        )
        oracle <- audit_moment_covariance(
          predictions, labels, inclusion, design$linear, design$quadratic
        )
        true_moments <- vapply(seq_len(ncol(design$linear)), function(s) {
          sum(labels * design$linear[, s]) +
            drop(crossprod(labels, design$quadratic[[s]] %*% labels))
        }, numeric(1))
        if (role == "Outcome") {
          audit <- c(
            estimate = corrected$moments[1],
            se = sqrt(max(0, corrected$covariance[1, 1]))
          )
          oracle_fit <- c(estimate = corrected$moments[1], se = sqrt(oracle[1, 1]))
        } else {
          audit <- audit_ratio(corrected$moments, corrected$covariance)
          gradient <- c(
            1 / true_moments[2],
            -true_moments[1] / true_moments[2]^2
          )
          oracle_variance <- drop(crossprod(gradient, oracle %*% gradient))
          oracle_fit <- c(
            estimate = audit["estimate"],
            se = sqrt(max(0, oracle_variance))
          )
          names(oracle_fit) <- c("estimate", "se")
        }
        for (method in c("Record HC", "Item audit", "Oracle audit")) {
          fit <- switch(method,
            "Record HC" = naive[[role]],
            "Item audit" = audit,
            "Oracle audit" = oracle_fit
          )
          available <- all(is.finite(fit))
          position <- position + 1L
          rows[[position]] <- data.frame(
            units = units, items = length(labels), structure = structure,
            role = role, draw = draw, method = method, target = targets[role],
            estimate = fit["estimate"], se = fit["se"], available = available,
            covered = available && abs(fit["estimate"] - targets[role]) <= 1.96 * fit["se"]
          )
        }
      }
    }
  }
}
draws <- do.call(rbind, rows)
rownames(draws) <- NULL
write.csv(draws, "data/results/regression_inference_draws.csv", row.names = FALSE)
groups <- split(draws, interaction(draws$units, draws$structure, draws$role,
  draws$method,
  drop = TRUE
))
summary <- do.call(rbind, lapply(groups, function(x) {
  keep <- x$available
  coverage <- mean(x$covered)
  data.frame(
    x[1, c("units", "items", "structure", "role", "method")],
    replications = nrow(x), availability = mean(keep),
    bias = mean(x$estimate[keep] - x$target[keep]),
    empirical_sd = sd(x$estimate[keep]), mean_se = mean(x$se[keep]),
    coverage = coverage, coverage_mcse = sqrt(coverage * (1 - coverage) / nrow(x))
  )
}))
rownames(summary) <- NULL
write.csv(summary, "data/results/regression_inference_summary.csv", row.names = FALSE)
print(summary[summary$units == 800 & summary$method != "Oracle audit", ], row.names = FALSE)
