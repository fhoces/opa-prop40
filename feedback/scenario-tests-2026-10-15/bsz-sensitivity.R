# Sensitivity of the BSZ main revenue estimate (Table 5 row 1, $103.82B) to the assumptions
# the BSZ papers and workbook change, reproduced with the BSZ analysis's own functions.
#
# Run from the repo root:
#   Rscript feedback/scenario-tests-2026-10-15/bsz-sensitivity.R
#
# Needs the August (default) and May workbooks under bsz-analysis/original-materials/ (not in
# the repo). Changes no file. Cases S1-S3 use the explorer's dials, so the script reads their
# values from site/explorer/grid.js and also recomputes them with score_tab5_cell(). Cases
# S4-S7 use the May workbook (BSZ_VINTAGE=may). Cases S8-S10 are valuation dates from the
# workbook's daily 2026 series; the BSZ analysis has no setting for the date, so the script
# only shows what score_tab5_cell() would give if the wealth were replaced by hand.

root <- if (dir.exists("bsz-analysis")) "bsz-analysis" else "."
setwd(root)
Sys.unsetenv("BSZ_VINTAGE")
suppressMessages(invisible(lapply(list.files("R", pattern = "[.]R$", full.names = TRUE), source)))

inputs_for <- function(vintage = c("august", "may")) {
  vintage <- match.arg(vintage)
  if (vintage == "may") {
    Sys.setenv(BSZ_VINTAGE = "may")
    on.exit(Sys.unsetenv("BSZ_VINTAGE"))
  }
  pm <- compute_pareto_missing(extract_pareto_missing())
  tab5_scoring_inputs(pm, extract_tab2(), extract_tab3())
}
aug <- inputs_for("august")
may <- inputs_for("may")
stopifnot(aug$vintage == "august", may$vintage == "may")
rev_of <- function(inp, ...) score_tab5_cell(inp, ...)[["wealth_tax_revenue"]]

main_opa     <- rev_of(aug)   # 103.815
main_printed <- 104           # Table 5 row 1 as printed

# The explorer's grid (August workbook): look up a dial setting by level indices (0-based).
g <- jsonlite::fromJSON(sub(";\\s*$", "", sub("^[^=]*=\\s*", "",
       paste(readLines("site/explorer/grid.js", warn = FALSE)[-1], collapse = "\n"))),
       simplifyVector = FALSE)
sizes <- vapply(g$dials, function(d) length(d$levels), 1L)
keys  <- unlist(g$keys)
explorer_revenue <- function(name) {
  idx0 <- unlist(g$named[[name]])
  i <- 1L + sum(idx0 * rev(cumprod(c(1L, rev(sizes)[-length(sizes)]))))
  v <- unlist(g$snap[[i]]); names(v) <- keys
  v[["wealth_tax_revenue"]]
}

# The workbook's daily 2026 series (shortrunseries rows 15-272, columns A:D): date, number,
# wealth, wealth tax revenue at 10% avoidance (0.045 x wealth).
daily <- readxl::read_excel(xlsx_path_default(), sheet = "shortrunseries",
                            range = "A15:D272", col_names = c("date", "n", "wealth", "revenue"))
daily$date <- as.Date(daily$date)
day <- function(d) daily[daily$date == as.Date(d), ]

cases <- list()
# d_printed is the change from the main estimate as printed in the paper ($104B) for paper
# cases, and from the workbook's own cell (103.815) for workbook cases.
add <- function(id, source, change, printed, opa, how, base = main_printed) {
  cases[[length(cases) + 1L]] <<- data.frame(
    id = id, source = source, change = change, printed = printed,
    d_printed = printed - base, opa = opa, d_opa = opa - main_opa,
    gap = opa - printed, gap_pct = 100 * (opa - printed) / printed, how = how)
}

# S1-S3. August paper, Table 5 rows 2-4 (p.39). Explorer dials P and L.
s1_r <- rev_of(aug, pareto = TRUE)
s2_r <- rev_of(aug, leavers = TRUE)
s3_r <- rev_of(aug, pareto = TRUE, leavers = TRUE)
stopifnot(abs(explorer_revenue("Missing billionaires") - s1_r) < 1e-4,
          abs(explorer_revenue("Leavers") - s2_r) < 1e-4,
          abs(explorer_revenue("Missing + leavers") - s3_r) < 1e-4)
add("S1", "Aug paper T5 r2", "missing billionaires added (Pareto, 20% avoidance for them, phase-in)",
    128, explorer_revenue("Missing billionaires"), "explorer: P on")
add("S2", "Aug paper T5 r3", "aggressive leavers (Page, Thiel, Hankey, Kalanick escape)",
    89, explorer_revenue("Leavers"), "explorer: L on")
add("S3", "Aug paper T5 r4", "both of the above", 115,
    explorer_revenue("Missing + leavers"), "explorer: P and L on")

# S4-S7. May paper, Table 5 rows 1-4 (May PDF p.34): valuation date 4/15/2026.
add("S4", "May paper T5 r1", "valuation date 4/15/2026", 98, rev_of(may), "R: BSZ_VINTAGE=may")
add("S5", "May paper T5 r2", "4/15/2026 + missing billionaires", 121,
    rev_of(may, pareto = TRUE), "R: BSZ_VINTAGE=may, pareto = TRUE")
add("S6", "May paper T5 r3", "4/15/2026 + aggressive leavers", 84,
    rev_of(may, leavers = TRUE), "R: BSZ_VINTAGE=may, leavers = TRUE")
add("S7", "May paper T5 r4", "4/15/2026 + both", 109,
    rev_of(may, pareto = TRUE, leavers = TRUE), "R: BSZ_VINTAGE=may, both TRUE")

# S8-S10. Workbook only: the daily 2026 series at three valuation dates. No setting in the
# BSZ analysis: opa = NA. by_hand = score_tab5_cell() with W0 replaced by that day's wealth.
by_hand <- function(d) { x <- aug; x$W0 <- day(d)$wealth; rev_of(x) }
for (s in list(list("S8", "2026-01-01", "valuation date 1/1/2026 (the residency date)"),
               list("S9", "2026-03-30", "valuation date 3/30/2026 (2026 low)"),
               list("S10", "2026-10-06", "valuation date 10/6/2026 (2026 high to date)"))) {
  add(s[[1]], "workbook shortrunseries", s[[3]], day(s[[2]])$revenue, NA_real_,
      sprintf("not reachable (by hand %.2f)", by_hand(s[[2]])), base = main_opa)
}

out <- do.call(rbind, cases)
num <- c("printed", "d_printed", "opa", "d_opa", "gap", "gap_pct")
out[num] <- lapply(out[num], function(x) round(x, 2))
options(width = 220)
print(out, row.names = FALSE)

cat(sprintf("\nMain estimate: OPA %.3f, printed %d\n", main_opa, main_printed))
cat(sprintf("Daily series check, 7/1/2026: wealth %.3f, revenue %.3f\n",
            day("2026-07-01")$wealth, day("2026-07-01")$revenue))
cat(sprintf("Daily series 4/15/2026: wealth %.3f, revenue %.3f (May paper: wealth 2,182)\n",
            day("2026-04-15")$wealth, day("2026-04-15")$revenue))
cat(sprintf("Latest day %s: wealth %.3f, revenue %.3f\n", max(daily$date),
            daily$wealth[which.max(daily$date)], daily$revenue[which.max(daily$date)]))
cat(sprintf("May inputs: n0 %.0f, W0 %.1f\n", may$n0, may$W0))
