simulate_exposure <- function(seed = 1234, respondents = 1000,
                              rho = 0.9, bias = 0.1) {
  set.seed(seed)
  sigma <- matrix(c(1, rho, rho, 1), nrow = 2)
  records <- vector("list", respondents)
  for (i in seq_len(respondents)) {
    n <- sample(5:1000, 1)
    draws <- MASS::mvrnorm(n, mu = c(0, 0), Sigma = sigma)
    records[[i]] <- data.frame(
      respondent = i,
      truth = draws[, 1],
      unbiased = draws[, 2],
      constant = draws[, 2] + bias,
      original = draws[, 2] + bias * sd(draws[, 1])
    )
  }
  observations <- do.call(rbind, records)
  measures <- c("truth", "unbiased", "constant", "original")
  totals <- aggregate(
    observations[measures],
    list(respondent = observations$respondent), sum
  )
  counts <- tabulate(observations$respondent, nbins = respondents)
  means <- totals
  means[measures] <- means[measures] / counts
  results <- do.call(rbind, lapply(measures[-1], function(measure) {
    data.frame(
      model = measure,
      observation_correlation = cor(
        observations$truth, observations[[measure]]
      ),
      mean_correlation = cor(means$truth, means[[measure]]),
      total_correlation = cor(totals$truth, totals[[measure]]),
      mean_total_error = mean(totals[[measure]] - totals$truth)
    )
  }))
  list(
    observations = observations, totals = totals, means = means,
    counts = counts, results = results
  )
}

total_correlation <- function(rho, bias, counts) {
  variance <- mean((counts - mean(counts))^2)
  rho / sqrt(1 + bias^2 * variance / mean(counts))
}

expected_bias <- function(total, volume, fpr, fnr) {
  fpr * (volume - total) - fnr * total
}

adjust_total <- function(predicted, volume, fpr, fnr) {
  denominator <- 1 - fpr - fnr
  if (any(abs(denominator) < .Machine$double.eps^0.5)) {
    stop("The error rates do not identify the total.")
  }
  (predicted - fpr * volume) / denominator
}

write_results <- function(simulation, directory = "tabs") {
  dir.create(directory, showWarnings = FALSE)
  results <- simulation$results
  original <- results[results$model == "original", ]
  constant <- results[results$model == "constant", ]
  values <- c(
    OriginalObservationCorrelation = original$observation_correlation,
    OriginalMeanCorrelation = original$mean_correlation,
    OriginalTotalCorrelation = original$total_correlation,
    OriginalMeanError = original$mean_total_error,
    ConstantTotalCorrelation = constant$total_correlation,
    TheoreticalTotalCorrelation = total_correlation(0.9, 0.1, 5:1000)
  )
  macros <- sprintf("\\newcommand{\\%s}{%.3f}", names(values), values)
  writeLines(macros, file.path(directory, "results.tex"))
  labels <- c("No added bias", "Constant bias", "Original SD-scaled bias")
  rows <- vapply(seq_len(nrow(results)), function(i) {
    sprintf(
      "%s & %.3f & %.3f & %.3f & %.3f \\\\", labels[i],
      results$observation_correlation[i], results$mean_correlation[i],
      results$total_correlation[i], results$mean_total_error[i]
    )
  }, character(1))
  writeLines(c(
    "\\begin{tabular}{lrrrr}", "\\toprule",
    " & \\multicolumn{3}{c}{Correlation} & Mean total \\\\",
    "\\cmidrule(lr){2-4}",
    "Proxy & Observation & Mean & Total & error \\\\",
    "\\midrule", rows, "\\bottomrule", "\\end{tabular}"
  ), file.path(directory, "simulation_table.tex"))
}
