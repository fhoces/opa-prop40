# Scenario tests of the BSZ analysis against numbers printed in the BSZ paper.
#
# Run from the repo root:
#   Rscript feedback/scenario-tests-2026-10-15/bsz-scenarios.R
#
# Reads the authors' workbooks under bsz-analysis/original-materials/ (not in the repo) and
# calls the BSZ analysis's own functions (R/compute_tab5.R, R/compute_pareto.R,
# R/site_exports.R). It does not use the targets store, so a stale store cannot affect it,
# and it changes no file. Combination C4 switches to the May workbook with BSZ_VINTAGE=may
# for the duration of one call.
#
# Output: one line per checked number (id, quantity, printed, OPA value, gap, whether the OPA
# value rounds to the printed digits), then the explorer cells for the Table 5 rows.

root <- if (dir.exists("bsz-analysis")) "bsz-analysis" else "."
setwd(root)
Sys.unsetenv("BSZ_VINTAGE")
suppressMessages(invisible(lapply(list.files("R", pattern = "[.]R$", full.names = TRUE), source)))

# The fixed inputs of the one-time estimate, built from the workbook of one vintage.
inputs_for <- function(vintage = c("august", "may")) {
  vintage <- match.arg(vintage)
  if (vintage == "may") {
    Sys.setenv(BSZ_VINTAGE = "may")
    on.exit(Sys.unsetenv("BSZ_VINTAGE"))
  }
  pm <- compute_pareto_missing(extract_pareto_missing())
  list(pm = pm,
       pareto = compute_pareto_summary(pm),
       inp = tab5_scoring_inputs(pm, extract_tab2(), extract_tab3()))
}

aug <- inputs_for("august")
may <- inputs_for("may")
stopifnot(aug$inp$vintage == "august", may$inp$vintage == "may")

res <- list()
add <- function(id, quantity, printed, opa, digits) {
  res[[length(res) + 1L]] <<- data.frame(
    id = id, quantity = quantity, printed = printed, opa = opa,
    gap = opa - printed, gap_pct = 100 * (opa - printed) / abs(printed),
    rounds_to_printed = round(opa, digits) == printed)
}
cell_out <- function(x) {
  # Table 5 columns plus the OPA's present value over 5 years at 3% (site_pv_factor()).
  c(x, income_tax_loss_pv = x[["annual_ca_inctax_loss"]] * site_pv_factor())
}

# C1. Table 5 row 1, the benchmark (August PDF p.39; text p.22).
c1 <- cell_out(score_tab5_cell(aug$inp))
add("C1", "wealth tax revenue ($B)", 104, c1[["wealth_tax_revenue"]], 0)
add("C1", "extra CA income tax from sales ($B)", 3.7, c1[["extra_ca_inctax_sales"]], 1)
add("C1", "annual CA income tax loss ($B/yr)", -0.15, c1[["annual_ca_inctax_loss"]], 2)

# C2. Table 5 row 2, adding the billionaires Forbes misses (p.39; text p.23: "+$24 billion
# to $128 billion").
c2 <- cell_out(score_tab5_cell(aug$inp, pareto = TRUE))
add("C2", "wealth tax revenue ($B)", 128, c2[["wealth_tax_revenue"]], 0)
add("C2", "increase over benchmark ($B, 'over $24 billion')", 24,
    c2[["wealth_tax_revenue"]] - c1[["wealth_tax_revenue"]], 0)
add("C2", "overall avoidance rate (%)", 12.2, 100 * c2[["avoidance_rate"]], 1)
add("C2", "extra CA income tax from sales ($B)", 4.5, c2[["extra_ca_inctax_sales"]], 1)
add("C2", "annual CA income tax loss ($B/yr)", -0.19, c2[["annual_ca_inctax_loss"]], 2)

# C3. Table 5 row 4, missing billionaires and aggressive leavers combined (p.39; text p.25).
c3 <- cell_out(score_tab5_cell(aug$inp, pareto = TRUE, leavers = TRUE))
add("C3", "wealth tax revenue ($B)", 115, c3[["wealth_tax_revenue"]], 0)
add("C3", "taxable wealth ($B)", 2296, c3[["taxable_wealth"]], 0)
add("C3", "overall avoidance rate (%)", 22.4, 100 * c3[["avoidance_rate"]], 1)
add("C3", "extra CA income tax from sales ($B)", 4.1, c3[["extra_ca_inctax_sales"]], 1)
add("C3", "annual CA income tax loss ($B/yr)", -0.56, c3[["annual_ca_inctax_loss"]], 2)
# Row 4 does not subtract the phase-in deduction that row 2 subtracts (Tab5!F9 vs F7).
c3_with_phasein <- c3[["wealth_tax_revenue"]] - aug$inp$row4_phasein_gap

# C4. Table 5 row 3 of the MAY paper (May PDF p.32), aggressive leavers, May workbook.
c4 <- cell_out(score_tab5_cell(may$inp, leavers = TRUE))
add("C4", "May: taxable wealth ($B)", 1679, c4[["taxable_wealth"]], 0)
add("C4", "May: overall avoidance rate (%)", 23.1, 100 * c4[["avoidance_rate"]], 1)
add("C4", "May: wealth tax revenue ($B)", 84, c4[["wealth_tax_revenue"]], 0)
add("C4", "May: extra CA income tax from sales ($B)", 3.0, c4[["extra_ca_inctax_sales"]], 1)
add("C4", "May: annual CA income tax loss ($B/yr)", -0.53, c4[["annual_ca_inctax_loss"]], 2)

# C5. The Pareto extrapolation (August PDF p.23 and Table 5 notes p.39).
p <- aug$pareto; pm <- aug$pm
extra_n <- p$total_count_proj - p$total_count_emp
missing_in_1_to_1.5 <- pm$projected_density[1] - pm$actual_density[1]
add("C5", "Pareto b above $4.5B", 4.48, p$pareto_b, 2)
add("C5", "Forbes b at the $1B threshold ('almost 9')", 9, pm$pareto_b_emp[1], 0)
add("C5", "billionaires after extrapolation", 617, p$total_count_proj, 0)
add("C5", "extra billionaires", 368, extra_n, 0)
add("C5", "extra wealth ($B)", 615, p$total_wealth_proj - p$total_wealth_emp, 0)
add("C5", "wealth increase (%)", 28, 100 * p$pct_wealth_increase, 0)
add("C5", "count increase (%, Table 5 notes)", 148, 100 * p$pct_count_increase, 0)
add("C5", "missing billionaires in ($1b, $1.5b)", 208, missing_in_1_to_1.5, 0)

# C6. Years for the income tax loss to match the wealth tax (August PDF p.20). The paper's
# arithmetic is 5% / 0.2% = 25 years (all leave) and 5% / (0.25 x 0.2%) = 100 years.
# With the OPA: revenue with no avoidance (the leavers pay, as they leave after 1 January)
# over the yearly loss when a share of billionaires leaves (avoidance = share, mobility = 1).
rev_all  <- score_tab5_cell(aug$inp, avoidance = 0)[["wealth_tax_revenue"]]
loss_all <- -score_tab5_cell(aug$inp, avoidance = 1, mobility_share = 1)[["annual_ca_inctax_loss"]]
loss_q   <- -score_tab5_cell(aug$inp, avoidance = 0.25, mobility_share = 1)[["annual_ca_inctax_loss"]]
add("C6", "years to break even, all leave", 25, rev_all / loss_all, 0)
add("C6", "years to break even, one-fourth leave", 100, rev_all / loss_q, 0)
c6_ratio_opa <- aug$inp$C / aug$inp$W0   # income tax per $ of wealth the OPA applies

# C7. Footnote 29 (August PDF p.20): a permanent loss is "magnified by a factor 33" at 3%.
add("C7", "present-value factor of a permanent loss at 3%", 33, site_pv_factor(0.03, Inf), 0)
c7_pv5 <- site_pv_factor()   # the OPA's own horizon: 5 years at 3%

# C8. Permanent wealth tax, Figure 9 and p.27-28: a 1% tax (on top of the 0.2% income tax)
# "collects 88% of the projected revenue absent mobility responses"; e = 10.
lf <- compute_fig8_laffer()
at <- function(rate, col) lf[[col]][which.min(abs(lf$tax_rate - rate))]
tau0 <- 0.002; W <- 2000
net_new <- at(tau0 + 0.01, "actual_tax_revenue") - tau0 * W
add("C8", "share of mechanical revenue kept by a 1% tax (%)", 88, 100 * net_new / (0.01 * W), 0)
wt_lost <- 1 - at(tau0 + 0.01, "wealth_tax_base") / W
add("C8", "wealth tax revenue lost to mobility at 1% (%, 'less than 10')", 10, 100 * wt_lost, 0)

# C9. Revenue-maximising rates (p.26-28): 1/e = 10% (9.8% on top of the income tax) with
# mobility only; 1/(1+d+e) = 3.8% with de-concentration; a 1% tax lowers the base by about
# 15% through de-concentration.
add("C9", "revenue-maximising total rate, mobility only (%)", 10,
    100 * lf$tax_rate[which.max(lf$actual_tax_revenue)], 1)
add("C9", "revenue-maximising rate, with de-concentration (%)", 3.8,
    100 * lf$tax_rate[which.max(lf$long_run_tax_revenue)], 1)
add("C9", "base lost to de-concentration at 1% (%)", 15, 100 * (1 - 0.99^15), 0)
# The exact optimum of tau * exp(-e tau) * (1 - tau)^d, off the 0.1-point grid:
c9_exact <- optimize(function(t) t * exp(-10 * t) * (1 - t)^15, c(0, 0.2), maximum = TRUE)$maximum

# C10. p.27 and footnote 37: with e = 500, removing the 0.2% income tax multiplies the number
# of billionaires by 2.7.
lf500 <- compute_fig8_laffer(semi_elasticity_mobility = 500)
add("C10", "base at zero tax / current base, e = 500", 2.7,
    lf500$wealth_tax_base[lf500$tax_rate == 0] / 2000, 1)

out <- do.call(rbind, res)
out$printed <- format(out$printed); out$opa <- signif(out$opa, 6)
out$gap <- signif(out$gap, 3); out$gap_pct <- round(out$gap_pct, 2)
options(width = 200)
print(out, row.names = FALSE)

cat("\nExtra values used in the report\n")
cat(sprintf("C3 row 4 revenue if it applied row 2's phase-in deduction: %.3f\n", c3_with_phasein))
cat(sprintf("C3 five-year loss vs extra tax, rows 1-4 (undiscounted): %s\n",
            paste(sprintf("%.2f vs %.2f",
                          -5 * c(c1[["annual_ca_inctax_loss"]], c2[["annual_ca_inctax_loss"]],
                                 score_tab5_cell(aug$inp, leavers = TRUE)[["annual_ca_inctax_loss"]],
                                 c3[["annual_ca_inctax_loss"]]),
                          c(c1[["extra_ca_inctax_sales"]], c2[["extra_ca_inctax_sales"]],
                            score_tab5_cell(aug$inp, leavers = TRUE)[["extra_ca_inctax_sales"]],
                            c3[["extra_ca_inctax_sales"]])), collapse = "; ")))
cat(sprintf("C6 OPA income tax per $ of wealth: C / W0 = %.3f / %.0f = %.4f%%\n",
            aug$inp$C, aug$inp$W0, 100 * c6_ratio_opa))
cat(sprintf("C6 revenue (no avoidance) %.2f, loss all %.3f, loss one-fourth %.3f\n",
            rev_all, loss_all, loss_q))
cat(sprintf("C7 OPA five-year factor at 3%%: %.4f\n", c7_pv5))
cat(sprintf("C9 exact long-run optimum: %.4f%%\n", 100 * c9_exact))
cat(sprintf("May inputs: n0 %.0f, W0 %.1f, C %.4f, W_pre %.2f, leaver_loss %.4f\n",
            may$inp$n0, may$inp$W0, may$inp$C, may$inp$W_pre, may$inp$leaver_loss))

# The explorer (site/explorer/grid.js, August workbook): the cells of the four Table 5 rows.
g <- jsonlite::fromJSON(sub(";\\s*$", "", sub("^[^=]*=\\s*", "",
       paste(readLines("site/explorer/grid.js", warn = FALSE)[-1], collapse = "\n"))),
       simplifyVector = FALSE)
sizes <- vapply(g$dials, function(d) length(d$levels), 1L)
cell_index <- function(idx0) 1L + sum(idx0 * rev(cumprod(c(1L, rev(sizes)[-length(sizes)]))))
keys <- unlist(g$keys)
cat("\nExplorer cells for the Table 5 rows (grid.js)\n")
for (nm in names(g$named)) {
  v <- unlist(g$snap[[cell_index(unlist(g$named[[nm]]))]])
  names(v) <- keys
  cat(sprintf("  %-22s revenue %.2f  extra %.3f  loss/yr %.4f  main estimate %.2f\n", nm,
              v[["wealth_tax_revenue"]], v[["extra_ca_inctax_sales"]],
              v[["annual_ca_inctax_loss"]], v[["main_estimate"]]))
}
