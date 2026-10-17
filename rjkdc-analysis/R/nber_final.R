# NBER bridge inputs, rebuilt from RAUH/NBER_2026_litigation_weighted/
# NPV_data/final.csv (240 rows: 212 domestic + 28 international; see
# extract_nber_final()) rather than hard-coded, by design. final.csv's
# `face_tax_5pct` column is 5% of `wealth_in_tax_base_usd_7pct` (net worth
# grown 7% to the Dec 31 2026 valuation date, net of real estate) - i.e. the
# NBER-vintage analogue of revenue_chain.R's per-row `O` column.

extract_nber_final <- function(path = rauh_nber_final_csv()) {
  readr_read_csv <- function(path) {
    df <- utils::read.csv(path, stringsAsFactors = FALSE, check.names = TRUE)
    tibble::as_tibble(df)
  }
  readr_read_csv(path)
}

# Domestic total at grown (7%) vintage = the NBER version's "$100.9B face
# value" (NBER README table). Removing the 7 removed_departed rows gives
# the ceiling the README calls "$72.06B" (we recompute 72.05B - see
# NOTES.md note 4). The 7 = SSRN's 6 confirmed departures (Page, Brin,
# Thiel, Hankey, Spielberg, Sacks) plus Travis Kalanick (net worth $3.5B,
# added for the NBER vintage).
compute_nber_ceiling <- function(final_df) {
  dom <- final_df[final_df$panel == "domestic", ]
  intl <- final_df[final_df$panel == "international", ]
  removed <- dom[dom$bucket == "removed_departed", ]

  domestic_total_grown <- sum(dom$face_tax_5pct) / 1e9
  removed_departed_total <- sum(removed$face_tax_5pct) / 1e9
  ceiling_recomputed <- domestic_total_grown - removed_departed_total
  international_net_worth <- sum(intl$net_worth_usd) / 1e9
  # Two subsets of the seven, for the comparison's departures dial: the four the BSZ
  # analysis's aggressive row also removes, at this file's grown taxable value, and the two
  # the BSZ workbook does not list by name, at their net worth.
  four <- c("Larry Page", "Peter Thiel", "Don Hankey", "Travis Kalanick")
  two  <- c("Steven Spielberg", "David Sacks")
  stopifnot(all(c(four, two) %in% removed$name))
  departed_four_grown <- sum(removed$wealth_in_tax_base_usd_7pct[removed$name %in% four]) / 1e9
  spielberg_sacks_net_worth <- sum(removed$net_worth_usd[removed$name %in% two]) / 1e9

  list(
    n_domestic = nrow(dom),
    n_international = nrow(intl),
    n_removed_departed = nrow(removed),
    domestic_total_grown = domestic_total_grown,        # ~100.906 ("$100.9B")
    removed_departed_total = removed_departed_total,     # ~28.854
    ceiling_recomputed = ceiling_recomputed,              # ~72.051 (README says 72.06)
    international_net_worth = international_net_worth,   # ~146.3 ("$146.3B")
    departed_four_grown = departed_four_grown,            # ~314.8 (Page, Thiel, Hankey, Kalanick)
    spielberg_sacks_net_worth = spielberg_sacks_net_worth, # ~9.0
    removed_names = removed$name
  )
}
