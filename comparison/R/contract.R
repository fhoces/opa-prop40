# Reading the two sides' export contracts, and nothing else from them.
#
# comparison/ reads exactly three kinds of file:
#   <side>/export/r/inputs.csv, <side>/export/r/outputs.csv   (each side's contract)
#   comparison/data/document-inputs.csv                        (values transcribed here from
#                                                               the PDFs, each with its page:
#                                                               inputs neither contract carries)
#   comparison/data/hoopes-fig2.csv                             (Hoopes Figure 2, digitized)

comparison_root <- function() {
  root <- Sys.getenv("OPA_PROP40_ROOT", unset = "")
  if (nzchar(root)) return(root)
  dir <- getwd()
  repeat {
    if (dir.exists(file.path(dir, "comparison")) &&
        dir.exists(file.path(dir, "supporting-analysis")) &&
        dir.exists(file.path(dir, "opposing-analysis"))) return(dir)
    parent <- dirname(dir)
    if (parent == dir) stop("cannot find the opa-prop40 root; set OPA_PROP40_ROOT")
    dir <- parent
  }
}

read_csv_plain <- function(path) {
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
                  na.strings = c("NA", ""), encoding = "UTF-8")
}

read_contracts <- function(root = comparison_root()) {
  side <- function(s) list(
    inputs  = read_csv_plain(file.path(root, s, "export", "r", "inputs.csv")),
    outputs = read_csv_plain(file.path(root, s, "export", "r", "outputs.csv")))
  docs <- read_csv_plain(file.path(root, "comparison", "data", "document-inputs.csv"))
  docs$value <- as.numeric(docs$value)          # "Inf" parses to Inf
  list(supporting = side("supporting-analysis"),
       opposing   = side("opposing-analysis"),
       docs       = docs,
       hoopes     = read_csv_plain(file.path(root, "comparison", "data", "hoopes-fig2.csv")))
}

# Look up one value, failing loudly if the contract row is missing or duplicated.
pick <- function(df, id, col = "value", key = NULL) {
  key <- key %||% names(df)[1]
  hit <- df[df[[key]] == id, , drop = FALSE]
  if (nrow(hit) != 1) stop(sprintf("expected exactly one row '%s', found %d", id, nrow(hit)))
  hit[[col]]
}
`%||%` <- function(a, b) if (is.null(a)) b else a
