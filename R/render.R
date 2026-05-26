# Phase 3 - render gt + ggplot objects to files in outputs/.
#
# Each render function returns a file path so it can be registered as a
# `format = "file"` tar_target, which makes the file part of the pipeline's
# tracked state.

outputs_dir <- function() {
  d <- file.path(project_root(), "outputs")
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
  d
}

render_table_html <- function(gt_obj, name) {
  dir <- file.path(outputs_dir(), "tables")
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  path <- file.path(dir, paste0(name, ".html"))
  writeLines(as.character(gt::as_raw_html(gt_obj)), path)
  path
}

render_table_latex <- function(gt_obj, name) {
  dir <- file.path(outputs_dir(), "tables")
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  path <- file.path(dir, paste0(name, ".tex"))
  writeLines(as.character(gt::as_latex(gt_obj)), path)
  path
}

render_figure_png <- function(plot_obj, name, width = 7, height = 5, dpi = 200) {
  dir <- file.path(outputs_dir(), "figures")
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  path <- file.path(dir, paste0(name, ".png"))
  ggplot2::ggsave(path, plot = plot_obj, width = width, height = height,
                  dpi = dpi, units = "in")
  path
}

render_report <- function(qmd_path, format, ...) {
  # Renders a Quarto .qmd to `format` ("html" or "pdf"). Requires the Quarto
  # CLI on PATH (install via `brew install --cask quarto` on macOS or download
  # from https://quarto.org/docs/get-started/). The dependency injections via
  # `...` are ignored — they exist so this function can be a tar_target with
  # explicit upstream artifacts, so the report re-renders when data changes.
  qmd_path <- normalizePath(qmd_path)
  qmd_dir  <- dirname(qmd_path)
  qmd_name <- basename(qmd_path)
  stopifnot(format %in% c("html", "pdf"))
  ext <- format
  out_path <- file.path(qmd_dir, sub("\\.qmd$", paste0(".", ext), qmd_name))
  quarto_bin <- Sys.which("quarto")
  if (!nzchar(quarto_bin)) {
    stop("`quarto` not found on PATH. Install Quarto CLI: ",
         "https://quarto.org/docs/get-started/ ",
         "(or `brew install --cask quarto`).")
  }
  status <- system2(quarto_bin,
                     args = c("render", shQuote(qmd_path),
                              "--to", format,
                              "--output-dir", shQuote(qmd_dir)),
                     stdout = TRUE, stderr = TRUE)
  if (!file.exists(out_path)) {
    stop("Quarto render did not produce ", out_path,
         "; output:\n", paste(status, collapse = "\n"))
  }
  out_path
}

render_figure_pdf <- function(plot_obj, name, width = 7, height = 5) {
  dir <- file.path(outputs_dir(), "figures")
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  path <- file.path(dir, paste0(name, ".pdf"))
  ggplot2::ggsave(path, plot = plot_obj, width = width, height = height,
                  units = "in")
  path
}
