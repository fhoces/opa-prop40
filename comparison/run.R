# Build the reconciliation: R exports, Python twin exports, and the site-root page.
# Run from anywhere inside the repo:  Rscript comparison/run.R
# Needs the two sides' export contracts to be current (each side's own pipeline
# writes them). Python: set PYTHON, default /opt/anaconda3/bin/python3.

local({
  here <- normalizePath(dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])))
  for (f in list.files(file.path(here, "R"), pattern = "\\.R$", full.names = TRUE)) source(f)
  root <- comparison_root()
  write_exports(build_all(read_contracts(root)), file.path(root, "comparison", "export", "r"))
  py <- Sys.getenv("PYTHON", unset = "/opt/anaconda3/bin/python3")
  status <- system2(py, file.path(root, "comparison", "py", "bridge.py"))
  if (status != 0) stop("python twin failed")
  write_site(root)
  message("wrote comparison/export/{r,py}/, index.html, assets/comparison-data.js")
})
