# Phase 1.5 POC: SEC EDGAR ↔ `data_sec_top4` cross-validation

**Entity / year:** Jensen Huang (CIK 0001197649) / 2025 calendar year.
**Source:** 34 Form 4 filings, fetched from `data.sec.gov` and
`www.sec.gov/Archives/edgar/data/1197649/<accession>/<file>.xml`.
**Script:** `data-raw/sec/fetch_huang_2025.R`.

## Results

| Metric | EDGAR (raw Form 4) | `data_sec_top4` (BSZ) | Match? |
|---|---:|---:|---|
| Purchase ($M) | 0 | 0 | ✅ exact |
| Sale ($M), code S only (open-market sale) | 1,048.59 | 1,048.59 | ✅ exact |
| Sale ($M), codes S + F (incl. tax-withholding) | 1,118.65 | n/a | ⚠️ Excel excludes F |
| Donation (shares) | 1,926,488 | implied via $/share | needs date-by-date price |
| Donation ($M) | not directly observable in Form 4 (price=0 for gifts) | 314.83 | needs daily NVDA close |

## What we learned

1. **The Excel `sale` column is faithful to SEC raw data** when interpreted as
   "open-market sales only" (transaction code `S` with `transactionAcquiredDisposedCode = D`). Code `F` (shares withheld for tax-related withholding on RSU vesting) is excluded; this is the standard convention.
2. **`purchase` = 0 is verified.** Huang made no open-market acquisitions in
   2025.
3. **Donations (`G` code) are reported in shares only**, with
   `transactionPricePerShare = 0` per SEC convention. To match Excel's $314.83M
   donation value, the workbook must be multiplying shares by the daily NVDA
   close on each donation date. The implied average is $163.4/share over
   1.93M shares, consistent with NVDA closing prices through 2025.

## Implications for full Phase 1.5

- **Recommended next step:** add per-day close-price lookup for donations (via
  e.g. Tiingo, AlphaVantage, or yfinance) and verify donation $ values to
  ~1e-2 tolerance for each top-4 billionaire-year.
- **Other transaction codes to track:** `M` (option exercise, feeds
  `option_profit`), `A` (RSU vesting, sometimes feeds `noneq_comp`), `J`
  (other: small adjustments).
- **The fetch pattern works** with SEC's public API + polite User-Agent. No
  authentication required. Rate-limit `Sys.sleep(0.15)` per request was
  sufficient for 34 filings.

## Schema cheat-sheet

```
<ownershipDocument>
  <periodOfReport>YYYY-MM-DD</periodOfReport>
  <reportingOwner><reportingOwnerId><rptOwnerCik>...
  <nonDerivativeTable>
    <nonDerivativeTransaction>
      <transactionDate><value>YYYY-MM-DD</value></transactionDate>
      <transactionCoding><transactionCode>S|P|F|G|A|...</transactionCode></...>
      <transactionAmounts>
        <transactionShares><value>N</value></transactionShares>
        <transactionPricePerShare><value>P</value></transactionPricePerShare>
        <transactionAcquiredDisposedCode><value>A|D</value></...>
      </...>
    </...>
  </...>
  <derivativeTable>
    <derivativeTransaction>...similar shape, plus exercise/expiration dates...
```

## Files cached

- `cache/huang_submissions.json`: full submissions index from data.sec.gov
- `cache/huang_2025_form4_index.csv`: 34-row table of accession + primary doc
- `cache/0001*-25-*.xml`: 34 raw Form 4 XML files
- `cache/huang_2025_transactions.rds`: parsed 391-row transaction table

The cache directory is gitignored; re-run `Rscript data-raw/sec/fetch_huang_2025.R`
to regenerate.
