# Monte Carlo error tolerance: k * sd / sqrt(n) (brief's own suggested
# form). k = 4 is a loose ~4-sigma band on the *estimated mean's* sampling
# error, generous enough to absorb R-version RNG drift while still catching
# a real logic bug (which typically misses by many multiples of this).
mc_tol <- function(sd, n, k = 4) k * sd / sqrt(n)

skip_if_no_rauh <- function() {
  if (!rauh_available()) skip("RAUH_REPO_DIR not available - skipping vs-authors'-script test")
}

# testthat's test_file()/test_dir() run each test file with the working
# directory set to that file's own directory (tests/testthat/), not the
# project root - so a bare relative path like "export/r/outputs.csv" silently
# resolves to the wrong place and looks like a missing file. Walk up from the
# CURRENT working directory (whatever testthat set it to) until we find
# _targets.R, which only exists at the project root.
find_project_root <- function(start = getwd()) {
  d <- normalizePath(start)
  for (i in 1:6) {
    if (file.exists(file.path(d, "_targets.R"))) return(d)
    parent <- dirname(d)
    if (identical(parent, d)) break
    d <- parent
  }
  stop("Could not find project root (opposing-analysis/_targets.R) from ", start)
}
project_path <- function(...) file.path(find_project_root(), ...)
