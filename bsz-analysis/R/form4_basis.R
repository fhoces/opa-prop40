# R twin of py/form4_basis.py: capital gains on Form 4 sales, the sequential
# cost-basis step between sql/09_form4_income.sql and sql/10_form4_annual.sql.
#
# Run from bsz-analysis/:
#   Rscript R/form4_basis.R
#
# Reads form4_basis_input from data-raw/bundle.sqlite and writes form4_kg (one
# row per sale) and form4_basis_held (one row per owner, issuer and year).
# The rules are written out in py/form4_basis.py; this file follows it step
# by step with plain vectors and lists (no data frame per row), so the two can
# be read side by side. Not wired into _targets.R: like R/run_sql.R it only
# defines functions when sourced, and calls DBI with `::` inside functions.

# One sale against the inventory. inv is a list of lots, each a list with
# shares, basis, date (ISO text) and ajexdi. Returns the new inventory and
# the sale's total_basis, kg, kg_short, kg_long.
form4_sell <- function(inv, row) {
  shares_to_sell <- row$shares_sold
  sale_price <- row$price_per_share
  sale_date <- row$transaction_date
  sale_ajexdi <- row$ajexdi
  total_sale <- shares_to_sell * sale_price
  if (length(inv) == 0L) {
    return(list(inv = inv, res = c(total_basis = 0, kg = total_sale, kg_short = 0,
                                   kg_long = total_sale)))
  }
  adj <- vapply(inv, function(l) {
    if (!is.na(l$ajexdi) && !is.na(sale_ajexdi) && sale_ajexdi > 0) l$ajexdi / sale_ajexdi else 1
  }, numeric(1))
  basis <- vapply(inv, function(l) l$basis, numeric(1))
  shares <- vapply(inv, function(l) l$shares, numeric(1))
  basis_adj <- basis / adj
  shares_adj <- shares * adj
  # Highest cost first; unknown costs last; ties keep their order.
  ord <- order(is.na(basis_adj), -basis_adj, seq_along(inv), na.last = TRUE)
  remaining <- shares_to_sell
  total_basis <- 0; basis_short <- 0; basis_long <- 0
  sold_short <- 0; sold_long <- 0
  kept <- list()
  for (j in ord) {
    lot <- inv[[j]]
    if (remaining > 0) {
      take <- min(shares_adj[j], remaining)
      total_basis <- total_basis + take * basis_adj[j]
      remaining <- remaining - take
      held <- if (is.na(sale_date) || is.na(lot$date)) NA_real_ else
        as.numeric(as.Date(sale_date) - as.Date(lot$date))
      if (is.na(held) || held > 365) {
        sold_long <- sold_long + take
        basis_long <- basis_long + take * basis_adj[j]
      } else {
        sold_short <- sold_short + take
        basis_short <- basis_short + take * basis_adj[j]
      }
      if (shares_adj[j] > take) {
        lot$shares <- lot$shares - take / adj[j]
        kept[[length(kept) + 1L]] <- lot
      }
    } else {
      kept[[length(kept) + 1L]] <- lot
    }
  }
  if (remaining > 0) sold_long <- sold_long + remaining
  list(inv = kept,
       res = c(total_basis = total_basis, kg = total_sale - total_basis,
               kg_short = sold_short * sale_price - basis_short,
               kg_long = sold_long * sale_price - basis_long))
}

# rows: data frame sorted by owner_cik_1, issuer_cik, seq.
form4_basis_run <- function(rows) {
  kg_out <- list()
  basis_out <- list()
  key <- paste(rows$owner_cik_1, rows$issuer_cik)
  starts <- which(!duplicated(key))
  ends <- c(starts[-1] - 1L, nrow(rows))
  for (g in seq_along(starts)) {
    idx <- starts[g]:ends[g]
    inv <- list()
    for (k in seq_along(idx)) {
      row <- as.list(rows[idx[k], ])
      new_lot <- NULL
      if (row$code == "M" && row$type == "A") {
        if (!is.na(row$shares_option) && row$shares_option > 0) new_lot <- c(row$shares_option, row$prccd)
      } else if (row$code == "P" && row$type == "A") {
        if (!is.na(row$shares_purchased) && row$shares_purchased > 0) new_lot <- c(row$shares_purchased, row$price_per_share)
      } else if (row$code == "F" && row$type == "D") {
        if (!is.na(row$shares_option) && row$shares_option > 0) new_lot <- c(row$shares_option, row$price_per_share)
      }
      if (!is.null(new_lot)) {
        inv[[length(inv) + 1L]] <- list(shares = as.numeric(new_lot[1]), basis = as.numeric(new_lot[2]),
                                        date = row$transaction_date, ajexdi = row$ajexdi)
      }
      if (row$code == "S" && row$type == "D" && !is.na(row$shares_sold) && row$shares_sold > 0) {
        out <- form4_sell(inv, row)
        inv <- out$inv
        kg_out[[length(kg_out) + 1L]] <- c(row_id = row$row_id, out$res)
      }
      last_in_year <- k == length(idx) || rows$year[idx[k + 1L]] != row$year
      if (last_in_year) {
        snap <- 0
        for (l in inv) {
          v <- l$shares * l$basis
          if (!is.na(v)) snap <- snap + v
        }
        basis_out[[length(basis_out) + 1L]] <- data.frame(
          owner_cik_1 = row$owner_cik_1, issuer_cik = row$issuer_cik,
          year = as.integer(row$year), total_basis = snap)
      }
    }
  }
  kg <- as.data.frame(do.call(rbind, kg_out))
  kg$row_id <- as.integer(kg$row_id)
  list(kg = kg, basis_held = do.call(rbind, basis_out))
}

form4_basis_main <- function(db = file.path("data-raw", "bundle.sqlite")) {
  con <- DBI::dbConnect(RSQLite::SQLite(), db)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  rows <- DBI::dbGetQuery(con, "SELECT * FROM form4_basis_input ORDER BY owner_cik_1, issuer_cik, seq")
  out <- form4_basis_run(rows)
  DBI::dbWriteTable(con, "form4_kg", out$kg[c("row_id", "total_basis", "kg", "kg_short", "kg_long")],
                    overwrite = TRUE)
  DBI::dbWriteTable(con, "form4_basis_held", out$basis_held, overwrite = TRUE)
  cat(sprintf("form4_kg: %s sales; form4_basis_held: %s owner-issuer-years\n",
              format(nrow(out$kg), big.mark = ","), format(nrow(out$basis_held), big.mark = ",")))
  invisible(out)
}

if (sys.nframe() == 0L && !interactive()) {
  form4_basis_main()
}
