# gt table builders.
#
# Each builder takes already-validated upstream targets (Excel extractors or
# `*_r` re-derivations) and returns a `gt` object. Render to HTML or LaTeX
# downstream via `gt::as_raw_html()` / `gt::as_latex()`.

.long_run_compare <- function(row_1982, row_2025, n_years = 43) {
  # Given two one-row tibbles with matching numeric columns (and a `year`
  # label column), build the trailing two summary rows that Tab1 / TabA1
  # Panel B share: a "Ratio 2025 to 1982" row (element-wise division) and an
  # "Annualized growth" row (ratio^(1/n) - 1).
  num_cols <- setdiff(names(row_1982), "year")
  ratio <- vapply(num_cols, \(c) row_2025[[c]] / row_1982[[c]], numeric(1))
  ann   <- ratio^(1 / n_years) - 1
  list(
    ratio      = tibble::as_tibble(c(list(year = "Ratio 2025 to 1982"), as.list(ratio))),
    annualized = tibble::as_tibble(c(list(year = "Annualized growth"),  as.list(ann)))
  )
}

build_tab2 <- function(data_sec_agg_r, billionaires_ca_inctax_r, data_sec_top4,
                       vintage = bsz_vintage()) {
  # Table 2: California Income Tax Paid by California Billionaires.
  # Two side-by-side sub-panels: all CA billionaires (cols B-D) and the top 4
  # on company wealth (cols F-H), 2019-2025 + a 2019-2025 average row.

  yrs <- 2019:2025
  m1 <- billionaires_ca_inctax_r$method1
  m1_idx <- match(yrs, m1$year)

  agg_y <- data_sec_agg_r[match(yrs, data_sec_agg_r$year), ]
  total_excl <- data_sec_top4[data_sec_top4$forbes_id == "Total (excluding Ellison)" &
                                data_sec_top4$year %in% yrs, ]
  total_excl <- total_excl[order(total_excl$year), ]

  panel <- tibble::tibble(
    year                       = as.character(yrs),
    wealth_b                   = agg_y$forbes_worth,
    ca_inctax_b                = m1$ca_inctax_ca_billionaires_b[m1_idx],
    ca_inctax_per_wealth       = NA_real_,
    top4_company_wealth_b      = total_excl$public_worth   / 1000,
    top4_ca_inctax_b           = total_excl$ca_income_tax  / 1000,
    top4_ca_inctax_per_wealth  = NA_real_
  )
  panel$ca_inctax_per_wealth      <- panel$ca_inctax_b      / panel$wealth_b
  panel$top4_ca_inctax_per_wealth <- panel$top4_ca_inctax_b / panel$top4_company_wealth_b

  # Average row — Excel quirk: D14 = AVERAGE(D7:D12) (6 yrs, 2019-2024 only,
  # a direct average of the RATIO column) while B/C/F14 = AVERAGE(*7:*13)
  # (7 yrs). May's top4-ratio cell (H14) = G14/F14, i.e. mean-of-PARTS over
  # all 7 years (matches the code below unconditionally). August's
  # equivalent cell (J14) changed formula entirely to
  # `=AVERAGE(J7:J12)` - a direct 6-year average of the ratio column itself,
  # picking up the SAME 6-year truncation quirk as D14/E14 - a genuine,
  # vintage-specific formula difference, not a row-shift artifact (verified
  # against both workbooks' formulas directly).
  top4_ratio_avg <- if (identical(vintage, "may")) {
    mean(panel$top4_ca_inctax_b) / mean(panel$top4_company_wealth_b)
  } else {
    mean(panel$top4_ca_inctax_per_wealth[1:6])   # 2019-2024
  }
  avg_row <- tibble::tibble(
    year                      = "2019-2025 average",
    wealth_b                  = mean(panel$wealth_b),
    ca_inctax_b               = mean(panel$ca_inctax_b),
    ca_inctax_per_wealth      = mean(panel$ca_inctax_per_wealth[1:6]),  # 2019-2024
    top4_company_wealth_b     = mean(panel$top4_company_wealth_b),
    top4_ca_inctax_b          = mean(panel$top4_ca_inctax_b),
    top4_ca_inctax_per_wealth = top4_ratio_avg
  )
  full <- dplyr::bind_rows(panel, avg_row)

  tab <- gt::gt(full) |>
    gt::tab_header(title = "Table 2. California Income Tax Paid by California Billionaires") |>
    gt::tab_spanner(label = "All California Billionaires",
                    columns = c(wealth_b, ca_inctax_b, ca_inctax_per_wealth)) |>
    gt::tab_spanner(label = "Top 4 (Page, Brin, Zuckerberg, Huang) on Company Wealth",
                    columns = c(top4_company_wealth_b, top4_ca_inctax_b,
                                top4_ca_inctax_per_wealth)) |>
    gt::cols_label(
      year                      = "Year",
      wealth_b                  = "Wealth ($B)",
      ca_inctax_b               = "Est. CA inc. tax ($B)",
      ca_inctax_per_wealth      = "Tax / wealth",
      top4_company_wealth_b     = "Company wealth ($B)",
      top4_ca_inctax_b          = "Est. CA inc. tax ($B)",
      top4_ca_inctax_per_wealth = "Tax / wealth"
    ) |>
    gt::fmt_number(columns = c(wealth_b, top4_company_wealth_b),
                   decimals = 0, use_seps = TRUE) |>
    gt::fmt_number(columns = c(ca_inctax_b, top4_ca_inctax_b),
                   decimals = 2) |>
    gt::fmt_percent(columns = c(ca_inctax_per_wealth, top4_ca_inctax_per_wealth),
                    decimals = 3) |>
    gt::tab_source_note(source_note = gt::md(paste(
      "**Notes:** All amounts in nominal $B. CA income tax for all billionaires comes",
      "from the Method I FTB-extrapolation calculation; top 4 figures come from SEC",
      "filings. Source: `billionaires_ca_inctax_r` + `data_sec_top4`."
    )))

  attr(tab, "panel") <- full
  tab
}

build_tab_a1 <- function(shortrunseries, longrunseries, vintage = bsz_vintage()) {
  # Appendix Table A1: Wealth Growth of US Billionaires (mirrors Tab1 but
  # for the US). Panel A: recent nominal growth 2022-2025(+2026 in August).
  # Panel B: 1982 vs 2025(2026 in August) long-term real growth of the top
  # .0002% (May) / .001% (August) US families.
  #
  # Mirrors the same RC4/RC5/RC6 August changes as build_tab1() (see its
  # comment): a new AGI column (August's Panel A gains F/G columns that did
  # not exist at all in May), a new 2026 row, and the widened/rebased
  # percentile in Panel B. All ported directly from both workbooks' cell
  # formulas (openpyxl, data_only=False) - see VERIFY-AUGUST.md.
  srs <- shortrunseries
  lrs <- longrunseries
  num <- function(df, col, rows) {
    unname(vapply(rows, function(r) suppressWarnings(as.numeric(df[[col]][r])),
                  numeric(1)))
  }

  # ---- Panel A inputs (shortrunseries rows 10..13 = years 2022..2025, +14
  # for 2026 in August) ------------------------------------------------------
  years_a <- if (identical(vintage, "may")) 2022:2025 else 2022:2026
  rows_a  <- if (identical(vintage, "may")) 10:13 else 10:14
  n_us_b <- num(srs, srs_col("n_us_citizen"), rows_a)
  w_us_b <- num(srs, srs_col("Q_us_wealth"),  rows_a)

  panel_a <- tibble::tibble(
    year                = as.character(years_a),
    n_us_billionaires   = n_us_b,
    wealth_b            = w_us_b,
    annual_growth       = c(NA_real_, w_us_b[-1] / w_us_b[-length(w_us_b)] - 1)
  )
  if (!identical(vintage, "may")) {
    # 2026's growth cell doubles the (partial-year) rate, same as Tab1.
    n <- nrow(panel_a)
    panel_a$annual_growth[n] <- 2 * (w_us_b[n] / w_us_b[n - 1] - 1)
    # New AGI columns (August only; May's sheet has no US-AGI columns at all
    # in Panel A). longrunseries!AV = "US TOTAL AGI", nominal, rows 48:52.
    agi <- suppressWarnings(as.numeric(lrs$AV[48:52]))
    panel_a$us_agi_b       <- agi
    panel_a$wealth_per_agi <- w_us_b / agi
  }
  # Growth row stays anchored to the 2022 -> 2025 window (indices 1 and 4)
  # regardless of whether the 2026 row above extended the table.
  growth_row <- tibble::tibble(
    year                = "Growth during 3 years (2023-2025)",
    n_us_billionaires   = NA_integer_,
    wealth_b            = panel_a$wealth_b[4] / panel_a$wealth_b[1] - 1,
    annual_growth       = NA_real_
  )
  if (!identical(vintage, "may")) {
    growth_row$us_agi_b       <- panel_a$us_agi_b[4] / panel_a$us_agi_b[1] - 1
    growth_row$wealth_per_agi <- NA_real_
  }
  panel_a_full <- dplyr::bind_rows(panel_a, growth_row)

  # ---- Panel B inputs (longrunseries rows 8 = 1982, 51 = 2025 / 52 = 2026) -
  num_lr <- function(col, row) suppressWarnings(as.numeric(lrs[[col]][row]))
  W8 <- num_lr("W", 8)
  cur_row <- lrs_current_row(vintage)
  W_cur <- num_lr("W", cur_row)
  defl_1982 <- W8 / W_cur

  if (identical(vintage, "may")) {
    AM_1982 <- num_lr("AM", 8);  AM_cur <- num_lr("AM", cur_row)
    wealth_1982 <- num_lr("AP", 8) * defl_1982
    wealth_cur  <- num_lr("AP", cur_row)             # already 2025$
    agi_1982    <- num_lr("AS", 8) * defl_1982
    agi_cur     <- num_lr("AS", cur_row)             # already 2025$
  } else {
    # Families: top .001% = 5x top .0002% (longrunseries!AM, US version of
    # AL, unchanged column both vintages). Wealth: US GDP (longrunseries!G,
    # nominal) x (US top .001%/GDP ratio, longrunseries!BQ) x deflator - the
    # workbook's own Pareto-scaled wealth figure (no separate "already real"
    # column exists for the US the way CA has BT). AGI: longrunseries!AV
    # (nominal "US TOTAL AGI") x deflator.
    AM_1982 <- num_lr("AM", 8) * 5;  AM_cur <- num_lr("AM", cur_row) * 5
    wealth_1982 <- num_lr("G", 8)       * num_lr("BQ", 8)       * defl_1982
    wealth_cur  <- num_lr("G", cur_row) * num_lr("BQ", cur_row) * (W_cur / W_cur)
    agi_1982    <- num_lr("AV", 8) * defl_1982
    agi_cur     <- num_lr("AV", cur_row) * (W_cur / W_cur)
  }
  X_1982 <- num_lr("X", 8);  X_cur <- num_lr("X", cur_row)

  make_year_row <- function(label, AM, wealth_b, X, agi_b) {
    n_fam_m <- X / 1000
    tibble::tibble(
      year                  = label,
      families_top0002_k    = AM,
      wealth_top0002_b      = wealth_b,
      wealth_per_family_b   = wealth_b / AM,
      n_us_families_m       = n_fam_m,
      us_gdp_2025dollars_b  = agi_b,
      gdp_per_family_k      = 1000 * agi_b / n_fam_m
    )
  }
  cur_label <- if (identical(vintage, "may")) "2025" else "2026"
  n_years   <- if (identical(vintage, "may")) 43 else 44
  row_1982 <- make_year_row("1982", AM_1982, wealth_1982, X_1982, agi_1982)
  row_cur  <- make_year_row(cur_label, AM_cur, wealth_cur, X_cur, agi_cur)
  lr <- .long_run_compare(row_1982, row_cur, n_years = n_years)
  panel_b <- dplyr::bind_rows(row_1982, row_cur, lr$ratio, lr$annualized)

  panel_a_render <- tibble::tibble(
    section = "A. Recent nominal wealth growth of US billionaires",
    year    = panel_a_full$year,
    col1    = panel_a_full$n_us_billionaires,
    col2    = panel_a_full$wealth_b,
    col3    = panel_a_full$annual_growth,
    col4    = NA_real_,
    col5    = if (!identical(vintage, "may")) panel_a_full$us_agi_b else NA_real_,
    col6    = if (!identical(vintage, "may")) panel_a_full$wealth_per_agi else NA_real_
  )
  pctile_label <- if (identical(vintage, "may")) "top .0002%" else "top .001%"
  panel_b_render <- tibble::tibble(
    section = paste0("B. Long-term real wealth growth: ", pctile_label,
                      " wealthiest US families (", cur_label, " $)"),
    year    = panel_b$year,
    col1    = panel_b$families_top0002_k,
    col2    = panel_b$wealth_top0002_b,
    col3    = panel_b$wealth_per_family_b,
    col4    = panel_b$n_us_families_m,
    col5    = panel_b$us_gdp_2025dollars_b,
    col6    = panel_b$gdp_per_family_k
  )
  combined <- dplyr::bind_rows(panel_a_render, panel_b_render)

  tab <- gt::gt(combined, groupname_col = "section") |>
    gt::tab_header(title = "Appendix Table A1. Wealth Growth of US Billionaires") |>
    gt::cols_label(
      year = "Year",
      col1 = "# / families",
      col2 = "Wealth",
      col3 = "Growth / per family",
      col4 = "# US families (M)",
      col5 = "US GDP",
      col6 = "GDP / family ($)"
    ) |>
    gt::fmt_number(columns = c(col1, col2, col4, col5, col6),
                   decimals = 0, use_seps = TRUE) |>
    gt::fmt_percent(columns = col3, decimals = 1) |>
    gt::sub_missing(missing_text = "—") |>
    gt::tab_source_note(source_note = gt::md(paste(
      "**Notes:** Repeats Tab 1 for US billionaires instead of CA. Panel A:",
      "nominal wealth of all US citizen billionaires (Forbes). Panel B: 1982",
      "vs 2025 real wealth of top .0002% US families, in 2025 dollars."
    )))

  attr(tab, "panel_a") <- panel_a_full
  attr(tab, "panel_b") <- panel_b
  tab
}

build_tab5 <- function(tab5_r) {
  # Table 5: Scoring the One-Time 5% CA Wealth Tax.
  # 4 scenarios × 7 metric columns. tab5_r already verified element-wise
  # against the Excel sheet by the upstream R re-derivation.

  long_labels <- c(
    "1. Benchmark: Forbes estimates + 10% avoidance",
    "2. Adding missing small billionaires (Pareto extrapolation)",
    "3. Aggressive assumptions for pre/post-2026 leavers",
    "4. Benchmark with both adding small billionaires and aggressive leavers"
  )
  panel <- tab5_r
  panel$scenario <- long_labels

  tab <- gt::gt(panel) |>
    gt::tab_header(title = "Table 5. Scoring the One-Time 5% California Wealth Tax") |>
    gt::cols_label(
      scenario              = "",
      n_billionaires        = "# CA billionaires",
      wealth                = "Wealth ($B)",
      taxable_wealth        = "Taxable wealth ($B)",
      avoidance_rate        = "Avoidance rate",
      wealth_tax_revenue    = "Wealth tax revenue ($B)",
      extra_ca_inctax_sales = "Extra CA inctax from sales ($B)",
      annual_ca_inctax_loss = "Annual CA inctax loss ($B)"
    ) |>
    gt::fmt_number(columns = c(n_billionaires, wealth, taxable_wealth,
                                wealth_tax_revenue, extra_ca_inctax_sales,
                                annual_ca_inctax_loss),
                   decimals = 1, use_seps = TRUE) |>
    gt::fmt_percent(columns = avoidance_rate, decimals = 1) |>
    gt::tab_source_note(source_note = gt::md(paste(
      "**Notes:** Scenarios assume a one-time 5% wealth tax. Wealth tax revenue =",
      "taxable_wealth × 5%. Extra CA income tax from sales reflects forced",
      "asset sales to pay the tax (33% realization × 80% LTCG-taxable × 13.3%",
      "CA rate). Annual CA inctax loss is the steady-state revenue forgone from",
      "billionaires leaving California. Source: `tab5_r`."
    )))

  attr(tab, "panel") <- panel
  tab
}

build_tab4 <- function(data_sec_top4) {
  # Table 4: Wealth, Income, and Taxes of the Top 4, 2019-2025.
  # Two columns: "Total 2019-2025" and "Annual average" (= total / 7).

  d <- data_sec_top4
  total_excl <- d[d$forbes_id == "Total (excluding Ellison)" &
                    d$year %in% 2019:2025, ]
  total_excl <- total_excl[order(total_excl$year), ]
  begin <- d[d$forbes_id == "Total (excluding Ellison)" & d$year == 2018, ]
  end   <- d[d$forbes_id == "Total (excluding Ellison)" & d$year == 2025, ]
  # All values converted from $M to $B by dividing by 1000.
  wealth_begin <- begin$public_worth / 1000
  wealth_end   <- end$public_worth   / 1000
  wealth_gain  <- wealth_end - wealth_begin
  wealth_avg   <- mean(total_excl$public_worth) / 1000

  sum_col <- function(col) sum(total_excl[[col]]) / 1000

  fiscal_income      <- sum_col("fiscal_income")
  stock_options      <- sum_col("option_profit") + sum_col("noneq_comp")
  dividends          <- sum_col("dividend")
  realized_gains     <- sum_col("kg_taxable")
  appreciated_stock  <- sum_col("donation")
  net_collateral     <- sum_col("value_borrowed")
  fed_inctax         <- sum_col("fed_income_tax")
  ca_inctax          <- sum_col("ca_income_tax")
  corp_profits       <- sum_col("w_pi")
  corp_taxes         <- sum_col("w_txt")

  rows <- tibble::tibble(
    metric = c(
      "Wealth in 2019 (beginning of year)",
      "Wealth in 2025 (end of year)",
      "Gain in wealth during 2019-2025",
      "Wealth (average over 2019-2025)",
      "Fiscal individual income",
      "        Stock-options exercise + non-equity comp",
      "        Dividends",
      "        Realized capital gains",
      "Memo: Appreciated stock donated to charity",
      "Memo: Net collateral pledged",
      "Federal individual income tax",
      "California individual income tax",
      "Individual taxes / individual income",
      "Corporate profits",
      "Corporate taxes (federal)",
      "Corporate tax rate (effective)"
    ),
    total = c(
      wealth_begin, wealth_end, wealth_gain, NA_real_,
      fiscal_income, stock_options, dividends, realized_gains,
      appreciated_stock, net_collateral,
      fed_inctax, ca_inctax,
      (fed_inctax + ca_inctax) / fiscal_income,
      corp_profits, corp_taxes, corp_taxes / corp_profits
    ),
    annual_avg = c(
      NA_real_, NA_real_, wealth_gain / 7, wealth_avg,
      fiscal_income / 7, stock_options / 7, dividends / 7, realized_gains / 7,
      appreciated_stock / 7, net_collateral / 7,
      fed_inctax / 7, ca_inctax / 7,
      (fed_inctax + ca_inctax) / fiscal_income,
      corp_profits / 7, corp_taxes / 7, corp_taxes / corp_profits
    )
  )

  ratio_rows <- c(13, 16)        # tax-rate rows
  fmt_rows   <- setdiff(seq_len(nrow(rows)), ratio_rows)

  tab <- gt::gt(rows) |>
    gt::tab_header(title = "Table 4. Wealth, Income, and Taxes of the Top 4, 2019-2025") |>
    gt::cols_label(
      metric     = "",
      total      = "Total 2019-2025 ($B)",
      annual_avg = "Annual average ($B)"
    ) |>
    gt::fmt_number(rows = fmt_rows, decimals = 2) |>
    gt::fmt_percent(rows = ratio_rows, decimals = 1) |>
    gt::sub_missing(missing_text = "—") |>
    gt::tab_source_note(source_note = gt::md(paste(
      "**Notes:** All amounts in nominal $B. Source: per-billionaire SEC Form 4",
      "filings aggregated as `data_sec_top4`'s \"Total (excluding Ellison)\" rows."
    )))

  attr(tab, "panel") <- rows
  tab
}

build_tab3 <- function(data_sec_top4) {
  # Table 3: CA Income Tax Paid by the Top 4 on Company Wealth.
  # Per-billionaire panel (Page, Brin, Zuckerberg, Huang) + all-top-4 sum.
  # 7 yearly CA income tax rows (2019-2025) + 1 average row +
  # begin-of-2019 wealth + end-of-2025 wealth + tax / wealth-gain.

  ids <- c("larry-page", "sergey-brin", "mark-zuckerberg", "jensen-huang")
  ids_lbl <- c("page", "brin", "zuckerberg", "huang")

  d <- data_sec_top4
  pick <- function(id, yr, col) {
    row <- d[d$forbes_id == id & d$year == yr, ]
    if (nrow(row) == 1L) row[[col]] else NA_real_
  }
  ca_tax_yearly <- function(yr) {
    setNames(vapply(ids, pick, numeric(1), yr = yr, col = "ca_income_tax"), ids_lbl)
  }

  tax_yrs <- lapply(2019:2025, ca_tax_yearly)
  # Per-row: per-billionaire + all_top4 sum
  yearly_rows <- lapply(seq_along(tax_yrs), function(i) {
    row <- as.list(tax_yrs[[i]])
    row$all_top4 <- sum(unlist(row))
    row$metric   <- paste("CA income tax", 2018 + i)
    tibble::as_tibble(row)
  })
  panel <- dplyr::bind_rows(yearly_rows)
  panel <- panel[, c("metric", "page", "brin", "zuckerberg", "huang", "all_top4")]

  # Average row (mean of the 7 yearly rows, per column)
  num_cols <- setdiff(names(panel), "metric")
  avg_values <- setNames(lapply(num_cols, function(c) mean(panel[[c]])), num_cols)
  avg_row <- tibble::as_tibble(c(
    list(metric = "Average CA income tax 2019-2025"),
    avg_values
  ))

  # Wealth rows: begin = end-of-2018 public_worth; end = end-of-2025 public_worth.
  wealth_begin <- setNames(vapply(ids, pick, numeric(1),
                                   yr = 2018, col = "public_worth"), ids_lbl)
  wealth_end   <- setNames(vapply(ids, pick, numeric(1),
                                   yr = 2025, col = "public_worth"), ids_lbl)
  wealth_begin_row <- tibble::as_tibble(c(
    list(metric = "Wealth at the beginning of 2019"),
    as.list(wealth_begin),
    list(all_top4 = sum(wealth_begin))
  ))
  wealth_end_row <- tibble::as_tibble(c(
    list(metric = "Wealth at end of 2025"),
    as.list(wealth_end),
    list(all_top4 = sum(wealth_end))
  ))
  # Total CA income tax / (end_wealth - begin_wealth), per column.
  total_taxes <- vapply(num_cols, function(c) sum(panel[[c]]), numeric(1))
  end_minus_begin <- c(wealth_end, all_top4 = sum(wealth_end)) -
                      c(wealth_begin, all_top4 = sum(wealth_begin))
  ratio_row <- tibble::as_tibble(c(
    list(metric = "Total CA income tax / wealth gain 2019-2025"),
    as.list(total_taxes / end_minus_begin)
  ))

  full <- dplyr::bind_rows(panel, avg_row, wealth_begin_row, wealth_end_row, ratio_row)

  tab <- gt::gt(full) |>
    gt::tab_header(title = "Table 3. California Income Tax Paid by the Top 4 on Company Wealth") |>
    gt::cols_label(
      metric     = "",
      page       = "Larry Page (Alphabet)",
      brin       = "Sergei Brin (Alphabet)",
      zuckerberg = "Mark Zuckerberg (Meta)",
      huang      = "Jensen Huang (Nvidia)",
      all_top4   = "All top 4"
    ) |>
    gt::fmt_number(rows = 1:8, decimals = 2, use_seps = TRUE) |>
    gt::fmt_number(rows = 9:10, decimals = 0, use_seps = TRUE) |>
    gt::fmt_percent(rows = 11, decimals = 3) |>
    gt::tab_source_note(source_note = gt::md(paste(
      "**Notes:** All amounts in nominal $M unless noted. CA income tax is",
      "computed from each billionaire's SEC Form 4 filings (target",
      "`data_sec_top4`). Row 11 is the lifetime effective tax rate on the",
      "2019-2025 wealth gain."
    )))

  attr(tab, "panel") <- full
  tab
}

build_tab1 <- function(data_sec_agg_r, shortrunseries_r, longrunseries,
                       shortrunseries, vintage = bsz_vintage()) {
  # Table 1: Wealth Growth of California Billionaires.
  # Panel A: 2022-2025(+2026 in August) nominal wealth + growth + CA GDP/AGI.
  # Panel B: 1982 vs 2025(2026 in August) long-term real-wealth growth of the
  # top .0002% (May) / .001% (August) wealthiest CA families.
  #
  # RC4 (class b): August redefined the Panel A/B denominator from CA GDP to
  # CA total AGI (Tab1!G5 header + formula both changed; new source sheet
  # `2023-b-1__adjusted_gross_income`). RC5: August inserted a "2026 (July
  # 1st)" row into Panel A (and pushed the growth row down one). RC6 (class
  # b): Panel B's percentile widened .0002% -> .001% and its "current year"
  # endpoint moved 2025 -> 2026. All ported directly from both workbooks'
  # cell formulas (openpyxl, data_only=False) - see VERIFY-AUGUST.md.

  # ---- Panel A inputs --------------------------------------------------------
  agg <- data_sec_agg_r[data_sec_agg_r$year %in% 2022:2025, ]
  srs <- shortrunseries_r$panel
  srs_a <- srs[srs$year %in% 2022:2025, c("year", "top5_total_b")]
  denom_col <- if (identical(vintage, "may")) "AT" else "AY"  # GDP (May) / AGI (August)
  denom_1 <- suppressWarnings(as.numeric(longrunseries[[denom_col]][48:51]))

  panel_a <- tibble::tibble(
    year                 = as.character(2022:2025),
    n_billionaires       = agg$n,
    wealth_b             = agg$forbes_worth,
    annual_growth        = c(NA_real_, agg$forbes_worth[-1] / agg$forbes_worth[-4] - 1),
    fraction_public      = agg$forbes_public_worth / agg$forbes_worth,
    top4_wealth_b        = srs_a$top5_total_b,
    ca_gdp_b             = denom_1,
    wealth_per_gdp       = agg$forbes_worth / denom_1
  )

  if (!identical(vintage, "may")) {
    # August's new "2026 (July 1st)" row (Tab1 row 10): n and the 60%
    # public-wealth fraction are hand-entered literals; wealth and top-4
    # wealth are literal reads from shortrunseries (row 14, the 2026 row -
    # outside compute_shortrunseries()'s 2018-2025 panel, so read directly
    # from the raw sheet); D10 doubles the (partial-year) growth rate; the
    # denominator is longrunseries!AY52.
    cell_2026 <- function(col) xls_cell(shortrunseries, paste0(col, 14))
    wealth_2026 <- cell_2026("C")
    top4_2026   <- cell_2026(srs_col("top5_total"))
    denom_2026  <- suppressWarnings(as.numeric(longrunseries[[denom_col]][52]))
    row_2026 <- tibble::tibble(
      year                 = "2026 (July 1st)",
      n_billionaires       = 250L,
      wealth_b             = wealth_2026,
      annual_growth        = 2 * (wealth_2026 / panel_a$wealth_b[4] - 1),
      fraction_public      = 0.6,
      top4_wealth_b        = top4_2026,
      ca_gdp_b             = denom_2026,
      wealth_per_gdp       = wealth_2026 / denom_2026
    )
    panel_a <- dplyr::bind_rows(panel_a, row_2026)
  }

  # Append "Growth during 2023-2025" row (Tab1 row 10 May / 11 August) - this
  # stays anchored to the 2022 -> 2025 window in BOTH vintages (indices 1 and
  # 4 of `panel_a`, which are always 2022 and 2025 regardless of whether the
  # 2026 row above was appended after them).
  growth_row <- tibble::tibble(
    year                 = "Growth during 2023-2025",
    n_billionaires       = NA_integer_,
    wealth_b             = panel_a$wealth_b[4] / panel_a$wealth_b[1] - 1,
    annual_growth        = NA_real_,
    fraction_public      = NA_real_,
    top4_wealth_b        = panel_a$top4_wealth_b[4] / panel_a$top4_wealth_b[1] - 1,
    ca_gdp_b             = panel_a$ca_gdp_b[4] / panel_a$ca_gdp_b[1] - 1,
    wealth_per_gdp       = NA_real_
  )
  panel_a_full <- dplyr::bind_rows(panel_a, growth_row)
  panel_a_full$panel <- "A. Recent nominal wealth growth of CA billionaires"

  # ---- Panel B inputs --------------------------------------------------------
  lrs <- longrunseries
  num <- function(col, row) suppressWarnings(as.numeric(lrs[[col]][row]))
  W8 <- num("W", 8)
  cur_row <- lrs_current_row(vintage)   # 51 (May, 2025) / 52 (August, 2026)
  W_cur <- num("W", cur_row)
  defl_1982 <- W8 / W_cur

  if (identical(vintage, "may")) {
    AL_1982 <- num("AL", 8);       AL_cur <- num("AL", cur_row)
    wealth_1982 <- num("AQ", 8) * defl_1982
    wealth_cur  <- num("AQ", cur_row)                       # already 2025$
    gdp_1982    <- num("AT", 8) * defl_1982
    gdp_cur     <- num("AT", cur_row)                       # already 2025$
  } else {
    # Families: top .001% = 5x the top .0002% count (longrunseries!AL, same
    # column both vintages). Wealth: longrunseries!BT is ALREADY real (2026
    # $), no deflation needed. AGI: longrunseries!BA (nominal, "CA total AGI
    # consistent KG") deflated the same way GDP used to be.
    AL_1982 <- num("AL", 8) * 5;   AL_cur <- num("AL", cur_row) * 5
    wealth_1982 <- num("BT", 8)
    wealth_cur  <- num("BT", cur_row)
    gdp_1982    <- num("BA", 8) * defl_1982
    gdp_cur     <- num("BA", cur_row) * (W_cur / W_cur)     # = num("BA", cur_row)
  }
  AI_1982 <- num("AI", 8);  AI_cur <- num("AI", cur_row)

  make_year_row <- function(label, AL, wealth_b, AI, gdp_b, round_gdp_per_family) {
    n_fam_m <- AI / 1000
    gdp_per_family <- 1000 * gdp_b / n_fam_m
    if (round_gdp_per_family) gdp_per_family <- round(gdp_per_family, -2)
    tibble::tibble(
      year                 = label,
      families_top0002_k   = AL,
      wealth_top0002_b     = wealth_b,
      wealth_per_family_b  = wealth_b / AL,
      n_ca_families_m      = n_fam_m,
      ca_gdp_2025dollars_b = gdp_b,
      gdp_per_family_k     = gdp_per_family
    )
  }
  cur_label <- if (identical(vintage, "may")) "2025" else "2026"
  n_years   <- if (identical(vintage, "may")) 43 else 44
  round_gpf <- !identical(vintage, "may")   # August's H column uses ROUND(.,-2)
  row_1982 <- make_year_row("1982", AL_1982, wealth_1982, AI_1982, gdp_1982, round_gpf)
  row_cur  <- make_year_row(cur_label, AL_cur, wealth_cur, AI_cur, gdp_cur, round_gpf)
  lr <- .long_run_compare(row_1982, row_cur, n_years = n_years)
  panel_b <- dplyr::bind_rows(row_1982, row_cur, lr$ratio, lr$annualized)

  # ---- Render with gt -------------------------------------------------------
  # Two stacked panels rendered as one gt; row groups give the panel headers.
  panel_a_render <- tibble::tibble(
    section = "A. Recent nominal wealth growth of CA billionaires",
    year    = panel_a_full$year,
    col1    = panel_a_full$n_billionaires,
    col2    = panel_a_full$wealth_b,
    col3    = panel_a_full$annual_growth,
    col4    = panel_a_full$fraction_public,
    col5    = panel_a_full$top4_wealth_b,
    col6    = panel_a_full$ca_gdp_b,
    col7    = panel_a_full$wealth_per_gdp
  )
  pctile_label <- if (identical(vintage, "may")) "top .0002%" else "top .001%"
  panel_b_render <- tibble::tibble(
    section = paste0("B. Long-term real wealth growth: ", pctile_label,
                      " wealthiest CA families (", cur_label, " $)"),
    year    = panel_b$year,
    col1    = panel_b$families_top0002_k,
    col2    = panel_b$wealth_top0002_b,
    col3    = panel_b$wealth_per_family_b,
    col4    = panel_b$n_ca_families_m,
    col5    = panel_b$ca_gdp_2025dollars_b,
    col6    = panel_b$gdp_per_family_k,
    col7    = NA_real_
  )
  combined <- dplyr::bind_rows(panel_a_render, panel_b_render)

  tab <- gt::gt(combined, groupname_col = "section") |>
    gt::tab_header(title = "Table 1. Wealth Growth of California Billionaires") |>
    gt::cols_label(
      year = "Year",
      col1 = "#",
      col2 = "Wealth",
      col3 = "Growth",
      col4 = "% public",
      col5 = "Top 4 wealth",
      col6 = "CA GDP",
      col7 = "Wealth / GDP"
    ) |>
    gt::fmt_number(columns = c(col1, col2, col5, col6),
                   decimals = 0, use_seps = TRUE) |>
    gt::fmt_percent(columns = c(col3, col4, col7), decimals = 1) |>
    gt::sub_missing(missing_text = "—") |>
    gt::tab_source_note(source_note = gt::md(paste(
      "**Notes:** Panel A illustrates the wealth growth of CA billionaires in 2022-2025.",
      "Panel B compares the top .0002% wealthiest CA families' wealth in 1982 vs 2025,",
      "all in 2025 dollars. Source: Forbes RTB snapshots + SEC EDGAR."
    )))

  # Attach a tidy version for downstream use / tests.
  attr(tab, "panel_a") <- panel_a_full
  attr(tab, "panel_b") <- panel_b
  tab
}
