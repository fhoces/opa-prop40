# Run one of the authors' own R scripts from a scratch copy: strip the
# relative plot_dir so it doesn't try to write outside tempdir, give it a
# null graphics device (Rscript has none by default), source() it into a
# fresh environment, and return that environment so tests can read its
# objects directly. Skips (does not fail) when RAUH_REPO_DIR / the script
# is unavailable, per the brief.

run_author_script <- function(script_path, extra_subs = list()) {
  if (!file.exists(script_path)) return(NULL)

  tmp_dir <- tempfile("author_run_")
  dir.create(tmp_dir)
  dir.create(file.path(tmp_dir, "plots"))
  lines <- readLines(script_path, warn = FALSE)  # authors' files have no trailing newline

  # Redirect the script's own plot_dir to the scratch tempdir. Every script
  # in RAUH defines it the same way: plot_dir <- "../NPV_plots".
  lines <- sub('plot_dir <- "\\.\\./NPV_plots"',
               sprintf('plot_dir <- "%s"', file.path(tmp_dir, "plots")),
               lines)
  # monte_carlo_sim.R also writes a results CSV to the cwd.
  lines <- sub('write\\.csv\\(results, "monte_carlo_results_v2\\.csv", row\\.names = FALSE\\)',
               sprintf('write.csv(results, "%s", row.names = FALSE)',
                       file.path(tmp_dir, "monte_carlo_results_v2.csv")),
               lines)
  for (pat in names(extra_subs)) {
    lines <- gsub(pat, extra_subs[[pat]], lines, fixed = TRUE)
  }

  scratch_script <- file.path(tmp_dir, basename(script_path))
  writeLines(lines, scratch_script)

  env <- new.env(parent = globalenv())
  grDevices::pdf(file.path(tmp_dir, "Rplots.pdf"))
  on.exit(grDevices::dev.off(), add = TRUE)
  withr_wd <- getwd()
  on.exit(setwd(withr_wd), add = TRUE)
  setwd(tmp_dir)
  sys.source(scratch_script, envir = env)
  env
}
