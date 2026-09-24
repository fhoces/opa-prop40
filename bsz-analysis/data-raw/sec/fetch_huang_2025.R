# Phase 1.5 POC: cross-validate data_sec_top4 (Jensen Huang, 2025) against
# SEC EDGAR Form 4 filings. Fetches all 34 Form 4s filed in 2025 by Huang
# (CIK 0001197649), parses non-derivative + derivative tables, aggregates by
# transaction code, and compares to the Excel-derived totals.

CIK <- "0001197649"
UA  <- "CAWT-BSZ research replication fhoces@gmail.com"
CACHE <- file.path("data-raw", "sec", "cache")
dir.create(CACHE, recursive = TRUE, showWarnings = FALSE)

fetch_one <- function(accession, primary, dest) {
  if (file.exists(dest)) return(invisible())
  acc_nodash <- gsub("-", "", accession)
  # Strip the "xslF345X05/" XSLT-rendered prefix so we get raw XML
  xml_name <- sub("^xslF345X05/", "", primary)
  url <- sprintf(
    "https://www.sec.gov/Archives/edgar/data/%d/%s/%s",
    as.integer(CIK), acc_nodash, xml_name
  )
  curl::curl_download(url, dest, mode = "wb",
                       handle = curl::new_handle(useragent = UA))
  Sys.sleep(0.15)  # be polite; SEC suggests <10 req/sec
}

parse_form4 <- function(xml_path) {
  doc <- xml2::read_xml(xml_path)
  period <- xml2::xml_text(xml2::xml_find_first(doc, "//periodOfReport"))
  out <- list()
  # Non-derivative transactions
  nd <- xml2::xml_find_all(doc, "//nonDerivativeTransaction")
  for (tx in nd) {
    code <- xml2::xml_text(xml2::xml_find_first(tx, ".//transactionCode"))
    shares <- as.numeric(xml2::xml_text(xml2::xml_find_first(tx, ".//transactionShares/value")))
    price <- as.numeric(xml2::xml_text(xml2::xml_find_first(tx, ".//transactionPricePerShare/value")))
    ad <- xml2::xml_text(xml2::xml_find_first(tx, ".//transactionAcquiredDisposedCode/value"))
    date <- xml2::xml_text(xml2::xml_find_first(tx, ".//transactionDate/value"))
    out[[length(out) + 1L]] <- data.frame(
      period_of_report = period, transaction_date = date,
      table = "non-derivative", code = code,
      shares = shares, price = price, ad_code = ad
    )
  }
  # Derivative transactions (option exercise = M, etc.)
  dt <- xml2::xml_find_all(doc, "//derivativeTransaction")
  for (tx in dt) {
    code <- xml2::xml_text(xml2::xml_find_first(tx, ".//transactionCode"))
    shares <- as.numeric(xml2::xml_text(xml2::xml_find_first(tx, ".//transactionShares/value")))
    price <- as.numeric(xml2::xml_text(xml2::xml_find_first(tx, ".//transactionPricePerShare/value")))
    ad <- xml2::xml_text(xml2::xml_find_first(tx, ".//transactionAcquiredDisposedCode/value"))
    date <- xml2::xml_text(xml2::xml_find_first(tx, ".//transactionDate/value"))
    out[[length(out) + 1L]] <- data.frame(
      period_of_report = period, transaction_date = date,
      table = "derivative", code = code,
      shares = shares, price = price, ad_code = ad
    )
  }
  if (length(out) == 0L) return(NULL)
  do.call(rbind, out)
}

idx <- read.csv(file.path(CACHE, "huang_2025_form4_index.csv"),
                stringsAsFactors = FALSE)
cat("Fetching", nrow(idx), "Form 4 XMLs...\n")
xml_paths <- file.path(CACHE, paste0(gsub("-", "", idx$accession), ".xml"))
for (i in seq_along(xml_paths)) {
  fetch_one(idx$accession[i], idx$primary[i], xml_paths[i])
  if (i %% 10 == 0) cat("  fetched", i, "/", length(xml_paths), "\n")
}

cat("\nParsing...\n")
parsed <- lapply(xml_paths, parse_form4)
all_tx <- do.call(rbind, parsed)
cat("total transactions:", nrow(all_tx), "\n")
print(table(all_tx$table, all_tx$code))

cat("\nFiltering to calendar-year 2025 transactions (by transaction_date):\n")
all_tx$transaction_date <- as.Date(all_tx$transaction_date)
y2025 <- all_tx[format(all_tx$transaction_date, "%Y") == "2025", ]
cat("# 2025 transactions:", nrow(y2025), "\n")

cat("\nAggregate by code (USD, in millions):\n")
y2025$dollars <- y2025$shares * y2025$price
agg <- aggregate(dollars ~ table + code + ad_code, data = y2025, sum)
agg$dollars_m <- round(agg$dollars / 1e6, 2)
print(agg[, c("table", "code", "ad_code", "dollars_m")])

cat("\n--- Comparison to data_sec_top4 (Huang, 2025) ---\n")
sale_codes   <- c("S", "F")   # Open-market sale + tax-withholding sale
gift_codes   <- c("G")
purch_codes  <- c("P")
sale_total <- sum(y2025$dollars[y2025$table == "non-derivative" &
                                  y2025$code %in% sale_codes &
                                  y2025$ad_code == "D"]) / 1e6
gift_total <- sum(y2025$dollars[y2025$table == "non-derivative" &
                                  y2025$code %in% gift_codes &
                                  y2025$ad_code == "D"]) / 1e6
gift_shares <- sum(y2025$shares[y2025$table == "non-derivative" &
                                  y2025$code %in% gift_codes &
                                  y2025$ad_code == "D"])
purch_total <- sum(y2025$dollars[y2025$table == "non-derivative" &
                                   y2025$code %in% purch_codes &
                                   y2025$ad_code == "A"]) / 1e6
cat("EDGAR-derived ($M, 2025):\n")
cat("  sale (codes S+F, disposed):", round(sale_total, 2), "\n")
cat("  donation (code G, shares):", gift_shares,
    " (sum of price*shares is 0 since G price=0; use mean stock price)\n")
cat("  purchase (code P, acquired):", round(purch_total, 2), "\n")

# Save aggregated transactions for downstream comparison
saveRDS(y2025, file.path(CACHE, "huang_2025_transactions.rds"))
cat("\nSaved", nrow(y2025), "transactions to",
    file.path(CACHE, "huang_2025_transactions.rds"), "\n")
