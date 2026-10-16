# Scenario tests for the JR analysis (rjkdc-analysis/), 2026-10-15.
#
# Ten combinations of assumptions for which Jaros and Rauh print an estimate, run through the
# OPA's own functions with those settings. Nothing in the OPA is changed: this script only
# sources rjkdc-analysis/R/*.R and calls the functions there.
#
# Run from the repo root:
#   export RAUH_REPO_DIR=$PWD/rjkdc-analysis/original-materials/author-shared/2026-09-23_wealth_tax-repo
#   Rscript feedback/scenario-tests-2026-10-15/jr-scenarios.R
#
# The income tax Monte Carlo (combination 5) replays the authors' full 37-point sweep at
# 100,000 draws per K, which takes a few minutes. Set JR_SKIP_INCOME_MC=1 to read the
# pipeline's stored result (targets object income_tax_mc) instead.

if (!dir.exists("rjkdc-analysis")) stop("Run this script from the opa-prop40 repo root.")
setwd("rjkdc-analysis")
if (Sys.getenv("RAUH_REPO_DIR") == "") {
  Sys.setenv(RAUH_REPO_DIR = normalizePath(
    "original-materials/author-shared/2026-09-23_wealth_tax-repo", mustWork = TRUE))
}
invisible(lapply(list.files("R", pattern = "\\.R$", full.names = TRUE), source))
stopifnot(rauh_available())

res <- list()
add <- function(id, item, printed, opa, digits) {
  res[[length(res) + 1L]] <<- data.frame(
    id = id, item = item, printed = printed, opa = opa,
    opa_rounded = round(opa, digits),
    gap = opa - printed, gap_pct = 100 * (opa - printed) / abs(printed),
    match_at_print = isTRUE(all.equal(round(opa, digits), printed, tolerance = 1e-9)),
    stringsAsFactors = FALSE)
}

final_df <- extract_nber_final()
rc <- compute_revenue_chain(extract_calculations_preferred(), extract_calculations_expanded())
grid <- compute_site_grid(rc)
named <- site_named()
cell <- function(nm) site_grid_cell(grid, as.list(named[[nm]]))

# ---- 1. NBER: the headline Monte Carlo (PDF p.35, eqs. 16-19) ---------------------------
# WT ~ U[0, 72], f ~ U[0.30, 0.60], C ~ U[3.3, 5.8], (r - g) ~ U[0.015, 0.045], seed 2026.
mc_n <- compute_npv_mc_nber()
s <- mc_n$summary
se_n <- s$sd / sqrt(s$n)
add(1, "mean NPV ($B)", -38.9, s$mean, 1)
add(1, "median NPV ($B)", -35.3, s$median, 1)
add(1, "sd NPV ($B)", 37.6, s$sd, 1)
add(1, "share negative (%)", 85.2, s$pct_negative, 1)
add(1, "P5 NPV ($B)", -107.9, s$p05, 1)
add(1, "P95 NPV ($B)", 15.9, s$p95, 1)
add(1, "exact mean, closed form ($B)", -38.9,
    npv_mc_analytic_mean(0, 72, 3.3, 5.8, 0.015, 0.045, f_mode = "nber", f_min = 0.30, f_max = 0.60), 1)
add(1, "explorer grid cell 'nber', mean ($B)", -38.9, cell("nber")$mean_npv, 1)
add(1, "explorer grid cell 'nber', share negative (%)", 85.2, cell("nber")$pct_negative, 1)
cat(sprintf("[1] NBER MC simulation error of the mean: %.3f ($B)\n", se_n))

# ---- 2. NBER: break-even departure shares (Table 10, PDF p.34, and the text below it) --
# x* = WT (r - g) / C. Central row: WT = 36 (q = 0.5 times the 72 ceiling), C = 4.55.
t10n <- compute_npv_table10(
  scenarios = list(central = list(label = "Central", WT = 36, C = 4.55)))
add(2, "Table 10 central, r-g = 1.5% (%)", 11.9, 100 * t10n$break_even_pct[1], 1)
add(2, "Table 10 central, r-g = 3.0% (%)", 23.7, 100 * t10n$break_even_pct[2], 1)
add(2, "Table 10 central, r-g = 4.5% (%)", 35.6, 100 * t10n$break_even_pct[3], 1)
t10n_text <- compute_npv_table10(
  scenarios = list(c_low  = list(label = "C = 3.3", WT = 36, C = 3.3),
                   c_high = list(label = "C = 5.8", WT = 36, C = 5.8),
                   ceil72 = list(label = "WT = 72", WT = 72, C = 4.55)),
  r_values = 0.03)
add(2, "text: C = 3.3, r-g = 3% (%)", 32.7, 100 * t10n_text$break_even_pct[1], 1)
add(2, "text: C = 5.8, r-g = 3% (%)", 18.6, 100 * t10n_text$break_even_pct[2], 1)
add(2, "text: WT = 72 ceiling, r-g = 3% (%)", 47.5, 100 * t10n_text$break_even_pct[3], 1)
# Sensitivity: the same central cell with q times the ceiling rebuilt from final.csv.
ceil <- compute_nber_ceiling(final_df)
x_rebuilt <- compute_npv_table10(
  scenarios = list(central = list(label = "Central", WT = 0.5 * ceil$ceiling_recomputed, C = 4.55)),
  r_values = 0.03)$break_even_pct
cat(sprintf("[2] central x* at 3%% with WT = 0.5 x %.4f: %.4f%%\n", ceil$ceiling_recomputed, 100 * x_rebuilt))

# ---- 3. NBER: collectible revenue with the litigation weight q (PDF pp.22-23, eqs. 5-8) -
coll <- compute_nber_collectible(final_df, q = 0.50)
add(3, "collectible base, before Zuckerberg ($B)", 71.17, coll$collectible_base, 2)
add(3, "recognized base, eq. 5 ($B)", 59.15, coll$recognized, 2)
add(3, "E[R] = q x recognized, eqs. 6 and 8 ($B)", 29.6, coll$central, 1)
add(3, "E[R] keeping Zuckerberg, eq. 7 ($B)", 35.6, coll$upper, 1)
add(3, "E[R] with gray zone out, p.23 ($B)", 28.4, coll$lower, 1)
add(3, "stayers ($B)", 58.06, coll$stayer_base, 2)
add(3, "ambiguous ($B)", 1.09, coll$ambiguous, 2)

# ---- 4. NBER: seven publicly reported moves (PDF pp.19-22, Table 7, eq. 4) --------------
add(4, "domestic face value at grown vintage ($B)", 100.9, ceil$domestic_total_grown, 1)
add(4, "seven departures, tax avoided ($B)", 28.85, ceil$removed_departed_total, 2)
add(4, "ceiling after seven departures ($B)", 72.06, ceil$ceiling_recomputed, 2)
add(4, "pre-filing departures ($B)", 0.88, coll$removed_prefiling, 2)
share7 <- 1 - ceil$ceiling_recomputed / ceil$domestic_total_grown
add(4, "share of base lost (%)", 28.6, 100 * share7, 1)
add(4, "semi-elasticity eps, eq. 4", 5.73, 100 * share7 / 5, 2)
cat(sprintf("[4] eps from the paper's own rounded inputs, (100.9 - 72.06)/100.9/0.05 = %.4f\n",
            (100.9 - 72.06) / 100.9 / 0.05))

# ---- 5. NBER: income tax Monte Carlo (Sec 5.1, Table 9, PDF pp.26-30) -------------------
pf <- compute_pareto_fit()
sched <- compute_pareto_income_schedule(pf)
add(5, "Pareto alpha", 1.44, pf$alpha, 2)
add(5, "Pareto R^2", 0.999, pf$r_squared, 3)
add(5, "top-212 share S(212, 4729), Sec 5.1 (%)", 39.0, 100 * sched$continuous_top_share, 1)
add(5, "top-212 share S(212, 4729), Sec 5.1 lower bound (%)", 38.8, 100 * sched$continuous_top_share, 1)
cat(sprintf("[5] S(212, 4729) with alpha rounded to 1.44: %.4f%%\n",
            100 * (212 / 4729)^((1.44 - 1) / 1.44)))
if (Sys.getenv("JR_SKIP_INCOME_MC") == "1") {
  imc <- targets::tar_read(income_tax_mc)
} else {
  imc <- compute_income_tax_mc(sched$tax_by_rank)
}
sf <- attr(imc, "scale_factor"); if (is.null(sf)) sf <- income_tax_mc_scale_factor()
row <- function(k) imc[imc$K == k, ]
add(5, "K = 212 mean, upper bound ($B)", 5.76, row(212)$mean_fy25, 2)
add(5, "K = 300 mean ($B)", 4.61, row(300)$mean_fy25, 2)
add(5, "K = 300 P5 ($B)", 4.14, row(300)$p05_fy25, 2)
add(5, "K = 300 P95 ($B)", 5.01, row(300)$p95_fy25, 2)
add(5, "K = 500 mean ($B)", 3.31, row(500)$mean_fy25, 2)
add(5, "K = 500 P5 ($B)", 2.83, row(500)$p05_fy25, 2)
add(5, "K = 500 P95 ($B)", 3.82, row(500)$p95_fy25, 2)
add(5, "K = 1000 mean ($B)", 2.10, row(1000)$mean_fy25, 2)
for (k in c(300, 500, 1000)) cat(sprintf("[5] K = %d simulation error of the mean: %.4f ($B)\n",
                                         k, row(k)$sd * sf / sqrt(1e5)))

# ---- 6. NBER: expanded departures (Table 8, PDF p.25; Appendix D, PDF p.45) -------------
# The OPA has no function for this scenario. The candidate sets below use only final.csv
# bucket totals (OPA data) to see which set the printed ~42% and eps = 8.41 correspond to.
dom <- final_df[final_df$panel == "domestic", ]
tot <- function(rows) sum(dom$face_tax_5pct[rows]) / 1e9
dep <- tot(dom$bucket == "removed_departed"); zk <- tot(dom$bucket == "zuckerberg")
pfd <- tot(dom$bucket == "removed_prefiling"); amb <- tot(dom$bucket == "ambiguous")
gray3 <- tot(dom$bucket == "stayer_base" & dom$name %in% nber_gray_zone_names())
cands <- c("7 + Zuckerberg" = dep + zk,
           "7 + Zuckerberg + pre-filing" = dep + zk + pfd,
           "7 + Zuckerberg + Koum, Hastings, Fang" = dep + zk + gray3,
           "7 + Zuckerberg + 3 reported + pre-filing" = dep + zk + gray3 + pfd,
           "7 + Zuckerberg + 3 reported + ambiguous" = dep + zk + gray3 + amb,
           "all of the above" = dep + zk + gray3 + pfd + amb)
cand_tab <- data.frame(set = names(cands),
                       share_pct = round(100 * cands / ceil$domestic_total_grown, 2),
                       eps = round(100 * cands / ceil$domestic_total_grown / 5, 2))
cat("[6] candidate expanded-departure sets (printed: ~42%, eps 8.41; Appendix D: 41.5%)\n")
print(cand_tab, row.names = FALSE)

# ---- 7. First version: NPV by departure scenario (Table 9, SSRN p.19) -------------------
t9 <- compute_npv_table9()
pr9 <- data.frame(
  scenario = rep(c("six_confirmed", "central", "lit_calibrated"), each = 3),
  r = rep(c(0.015, 0.03, 0.045), 3),
  pv = c(62.3, 31.2, 20.8, 168.1, 84.0, 56.0, 243.0, 121.5, 81.0),
  npv = c(5.2, 36.3, 46.7, -126.1, -42.0, -14.0, -208.0, -86.5, -46.0))
for (i in seq_len(nrow(pr9))) {
  o <- t9[t9$scenario == pr9$scenario[i] & abs(t9$r - pr9$r[i]) < 1e-12, ]
  lab <- sprintf("%s, r-g = %.1f%%", pr9$scenario[i], 100 * pr9$r[i])
  add(7, paste(lab, "PV lost ($B)"), pr9$pv[i], o$pv_lost, 1)
  add(7, paste(lab, "NPV ($B)"), pr9$npv[i], o$npv, 1)
}
add(7, "six_confirmed f (%)", 28.3, 100 * t9$f[t9$scenario == "six_confirmed"][1], 1)
add(7, "central f (%)", 55.4, 100 * t9$f[t9$scenario == "central"][1], 1)
add(7, "lit_calibrated f (%)", 62.8, 100 * t9$f[t9$scenario == "lit_calibrated"][1], 1)

# ---- 8. First version: break-even departure shares (Table 10, SSRN p.20) ----------------
t10 <- compute_npv_table10()
pr10 <- data.frame(
  scenario = rep(c("six_confirmed", "central", "lit_calibrated"), each = 3),
  r = rep(c(0.015, 0.03, 0.045), 3),
  x = c(30.7, 61.4, 92.1, 13.8, 27.7, 41.5, 9.1, 18.1, 27.2))
for (i in seq_len(nrow(pr10))) {
  o <- t10[t10$scenario == pr10$scenario[i] & abs(t10$r - pr10$r[i]) < 1e-12, ]
  add(8, sprintf("%s, r-g = %.1f%% (%%)", pr10$scenario[i], 100 * pr10$r[i]), pr10$x[i],
      100 * o$break_even_pct, 1)
}

# ---- 9. First version: the revenue chain (SSRN pp.10-14) --------------------------------
add(9, "baseline, no departures ($B)", 94.20, rc$baseline_precise, 2)
add(9, "six confirmed departures ($B)", 67.51, rc$confirmed6_ceiling, 2)
add(9, "ten reported departures ($B)", 55.10, rc$expanded10_estimate, 2)
add(9, "literature calibrated, eps = 10.32 ($B)", 45.59, rc$literature_calibrated, 2)
add(9, "eps, six confirmed (eq. 8)", 5.67, (1 - rc$confirmed6_ceiling / rc$baseline_literal) / 0.05, 2)
add(9, "eps, ten reported (eq. 11)", 8.30, (1 - rc$expanded10_estimate / rc$baseline_literal) / 0.05, 2)
add(9, "footnote 6: eps 12, revenue ($B)", 37.7,
    compute_revenue_chain(extract_calculations_preferred(), extract_calculations_expanded(),
                          brulhart_semi_elasticity = 12)$literature_calibrated, 1)
add(9, "footnote 6: eps 13, revenue ($B)", 33.0,
    compute_revenue_chain(extract_calculations_preferred(), extract_calculations_expanded(),
                          brulhart_semi_elasticity = 13)$literature_calibrated, 1)

# ---- 10. First version: the Monte Carlo (SSRN p.20, eqs. 22-24) -------------------------
mc_s <- compute_npv_mc_ssrn()
s2 <- mc_s$summary
add(10, "mean NPV ($B)", -24.7, s2$mean, 1)
add(10, "median NPV ($B)", -19.1, s2$median, 1)
add(10, "sd NPV ($B)", 38.4, s2$sd, 1)
add(10, "share negative (%)", 71, s2$pct_negative, 0)
add(10, "exact mean, closed form ($B)", -24.7,
    npv_mc_analytic_mean(35, 67.51, 3.3, 5.8, 0.015, 0.045, f_mode = "ssrn", baseline_revenue = 94.2), 1)
add(10, "explorer grid cell 'ssrn', mean ($B)", -24.7, cell("ssrn")$mean_npv, 1)
cat(sprintf("[10] SSRN MC simulation error of the mean: %.3f ($B)\n", s2$sd / sqrt(s2$n)))
mc_s671 <- compute_npv_mc_ssrn(wt_max = 67.1)$summary
cat(sprintf("[10] with the printed eq. 22 bound 67.1: mean %.3f, sd %.3f\n", mc_s671$mean, mc_s671$sd))

# ---- All rows -----------------------------------------------------------------------------
out <- do.call(rbind, res)
out$gap <- round(out$gap, 4); out$gap_pct <- round(out$gap_pct, 3); out$opa <- round(out$opa, 4)
options(width = 200)
print(out, row.names = FALSE)
