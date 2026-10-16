# Sensitivity tests for the JR analysis's main estimate (rjkdc-analysis/), 2026-10-15.
#
# The main estimate is the NBER chapter's mean NPV, -$38.9B (PDF p.35). This script takes every
# net estimate the papers (and the authors' public repo) print under assumptions other than the
# main ones, and reproduces each with the OPA: from the explorer's own grid (site/explorer/grid.js)
# when its dials reach the setting, otherwise with the R functions in rjkdc-analysis/R/.
# Nothing in the OPA is changed.
#
# Run from the repo root:
#   export RAUH_REPO_DIR=$PWD/rjkdc-analysis/original-materials/author-shared/2026-09-23_wealth_tax-repo
#   Rscript feedback/scenario-tests-2026-10-15/jr-sensitivity.R

if (!dir.exists("rjkdc-analysis")) stop("Run this script from the opa-prop40 repo root.")
setwd("rjkdc-analysis")
if (Sys.getenv("RAUH_REPO_DIR") == "") {
  Sys.setenv(RAUH_REPO_DIR = normalizePath(
    "original-materials/author-shared/2026-09-23_wealth_tax-repo", mustWork = TRUE))
}
invisible(lapply(list.files("R", pattern = "\\.R$", full.names = TRUE), source))

# ---- The explorer's grid, read as the page reads it -------------------------------------
js <- readLines("site/explorer/grid.js")
js <- paste(js[grepl("^window.__GRID__", js)], collapse = "")
G <- jsonlite::fromJSON(sub(";\\s*$", "", sub("^window.__GRID__ = ", "", js)), simplifyVector = FALSE)
dial_keys <- vapply(G$dials, `[[`, "", "key")
explorer_cell <- function(levels) {
  # levels: named integer vector of level indices, one per dial. Same mixed-radix order as
  # the page's idx(): the last dial varies fastest.
  lv <- levels[dial_keys]
  sizes <- vapply(G$dials, function(d) length(d$labels), integer(1))
  i <- 0L
  for (k in seq_along(lv)) i <- i * sizes[k] + lv[[k]]
  setNames(unlist(G$snap[[i + 1L]]), c("mean_npv", "pct_negative", "wt_collected", "pv_lost"))
}
explorer_labels <- function(levels) {
  vapply(seq_along(dial_keys), function(k)
    paste0(dial_keys[k], " = ", G$dials[[k]]$labels[[levels[[dial_keys[k]]] + 1L]]), "")
}

# ---- The main estimate (NBER, PDF p.35) ----------------------------------------------------
main_printed <- -38.9
main_levels <- c(wt_lo = 0, wt_hi = 2, q = 0, c = 0, rate = 0, f = 1, g = 0)
main_exact <- explorer_cell(main_levels)[["mean_npv"]]
main_seeded <- compute_npv_mc_nber()$summary$mean
cat(sprintf("Main estimate: printed %.1f; OPA exact (explorer) %.3f; OPA seeded %.3f\n\n",
            main_printed, main_exact, main_seeded))

res <- list()
add <- function(case, source, item, printed, opa, opa_seeded = NA_real_, digits = 1, how) {
  res[[length(res) + 1L]] <<- data.frame(
    case = case, source = source, item = item, printed = printed,
    opa = round(opa, 3), opa_seeded = round(opa_seeded, 3),
    gap = round(opa - printed, 3),
    paper_change = round(printed - main_printed, 1),
    opa_change = round(opa - main_exact, 3),
    match_at_print = isTRUE(all.equal(round(opa, digits), printed, tolerance = 1e-9)),
    how = how, stringsAsFactors = FALSE)
}

# ---- Case 1. First version's Monte Carlo (SSRN p.20, eqs. 22-24) -------------------------
# Changes from the main: WT ~ U[0, 72] -> U[35, 67.51]; f ~ U[0.30, 0.60] -> f = 1 - WT/94.2.
lv1 <- c(wt_lo = 1, wt_hi = 1, q = 0, c = 0, rate = 0, f = 0, g = 0)
cat("Case 1 explorer setting:", paste(explorer_labels(lv1), collapse = "; "), "\n")
s1 <- compute_npv_mc_ssrn()$summary
add(1, "paper (SSRN)", "mean NPV, exact (explorer) and seeded", -24.7,
    explorer_cell(lv1)[["mean_npv"]], s1$mean, how = "explorer dials")
cat(sprintf("Case 1 seeded: mean %.3f (simulation error %.3f); exact %.3f\n\n",
            s1$mean, s1$sd / sqrt(s1$n), explorer_cell(lv1)[["mean_npv"]]))

# ---- Cases 2-4. First version's Table 9 (SSRN p.19) ----------------------------------------
# Point calculation, no draws: NPV = WT - f C / r, f = 1 - WT/94.2, at r = 1.5%, 3%, 4.5%.
# The explorer cannot fix WT at a single value, so these use compute_npv_table9().
t9 <- compute_npv_table9()
pr9 <- list(six_confirmed = c(5.2, 36.3, 46.7),
            central = c(-126.1, -42.0, -14.0),
            lit_calibrated = c(-208.0, -86.5, -46.0))
case_id <- c(six_confirmed = 2, central = 3, lit_calibrated = 4)
for (nm in names(pr9)) {
  rows <- t9[t9$scenario == nm, ]
  for (j in 1:3) {
    add(case_id[[nm]], "paper (SSRN)", sprintf("%s, r-g = %.1f%%", nm, 100 * rows$r[j]),
        pr9[[nm]][j], rows$npv[j], how = "R: compute_npv_table9()")
  }
}

# ---- Case 5. Repo: 2% tax rate, departures sunk (NPV_data/npv_decomposition_2pct.R) -------
# Plot NPV_plots/npv_decomposition_2pct.pdf prints NPV -42.0 at 5% and -67.2 at 2%, with
# f = 0.554, C = 4.55, (r-g) = 3%. The OPA has no wealth tax rate setting. The call below is
# NOT an OPA setting: it hands compute_npv_table9() a hand-computed 2% baseline
# (0.02 x 94.2/0.05 = 37.68) so that its f = 1 - WT/baseline equals the script's 0.554.
base2 <- 0.02 * 94.2 / 0.05
wt2 <- (1 - 0.554) * base2
c5 <- compute_npv_table9(baseline = base2,
                         scenarios = list(two_pct = list(label = "2%", WT = wt2, C = 4.55)),
                         r_values = 0.03)
add(5, "repo", "2% rate, f sunk at 0.554, r-g = 3% (hand-built inputs)", -67.2, c5$npv,
    how = "not reachable; hand-built inputs to compute_npv_table9()")
cat(sprintf("Case 5 hand-built: WT %.3f, f %.4f, PV lost %.3f, NPV %.3f\n\n",
            c5$WT, c5$f, c5$pv_lost, c5$npv))

out <- do.call(rbind, res)
options(width = 220)
print(out[, c("case", "source", "item", "printed", "opa", "opa_seeded", "gap",
              "paper_change", "opa_change", "match_at_print", "how")], row.names = FALSE)
