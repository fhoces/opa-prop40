# ggplot figure builders.
#
# Each builder takes already-validated upstream targets and returns a ggplot.
# Render to PNG / PDF downstream via R/render.R helpers.

build_fig_a4 <- function(pareto_missing_r) {
  # Appendix Figure A4: Pareto extrapolation for missing CA billionaires.
  # Panel A: Pareto b (empirical vs projected) at each wealth threshold.
  # Panel B: density (empirical vs projected) at each wealth threshold.
  d <- pareto_missing_r
  n <- nrow(d)

  panel_a <- tibble::tibble(
    threshold = rep(d$threshold_b, 2),
    pareto_b  = c(d$pareto_b_emp, d$pareto_b_proj),
    series    = factor(rep(c("Pareto b (Forbes data)", "Pareto b (projected)"),
                             each = n),
                        levels = c("Pareto b (Forbes data)", "Pareto b (projected)"))
  )
  panel_b <- tibble::tibble(
    threshold = rep(d$threshold_b, 2),
    density   = c(d$actual_density, d$projected_density),
    series    = factor(rep(c("Density (Forbes)", "Density (Pareto-projected)"),
                             each = n),
                        levels = c("Density (Forbes)", "Density (Pareto-projected)"))
  )
  colors_a <- c("Pareto b (Forbes data)" = "#d62728",
                "Pareto b (projected)"  = "#1f77b4")
  colors_b <- c("Density (Forbes)"            = "#d62728",
                "Density (Pareto-projected)" = "#1f77b4")

  pa <- ggplot2::ggplot(panel_a,
                         ggplot2::aes(x = threshold, y = pareto_b, color = series,
                                        shape = series)) +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::geom_point(size = 2) +
    ggplot2::labs(title = "A. Pareto coefficient b (actual and projected)",
                   x = "Wealth threshold ($B)", y = "Pareto b", color = NULL, shape = NULL) +
    ggplot2::scale_color_manual(values = colors_a) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(legend.position = "bottom",
                    plot.title = ggplot2::element_text(face = "bold"),
                    panel.grid.minor = ggplot2::element_blank())

  pb <- ggplot2::ggplot(panel_b,
                         ggplot2::aes(x = threshold, y = density, color = series,
                                        shape = series)) +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::geom_point(size = 2) +
    ggplot2::labs(title = "B. Density (Forbes vs. adding missing)",
                   x = "Wealth threshold ($B)", y = "# billionaires in bracket",
                   color = NULL, shape = NULL) +
    ggplot2::scale_color_manual(values = colors_b) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(legend.position = "bottom",
                    plot.title = ggplot2::element_text(face = "bold"),
                    panel.grid.minor = ggplot2::element_blank())

  patchwork::wrap_plots(pa, pb, ncol = 2) +
    patchwork::plot_annotation(
      title = "Appendix Figure A4: Pareto Extrapolation for Missing CA Billionaires"
    )
}

build_fig_a3 <- function(billionaires_ca_inctax_r) {
  # Appendix Figure A3: Total Taxes Paid by CA Billionaires on their Public
  # Stock Wealth. Two area panels (% of public-asset wealth; % of public-asset
  # economic income), each stacking CA inctax + Fed inctax + Corp + Property/sales.
  at <- billionaires_ca_inctax_r$all_taxes
  d <- at[at$year %in% 2019:2025, ]
  n <- nrow(d)

  # Tax labels in the natural reading order; factor levels listed in
  # TOP-TO-BOTTOM stack order so geom_area places CA inctax at the bottom
  # (matches the original BSZ chart).
  labels      <- c("CA income tax", "Federal income tax",
                    "Corporate taxes", "Property + sales taxes")
  stack_levels <- rev(labels)
  panel_w <- tibble::tibble(
    year  = rep(d$year, 4),
    share = c(d$ca_inctax_per_public_wealth,
              d$fed_inctax_per_public_wealth,
              d$corp_per_public_wealth,
              d$prop_sales_per_public_wealth),
    tax   = factor(rep(labels, each = n), levels = stack_levels)
  )
  panel_ei <- tibble::tibble(
    year  = rep(d$year, 4),
    share = c(d$ca_inctax_per_econ_income,
              d$fed_inctax_per_econ_income,
              d$corp_per_econ_income,
              d$prop_sales_per_econ_income),
    tax   = factor(rep(labels, each = n), levels = stack_levels)
  )
  fills <- c("CA income tax"          = "#4a1414",
             "Federal income tax"     = "#8a2c2c",
             "Corporate taxes"        = "#c47878",
             "Property + sales taxes" = "#f0d4d4")

  pw <- ggplot2::ggplot(panel_w, ggplot2::aes(x = year, y = share, fill = tax)) +
    ggplot2::geom_area(alpha = 0.85, color = "white", linewidth = 0.3) +
    ggplot2::scale_x_continuous(breaks = 2019:2025) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
    ggplot2::scale_fill_manual(values = fills) +
    ggplot2::labs(title = "A. Total taxes as % of public-asset wealth",
                   x = NULL, y = NULL, fill = NULL) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(legend.position = "bottom",
                    plot.title = ggplot2::element_text(face = "bold"),
                    panel.grid.minor = ggplot2::element_blank())

  pei <- ggplot2::ggplot(panel_ei, ggplot2::aes(x = year, y = share, fill = tax)) +
    ggplot2::geom_area(alpha = 0.85, color = "white", linewidth = 0.3) +
    ggplot2::scale_x_continuous(breaks = 2019:2025) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
    ggplot2::scale_fill_manual(values = fills) +
    ggplot2::labs(title = "B. Total taxes as % of economic income on public assets",
                   x = NULL, y = NULL, fill = NULL) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(legend.position = "bottom",
                    plot.title = ggplot2::element_text(face = "bold"),
                    panel.grid.minor = ggplot2::element_blank())

  patchwork::wrap_plots(pw, pei, ncol = 2) +
    patchwork::plot_annotation(
      title = "Appendix Figure A3: Total Taxes on CA Billionaire Public Stock Wealth"
    )
}

build_fig_a2 <- function(shortrunseries_r) {
  # Appendix Figure A2: CA Income Tax paid by Billionaires as % of total CA
  # income tax revenue. Two-series line, 2019-2025: all CA billionaires + top 5.
  panel <- shortrunseries_r$panel
  d <- panel[panel$year %in% 2019:2025, ]
  n <- nrow(d)

  long <- tibble::tibble(
    year   = rep(d$year, 2),
    share  = c(d$ca_inctax_share_total, d$top5_sec_share_of_total),
    series = factor(rep(c("All CA billionaires", "Top 5 (SEC filings)"), each = n),
                     levels = c("All CA billionaires", "Top 5 (SEC filings)"))
  )

  ggplot2::ggplot(long, ggplot2::aes(x = year, y = share, color = series,
                                       shape = series)) +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::geom_point(size = 2.5) +
    ggplot2::scale_x_continuous(breaks = 2019:2025) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 0.1),
                                 limits = c(0, NA)) +
    ggplot2::scale_color_manual(values = c(
      "All CA billionaires" = "#d62728", "Top 5 (SEC filings)" = "#1f77b4"
    )) +
    ggplot2::labs(
      title    = "Appendix Figure A2: CA Income Tax Paid by Billionaires",
      subtitle = "As % of total CA personal income tax revenue, 2019-2025",
      x = NULL, y = NULL, color = NULL, shape = NULL
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      legend.position    = "bottom",
      plot.title         = ggplot2::element_text(face = "bold"),
      panel.grid.minor.x = ggplot2::element_blank()
    )
}

build_fig_a1 <- function(xlsx_path) {
  # Appendix Figure A1: California Billionaires Wealth by Industry.
  # Stacked horizontal bar, 13 industries × 3 components: Public stock held
  # by Top 4 (col I), other public stock (col G), private stock (col H).
  # Block 2 of rtb_2026_industry: rows 22-34, cols A and G-I.
  raw <- read_sheet("rtb_2026_industry", path = xlsx_path,
                    range = cellranger::cell_limits(ul = c(22, 1), lr = c(34, 9)))
  names(raw) <- c("industry", paste0("c", 2:ncol(raw)))
  d <- raw
  d$top4_public    <- suppressWarnings(as.numeric(d$c9))  # col I
  d$other_public   <- suppressWarnings(as.numeric(d$c7))  # col G
  d$private        <- suppressWarnings(as.numeric(d$c8))  # col H
  d$total          <- d$top4_public + d$other_public + d$private
  d <- d[!is.na(d$total) & d$total > 0, ]
  d <- d[order(d$total, decreasing = TRUE), ]
  d$industry <- factor(d$industry, levels = rev(d$industry))

  long <- tibble::tibble(
    industry  = rep(d$industry, 3),
    share     = c(d$top4_public, d$other_public, d$private),
    component = factor(rep(c("Public stock (Top 4)",
                              "Public stock (other)",
                              "Private stock"), each = nrow(d)),
                        levels = c("Public stock (Top 4)",
                                   "Public stock (other)",
                                   "Private stock"))
  )

  ggplot2::ggplot(long, ggplot2::aes(y = industry, x = share, fill = component)) +
    ggplot2::geom_col() +
    ggplot2::scale_x_continuous(labels = scales::percent_format(accuracy = 1)) +
    ggplot2::scale_fill_manual(values = c(
      "Public stock (Top 4)" = "#d62728",
      "Public stock (other)" = "#1f77b4",
      "Private stock"        = "#999999"
    )) +
    ggplot2::labs(
      title    = "Appendix Figure A1: CA Billionaire Wealth by Industry",
      subtitle = "% of total CA billionaire wealth, end of 2025 (Forbes 2026/01/01)",
      x = NULL, y = NULL, fill = NULL
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      legend.position    = "bottom",
      plot.title         = ggplot2::element_text(face = "bold"),
      panel.grid.major.y = ggplot2::element_blank()
    )
}

build_fig8 <- function(fig8_laffer_r) {
  # Figure 8: Laffer Curve for a permanent annual CA wealth tax.
  # Three lines: mechanical revenue (rate * base), actual revenue (with
  # mobility response), long-run revenue (mobility + deconcentration).
  d <- fig8_laffer_r
  long <- tibble::tibble(
    rate   = rep(d$tax_rate, 3),
    revenue = c(d$mechanical_tax_revenue, d$actual_tax_revenue, d$long_run_tax_revenue),
    series  = factor(rep(c("Mechanical (no behavior)",
                            "Short-run (with mobility)",
                            "Long-run (mobility + deconcentration)"),
                          each = nrow(d)),
                      levels = c("Mechanical (no behavior)",
                                 "Short-run (with mobility)",
                                 "Long-run (mobility + deconcentration)"))
  )

  ggplot2::ggplot(long, ggplot2::aes(x = rate, y = revenue,
                                       color = series, linetype = series)) +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::scale_x_continuous(labels = scales::percent_format(accuracy = 1),
                                 breaks = seq(0, 0.2, by = 0.05)) +
    ggplot2::scale_y_continuous(
      labels = function(v) format(v, big.mark = ",", scientific = FALSE),
      limits = c(0, NA)
    ) +
    ggplot2::scale_color_manual(values = c(
      "Mechanical (no behavior)"            = "#999999",
      "Short-run (with mobility)"           = "#1f77b4",
      "Long-run (mobility + deconcentration)" = "#d62728"
    )) +
    ggplot2::scale_linetype_manual(values = c(
      "Mechanical (no behavior)"            = "dashed",
      "Short-run (with mobility)"           = "solid",
      "Long-run (mobility + deconcentration)" = "solid"
    )) +
    ggplot2::labs(
      title    = "Figure 8: Laffer Curve for a Permanent California Wealth Tax",
      subtitle = "Annual revenue ($B) vs. tax rate, under mobility (e=10) + deconcentration (d=15) responses",
      x = "Annual wealth-tax rate",
      y = "Annual revenue ($B)",
      color    = NULL, linetype = NULL
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      legend.position = "bottom",
      plot.title      = ggplot2::element_text(face = "bold"),
      panel.grid.minor = ggplot2::element_blank()
    )
}

build_fig7 <- function(top4taxes_r, data_dina) {
  # Figure 7: Total Taxes / Economic Income, Top 4 vs US-wide average; and
  # CA income tax / Economic Income, Top 4 vs CA average. 2004-2025.
  d <- top4taxes_r$panel
  yrs <- d$year   # 2004:2025
  # data_dina K = US avg total tax/economic income, S = CA avg ca_inctax/economic
  # income. Rows 6..27 = years 2004..2025.
  dina_K <- suppressWarnings(as.numeric(data_dina$K[6:27]))
  dina_S <- suppressWarnings(as.numeric(data_dina$S[6:27]))

  n <- length(yrs)
  panel_a <- tibble::tibble(
    year   = rep(yrs, 2),
    value  = c(d$total_tax_per_income, dina_K),
    series = factor(rep(c("Top 4 (CA billionaires)", "US average"), each = n),
                     levels = c("Top 4 (CA billionaires)", "US average"))
  )
  panel_b <- tibble::tibble(
    year   = rep(yrs, 2),
    value  = c(d$ca_inctax_per_income, dina_S),
    series = factor(rep(c("Top 4 (CA billionaires)", "CA average"), each = n),
                     levels = c("Top 4 (CA billionaires)", "CA average"))
  )

  colors <- c("Top 4 (CA billionaires)" = "#1f77b4",
              "US average"              = "#d62728",
              "CA average"              = "#d62728")

  pa <- ggplot2::ggplot(panel_a,
                         ggplot2::aes(x = year, y = value, color = series)) +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::geom_point(size = 1.5) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1),
                                 limits = c(0, NA)) +
    ggplot2::scale_color_manual(values = colors) +
    ggplot2::labs(title = "A. Top 4 vs. US average: Total Taxes / Economic Income",
                   x = NULL, y = NULL, color = NULL) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(legend.position = "bottom",
                    plot.title = ggplot2::element_text(face = "bold"),
                    panel.grid.minor = ggplot2::element_blank())

  pb <- ggplot2::ggplot(panel_b,
                         ggplot2::aes(x = year, y = value, color = series)) +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::geom_point(size = 1.5) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 0.1),
                                 limits = c(0, NA)) +
    ggplot2::scale_color_manual(values = colors) +
    ggplot2::labs(title = "B. Top 4 vs. CA average: CA Income Tax / Economic Income",
                   x = NULL, y = NULL, color = NULL) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(legend.position = "bottom",
                    plot.title = ggplot2::element_text(face = "bold"),
                    panel.grid.minor = ggplot2::element_blank())

  patchwork::wrap_plots(pa, pb, ncol = 2) +
    patchwork::plot_annotation(
      title = "Figure 7: Top 4 Effective Tax Rates vs. US/CA Averages"
    )
}

build_fig6 <- function(top4taxes_r) {
  # Figure 6: Taxes paid by Top 4 relative to wealth and economic income.
  # 2004-2025 line chart, two panels: A) tax/wealth, B) tax/economic income.
  d <- top4taxes_r$panel
  yrs <- d$year
  n  <- length(yrs)

  panel_a <- tibble::tibble(
    year   = rep(yrs, 2),
    value  = c(d$total_tax_per_wealth, d$ca_inctax_per_wealth),
    series = factor(rep(c("Total taxes / wealth", "CA income tax / wealth"),
                          each = n),
                     levels = c("Total taxes / wealth", "CA income tax / wealth"))
  )
  panel_b <- tibble::tibble(
    year   = rep(yrs, 2),
    value  = c(d$total_tax_per_income, d$ca_inctax_per_income),
    series = factor(rep(c("Total taxes / income", "CA income tax / income"),
                          each = n),
                     levels = c("Total taxes / income", "CA income tax / income"))
  )

  colors_a <- c("Total taxes / wealth" = "#d62728", "CA income tax / wealth" = "#1f77b4")
  colors_b <- c("Total taxes / income" = "#d62728", "CA income tax / income" = "#1f77b4")

  pa <- ggplot2::ggplot(panel_a, ggplot2::aes(x = year, y = value, color = series)) +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::geom_point(size = 1.5) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 0.1),
                                 limits = c(0, NA)) +
    ggplot2::scale_color_manual(values = colors_a) +
    ggplot2::labs(title = "A. Top 4 Total Tax and CA income tax (% of wealth)",
                   x = NULL, y = NULL, color = NULL) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(legend.position = "bottom",
                    plot.title = ggplot2::element_text(face = "bold"),
                    panel.grid.minor = ggplot2::element_blank())

  pb <- ggplot2::ggplot(panel_b, ggplot2::aes(x = year, y = value, color = series)) +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::geom_point(size = 1.5) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1),
                                 limits = c(0, NA)) +
    ggplot2::scale_color_manual(values = colors_b) +
    ggplot2::labs(title = "B. Top 4 Total Tax and CA income tax (% of economic income)",
                   x = NULL, y = NULL, color = NULL) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(legend.position = "bottom",
                    plot.title = ggplot2::element_text(face = "bold"),
                    panel.grid.minor = ggplot2::element_blank())

  patchwork::wrap_plots(pa, pb, ncol = 2) +
    patchwork::plot_annotation(
      title = "Figure 6: Taxes Paid by the Top 4 Relative to Wealth and Income"
    )
}

build_fig5 <- function(data_sec_top4) {
  # Figure 5: Fiscal Income, Economic Income, and Wealth Gains of the Top 4,
  # 2019-2025. Three stacked bars showing the size of each income/wealth
  # concept and the share absorbed by taxes (CA, federal, corporate, and a
  # hypothetical 5% wealth tax).
  total_excl <- data_sec_top4[data_sec_top4$forbes_id == "Total (excluding Ellison)" &
                                data_sec_top4$year %in% 2019:2025, ]
  d <- total_excl[order(total_excl$year), ]
  begin <- data_sec_top4[data_sec_top4$forbes_id == "Total (excluding Ellison)" &
                           data_sec_top4$year == 2018, ]
  end   <- data_sec_top4[data_sec_top4$forbes_id == "Total (excluding Ellison)" &
                           data_sec_top4$year == 2025, ]

  fiscal_income  <- sum(d$fiscal_income) / 1000
  econ_income    <- sum(d$economic_income) / 1000
  wealth_gain    <- (end$public_worth - begin$public_worth) / 1000
  ca_inctax      <- sum(d$ca_income_tax) / 1000
  fed_inctax     <- sum(d$fed_income_tax) / 1000
  corp_tax       <- sum(d$total_tax) / 1000 - ca_inctax - fed_inctax
  wealth_tax_5p  <- 0.05 * end$public_worth / 1000

  # Per-bar breakdown: net income + CA + Fed + (corp only for Econ/Wealth) +
  # (5% wealth tax only for Wealth Gain).
  net_fi <- fiscal_income - ca_inctax - fed_inctax
  net_ei <- econ_income   - ca_inctax - fed_inctax - corp_tax
  net_wg <- wealth_gain   - wealth_tax_5p           # corporate taxes absorbed within net

  bars <- tibble::tibble(
    bar = factor(rep(c("Fiscal Income", "Economic Income", "Wealth Gain"), each = 5),
                  levels = c("Fiscal Income", "Economic Income", "Wealth Gain")),
    component = factor(rep(c("Net of taxes", "CA income tax", "Federal income tax",
                              "Corporate taxes", "5% wealth tax"), times = 3),
                        levels = c("Net of taxes", "CA income tax",
                                   "Federal income tax", "Corporate taxes",
                                   "5% wealth tax")),
    value = c(
      net_fi, ca_inctax, fed_inctax, 0, 0,
      net_ei, ca_inctax, fed_inctax, corp_tax, 0,
      net_wg, ca_inctax, fed_inctax, corp_tax, wealth_tax_5p
    )
  )

  ggplot2::ggplot(bars, ggplot2::aes(x = bar, y = value, fill = component)) +
    ggplot2::geom_col(width = 0.65) +
    ggplot2::scale_y_continuous(
      labels = function(v) format(v, big.mark = ",", scientific = FALSE)
    ) +
    ggplot2::scale_fill_manual(values = c(
      "Net of taxes"        = "#a6cee3",
      "CA income tax"       = "#1f77b4",
      "Federal income tax"  = "#2ca02c",
      "Corporate taxes"     = "#d62728",
      "5% wealth tax"       = "#ff7f0e"
    )) +
    ggplot2::labs(
      title = "Figure 5: Fiscal Income, Economic Income, and Wealth Gains of the Top 4",
      subtitle = "2019-2025 cumulative, $B; bars stack net + tax components",
      x = NULL, y = "$B", fill = NULL
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      legend.position = "bottom",
      plot.title      = ggplot2::element_text(face = "bold"),
      panel.grid.major.x = ggplot2::element_blank()
    )
}

build_fig4 <- function(billionaires_ca_inctax_r) {
  # Figure 4: Total Taxes Paid by California Billionaires relative to Wealth.
  # Stacked area chart of 4 tax components (CA inctax, fed inctax, corporate,
  # property+sales) as % of total wealth, 2019-2025.
  at <- billionaires_ca_inctax_r$all_taxes
  yrs <- 2019:2025
  d <- at[at$year %in% yrs, ]

  # geom_area's default stacking plots the FIRST factor level on TOP. To
  # match the BSZ figure (CA income tax at the bottom, property+sales as the
  # thin top sliver), list factor levels in TOP-TO-BOTTOM order.
  stack_levels <- c("Property + sales taxes", "Corporate taxes",
                     "Federal income tax", "CA income tax")
  long <- tibble::tibble(
    year  = rep(d$year, 4),
    share = c(d$ca_inctax_per_total_wealth,
              d$fed_inctax_per_total_wealth,
              d$corp_per_total_wealth,
              d$prop_sales_per_total_wealth),
    tax   = factor(rep(c("CA income tax", "Federal income tax",
                           "Corporate taxes", "Property + sales taxes"),
                        each = nrow(d)),
                    levels = stack_levels)
  )

  ggplot2::ggplot(long, ggplot2::aes(x = year, y = share, fill = tax)) +
    ggplot2::geom_area(alpha = 0.95, color = "white", linewidth = 0.3) +
    ggplot2::scale_x_continuous(breaks = yrs) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
    ggplot2::scale_fill_manual(values = c(
      "CA income tax"          = "#4a1414",   # darkest, anchor band
      "Federal income tax"     = "#8a2c2c",   # burgundy
      "Corporate taxes"        = "#c47878",   # rose
      "Property + sales taxes" = "#f0d4d4"    # pale pink, top sliver
    )) +
    ggplot2::labs(
      title    = "Figure 4: Total Taxes Paid by California Billionaires (% of wealth)",
      subtitle = "CA income tax + Federal income tax + Corporate + Property/sales, 2019-2025",
      x = NULL, y = NULL, fill = NULL
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      legend.position    = "bottom",
      plot.title         = ggplot2::element_text(face = "bold"),
      panel.grid.minor   = ggplot2::element_blank()
    )
}

build_fig3 <- function(shortrunseries_r) {
  # Figure 3: The California Income Tax Paid by Billionaires.
  # Panel A: $B income tax for all CA billionaires + top 5 (from SEC),
  # 2019-2025. Panel B: same series as % of wealth.
  panel <- shortrunseries_r$panel
  d <- panel[panel$year %in% 2019:2025, ]
  n_yrs <- nrow(d)

  panel_a_data <- tibble::tibble(
    year   = rep(d$year, 2),
    value  = c(d$ca_inctax_billionaires_b, d$top5_sec_ca_inctax_b),
    series = factor(rep(c("All CA billionaires", "Top 5 (SEC filings)"),
                          each = n_yrs),
                     levels = c("All CA billionaires", "Top 5 (SEC filings)"))
  )
  panel_b_data <- tibble::tibble(
    year   = rep(d$year, 2),
    value  = c(d$ca_inctax_per_wealth, d$top5_sec_tax_rate),
    series = factor(rep(c("All CA billionaires", "Top 5 (SEC filings)"),
                          each = n_yrs),
                     levels = c("All CA billionaires", "Top 5 (SEC filings)"))
  )

  colors <- c("All CA billionaires" = "#d62728", "Top 5 (SEC filings)" = "#1f77b4")

  panel_a <- ggplot2::ggplot(panel_a_data,
                              ggplot2::aes(x = year, y = value, color = series,
                                            shape = series)) +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::geom_point(size = 2.2) +
    ggplot2::scale_x_continuous(breaks = 2019:2025) +
    ggplot2::scale_y_continuous(limits = c(0, NA)) +
    ggplot2::scale_color_manual(values = colors) +
    ggplot2::labs(
      title = "A. CA income tax paid by billionaires ($B)",
      x = NULL, y = NULL, color = NULL, shape = NULL
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(legend.position = "bottom",
                    plot.title = ggplot2::element_text(face = "bold"),
                    panel.grid.minor.x = ggplot2::element_blank())

  panel_b <- ggplot2::ggplot(panel_b_data,
                              ggplot2::aes(x = year, y = value, color = series,
                                            shape = series)) +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::geom_point(size = 2.2) +
    ggplot2::scale_x_continuous(breaks = 2019:2025) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 0.1),
                                 limits = c(0, NA)) +
    ggplot2::scale_color_manual(values = colors) +
    ggplot2::labs(
      title = "B. CA income tax / wealth",
      x = NULL, y = NULL, color = NULL, shape = NULL
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(legend.position = "bottom",
                    plot.title = ggplot2::element_text(face = "bold"),
                    panel.grid.minor.x = ggplot2::element_blank())

  patchwork::wrap_plots(panel_a, panel_b, ncol = 2) +
    patchwork::plot_annotation(
      title = "Figure 3: California Income Tax Paid by Billionaires"
    )
}

build_fig2 <- function(longrunseries, vintage = bsz_vintage()) {
  # Figure 2: Billionaire Class Wealth Grows Much Faster than the Economy.
  # Two panels stacked horizontally via patchwork.
  #   A: CA top .0002% wealth vs CA GDP per family: dual y-axis line chart.
  #   B: Top .0002% wealth as % of GDP for US and CA: two lines.
  # Year range 1982-2025 = longrunseries rows 8..51 (both vintages; August
  # added a 2026 row past this range that fig2 does not extend into).
  #
  # Column letters for these 4 series moved in August (longrunseries grew
  # 80 -> 96 columns): AZ -> BJ (CA top .0002% real average wealth, values
  # legitimately updated between the May/August Forbes snapshots, not just
  # relabeled); BE -> BP (CA GDP per family, $100Ks); AV -> BF (US top 400
  # wealth/GDP - value UNCHANGED, byte-identical between vintages); AW -> BG
  # (CA top 45 wealth/GDP - also unchanged). Verified cell-by-cell against
  # both workbooks (openpyxl) - see VERIFY-AUGUST.md.
  lrs <- longrunseries
  rows <- 8:51
  num <- function(col) suppressWarnings(as.numeric(lrs[[col]][rows]))
  year <- num("A")
  if (identical(vintage, "may")) {
    wealth_b    <- num("AZ")   # CA top .0002% real wealth, $B
    gdp_per_fam <- num("BE")   # CA GDP per family, $100Ks
    us_share    <- num("AV")   # US top 400 wealth / GDP
    ca_share    <- num("AW")   # CA top 45  wealth / GDP
  } else {
    wealth_b    <- num("BJ")
    gdp_per_fam <- num("BP")
    us_share    <- num("BF")
    ca_share    <- num("BG")
  }

  # Panel A: single y-axis, since both series naturally fit in 0..30 (wealth in $B,
  # GDP per family in $100Ks). Wealth is the headline (red, with points);
  # GDP per family is the baseline (black, also with points).
  n_a <- length(year)
  panel_a_data <- tibble::tibble(
    year   = rep(year, 2),
    value  = c(wealth_b, gdp_per_fam),
    series = factor(rep(c("CA top .0002% wealth ($B, 2025 $)",
                            "CA GDP per family ($100K, 2025 $)"),
                          each = n_a),
                     levels = c("CA top .0002% wealth ($B, 2025 $)",
                                "CA GDP per family ($100K, 2025 $)"))
  )
  panel_a <- ggplot2::ggplot(panel_a_data,
                              ggplot2::aes(x = year, y = value, color = series)) +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::geom_point(size = 1.5) +
    ggplot2::scale_color_manual(values = c(
      "CA top .0002% wealth ($B, 2025 $)" = "#a91d22",
      "CA GDP per family ($100K, 2025 $)" = "#222222"
    )) +
    ggplot2::scale_y_continuous(limits = c(0, NA),
                                 breaks = seq(0, 30, by = 5)) +
    ggplot2::labs(
      title = "A. CA Top .0002% wealth vs. GDP per family",
      x = NULL, y = NULL, color = NULL
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      legend.position = "bottom",
      plot.title      = ggplot2::element_text(face = "bold"),
      panel.grid.minor = ggplot2::element_blank()
    )

  n_yrs <- length(year)
  panel_b_data <- tibble::tibble(
    year   = rep(year, 2),
    share  = c(us_share, ca_share),
    region = factor(rep(c("US (top 400)", "California (top 45)"), each = n_yrs),
                     levels = c("US (top 400)", "California (top 45)"))
  )
  panel_b <- ggplot2::ggplot(panel_b_data,
                              ggplot2::aes(x = year, y = share, color = region)) +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
    ggplot2::scale_color_manual(values = c("US (top 400)"       = "#d62728",
                                            "California (top 45)" = "#1f77b4")) +
    ggplot2::labs(
      title = "B. Top .0002% wealth (% of annual GDP)",
      x = NULL, y = NULL, color = NULL
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      legend.position = "bottom",
      plot.title      = ggplot2::element_text(face = "bold"),
      panel.grid.minor = ggplot2::element_blank()
    )

  patchwork::wrap_plots(panel_a, panel_b, ncol = 2) +
    patchwork::plot_annotation(
      title = "Figure 2: Billionaire Wealth Grows Much Faster than the Economy"
    )
}

build_fig1 <- function(shortrunseries_r) {
  # Figure 1: The Rise of California Billionaires Wealth in Recent Years.
  # Two solid lines (2019-2025): total CA billionaire wealth (excl. Ellison) +
  # top-4 wealth. Two dashed segments 2024->2025 showing the 5% wealth-tax
  # counterfactual (95% of 2025 actual).

  panel <- shortrunseries_r$panel
  yrs <- 2019:2025
  d <- panel[panel$year %in% yrs, ]

  series <- tibble::tibble(
    year   = rep(d$year, 2),
    wealth = c(d$wealth_us_citizens_b, d$top5_total_b),
    series = factor(rep(c("All CA billionaires", "Top 4 (Page, Brin, Zuck, Huang)"),
                          each = nrow(d)),
                     levels = c("All CA billionaires",
                                "Top 4 (Page, Brin, Zuck, Huang)"))
  )

  # Dashed-line segments: from 2024 actual to 2025-after-5%-tax.
  d24 <- d[d$year == 2024, ]
  d25 <- d[d$year == 2025, ]
  dashed <- tibble::tibble(
    x      = c(2024, 2024),
    xend   = c(2025, 2025),
    y      = c(d24$wealth_us_citizens_b, d24$top5_total_b),
    yend   = c(d25$wealth_w_avoid_b,     d25$top5_w_avoid_b),
    series = factor(c("All CA billionaires",
                       "Top 4 (Page, Brin, Zuck, Huang)"),
                     levels = levels(series$series))
  )

  ggplot2::ggplot(series, ggplot2::aes(x = year, y = wealth,
                                        color = series, shape = series)) +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::geom_point(size = 2.5) +
    ggplot2::geom_segment(
      data = dashed,
      ggplot2::aes(x = x, xend = xend, y = y, yend = yend, color = series),
      linetype = "dashed", inherit.aes = FALSE
    ) +
    ggplot2::scale_x_continuous(breaks = yrs) +
    ggplot2::scale_y_continuous(
      labels = function(v) format(v, big.mark = ",", scientific = FALSE),
      limits = c(0, NA)
    ) +
    ggplot2::scale_color_manual(values = c("All CA billionaires" = "#d62728",
                                            "Top 4 (Page, Brin, Zuck, Huang)" = "#1f77b4")) +
    ggplot2::labs(
      title    = "Figure 1: The Rise of California Billionaires' Wealth",
      subtitle = "Wealth of CA billionaires ($B, end of year). Dashed: 5% wealth-tax counterfactual.",
      x        = NULL,
      y        = "Wealth ($B)",
      color    = NULL,
      shape    = NULL
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      legend.position    = "bottom",
      plot.title         = ggplot2::element_text(face = "bold"),
      panel.grid.minor.x = ggplot2::element_blank()
    )
}
