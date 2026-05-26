# Phase 3 - ggplot figure builders.
#
# Each builder takes already-validated upstream targets and returns a ggplot.
# Render to PNG / PDF downstream via R/render.R helpers.

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

  colors <- c("All CA billionaires" = "#1f77b4", "Top 5 (SEC filings)" = "#d62728")

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

build_fig2 <- function(longrunseries) {
  # Figure 2: Billionaire Class Wealth Grows Much Faster than the Economy.
  # Two panels stacked horizontally via patchwork.
  #   A: CA top .0002% wealth (AZ, $B real) vs CA GDP per family (BE, $100K real)
  #      — dual y-axis line chart.
  #   B: Top .0002% wealth as % of GDP for US (AV) and CA (AW) — two lines.
  # Year range 1982-2025 = longrunseries rows 8..51.
  lrs <- longrunseries
  rows <- 8:51
  num <- function(col) suppressWarnings(as.numeric(lrs[[col]][rows]))
  year <- num("A")
  wealth_b   <- num("AZ")   # CA top .0002% real wealth, $B
  gdp_per_fam <- num("BE")   # CA GDP per family, $100Ks
  us_share   <- num("AV")   # US top 400 wealth / GDP
  ca_share   <- num("AW")   # CA top 45  wealth / GDP

  # Panel A: dual-axis. Scale GDP-per-family to wealth-axis range so both
  # fit comfortably. wealth ranges ~0.9..28.4; gdp_per_fam ~1.0..1.9.
  # Use a fixed scaling factor: gdp shown as wealth * (gdp_max / wealth_max).
  wealth_max <- max(wealth_b);  gdp_max <- max(gdp_per_fam)
  scale_factor <- wealth_max / gdp_max     # multiply gdp by this to plot
  panel_a_data <- tibble::tibble(
    year = year,
    wealth = wealth_b,
    gdp_scaled = gdp_per_fam * scale_factor
  )
  panel_a <- ggplot2::ggplot(panel_a_data, ggplot2::aes(x = year)) +
    ggplot2::geom_line(ggplot2::aes(y = wealth, color = "Top .0002% wealth ($B)"),
                       linewidth = 0.9) +
    ggplot2::geom_line(ggplot2::aes(y = gdp_scaled,
                                     color = "CA GDP per family ($100K)"),
                       linewidth = 0.9, linetype = "dashed") +
    ggplot2::scale_y_continuous(
      name = "Top .0002% wealth ($B, 2025 $)",
      sec.axis = ggplot2::sec_axis(~ . / scale_factor,
                                    name = "CA GDP per family ($100K, 2025 $)")
    ) +
    ggplot2::scale_color_manual(values = c("Top .0002% wealth ($B)" = "#d62728",
                                            "CA GDP per family ($100K)" = "#1f77b4")) +
    ggplot2::labs(
      title = "A. CA Top .0002% wealth vs. GDP per family",
      x = NULL, color = NULL
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
    ggplot2::scale_color_manual(values = c("US (top 400)"       = "#1f77b4",
                                            "California (top 45)" = "#d62728")) +
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
    ggplot2::scale_color_manual(values = c("All CA billionaires" = "#1f77b4",
                                            "Top 4 (Page, Brin, Zuck, Huang)" = "#d62728")) +
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
