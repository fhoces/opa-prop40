# Phase 3 - gt table builders.
#
# Each builder takes already-validated upstream targets (Phase-1 extractors or
# Phase-2 `*_r` re-derivations) and returns a `gt` object. Render to HTML or
# LaTeX downstream via `gt::as_raw_html()` / `gt::as_latex()`.

build_tab2 <- function(data_sec_agg_r, billionaires_ca_inctax_r, data_sec_top4) {
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

  # Average row — Excel quirk: D14 = AVERAGE(D7:D12) (6 yrs, 2019-2024 only)
  # while B/C/F/G14 = AVERAGE(*7:*13) (7 yrs). Reproduce as-is for fidelity.
  avg_row <- tibble::tibble(
    year                      = "2019-2025 average",
    wealth_b                  = mean(panel$wealth_b),
    ca_inctax_b               = mean(panel$ca_inctax_b),
    ca_inctax_per_wealth      = mean(panel$ca_inctax_per_wealth[1:6]),  # 2019-2024
    top4_company_wealth_b     = mean(panel$top4_company_wealth_b),
    top4_ca_inctax_b          = mean(panel$top4_ca_inctax_b),
    top4_ca_inctax_per_wealth = mean(panel$top4_ca_inctax_b) /
                                  mean(panel$top4_company_wealth_b)
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
      "filings. Source: Phase 2 `billionaires_ca_inctax_r` + `data_sec_top4`."
    )))

  attr(tab, "panel") <- full
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
      "computed from each billionaire's SEC Form 4 filings (Phase-1 target",
      "`data_sec_top4`). Row 11 is the lifetime effective tax rate on the",
      "2019-2025 wealth gain."
    )))

  attr(tab, "panel") <- full
  tab
}

build_tab1 <- function(data_sec_agg_r, shortrunseries_r, longrunseries) {
  # Table 1: Wealth Growth of California Billionaires.
  # Panel A: 2022-2025 nominal wealth + growth + CA GDP comparison.
  # Panel B: 1982 vs 2025 long-term real-wealth growth of top .0002%.

  # ---- Panel A inputs --------------------------------------------------------
  agg <- data_sec_agg_r[data_sec_agg_r$year %in% 2022:2025, ]
  srs <- shortrunseries_r$panel
  srs_a <- srs[srs$year %in% 2022:2025, c("year", "top5_total_b")]
  # CA GDP: longrunseries col AT, rows 48..51 = years 2022..2025
  ca_gdp <- suppressWarnings(as.numeric(longrunseries$AT[48:51]))

  panel_a <- tibble::tibble(
    year                 = as.character(2022:2025),
    n_billionaires       = agg$n,
    wealth_b             = agg$forbes_worth,
    annual_growth        = c(NA_real_, agg$forbes_worth[-1] / agg$forbes_worth[-4] - 1),
    fraction_public      = agg$forbes_public_worth / agg$forbes_worth,
    top4_wealth_b        = srs_a$top5_total_b,
    ca_gdp_b             = ca_gdp,
    wealth_per_gdp       = agg$forbes_worth / ca_gdp
  )
  # Append "Growth during 2023-2025" row (matches Tab1 row 10).
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
  # longrunseries rows 8 = 1982, 51 = 2025. AL = # families top .0002%,
  # AQ = top .0002% wealth in current $B, AI = # CA families,
  # AT = CA GDP, W = deflator (W51 / W8 inflates 1982 -> 2025 $).
  lrs <- longrunseries
  num <- function(col, row) suppressWarnings(as.numeric(lrs[[col]][row]))
  W8  <- num("W", 8);  W51 <- num("W", 51)
  AL_1982 <- num("AL", 8);  AL_2025 <- num("AL", 51)
  AQ_1982 <- num("AQ", 8);  AQ_2025 <- num("AQ", 51)
  AI_1982 <- num("AI", 8);  AI_2025 <- num("AI", 51)
  AT_1982 <- num("AT", 8);  AT_2025 <- num("AT", 51)
  # Deflation: 1982 $ -> 2025 $ via W ratio; 2025 row deflator-ratios to 1.
  defl_1982 <- W8  / W51
  defl_2025 <- W51 / W51    # = 1

  row_1982 <- tibble::tibble(
    year                 = "1982",
    families_top0002_k   = AL_1982,
    wealth_top0002_b     = AQ_1982 * defl_1982,
    wealth_per_family_b  = NA_real_,
    n_ca_families_m      = AI_1982 / 1000,
    ca_gdp_2025dollars_b = AT_1982 * defl_1982,
    gdp_per_family_k     = NA_real_
  )
  row_1982$wealth_per_family_b <- row_1982$wealth_top0002_b / row_1982$families_top0002_k
  row_1982$gdp_per_family_k    <- 1000 * row_1982$ca_gdp_2025dollars_b / row_1982$n_ca_families_m

  row_2025 <- tibble::tibble(
    year                 = "2025",
    families_top0002_k   = AL_2025,
    wealth_top0002_b     = AQ_2025 * defl_2025,
    wealth_per_family_b  = NA_real_,
    n_ca_families_m      = AI_2025 / 1000,
    ca_gdp_2025dollars_b = AT_2025 * defl_2025,
    gdp_per_family_k     = NA_real_
  )
  row_2025$wealth_per_family_b <- row_2025$wealth_top0002_b / row_2025$families_top0002_k
  row_2025$gdp_per_family_k    <- 1000 * row_2025$ca_gdp_2025dollars_b / row_2025$n_ca_families_m

  ratio_row <- tibble::tibble(
    year                 = "Ratio 2025 to 1982",
    families_top0002_k   = row_2025$families_top0002_k   / row_1982$families_top0002_k,
    wealth_top0002_b     = row_2025$wealth_top0002_b     / row_1982$wealth_top0002_b,
    wealth_per_family_b  = row_2025$wealth_per_family_b  / row_1982$wealth_per_family_b,
    n_ca_families_m      = row_2025$n_ca_families_m      / row_1982$n_ca_families_m,
    ca_gdp_2025dollars_b = row_2025$ca_gdp_2025dollars_b / row_1982$ca_gdp_2025dollars_b,
    gdp_per_family_k     = row_2025$gdp_per_family_k     / row_1982$gdp_per_family_k
  )
  annualized_row <- tibble::tibble(
    year                 = "Annualized growth",
    families_top0002_k   = ratio_row$families_top0002_k  ^(1/43) - 1,
    wealth_top0002_b     = ratio_row$wealth_top0002_b    ^(1/43) - 1,
    wealth_per_family_b  = ratio_row$wealth_per_family_b ^(1/43) - 1,
    n_ca_families_m      = ratio_row$n_ca_families_m     ^(1/43) - 1,
    ca_gdp_2025dollars_b = ratio_row$ca_gdp_2025dollars_b^(1/43) - 1,
    gdp_per_family_k     = ratio_row$gdp_per_family_k    ^(1/43) - 1
  )
  panel_b <- dplyr::bind_rows(row_1982, row_2025, ratio_row, annualized_row)

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
  panel_b_render <- tibble::tibble(
    section = "B. Long-term real wealth growth: top .0002% wealthiest CA families (2025 $)",
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
      "all in 2025 dollars. Source: Forbes RTB snapshots + SEC EDGAR (Phase 1 / Phase 2",
      "of `~/Desktop/sandbox/CAWT-BSZ`)."
    )))

  # Attach a tidy version for downstream use / tests.
  attr(tab, "panel_a") <- panel_a_full
  attr(tab, "panel_b") <- panel_b
  tab
}
