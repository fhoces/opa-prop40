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

xlsx_path_default <- function() {
  file.path(project_root(), "original-materials", "BSZ_MainTablesFigures.xlsx")
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
