# R and Python twins: same inputs (the contracts), same numbers.
root <- comparison_root()
rdir <- file.path(root, "comparison", "export", "r")
pdir <- file.path(root, "comparison", "export", "py")

test_that("R exports are current (rebuilt from the contracts, byte-identical)", {
  tmp <- tempfile(); write_exports(build_all(), tmp)
  for (f in list.files(rdir, pattern = "\\.csv$"))
    expect_identical(readLines(file.path(tmp, f)), readLines(file.path(rdir, f)), label = f)
})

test_that("Python exports agree with R to 1e-9 on every shared numeric column", {
  skip_if_not(dir.exists(pdir), "run python comparison/py/bridge.py first")
  for (f in list.files(pdir, pattern = "\\.csv$")) {
    r <- read_csv_plain(file.path(rdir, f)); p <- read_csv_plain(file.path(pdir, f))
    expect_equal(nrow(r), nrow(p), label = paste(f, "rows"))
    key <- intersect(c("horizon_setting", "output", "step_id", "endpoint_id", "anchor_id",
                       "source_id", "key"), intersect(names(r), names(p)))
    kr <- do.call(paste, r[key]); kp <- do.call(paste, p[key])
    expect_setequal(kr, kp)
    p <- p[match(kr, kp), ]
    for (col in intersect(names(r), names(p))) {
      if (col %in% key || !is.numeric(r[[col]])) next
      pc <- suppressWarnings(as.numeric(p[[col]]))
      same_na <- is.na(r[[col]]) == is.na(pc)
      expect_true(all(same_na), label = paste(f, col, "NA pattern"))
      ok <- !is.na(r[[col]]) & is.finite(r[[col]])
      expect_equal(pc[ok], r[[col]][ok], tolerance = 1e-9, label = paste(f, col))
    }
  }
})

test_that("Python exports are current", {
  skip_if_not(nzchar(Sys.which("python3")) || file.exists("/opt/anaconda3/bin/python3"))
  py <- Sys.getenv("PYTHON", unset = "/opt/anaconda3/bin/python3")
  skip_if_not(file.exists(py))
  tmp <- tempfile(); dir.create(tmp)
  code <- sprintf("import sys; sys.path.insert(0, %s); import bridge as b; b.write_exports(b.build_all(b.read_contracts(%s)), %s)",
                  shQuote(file.path(root, "comparison", "py")), shQuote(root), shQuote(tmp))
  expect_equal(system2(py, c("-c", shQuote(code))), 0)
  for (f in list.files(pdir, pattern = "\\.csv$"))
    expect_identical(readLines(file.path(tmp, f)), readLines(file.path(pdir, f)), label = f)
})
