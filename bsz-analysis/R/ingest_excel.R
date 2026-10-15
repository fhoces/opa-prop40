project_root <- function() {
  root <- Sys.getenv("CAWTBSZ_ROOT", unset = "")
  if (nzchar(root)) return(root)
  dir <- getwd()
  repeat {
    if (file.exists(file.path(dir, "DESCRIPTION")) &&
        dir.exists(file.path(dir, "original-materials"))) {
      return(dir)
    }
    parent <- dirname(dir)
    if (parent == dir) break
    dir <- parent
  }
  getwd()
}

# Where the gitignored source files live. Defaults to <project root>/original-materials;
# CAWTBSZ_MATERIALS overrides only this directory (e.g. a git worktree pointing at the
# main checkout's sources), leaving project_root() and outputs/ where they are.
materials_dir <- function() {
  d <- Sys.getenv("CAWTBSZ_MATERIALS", unset = "")
  if (nzchar(d)) return(d)
  file.path(project_root(), "original-materials")
}

# Which workbook BSZ_VINTAGE selects:
#   "august" (default): original-materials/BSZ_MainTablesFigures.xlsx, the
#       August 2026 paper revision with its data appendix updated 2026-10-08
#       (Index sheet "Last update 2026-10-08"; SHA-256 ea0c1410...).
#   "september": original-materials/september-2026/BSZ_MainTablesFigures.xlsx,
#       the same paper revision with the data appendix of 2026-09-04
#       (SHA-256 c236cc94...), the default until 2026-10-14.
#   "may": original-materials/may-2026/BSZ_MainTablesFigures.xlsx, the May
#       2026 paper revision.
# "august" keeps its name because it is the paper's revision month; the
# appendix date is what tells the two August workbooks apart.
xlsx_path_default <- function() {
  vintage <- Sys.getenv("BSZ_VINTAGE", unset = "august")
  if (identical(vintage, "may")) {
    file.path(materials_dir(), "may-2026", "BSZ_MainTablesFigures.xlsx")
  } else if (identical(vintage, "september")) {
    file.path(materials_dir(), "september-2026", "BSZ_MainTablesFigures.xlsx")
  } else {
    file.path(materials_dir(), "BSZ_MainTablesFigures.xlsx")
  }
}

excel_col_letters <- function(n) {
  out <- character(n)
  for (i in seq_len(n)) {
    x <- i
    s <- ""
    while (x > 0) {
      r <- (x - 1L) %% 26L
      s <- paste0(LETTERS[r + 1L], s)
      x <- (x - 1L) %/% 26L
    }
    out[i] <- s
  }
  out
}

list_sheets <- function(path = xlsx_path_default()) {
  readxl::excel_sheets(path)
}

read_sheet <- function(sheet,
                      path = xlsx_path_default(),
                      range = NULL,
                      col_types = NULL) {
  args <- list(
    path = path,
    sheet = sheet,
    col_names = FALSE,
    .name_repair = "minimal",
    trim_ws = FALSE
  )
  if (!is.null(range)) args$range <- range
  if (!is.null(col_types)) args$col_types <- col_types
  tbl <- do.call(readxl::read_excel, args)
  names(tbl) <- excel_col_letters(ncol(tbl))
  tibble::as_tibble(tbl)
}
