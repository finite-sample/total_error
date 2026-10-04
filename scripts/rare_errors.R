results <- do.call(rbind, lapply(c(100, 1000, 10000, 100000), function(domains) {
  probability <- 1 / domains
  variance <- domains * probability * (1 - probability)
  radius <- qnorm(0.975) * sqrt(variance)
  lower_count <- max(0, ceiling(1 - radius))
  upper_count <- min(domains, floor(1 + radius))
  coverage <- pbinom(upper_count, domains, probability) -
    pbinom(lower_count - 1, domains, probability)
  data.frame(
    domains = domains, error_probability = probability,
    expected_errors = domains * probability, max_variance_share = 1 / domains,
    oracle_normal_coverage = coverage,
    third_moment_ratio = ((1 - probability)^2 + probability^2) / sqrt(variance)
  )
}))
dir.create("data/results", showWarnings = FALSE)
write.csv(results, "data/results/rare_errors.csv", row.names = FALSE)
print(results)
