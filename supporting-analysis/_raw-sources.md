The Excel workbook combines several public and proprietary inputs.
Independent re-pulls from each primary source (to cross-check the workbook's
cached values) are an ongoing strand of this project. Status:

| Raw source | Workbook sheet it feeds | Status |
|---|---|---|
| SEC EDGAR Form 4 (insider transactions) | `data_sec_top4`, `data_sec_all`, `data_sec_agg` | **POC done**: Huang 2025 only. `sale` matches exactly; donation $ requires per-day stock close prices (deferred). Other top-4 billionaires and earlier years not yet pulled. |
| BEA SAGDP / SQGDP macro series (CA + US GDP, deflators) | `longrunseries` cols AS, AT, W | **Not pulled** |
| California FTB Personal Income Tax Statistics (B4A bracket detail) | `ftb_b4a` | **Not pulled** (workbook ships its own copy; data.ca.gov may have newer release) |
| Saez-Zucman DINA tables (US-wide + CA-wide effective tax rates) | `data_dina` (cols K, S) | **Not pulled** |
| IRS SOI Top .001% income statistics | `billionairesCAinctax` rows 59-72 | **Not pulled** (literal pass-through from authors' compilation) |
| Forbes Real-Time Billionaires snapshots | `shortrunseries` cols B, K, Q | **Not pulled** (no public historical archive) |
| ProPublica IRS leak | `data_sec_propublica` | **Cannot be re-pulled**: restricted-access data |
| Compustat (corporate financials feeding SEC top-4 columns) | parts of `data_sec_top4` | **Cannot be re-pulled here**: paywalled |

**Interpretation.** The R pipeline verifies that R reproduces the Excel
cells. The cross-validation work (in progress) verifies that the Excel
cells in turn reproduce the public raw data. Until that second layer is
complete, the replication is "faithful to the authors' workbook" but not
yet "independently sourced from underlying public data" for most series.
