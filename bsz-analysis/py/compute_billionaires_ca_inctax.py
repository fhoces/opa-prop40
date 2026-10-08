"""Python twin of R/compute_billionaires_ca_inctax.R: the billionairesCAinctax
sheet (CA income tax paid by CA billionaires).

Four blocks, as in R: Method I year panel (rows 6-55), Memo 1 (US top .001%
IRS Pareto calibration, rows 58-72), Memo 2 robustness check (rows 76-105)
and the all-taxes block (rows 110-153). Row numbers in comments are the May
numbering the R file uses; vintage.bci_cell() remaps them for August.

Indexing: R vectors here are 1-based and aligned to years (panel 2018..2026
has 9 slots, the top-bracket block 2018..2023 has 6). numpy arrays are
0-based, so R's x[4] (2021) is x[3] below; each line keeps R's index in a
comment where it matters. R's `x[1:3]` is x[0:3].

The FTB table goes through the shared query sql/03_ftb_b4a.sql
(workbook_db.query_ftb_b4a) when the raw sheet is passed in.
"""
import numpy as np
import pandas as pd

from excel_cells import xls_cells_row
from vintage import bci_cell, bci_row, bci_sales_gross_up_rate, bsz_vintage
from workbook_db import query_ftb_b4a

NA = np.nan

AGG_MAP = {
    "C": "forbes_worth", "D": "forbes_public_worth",
    "S": "ca_income_tax", "V": "fed_income_tax",
    "AB": "sales_tax", "AC": "w_txt",
    "AD": "w_tax_ppent", "AF": "total_tax",
    "AG": "economic_income",
}

# Sheet columns of the FTB table: D all returns, H CA AGI, J taxable income,
# K total tax (R: .BCI_FTB_COLS).
FTB_COLS = {"D": "all_returns", "H": "ca_agi", "J": "taxable_income", "K": "total_tax"}

# FTB statistics for 2023 the workbook hand-enters (ftb_b4a ends in 2022).
FTB_2023 = dict(
    ca_agi_b=1946170 / 1000,      # G14
    ca_inctax_b=97293 / 1000,     # G15
    top_5m_9m_returns=7463,       # G32
    top_5m_9m_agi_b=51.097,       # G33
    top_5m_9m_tax_b=48.479,       # G34
    top_5m_9m_inctax_b=4.347,     # G35
)

PAN_COLS = ["B", "C", "D", "E", "F", "G", "H", "I", "J"]


def _rmean(x):
    return float(np.mean(np.asarray(x, dtype=float)))


def make_agg(agg_r):
    def agg(letter):
        return agg_r[AGG_MAP[letter]].to_numpy(float)
    return agg


def make_ftb(ftb_b4a):
    """`ftb_b4a` is query 3's result (dict with "year" and "top") or the raw
    positional sheet, which goes through the same query in memory."""
    q = ftb_b4a if isinstance(ftb_b4a, dict) else query_ftb_b4a(ftb_b4a)
    yr_df, top_df = q["year"], q["top"]

    def sum_year(col, yr, scale=1):
        v = yr_df.loc[yr_df["taxable_year"] == yr, FTB_COLS[col]]
        if len(v) != 1:
            raise ValueError(f"ftb_b4a: no single row for taxable year {yr}")
        return float(v.iloc[0]) * scale

    def top(bracket, yr, col):
        v = top_df.loc[(top_df["taxable_year"] == yr) & (top_df["bracket"] == bracket), FTB_COLS[col]]
        if len(v) != 1:
            raise ValueError(f"ftb_b4a: no single {bracket} row for taxable year {yr}")
        return float(v.iloc[0])

    return {"sum_year": sum_year, "top": top}


# ---------------------------------------------------------------------------
# Memo 1: US top .001% IRS Pareto calibration (rows 58-72)
# ---------------------------------------------------------------------------

def bci_memo1(bci):
    m1_cols = ["B", "C", "D", "E", "F"]          # IRS years 2018..2022

    def read_row(row):
        return xls_cells_row(bci, m1_cols, bci_row(row))

    n_returns = read_row(59)
    agi_cutoff_k = read_row(60)
    agi_avg_k = read_row(61)
    fed_tax_total_m = read_row(63)
    top10m_n = read_row(66)
    top10m_cutoff_k = read_row(67)
    top10m_agi_avg_k = read_row(68)

    pareto_b_001 = agi_avg_k / agi_cutoff_k                                   # row 62
    fed_tax_per_agi = 1000 * (fed_tax_total_m / n_returns) / agi_avg_k        # row 64
    pareto_b_10m = top10m_agi_avg_k / top10m_cutoff_k                         # row 69
    proj_cutoff_001 = top10m_cutoff_k * (top10m_n / n_returns) ** (1 - 1 / pareto_b_10m)  # row 70
    proj_agi_001 = proj_cutoff_001 * pareto_b_10m                             # row 71
    pct_overshoot = (proj_agi_001 - agi_avg_k) / proj_agi_001                 # row 72

    memo1 = pd.DataFrame({
        "year": np.arange(2018, 2023),
        "n_returns": n_returns, "agi_cutoff_k": agi_cutoff_k, "agi_avg_k": agi_avg_k,
        "pareto_b_001": pareto_b_001, "fed_tax_total_m": fed_tax_total_m,
        "fed_tax_per_agi": fed_tax_per_agi, "n_returns_10m": top10m_n,
        "agi_cutoff_10m_k": top10m_cutoff_k, "agi_avg_10m_k": top10m_agi_avg_k,
        "pareto_b_10m": pareto_b_10m, "proj_cutoff_001_k": proj_cutoff_001,
        "proj_agi_001_k": proj_agi_001, "pct_overshoot": pct_overshoot,
    })
    # Panel years 2018..2023; 2023 repeats 2022 (G72 = F72).
    pct_by_panel_year = np.append(pct_overshoot, pct_overshoot[4])
    return {"memo1": memo1, "fed_tax_per_agi": fed_tax_per_agi, "pct_overshoot": pct_by_panel_year}


# ---------------------------------------------------------------------------
# Block B: aggregate CA income tax stats (rows 13-21)
# ---------------------------------------------------------------------------

def bci_aggregate_stats(bci, ftb, tax_rate_5m, vintage=None):
    vintage = vintage or bsz_vintage()

    def cell(addr):
        return bci_cell(bci, addr, vintage)

    ftb_yrs = range(2018, 2023)
    # Row 13: # returns; row 14: CA AGI ($B); 2023 literal; 2024-2026 NA.
    n_returns_ca = np.array([ftb["sum_year"]("D", y) for y in ftb_yrs] + [NA] * 4)
    ca_agi_b = np.array([ftb["sum_year"]("H", y, 1e-9) for y in ftb_yrs]
                        + [FTB_2023["ca_agi_b"]] + [NA] * 3)
    # Row 15 base (CA inctax residents $B), 2018..2023.
    resid_base = np.array([ftb["sum_year"]("K", y, 1e-9) for y in ftb_yrs]
                          + [FTB_2023["ca_inctax_b"]])

    passthrough_2023 = cell("G16")

    if vintage == "may":
        # Row 16: G16 literal; F16 = G16 * F15 / G15; E16 = F16.
        F16 = passthrough_2023 * resid_base[4] / resid_base[5]
        E16 = F16
        pre_part16 = np.array([NA, NA, NA, E16, F16, passthrough_2023])
        resid_pre = resid_base.copy()
        F17 = cell("F17")
        ratio = F17 / resid_pre[4]
        pre_part17 = np.concatenate([resid_pre[0:4] * ratio, [F17], [resid_pre[5] * ratio]])
        # R: ifelse(is.na(pre_part16), 0, pre_part16)
        total_pre = resid_pre + np.where(np.isnan(pre_part16), 0, pre_part16) + pre_part17
    else:
        # August folds the passthrough into row 15 for 2021-2023; 2021's
        # passthrough scales off the $5M-bracket tax RATE (R: tax_rate_5m[3],
        # [4], [6] = 2020, 2021, 2023).
        passthrough_2022 = passthrough_2023
        passthrough_2021 = (passthrough_2022 * (tax_rate_5m[2] - tax_rate_5m[3])
                            / (tax_rate_5m[2] - tax_rate_5m[5]))
        pre_part16 = np.full(6, NA)
        resid_pre = resid_base.copy()
        resid_pre[3] = resid_base[3] + passthrough_2021
        resid_pre[4] = resid_base[4] + passthrough_2022
        resid_pre[5] = resid_base[5] + passthrough_2023
        F_partyear = cell("F17")
        ratio = F_partyear / resid_pre[4]
        pre_part17 = np.concatenate([resid_pre[0:4] * ratio, [F_partyear], [resid_pre[5] * ratio]])
        total_pre = resid_pre + pre_part17

    # Row 20 (May) / 21 (August): CA inctax revenue, fiscal year ($B), literal.
    ca_inctax_fy_b = xls_cells_row(bci, PAN_COLS, bci_row(20, vintage))

    total_full = np.zeros(9)
    total_full[0:6] = total_pre
    fy_to_cy = np.zeros(9)
    fy_to_cy[0:6] = total_pre / ca_inctax_fy_b[0:6] - 1
    fy_to_cy[6] = _rmean(fy_to_cy[2:6])          # R: mean(fy_to_cy_adj[3:6])
    fy_to_cy[7] = fy_to_cy[6]
    total_full[6] = ca_inctax_fy_b[6] * (1 + fy_to_cy[6])
    total_full[7] = ca_inctax_fy_b[7] * (1 + fy_to_cy[7])
    total_full[8] = NA

    total_2023, total_2024, total_2025 = total_full[5], total_full[6], total_full[7]
    partyear_2023 = pre_part17[5]
    partyear_2024 = partyear_2023 * (total_2024 / total_2023)
    partyear_2025 = partyear_2023 * (total_2025 / total_2023)
    resid_2024 = total_2024 - partyear_2024
    resid_2025 = total_2025 - partyear_2025

    return {
        "n_returns_ca": n_returns_ca,
        "ca_agi_b": ca_agi_b,
        "ca_inctax_resid_b": np.concatenate([resid_pre, [resid_2024, resid_2025, NA]]),
        "ca_inctax_part16": np.concatenate([pre_part16, [NA, NA, NA]]),
        "ca_inctax_part17": np.concatenate([pre_part17, [partyear_2024, partyear_2025, NA]]),
        "ca_inctax_total_full": total_full,
        "ca_inctax_fy_b": ca_inctax_fy_b,
        "fy_to_cy_adj": fy_to_cy,
        "H15": resid_2024,
        "I15": resid_2025,
    }


# ---------------------------------------------------------------------------
# Block C: top-bracket Pareto projection (rows 26-44), years 2018..2023
# ---------------------------------------------------------------------------

def bci_top_brackets(bci, ftb, n_ca_b, pct_overshoot_yr):
    def cell(addr):
        return bci_cell(bci, addr)

    top = ftb["top"]
    scale_b = 1e-9

    # $10M+ bracket (rows 26-31): 2021/2022 from FTB, 2023 literal G26..G29.
    n_ret_10m = np.full(6, NA)
    agi_10m_b = np.full(6, NA)
    taxable_10m_b = np.full(6, NA)
    tax_10m_b = np.full(6, NA)
    for i in (3, 4):                       # R i_year 4, 5 = 2021, 2022
        yr = 2018 + i
        n_ret_10m[i] = top("10m_plus", yr, "D")
        agi_10m_b[i] = top("10m_plus", yr, "H") * scale_b
        taxable_10m_b[i] = top("10m_plus", yr, "J") * scale_b
        tax_10m_b[i] = top("10m_plus", yr, "K") * scale_b
    n_ret_10m[5] = cell("G26")
    agi_10m_b[5] = cell("G27")
    taxable_10m_b[5] = cell("G28")
    tax_10m_b[5] = cell("G29")

    tax_rate_10m = tax_10m_b / taxable_10m_b                  # row 30
    pareto_b_10m = 1000 * agi_10m_b / (10 * n_ret_10m)        # row 31

    # $5M+ bracket (rows 32-37).
    n_ret_5m = np.zeros(6)
    agi_5m_b = np.zeros(6)
    taxable_5m_b = np.zeros(6)
    tax_5m_b = np.zeros(6)
    for i in (0, 1, 2):                    # 2018-2020: one $5M+ row
        yr = 2018 + i
        n_ret_5m[i] = top("5m_plus", yr, "D")
        agi_5m_b[i] = top("5m_plus", yr, "H") * scale_b
        taxable_5m_b[i] = top("5m_plus", yr, "J") * scale_b
        tax_5m_b[i] = top("5m_plus", yr, "K") * scale_b
    for i in (3, 4):                       # 2021-2022: $5M-$9.999M + $10M+
        yr = 2018 + i
        n_ret_5m[i] = top("5m_to_10m", yr, "D") + top("10m_plus", yr, "D")
        agi_5m_b[i] = agi_10m_b[i] + top("5m_to_10m", yr, "H") * scale_b
        taxable_5m_b[i] = taxable_10m_b[i] + top("5m_to_10m", yr, "J") * scale_b
        tax_5m_b[i] = tax_10m_b[i] + top("5m_to_10m", yr, "K") * scale_b
    n_ret_5m[5] = FTB_2023["top_5m_9m_returns"] + n_ret_10m[5]
    agi_5m_b[5] = agi_10m_b[5] + FTB_2023["top_5m_9m_agi_b"]
    taxable_5m_b[5] = taxable_10m_b[5] + FTB_2023["top_5m_9m_tax_b"]
    tax_5m_b[5] = tax_10m_b[5] + FTB_2023["top_5m_9m_inctax_b"]

    tax_rate_5m = tax_5m_b / taxable_5m_b                     # row 36
    pareto_b_5m = 1000 * agi_5m_b / (5 * n_ret_5m)            # row 37

    # Row 38: projected cutoff ($M) for the top-N-th taxpayer.
    n6 = n_ca_b[0:6]
    proj_cutoff_top = np.zeros(6)
    proj_cutoff_top_5m = 5 * (n_ret_5m / n6) ** (1 - 1 / pareto_b_5m)
    for i in (3, 4, 5):
        proj_cutoff_top[i] = 10 * (n_ret_10m[i] / n_ca_b[i]) ** (1 - 1 / pareto_b_10m[i])
    F38, F41 = proj_cutoff_top[4], proj_cutoff_top_5m[4]
    for i in (0, 1, 2):
        proj_cutoff_top[i] = proj_cutoff_top_5m[i] * (F38 / F41)

    # Row 39: projected AGI ($B) for the top taxpayer.
    proj_agi_top = np.zeros(6)
    proj_agi_top_5m = 0.001 * proj_cutoff_top_5m * pareto_b_5m * n6
    for i in (3, 4, 5):
        proj_agi_top[i] = 0.001 * proj_cutoff_top[i] * pareto_b_10m[i] * n_ca_b[i]
    F39, F42 = proj_agi_top[4], proj_agi_top_5m[4]
    for i in (0, 1, 2):
        proj_agi_top[i] = proj_agi_top_5m[i] * (F39 / F42)

    # Row 40: projected tax ($B): 5M tax rate for 2018-2020, 10M for 2021-2023.
    proj_tax_top = np.zeros(6)
    for i in (0, 1, 2):
        proj_tax_top[i] = proj_agi_top[i] * (tax_5m_b[i] / agi_5m_b[i])
    for i in (3, 4, 5):
        proj_tax_top[i] = proj_agi_top[i] * (tax_10m_b[i] / agi_10m_b[i])

    # Rows 43-44: overshoot correction.
    proj_agi_top_corr = proj_agi_top * (1 - pct_overshoot_yr)
    proj_tax_top_corr = proj_tax_top * (1 - pct_overshoot_yr)
    avg_tax_rate_5m_bcd = _rmean(tax_rate_5m[0:3])
    for i in (3, 4, 5):
        proj_tax_top_corr[i] = proj_tax_top_corr[i] * avg_tax_rate_5m_bcd / tax_rate_10m[i]

    return dict(
        n_ret_10m=n_ret_10m, agi_10m_b=agi_10m_b, taxable_10m_b=taxable_10m_b,
        tax_10m_b=tax_10m_b, tax_rate_10m=tax_rate_10m, pareto_b_10m=pareto_b_10m,
        n_ret_5m=n_ret_5m, agi_5m_b=agi_5m_b, taxable_5m_b=taxable_5m_b,
        tax_5m_b=tax_5m_b, tax_rate_5m=tax_rate_5m, pareto_b_5m=pareto_b_5m,
        proj_cutoff_top=proj_cutoff_top, proj_agi_top=proj_agi_top,
        proj_tax_top=proj_tax_top, proj_cutoff_top_5m=proj_cutoff_top_5m,
        proj_agi_top_5m=proj_agi_top_5m, proj_agi_top_corr=proj_agi_top_corr,
        proj_tax_top_corr=proj_tax_top_corr,
    )


# ---------------------------------------------------------------------------
# Memo 2 robustness check (rows 76-105)
# ---------------------------------------------------------------------------

def bci_robustness(bci, D99, ca_inctax_ca_b, tax_5m_b, agi_5m_b):
    def cell(addr):
        return bci_cell(bci, addr)

    B96 = cell("B96")
    B100 = D99 * B96 * _rsum(tax_5m_b[0:3]) / _rsum(agi_5m_b[0:3])
    B101 = cell("B101")
    B102 = B101 * B100 / 1e6
    B103 = _rmean(ca_inctax_ca_b[0:3])
    B104 = _rmean([cell("D104"), cell("E104"), cell("F104")])
    B105 = B102 * B103 / B104
    C105 = B105 / B103 - 1
    return dict(D99=D99, B100=B100, B102=B102, B103=B103, B104=B104, B105=B105, C105=C105)


def _rsum(x):
    """R's sum(): left to right from 0."""
    s = 0.0
    for v in x:
        s += float(v)
    return s


# ---------------------------------------------------------------------------
# All-taxes block (rows 110-153)
# ---------------------------------------------------------------------------

def bci_all_taxes(yrs, proj_agi_top_corr, inc_top_w_rel, ca_inctax_ca_b,
                  m1_fed_tax_per_agi, D99, agg, public_share_b, total_w_ca, vintage=None):
    vintage = vintage or bsz_vintage()

    # Row 111: CA AGI of CA Forbes billionaires.
    ca_agi_bill = np.zeros(9)
    ca_agi_bill[0:6] = proj_agi_top_corr * inc_top_w_rel[0:6]
    ca_agi_bill[6] = ca_agi_bill[5] * ca_inctax_ca_b[6] / ca_inctax_ca_b[5]
    ca_agi_bill[7] = ca_agi_bill[5] * ca_inctax_ca_b[7] / ca_inctax_ca_b[5]
    ca_agi_bill[8] = NA

    # Row 113: federal income tax of billionaires; row 114 the fed/CA ratio.
    fed_inctax_b = np.zeros(9)
    fed_inctax_b[0:5] = m1_fed_tax_per_agi * ca_agi_bill[0:5] * D99
    fed_to_ca = np.full(9, NA)
    fed_to_ca[0:5] = fed_inctax_b[0:5] / ca_inctax_ca_b[0:5]
    fed_to_ca[5] = fed_to_ca[4]                      # G114 = F114
    fed_to_ca[6] = _rmean(fed_to_ca[0:3])            # H114 = AVERAGE(B114:D114)
    fed_to_ca[7] = fed_to_ca[6]                      # I114 = H114
    fed_inctax_b[5:8] = ca_inctax_ca_b[5:8] * fed_to_ca[5:8]
    fed_inctax_b[8] = NA

    public_share = public_share_b
    sales_gross_up_public = bci_sales_gross_up_rate(vintage) * public_share

    def pad(v):
        return np.concatenate([[NA], v, [NA]])

    ca_inctax_pub = pad(agg("S"))
    fed_inctax_pub = pad(agg("V"))
    corp_tax_pub = pad(agg("AC"))
    prop_tax_pub = pad(agg("AD"))
    sales_tax_pub = pad(agg("AB"))
    total_tax_pub = pad(agg("AF"))
    econ_income_pub = pad(agg("AG"))
    public_wealth_b = public_share * total_w_ca                 # row 123

    pw = public_wealth_b
    tot_tax_per_w = total_tax_pub / pw
    ca_inctax_per_w = ca_inctax_pub / pw
    fed_inctax_per_w = fed_inctax_pub / pw
    corp_per_w = corp_tax_pub / pw
    prop_sales_per_w = (prop_tax_pub + sales_tax_pub) / pw
    check_w = tot_tax_per_w - (ca_inctax_per_w + fed_inctax_per_w + corp_per_w + prop_sales_per_w)

    ei = econ_income_pub
    tot_tax_per_ei = total_tax_pub / ei
    ca_inctax_per_ei = ca_inctax_pub / ei
    fed_inctax_per_ei = fed_inctax_pub / ei
    corp_per_ei = corp_tax_pub / ei
    prop_sales_per_ei = (prop_tax_pub + sales_tax_pub) / ei
    check_ei = tot_tax_per_ei - (ca_inctax_per_ei + fed_inctax_per_ei + corp_per_ei + prop_sales_per_ei)

    private_share = 1 - public_share - sales_gross_up_public
    if vintage == "may":
        weight_passthrough, weight_private_c = 46.8 + 25, 61
    else:
        weight_passthrough, weight_private_c = 93, 116
    weight_total = weight_passthrough + weight_private_c
    passthrough_share = private_share * weight_passthrough / weight_total
    private_c_share = private_share * weight_private_c / weight_total
    test_share = public_share + sales_gross_up_public + passthrough_share + private_c_share

    corp_tax_priv_c = corp_tax_pub * (private_c_share / public_share)
    corp_tax_div = 0.11 * corp_tax_pub
    prop_tax_priv = (prop_tax_pub / corp_tax_pub) * (corp_tax_priv_c + corp_tax_div)
    if vintage == "may":
        prop_tax_passthrough = 0
    else:
        prop_tax_passthrough = prop_tax_pub * passthrough_share / (public_share + sales_gross_up_public)
    tot_corp_prop = ((corp_tax_pub + prop_tax_pub) + corp_tax_priv_c + corp_tax_div
                     + prop_tax_priv + prop_tax_passthrough)
    total_sales_tax = 0.03 * (ca_agi_bill - ca_inctax_ca_b - fed_inctax_b - 0.25 * ca_agi_bill) * 0.5
    total_inctax_b = ca_inctax_ca_b + fed_inctax_b
    total_taxes_b = tot_corp_prop + total_sales_tax + total_inctax_b

    tw = total_w_ca
    tot_per_total_w = total_taxes_b / tw
    ca_per_total_w = ca_inctax_ca_b / tw
    fed_per_total_w = fed_inctax_b / tw
    corp_per_total_w = (corp_tax_pub + corp_tax_priv_c + corp_tax_div) / tw
    ps_per_total_w = (prop_tax_pub + prop_tax_priv + total_sales_tax) / tw
    check_total = tot_per_total_w - (ca_per_total_w + fed_per_total_w + corp_per_total_w + ps_per_total_w)

    return pd.DataFrame({
        "year": yrs,
        "ca_agi_ca_billionaires_b": ca_agi_bill,
        "ca_inctax_ca_billionaires_b": ca_inctax_ca_b,
        "fed_inctax_ca_billionaires_b": fed_inctax_b,
        "fed_to_ca_inctax_ratio": fed_to_ca,
        "public_assets_share": public_share,
        "sales_gross_up_public": sales_gross_up_public,
        "ca_inctax_public_b": ca_inctax_pub,
        "fed_inctax_public_b": fed_inctax_pub,
        "corp_tax_public_b": corp_tax_pub,
        "property_tax_public_b": prop_tax_pub,
        "sales_tax_public_b": sales_tax_pub,
        "total_tax_public_b": total_tax_pub,
        "public_wealth_b": public_wealth_b,
        "total_tax_per_public_wealth": tot_tax_per_w,
        "ca_inctax_per_public_wealth": ca_inctax_per_w,
        "fed_inctax_per_public_wealth": fed_inctax_per_w,
        "corp_per_public_wealth": corp_per_w,
        "prop_sales_per_public_wealth": prop_sales_per_w,
        "check_decomp_public_wealth": check_w,
        "public_econ_income_b": econ_income_pub,
        "total_tax_per_econ_income": tot_tax_per_ei,
        "ca_inctax_per_econ_income": ca_inctax_per_ei,
        "fed_inctax_per_econ_income": fed_inctax_per_ei,
        "corp_per_econ_income": corp_per_ei,
        "prop_sales_per_econ_income": prop_sales_per_ei,
        "check_decomp_econ_income": check_ei,
        "private_share": private_share,
        "passthrough_share": passthrough_share,
        "private_c_share": private_c_share,
        "test_share_sum": test_share,
        "corp_tax_private_c_b": corp_tax_priv_c,
        "corp_tax_diversified_b": corp_tax_div,
        "property_tax_private_b": prop_tax_priv,
        "total_corp_property_b": tot_corp_prop,
        "total_sales_tax_b": total_sales_tax,
        "total_inctax_b": total_inctax_b,
        "total_taxes_b": total_taxes_b,
        "total_per_total_wealth": tot_per_total_w,
        "ca_inctax_per_total_wealth": ca_per_total_w,
        "fed_inctax_per_total_wealth": fed_per_total_w,
        "corp_per_total_wealth": corp_per_total_w,
        "prop_sales_per_total_wealth": ps_per_total_w,
        "check_total_decomp": check_total,
    })


# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

def compute_billionaires_ca_inctax(data_sec_agg_r, billionaires_ca_inctax, ftb_b4a):
    bci = billionaires_ca_inctax

    def cell(addr):
        return bci_cell(bci, addr)

    agg = make_agg(data_sec_agg_r)
    ftb = make_ftb(ftb_b4a)

    m1 = bci_memo1(bci)
    B96, B98 = cell("B96"), cell("B98")
    D99 = (B98 / B96) / _rmean(m1["fed_tax_per_agi"][0:3])

    yrs = np.arange(2018, 2027)
    n_ca_b = xls_cells_row(bci, PAN_COLS, bci_row(8))
    total_w_ca = np.concatenate([[NA], agg("C"), [NA]])
    avg_w_ca = total_w_ca / n_ca_b

    brk = bci_top_brackets(bci, ftb, n_ca_b, m1["pct_overshoot"])
    stats = bci_aggregate_stats(bci, ftb, tax_rate_5m=brk["tax_rate_5m"])

    inc_top_w_rel = np.array([cell("B46")] * 6 + [NA] * 3)
    corr_passthru = np.array([D99] * 6 + [NA] * 3)

    # Row 49 (CA inctax paid by CA Forbes billionaires), the main output.
    ca_inctax_ca_b = np.full(9, NA)
    ca_inctax_ca_b[0:6] = brk["proj_tax_top_corr"] * inc_top_w_rel[0:6] * corr_passthru[0:6]
    pct_by_b = np.zeros(9)
    pct_by_b[0:6] = ca_inctax_ca_b[0:6] / stats["ca_inctax_total_full"][0:6]
    pct_by_b[6] = _rmean(pct_by_b[0:6])      # H50 = AVERAGE(B50:G50)
    pct_by_b[7] = pct_by_b[3]                # I50 = E50 (2021)
    pct_by_b[8] = NA
    ca_inctax_ca_b[6] = pct_by_b[6] * stats["H15"]
    ca_inctax_ca_b[7] = pct_by_b[7] * stats["I15"]

    ca_inctax_b_per_w = ca_inctax_ca_b / total_w_ca
    ca_inctax_public_b = np.concatenate([[NA], agg("S"), [NA]])
    public_share_b = np.concatenate([[NA], agg("D") / agg("C"), [NA]])
    ca_inctax_public_per_b_b = ca_inctax_public_b / ca_inctax_ca_b

    def pad6(v):
        return np.concatenate([v, [NA, NA, NA]])

    method1 = pd.DataFrame({
        "year": yrs,
        "n_ca_billionaires": n_ca_b,
        "avg_wealth_ca_b": avg_w_ca,
        "total_wealth_ca_b": total_w_ca,
        "n_returns_ca": stats["n_returns_ca"],
        "ca_agi_b": stats["ca_agi_b"],
        "ca_inctax_residents_b": stats["ca_inctax_resid_b"],
        "ca_inctax_passthrough_b": stats["ca_inctax_part16"],
        "ca_inctax_partyear_nonres_b": stats["ca_inctax_part17"],
        "ca_inctax_total_b": stats["ca_inctax_total_full"],
        "ca_inctax_fy_b": stats["ca_inctax_fy_b"],
        "fy_to_cy_adjustment": stats["fy_to_cy_adj"],
        "n_returns_10m": pad6(brk["n_ret_10m"]),
        "ca_agi_10m_b": pad6(brk["agi_10m_b"]),
        "ca_taxable_10m_b": pad6(brk["taxable_10m_b"]),
        "ca_tax_10m_b": pad6(brk["tax_10m_b"]),
        "ca_tax_rate_10m": pad6(brk["tax_rate_10m"]),
        "pareto_b_10m_bracket": pad6(brk["pareto_b_10m"]),
        "n_returns_5m": pad6(brk["n_ret_5m"]),
        "ca_agi_5m_b": pad6(brk["agi_5m_b"]),
        "ca_taxable_5m_b": pad6(brk["taxable_5m_b"]),
        "ca_tax_5m_b": pad6(brk["tax_5m_b"]),
        "ca_tax_rate_5m": pad6(brk["tax_rate_5m"]),
        "pareto_b_5m_bracket": pad6(brk["pareto_b_5m"]),
        "proj_cutoff_top_pre_m": pad6(brk["proj_cutoff_top"]),
        "proj_agi_top_pre_b": pad6(brk["proj_agi_top"]),
        "proj_tax_top_pre_b": pad6(brk["proj_tax_top"]),
        "proj_cutoff_top_5m_m": pad6(brk["proj_cutoff_top_5m"]),
        "proj_agi_top_5m_b": pad6(brk["proj_agi_top_5m"]),
        "proj_agi_top_corr_b": pad6(brk["proj_agi_top_corr"]),
        "proj_tax_top_corr_b": pad6(brk["proj_tax_top_corr"]),
        "income_top_wealth_relative": inc_top_w_rel,
        "correction_passthrough": corr_passthru,
        "ca_inctax_ca_billionaires_b": ca_inctax_ca_b,
        "pct_ca_inctax_by_billionaires": pct_by_b,
        "ca_inctax_per_wealth": ca_inctax_b_per_w,
        "ca_inctax_public_assets_b": ca_inctax_public_b,
        "public_assets_share": public_share_b,
        "ca_inctax_public_share_of_total": ca_inctax_public_per_b_b,
    })

    robustness = bci_robustness(bci, D99, ca_inctax_ca_b, brk["tax_5m_b"], brk["agi_5m_b"])
    all_taxes = bci_all_taxes(yrs, brk["proj_agi_top_corr"], inc_top_w_rel, ca_inctax_ca_b,
                              m1["fed_tax_per_agi"], D99, agg, public_share_b, total_w_ca)
    return {"method1": method1, "memo1": m1["memo1"], "robustness": robustness,
            "all_taxes": all_taxes}
