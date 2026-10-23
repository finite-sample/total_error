source("R/audit_bounds.R")
source("scripts/verify_data.R")

domains <- read.csv(gzfile("data/adult_domains.csv.gz"), stringsAsFactors = FALSE)
references <- c(
  bitdefender_porn = "Bitdefender",
  forcepoint_sex = "Forcepoint",
  alphamountain_porn = "alphaMountain"
)
stopifnot(
  nrow(domains) == 64074,
  !anyDuplicated(domains$entity), !anyNA(domains$entity),
  all(is.finite(domains$visits)), all(domains$visits > 0),
  all(domains$visits == floor(domains$visits)),
  sum(domains$visits) == 6236834,
  all(domains$piedomains_porn %in% 0:1)
)
for (name in names(references)) {
  stopifnot(all(is.na(domains[[name]]) | domains[[name]] %in% 0:1))
}

results <- lapply(names(references), function(name) {
  observed <- !is.na(domains[[name]])
  reference_labels <- domains[[name]][observed]
  predictions <- domains$piedomains_porn[observed]
  visits <- domains$visits[observed]
  weights <- visits / sum(visits)
  proxy_only <- sum(predictions == 1 & reference_labels == 0)
  reference_only <- sum(predictions == 0 & reference_labels == 1)
  bounds <- confusion_bounds(
    predictions, weights, proxy_only, reference_only
  )
  proxy_share <- sum(weights * predictions)
  reference_share <- sum(weights * reference_labels)
  stopifnot(
    length(reference_labels) == sum(observed),
    abs(sum(weights) - 1) < 1e-12,
    sum(predictions == reference_labels) + proxy_only + reference_only ==
      length(reference_labels),
    bounds[1] <= reference_share + 1e-12,
    bounds[2] >= reference_share - 1e-12
  )
  data.frame(
    reference = name, label = references[[name]],
    domains = length(reference_labels), visits = sum(visits),
    visit_coverage = sum(visits) / sum(domains$visits),
    reference_positives = sum(reference_labels), proxy_positives = sum(predictions),
    reference_domain_share = mean(reference_labels),
    proxy_domain_share = mean(predictions),
    proxy_only = proxy_only, reference_only = reference_only,
    domain_agreement = mean(predictions == reference_labels),
    disagreement_visit_share = sum(weights[predictions != reference_labels]),
    largest_predicted_negative_visit_share = max(weights[predictions == 0]),
    proxy_visit_share = proxy_share, reference_visit_share = reference_share,
    observed_difference = proxy_share - reference_share,
    bound_lower = bounds[1], bound_upper = bounds[2]
  )
})
results <- do.call(rbind, results)
rownames(results) <- NULL
dir.create("data/results", showWarnings = FALSE)
write.csv(results, "data/results/adult_comparison.csv", row.names = FALSE)
sensitivity <- do.call(rbind, lapply(names(references), function(name) {
  observed <- !is.na(domains[[name]])
  labels <- domains[[name]][observed]
  predictions <- domains$piedomains_porn[observed]
  visits <- domains$visits[observed]
  entities <- domains$entity[observed]
  weights <- visits / sum(visits)
  visit_order <- order(-visits, entities)
  do.call(rbind, lapply(c(0L, 10L, 50L, 250L, 1000L), function(count) {
    known <- rep(FALSE, length(labels))
    known[visit_order[seq_len(count)]] <- TRUE
    bounds <- bounds_with_known_labels(
      predictions, weights, labels, known
    )
    observed_share <- sum(weights * labels)
    stopifnot(bounds[1] <= observed_share + 1e-12,
              bounds[2] >= observed_share - 1e-12)
    data.frame(
      reference = name, domains_retained = count,
      visit_share_retained = sum(weights[known]),
      bound_lower = bounds[1], bound_upper = bounds[2],
      bound_width = diff(bounds)
    )
  }))
}))
write.csv(sensitivity, "data/results/adult_head_sensitivity.csv", row.names = FALSE)
print(results)
