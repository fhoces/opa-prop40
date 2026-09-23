# Export contract: the only files the comparison layer (comparison/) reads from
# this side. Same schema as opposing-analysis/export/r/:
#   inputs.csv  input_id, version, description, value, unit, label, provenance, source, page
#   outputs.csv output_id, version, value, unit, printed_value, printed_page, abs_diff
#
# Nothing here computes anything new. Every value is read off an existing
# target (site_scoring_inputs, tab5_r, site_tab5_printed) or off the default of
# the function that target runs (compute_tab5(), compute_fig8_laffer()), so the
# export cannot drift from the reproduction. `version` is "ggss" (Galle, Gamage,
# Saez, Shanske expert report, updated 20 Jul 2026), "bsz" (NBER WP 35218, Aug
# 2026) or "both": GGSS's scoring (p.4) is the same 90% x 5% x $2,307B
# computation as BSZ Table 5 row 1, so the benchmark inputs are shared.
# Pages are PDF pages (BSZ's printed folio runs two behind in the main text).

export_contract_inputs <- function(inp) {
  tab5_defaults <- formals(compute_tab5)
  fig8_defaults <- formals(compute_fig8_laffer)
  lv <- inp$leavers
  row <- function(id, version, desc, value, unit, label, source, page) {
    tibble::tibble(input_id = id, version = version, description = desc,
                   value = as.numeric(value), unit = unit, label = label,
                   provenance = "public", source = source, page = page)
  }
  dplyr::bind_rows(
    row("n_billionaires", "both", "CA billionaires on the Forbes real-time list, 1 Jul 2026",
        inp$n0, "count", "data", "Tab5!B6 (BSZ Table 5 row 1); GGSS p.4", 24),
    row("baseline_net_worth", "both", "Aggregate net worth, CA billionaires, 1 Jul 2026 (incl. non-US citizens)",
        inp$W0, "$B", "data", "Tab5!C6; BSZ PDF p.24 (=90%*5%*$2307 billion); GGSS p.4", 24),
    row("tax_rate", "both", "Statutory one-time wealth tax rate",
        eval(tab5_defaults$wealth_tax_rate), "rate", "data", "The Act; GGSS p.1", 24),
    row("avoidance_rate", "both", "Avoidance and evasion allowance (share of the base)",
        eval(tab5_defaults$avoidance_rate), "share", "guesswork",
        "GGSS p.4 (\"a relatively small avoidance rate of 10%\"); BSZ PDF p.24", 24),
    row("mobility_share", "bsz", "Share of the avoidance allowance that is people leaving CA",
        eval(formals(score_tab5_cell)$mobility_share), "share", "guesswork",
        "BSZ PDF p.24 (\"half of the 10% avoidance takes the form of mobility\")", 24),
    row("sell_share", "bsz", "Share of the tax paid by selling assets",
        eval(tab5_defaults$realization_share), "share", "guesswork",
        "BSZ PDF p.24 (\"paid one-third by selling assets\")", 24),
    row("gains_share", "bsz", "Capital-gain share of a sale (1 - basis share)",
        eval(tab5_defaults$ltcg_taxable), "share", "research",
        "BSZ PDF p.24 (basis of 20%, CA billionaire wealth 80% unrealized gains)", 24),
    row("ca_cg_rate", "bsz", "Top CA income tax rate on realized gains",
        eval(tab5_defaults$ca_ltcg_rate), "rate", "data", "Tab5!G6", 39),
    row("ca_inctax_billionaires", "bsz", "CA income tax paid by billionaires, 2019-2025 average",
        inp$C, "$B/yr", "research", "Tab2!C14 (BSZ Table 2); BSZ PDF p.11 (\"average of $3 billion per year\")", 11),
    row("leavers_wealth", "bsz", "Wealth of the 7 named leavers in Table 5 rows 3-4 (Page, Thiel, Hankey, Kalanick, Brin, Zuckerberg, Fang)",
        sum(lv$wealth), "$B", "data", "Tab5!B20:B27 (Forbes 7/1/2026 values)", 39),
    row("leavers_annual_inctax", "bsz", "Annual CA income tax of the 7 named leavers (top 3 from SEC data, rest wealth-proportional)",
        sum(lv$annual_inctax_loss), "$B/yr", "data", "Tab5!F19+F24 (Tab3 row 13 SEC-based); BSZ PDF p.26", 26),
    row("pre2026_leavers_wealth", "bsz", "Wealth of the 4 pre-2026 leavers in the aggressive row (Page, Thiel, Hankey, Kalanick)",
        inp$W_pre, "$B", "guesswork", "Tab5!B20:B23; BSZ PDF p.26 (a legal judgment on residency)", 26),
    row("semi_elasticity_permanent", "bsz", "Mobility semi-elasticity for a PERMANENT annual wealth tax",
        eval(fig8_defaults$semi_elasticity_mobility), "coefficient", "research",
        "Fig8!B8; BSZ PDF p.28 (Brulhart et al. 2022, \"around 10\")", 28),
    row("pareto_pct_wealth_increase", "bsz", "Wealth added by the Pareto extrapolation of missing small billionaires",
        inp$pct_wealth_increase, "share", "research", "Pareto-missing!I23; BSZ PDF p.25", 25)
  )
}

export_contract_outputs <- function(tab5_printed) {
  p <- tab5_printed
  keep <- p$column %in% c("wealth_tax_revenue", "extra_ca_inctax_sales",
                          "annual_ca_inctax_loss", "taxable_wealth")
  p <- p[keep, ]
  value <- p$reproduced / ifelse(p$scale == 1, 1, p$scale)
  bsz <- tibble::tibble(
    output_id     = paste0("tab5_row", p$row, "_", p$column),
    version       = "bsz",
    value         = value,
    unit          = ifelse(p$column == "annual_ca_inctax_loss", "$B/yr", "$B"),
    printed_value = p$printed,
    printed_page  = 39,
    abs_diff      = abs(value - p$printed)
  )
  r1 <- p$reproduced[p$row == 1 & p$column == "wealth_tax_revenue"]
  ggss <- tibble::tibble(
    output_id     = c("ggss_scoring", "ggss_headline"),
    version       = "ggss",
    value         = c(r1, r1),
    unit          = "$B",
    # GGSS p.4: "leads to a scoring of $104 billion that we round to $100
    # billion for simplicity". The rounding is theirs; abs_diff shows its size.
    printed_value = c(104, 100),
    printed_page  = 4,
    abs_diff      = abs(c(r1 - 104, r1 - 100))
  )
  dplyr::bind_rows(bsz, ggss)
}

write_export_csv <- function(df, rel) {
  path <- file.path(project_root(), "export", "r", rel)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(df, path, row.names = FALSE, fileEncoding = "UTF-8")
  path
}
