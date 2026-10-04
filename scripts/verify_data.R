manifest <- read.csv("data/manifest.csv", stringsAsFactors = FALSE)
for (i in seq_len(nrow(manifest))) {
  path <- file.path("data", manifest$file[i])
  if (!file.exists(path)) stop("Missing bundled input: ", path)
  stopifnot(digest::digest(file = path, algo = "sha256") == manifest$sha256[i])
}
cat("Bundled input files match their SHA-256 hashes.\n")
