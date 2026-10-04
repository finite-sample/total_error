source("R/audit_bounds.R")

read_browsing <- function(directory = "data") {
  visits <- read.csv(gzfile(file.path(directory, "visits.csv.gz")),
    stringsAsFactors = FALSE
  )
  labels <- read.csv(gzfile(file.path(directory, "labels.csv.gz")),
    stringsAsFactors = FALSE
  )
  features <- read.csv(gzfile(file.path(directory, "features.csv.gz")),
    stringsAsFactors = FALSE, check.names = FALSE
  )
  stopifnot(
    !anyDuplicated(features$user), !anyDuplicated(labels$entity),
    !anyDuplicated(visits[c("user", "entity")]),
    !anyNA(visits[c("user", "entity", "visits")]),
    all(is.finite(visits$visits)), all(visits$visits > 0)
  )
  user <- match(visits$user, features$user)
  domain <- match(visits$entity, labels$entity)
  stopifnot(
    !anyNA(user), !anyNA(domain),
    length(unique(user)) == nrow(features),
    length(unique(domain)) == nrow(labels)
  )
  design <- as.matrix(features[-1])
  label_values <- as.matrix(labels[-1])
  stopifnot(
    all(is.finite(design)), all(is.finite(label_values)),
    all(label_values >= 0), qr(design)$rank == ncol(design)
  )
  counts <- Matrix::sparseMatrix(
    i = user, j = domain, x = visits$visits,
    dims = c(nrow(features), nrow(labels))
  )
  volume <- Matrix::rowSums(counts)
  stopifnot(all(volume > 0), sum(counts) == sum(visits$visits))
  shares <- Matrix::Diagonal(x = 1 / volume) %*% counts
  stopifnot(max(abs(Matrix::rowSums(shares) - 1)) < 1e-12)
  projection <- solve(crossprod(design), t(design))
  influences <- list(
    totals = as.matrix(projection %*% counts),
    shares = as.matrix(projection %*% shares)
  )
  list(
    labels = 1 * (label_values > 0), influences = influences,
    design = design, counts = counts, shares = shares,
    domains = labels$entity, users = features$user
  )
}

place_errors <- function(truth, rate, weights = NULL, direction = "random") {
  check_predictions(truth, rep(0, length(truth)))
  if (length(rate) != 1 || !is.finite(rate) || rate < 0 || rate > 1) {
    stop("rate must lie between zero and one.")
  }
  if (!direction %in% c("random", "lower", "upper")) {
    stop("direction must be random, lower, or upper.")
  }
  if (direction != "random") check_predictions(truth, weights)
  predictions <- truth
  for (label in 0:1) {
    eligible <- which(truth == label)
    number <- floor(rate * length(eligible))
    if (number == 0) next
    if (direction == "random") {
      selected <- eligible[sample.int(length(eligible), number)]
    } else {
      contribution <- (1 - 2 * label) * weights[eligible]
      ranked <- order(contribution, decreasing = direction == "upper")
      selected <- eligible[ranked[seq_len(number)]]
    }
    predictions[selected] <- 1 - label
  }
  predictions
}
