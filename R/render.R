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

render_figure_pdf <- function(plot_obj, name, width = 7, height = 5) {
  dir <- file.path(outputs_dir(), "figures")
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  path <- file.path(dir, paste0(name, ".pdf"))
  ggplot2::ggsave(path, plot = plot_obj, width = width, height = height,
                  units = "in")
  path
}
