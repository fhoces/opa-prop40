# Phase 3 - ggplot figure builders.
#
# Each builder takes already-validated upstream targets and returns a ggplot.
# Render to PNG / PDF downstream via R/render.R helpers.

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
