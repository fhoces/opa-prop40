# Sec 5.2-5.4: Table 9 (NPV by departure scenario, p.19) and Table 10
# (break-even departure fraction, p.20). Ported from
# NPV_calculations_5.2.xlsx!Sheet1, cells B32:D50 (Table 9) and B52:D64
# (Table 10). Deterministic: NPV = WT - f*C/(r-g), f = 1 - WT/baseline,
# x* = WT*(r-g)/C (paper eq. 20-21). No RNG.
#
# Scenario inputs (Sheet1!B12:B24), each a literal typed into the workbook:
npv_table9_scenarios <- function() {
  list(
    central       = list(label = "Central Scenario",              WT = 42.0,  C = 4.55),
    six_confirmed = list(label = "Only 6 Confirmed Departures",    WT = 67.51, C = 3.3),
    lit_calibrated = list(label = "Literature Calibrated Departures", WT = 35.0,  C = 5.8)
  )
}

npv_discount_rates <- function() c(0.015, 0.03, 0.045)

# Sheet1!B14/B19/B24: f = 1 - WT/baseline (baseline = Sheet1!B5 = 94.2, the
# literal, same one revenue_chain.R flags in MISMATCHES #6).
compute_npv_table9 <- function(baseline = 94.2,
                                scenarios = npv_table9_scenarios(),
                                r_values = npv_discount_rates()) {
  rows <- lapply(names(scenarios), function(nm) {
    s <- scenarios[[nm]]
    f <- 1 - (s$WT / baseline)
    do.call(rbind, lapply(r_values, function(r) {
      annual_loss <- f * s$C
      pv_lost <- annual_loss / r
      npv <- s$WT - pv_lost
      data.frame(
        scenario = nm, label = s$label, WT = s$WT, C = s$C, f = f,
        r = r, annual_loss = annual_loss, pv_lost = pv_lost, npv = npv,
        stringsAsFactors = FALSE
      )
    }))
  })
  tibble::as_tibble(do.call(rbind, rows))
}

# Sheet1!C56:C64: x* = (WT * r) / C  (paper eq. 21, with the paper's
# (r - g) written here simply as r since Sec 5.2-5.4 treat r as already the
# net real discount rate).
compute_npv_table10 <- function(baseline = 94.2,
                                 scenarios = npv_table9_scenarios(),
                                 r_values = npv_discount_rates()) {
  rows <- lapply(names(scenarios), function(nm) {
    s <- scenarios[[nm]]
    do.call(rbind, lapply(r_values, function(r) {
      x_star <- (s$WT * r) / s$C
      data.frame(
        scenario = nm, label = s$label, WT = s$WT, C = s$C,
        r = r, break_even_pct = x_star,
        stringsAsFactors = FALSE
      )
    }))
  })
  tibble::as_tibble(do.call(rbind, rows))
}
