# Vintage resolution + the small set of literals that differ between the May
# and August BSZ_MainTablesFigures.xlsx workbooks.
#
# `xlsx_path_default()` (R/ingest_excel.R) already resolves which workbook to
# read from BSZ_VINTAGE. Everything below keys off the SAME env var so a
# single override switches both the file path and every vintage-dependent
# literal/column-letter/row-offset together.
#
# August inserted rows and reshuffled columns in several raw sheets
# (shortrunseries, billionairesCAinctax) and changed several formulas
# (Tab1/TabA1's GDP->AGI denominator, the top .0002%->.001% percentile). We
# resolve those here, in one place, rather than scattering `if` statements
# through the compute_*/build_* files.

bsz_vintage <- function() {
  v <- Sys.getenv("BSZ_VINTAGE", unset = "august")
  if (identical(v, "may")) "may" else "august"
}

# ---------------------------------------------------------------------------
# shortrunseries: column letters, keyed by concept name.
#
# August restructured the sheet (new AGI + total-tax content inserted
# mid-sheet, "Top 5" relabelled "Top 4"); the year PANEL rows (6:13 = 2018:
# 2025) are unchanged in both vintages, but almost every column letter moved
# non-uniformly (confirmed cell-by-cell against both workbooks, see
# VERIFY-AUGUST.md). `NULL`/absent means the column does not exist in that
# vintage: August dropped the separate "CA wealth, US citizens only" memo
# column entirely; compute_shortrunseries.R falls back to the already-
# computed `C_wealth` (the same total the sheet's own August formulas fall
# back to - verified against Excel's cached ratios).
# ---------------------------------------------------------------------------
.SRS_COL <- list(
  may = c(
    K_ellison = "K", Q_us_wealth = "Q", V_share = "V",
    top5_total = "E", top5_wavoid = "F", top5_company = "G", share_public = "H",
    n_us_citizen = "I", n_ca = "J", share_ellison = "L", yoy_growth = "M",
    cum2019 = "N", cum2022 = "O", cum2023 = "P",
    top5_yoy = "R", top5_cum2019 = "S", top5_cum2022 = "T",
    ca_inctax = "X", ca_inctax_per_wealth = "Y", ca_inctax_total = "Z", ca_inctax_share = "AA",
    top5_sec_rate = "AD", top5_sec_inctax = "AE", top5_sec_share = "AF",
    top3_sum = "AG", top2_sum = "AH",
    brin = "AJ", page = "AK", zuck = "AL", ellison = "AM", huang = "AN"
  ),
  august = c(
    K_ellison = "R", Q_us_wealth = "X", V_share = "AC",
    top5_total = "K", top5_wavoid = "L", top5_company = "N", share_public = "O",
    n_us_citizen = "P", n_ca = "Q", share_ellison = "S", yoy_growth = "T",
    cum2019 = "U", cum2022 = "V", cum2023 = "W",
    top5_yoy = "Y", top5_cum2019 = "Z", top5_cum2022 = "AA",
    ca_inctax = "AF", ca_inctax_per_wealth = "AH", ca_inctax_total = "AI", ca_inctax_share = "AJ",
    top5_sec_rate = "AO", top5_sec_inctax = "AP", top5_sec_share = "AQ",
    top3_sum = "AR", top2_sum = "AS",
    brin = "AU", page = "AV", zuck = "AW", ellison = "AX", huang = "AY"
  )
)

srs_col <- function(name, vintage = bsz_vintage()) {
  col <- .SRS_COL[[vintage]][[name]]
  if (is.null(col)) stop("No shortrunseries column mapped for '", name, "' in vintage '", vintage, "'")
  unname(col)
}

# shortrunseries' bottom "2025 snapshot / averages / ratios / totals / public
# share" block (5 stacked mini-tables) shifted down by exactly 2 rows in
# August (a new numeric-2026 row plus a blank spacer were inserted between
# the year panel and this block). Row LETTERS within the block shifted too
# (see .SRS_COL); this only matters for the row literal itself.
srs_summary_row <- function(row_may, vintage = bsz_vintage()) {
  if (identical(vintage, "may")) return(row_may)
  row_may + 2L
}

# shortrunseries' growth-summary block (base-year rows) shifted the same +2.
srs_growth_row <- function(row_may, vintage = bsz_vintage()) srs_summary_row(row_may, vintage)

# ---------------------------------------------------------------------------
# billionairesCAinctax: a single new row ("Average income tax rate...") was
# inserted at row 16 in August, and a second new row ("Property taxes on
# passthrough") at old-row 144's position. Every other row is untouched.
# Verified against both workbooks' column-A row labels (see VERIFY-AUGUST.md
# Resolution section) for the full 8-153 range this file reads.
# ---------------------------------------------------------------------------
bci_row <- function(row_may, vintage = bsz_vintage()) {
  if (identical(vintage, "may")) return(row_may)
  if (row_may <= 15L) row_may
  else if (row_may <= 143L) row_may + 1L
  else row_may + 2L
}

# Vintage-aware single-cell reader for billionairesCAinctax: takes an
# May-numbered address like "G16" and remaps only the row via bci_row()
# before reading. Column letters are unaffected by the August insertion (it
# added ROWS, not columns) so no column remapping is needed here.
bci_cell <- function(bci, addr_may, vintage = bsz_vintage()) {
  m <- regmatches(addr_may, regexec("^([A-Z]+)([0-9]+)$", addr_may))[[1]]
  col <- m[2]
  row <- bci_row(as.integer(m[3]), vintage)
  xls_cell(bci, paste0(col, row))
}

# ---------------------------------------------------------------------------
# billionairesCAinctax all-taxes block: the "11% gross-up on public assets
# for diversified holdings" constant (row 116/117) itself changed to 9.5% in
# August (a genuine parameter update by the authors, not a layout artifact -
# confirmed by the row's own label text: "11% gross up..." -> "9.5% gross
# up...").
# ---------------------------------------------------------------------------
bci_sales_gross_up_rate <- function(vintage = bsz_vintage()) {
  if (identical(vintage, "may")) 0.11 else 0.095
}

# ---------------------------------------------------------------------------
# compute_tab5: Tab5's own benchmark row (n_billionaires, wealth) and the
# scenario-3 per-leaver wealth breakouts (Tab5 rows 20-29) are literals
# hand-entered in the workbook from a specific Forbes snapshot date; they
# moved between vintages (May: Forbes as of 4/15/2026; August: 7/1/2026).
# Private-wealth splits and the leavers with unchanged wealth (Hankey,
# Kalanick, Fang) did not move. Verified against both workbooks' Tab5 sheet
# formulas/literals directly (openpyxl, data_only=False).
# ---------------------------------------------------------------------------
.TAB5_CONST <- list(
  may = list(
    baseline_n = 249, baseline_wealth = 2182,
    page_wealth_B = 276,   page_private_B = 13.4,
    thiel_wealth_B = 28.9,
    hankey_wealth_B = 8.15,
    kalanick_wealth_B = 3.56,
    brin_wealth_B = 254.6, brin_private_B = 13.2,
    zuck_wealth_B = 230.2, zuck_private_B = 2.5,
    fang_wealth_B = 1.5,
    huang_wealth_B = 172,  huang_private_B = 2.84
  ),
  august = list(
    baseline_n = 250, baseline_wealth = 2307,
    page_wealth_B = 294.6, page_private_B = 13.4,
    thiel_wealth_B = 27.3,
    hankey_wealth_B = 8.15,
    kalanick_wealth_B = 3.56,
    brin_wealth_B = 271.7, brin_private_B = 13.2,
    zuck_wealth_B = 210.3, zuck_private_B = 2.5,
    fang_wealth_B = 1.5,
    huang_wealth_B = 170.9, huang_private_B = 2.84
  )
)

tab5_const <- function(name, vintage = bsz_vintage()) .TAB5_CONST[[vintage]][[name]]

# ---------------------------------------------------------------------------
# Tab1/TabA1 Panel A "top4/5 wealth" column feeding from shortrunseries, and
# the GDP->AGI denominator swap (RC4), and the top .0002%->.001% + 2025->2026
# endpoint redefinition of Panel B (RC6). Exact formulas read directly from
# both workbooks (openpyxl, data_only=False); see VERIFY-AUGUST.md.
#
# May Panel B (1982 row 8, "current" row 51):
#   families = longrunseries!AL<row>            (CA, top .0002%)
#   wealth   = longrunseries!AQ<row> * W8/W51    (CA, top .0002%, real 2025$)
#   gdp      = longrunseries!AT<row> * W8/W51    (CA GDP, real 2025$)
# August Panel B (1982 row 8, "current" row 52):
#   families = longrunseries!AL<row> * 5         (CA, top .001% = 5x .0002%)
#   wealth   = longrunseries!BT<row>             (CA, top .001%, ALREADY real 2026$)
#   agi      = longrunseries!BA<row> * W<row>/W52 (CA AGI, real 2026$)
#
# TabA1 (US) mirrors this: May uses AM (families)/AP (wealth)/AS (GDP) at
# W8/W51; August uses AM*5 / [longrunseries!G<row>*BQ<row>*W<row>/W52] (US
# top .001% wealth, via the US GDP * (top.001%/GDP) Pareto ratio the
# workbook itself uses) / AV<row>*W<row>/W52 (US AGI, real).
# ---------------------------------------------------------------------------
lrs_current_row <- function(vintage = bsz_vintage()) if (identical(vintage, "may")) 51L else 52L
lrs_base_row <- 8L  # 1982, unchanged both vintages
