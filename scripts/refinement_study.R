source("R/audit_design.R")
source("R/browsing_data.R")
source("scripts/verify_data.R")
panel <- read_browsing()
truth <- panel$labels[, "fb_pixel"]
weights <- panel$influences$shares["gender_Female", ]
set.seed(20261005)
predictions <- place_errors(truth, 0.05)
target <- sum(weights * truth)
set.seed(20261006)
replications <- 1000L
results <- list()
summary <- list()
for (bins in c(1, 5, 25)) {
  # Predicted-label strata are refined by ranks of signed influence.
  rank_bin <- ceiling(rank(weights, ties.method = "first") * bins / length(weights))
  strata <- paste(predictions, rank_bin, sep = "_")
  known_lower <- known_upper <- 0
  for (index in split(seq_along(weights), strata)) {
    interval <- confusion_bounds(
      predictions[index], weights[index],
      sum(predictions[index] == 1 & truth[index] == 0),
      sum(predictions[index] == 0 & truth[index] == 1)
    )
    known_lower <- known_lower + interval[1]
    known_upper <- known_upper + interval[2]
  }
  design <- audit_design(predictions, weights, 1000, strata = strata)
  draws <- lapply(seq_len(replications), function(draw) {
    sampled <- draw_audit(design)
    counts <- audit_counts(predictions, sampled, truth[sampled], design$strata)
    limits <- project_audit(counts, weights)
    data.frame(
      bins = bins, draw = draw, lower = limits[1], upper = limits[2],
      width = diff(limits), covered = limits[1] <= target & limits[2] >= target,
      certified = limits[1] > 0 | limits[2] < 0
    )
  })
  draws <- do.call(rbind, draws)
  results[[as.character(bins)]] <- draws
  ci <- binom.test(sum(draws$covered), replications)$conf.int
  summary[[as.character(bins)]] <- data.frame(
    bins = bins,
    strata = length(design$groups), budget = sum(design$allocation),
    known_lower = known_lower, known_upper = known_upper,
    known_width = known_upper - known_lower, mean_width = mean(draws$width),
    width_mcse = sd(draws$width) / sqrt(replications),
    coverage = mean(draws$covered), coverage_lower = ci[1], coverage_upper = ci[2],
    certification = mean(draws$certified), replications = replications
  )
}
write.csv(do.call(rbind, results), "data/results/refinement_draws.csv", row.names = FALSE)
summary <- do.call(rbind, summary)
write.csv(summary, "data/results/refinement_summary.csv", row.names = FALSE)
print(summary)
