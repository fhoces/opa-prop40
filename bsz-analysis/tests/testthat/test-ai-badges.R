# Tests for the review badges on the BSZ analysis's public objects.

# Review badges (author request 2026-10-15): every public object the author has not fully
# reviewed carries a badge next to its title, yellow for lightly reviewed and red for not
# reviewed, linking to the credit section (#how-ai-was-used). The level is read from
# site/credit/credit-answers.json, so a badge cannot drift from the author's answers.
BADGE_TEXT <- c(yellow = "AI generated, partially reviewed", red = "AI generated, not reviewed yet")
badge_level <- function(v) {
  if (v %in% c("Reviewed", "Understood")) return("none")
  if (v %in% c("Lightly reviewed", "Lightly checked")) return("yellow")
  if (v %in% c("No human review", "Not reviewed")) return("red")
  stop("unknown verification level: ", v)
}
badge_found <- function(path) {
  x <- paste(readLines(path, warn = FALSE), collapse = "\n")
  html <- regmatches(x, gregexpr('ai-badge-(red|yellow)" href="[^"]*#how-ai-was-used">[^<]*<', x))[[1]]
  md <- regmatches(x, gregexpr("img[.]shields[.]io/badge/AI_generated-[a-z_]+-(red|yellow)[)][]][(][^)]*#how-ai-was-used[)]", x))[[1]]
  hit <- c(html, md)
  if (!length(hit)) return(list(level = "none", text = NA_character_))
  expect_length(hit, 1)
  list(level = if (grepl("-red", hit)) "red" else "yellow",
       text = if (length(html)) sub('^.*">([^<]*)<$', "\\1", hit) else
         paste0("AI generated, ", gsub("_", " ", sub("^.*AI_generated-([a-z_]+)-(red|yellow).*$", "\\1", hit))))
}
check_badges <- function(credit_json, files) {
  ans <- jsonlite::fromJSON(credit_json, simplifyVector = FALSE)
  expect_setequal(names(files), unlist(ans$objects))
  for (o in names(files)) {
    want <- badge_level(ans$answers[[o]][["Human verification"]])
    got <- badge_found(files[[o]])
    expect_identical(got$level, want, label = paste(o, files[[o]]))
    if (want != "none") expect_identical(got$text, unname(BADGE_TEXT[want]), label = o)
  }
}

test_that("each object the author has not fully reviewed carries the matching badge", {
  base <- testthat::test_path("..", "..")
  check_badges(file.path(base, "site", "credit", "credit-answers.json"), c(
    "Explorer" = file.path(base, "site", "explorer", "index.html"),
    "Report" = file.path(base, "site", "repro.qmd"),
    "Slides" = file.path(base, "site", "slides", "slides.Rmd"),
    "Repository" = file.path(base, "README.md"),
    "Overview page" = file.path(base, "site", "index.html")))
})
