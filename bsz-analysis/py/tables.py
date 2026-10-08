"""Python twin of R/tables.R, the data only: each build_*() returns the data
frame(s) the R builder attaches to its gt table (attr "panel", or "panel_a"
and "panel_b"), not the gt styling.

R/tables.R documents every vintage-specific formula (the GDP to AGI swap,
the 2026 row, the .0002% to .001% percentile); the code below follows it line
for line. R's dplyr::bind_rows() of tibbles with different columns fills the
missing ones with NA; pd.concat() does the same with NaN.
"""
import numpy as np
import pandas as pd

from excel_cells import col_num, xls_cell
from vintage import bsz_vintage, lrs_current_row, srs_col

NA = np.nan


def _rmean(x):
    return float(np.mean(np.asarray(x, dtype=float)))


def _total_excl(top4, years):
    d = top4[(top4["forbes_id"] == "Total (excluding Ellison)") & top4["year"].isin(list(years))]
    return d.sort_values("year", kind="stable")


def _long_run_compare(row_1982, row_cur, n_years=43):
    num_cols = [c for c in row_1982 if c != "year"]
    ratio = {c: row_cur[c] / row_1982[c] for c in num_cols}
    ann = {c: ratio[c] ** (1 / n_years) - 1 for c in num_cols}
    return ({"year": "Ratio 2025 to 1982", **ratio}, {"year": "Annualized growth", **ann})


def build_tab2(data_sec_agg_r, billionaires_ca_inctax_r, data_sec_top4, vintage=None):
    vintage = vintage or bsz_vintage()
    yrs = list(range(2019, 2026))
    m1 = billionaires_ca_inctax_r["method1"].set_index("year")
    agg_y = data_sec_agg_r.set_index("year").loc[yrs]
    te = _total_excl(data_sec_top4, yrs)

    panel = pd.DataFrame({
        "year": [str(y) for y in yrs],
        "wealth_b": agg_y["forbes_worth"].to_numpy(float),
        "ca_inctax_b": m1.loc[yrs, "ca_inctax_ca_billionaires_b"].to_numpy(float),
        "ca_inctax_per_wealth": NA,
        "top4_company_wealth_b": te["public_worth"].to_numpy(float) / 1000,
        "top4_ca_inctax_b": te["ca_income_tax"].to_numpy(float) / 1000,
        "top4_ca_inctax_per_wealth": NA,
    })
    panel["ca_inctax_per_wealth"] = panel["ca_inctax_b"] / panel["wealth_b"]
    panel["top4_ca_inctax_per_wealth"] = panel["top4_ca_inctax_b"] / panel["top4_company_wealth_b"]

    # The average row's Excel quirks (6-year averages of the ratio columns).
    if vintage == "may":
        top4_ratio_avg = _rmean(panel["top4_ca_inctax_b"]) / _rmean(panel["top4_company_wealth_b"])
    else:
        top4_ratio_avg = _rmean(panel["top4_ca_inctax_per_wealth"].iloc[0:6])
    avg_row = {
        "year": "2019-2025 average",
        "wealth_b": _rmean(panel["wealth_b"]),
        "ca_inctax_b": _rmean(panel["ca_inctax_b"]),
        "ca_inctax_per_wealth": _rmean(panel["ca_inctax_per_wealth"].iloc[0:6]),
        "top4_company_wealth_b": _rmean(panel["top4_company_wealth_b"]),
        "top4_ca_inctax_b": _rmean(panel["top4_ca_inctax_b"]),
        "top4_ca_inctax_per_wealth": top4_ratio_avg,
    }
    return {"panel": pd.concat([panel, pd.DataFrame([avg_row])], ignore_index=True)}


def build_tab_a1(shortrunseries, longrunseries, vintage=None):
    vintage = vintage or bsz_vintage()
    srs, lrs = shortrunseries, longrunseries
    may = vintage == "may"

    years_a = list(range(2022, 2026)) if may else list(range(2022, 2027))
    rows_a = range(10, 14) if may else range(10, 15)
    n_us_b = col_num(srs, srs_col("n_us_citizen", vintage), rows_a)
    w_us_b = col_num(srs, srs_col("Q_us_wealth", vintage), rows_a)

    panel_a = pd.DataFrame({
        "year": [str(y) for y in years_a],
        "n_us_billionaires": n_us_b,
        "wealth_b": w_us_b,
        "annual_growth": np.concatenate([[NA], w_us_b[1:] / w_us_b[:-1] - 1]),
    })
    if not may:
        n = len(panel_a)
        panel_a.loc[n - 1, "annual_growth"] = 2 * (w_us_b[n - 1] / w_us_b[n - 2] - 1)
        agi = col_num(lrs, "AV", range(48, 53))
        panel_a["us_agi_b"] = agi
        panel_a["wealth_per_agi"] = w_us_b / agi
    growth_row = {
        "year": "Growth during 3 years (2023-2025)",
        "n_us_billionaires": NA,
        "wealth_b": panel_a["wealth_b"].iloc[3] / panel_a["wealth_b"].iloc[0] - 1,
        "annual_growth": NA,
    }
    if not may:
        growth_row["us_agi_b"] = panel_a["us_agi_b"].iloc[3] / panel_a["us_agi_b"].iloc[0] - 1
        growth_row["wealth_per_agi"] = NA
    panel_a_full = pd.concat([panel_a, pd.DataFrame([growth_row])], ignore_index=True)

    def num_lr(col, row):
        return xls_cell(lrs, f"{col}{row}")

    W8 = num_lr("W", 8)
    cur = lrs_current_row(vintage)
    W_cur = num_lr("W", cur)
    defl_1982 = W8 / W_cur
    if may:
        AM_1982, AM_cur = num_lr("AM", 8), num_lr("AM", cur)
        wealth_1982 = num_lr("AP", 8) * defl_1982
        wealth_cur = num_lr("AP", cur)
        agi_1982 = num_lr("AS", 8) * defl_1982
        agi_cur = num_lr("AS", cur)
    else:
        AM_1982, AM_cur = num_lr("AM", 8) * 5, num_lr("AM", cur) * 5
        wealth_1982 = num_lr("G", 8) * num_lr("BQ", 8) * defl_1982
        wealth_cur = num_lr("G", cur) * num_lr("BQ", cur) * (W_cur / W_cur)
        agi_1982 = num_lr("AV", 8) * defl_1982
        agi_cur = num_lr("AV", cur) * (W_cur / W_cur)
    X_1982, X_cur = num_lr("X", 8), num_lr("X", cur)

    def make_year_row(label, AM, wealth_b, X, agi_b):
        n_fam_m = X / 1000
        return {"year": label, "families_top0002_k": AM, "wealth_top0002_b": wealth_b,
                "wealth_per_family_b": wealth_b / AM, "n_us_families_m": n_fam_m,
                "us_gdp_2025dollars_b": agi_b, "gdp_per_family_k": 1000 * agi_b / n_fam_m}

    cur_label = "2025" if may else "2026"
    n_years = 43 if may else 44
    r82 = make_year_row("1982", AM_1982, wealth_1982, X_1982, agi_1982)
    rcur = make_year_row(cur_label, AM_cur, wealth_cur, X_cur, agi_cur)
    ratio, ann = _long_run_compare(r82, rcur, n_years)
    panel_b = pd.DataFrame([r82, rcur, ratio, ann])
    return {"panel_a": panel_a_full, "panel_b": panel_b}


TAB5_LONG_LABELS = [
    "1. Benchmark: Forbes estimates + 10% avoidance",
    "2. Adding missing small billionaires (Pareto extrapolation)",
    "3. Aggressive assumptions for pre/post-2026 leavers",
    "4. Benchmark with both adding small billionaires and aggressive leavers",
]


def build_tab5(tab5_r):
    panel = tab5_r.copy()
    panel["scenario"] = TAB5_LONG_LABELS
    return {"panel": panel}


def build_tab4(data_sec_top4):
    d = data_sec_top4
    te = _total_excl(d, range(2019, 2026))
    tot = d[d["forbes_id"] == "Total (excluding Ellison)"]
    begin = float(tot.loc[tot["year"] == 2018, "public_worth"].iloc[0])
    end = float(tot.loc[tot["year"] == 2025, "public_worth"].iloc[0])
    wealth_begin, wealth_end = begin / 1000, end / 1000
    wealth_gain = wealth_end - wealth_begin
    wealth_avg = _rmean(te["public_worth"]) / 1000

    def sum_col(col):
        s = 0.0
        for v in te[col].to_numpy(float):   # R's sum(): left to right
            s += v
        return s / 1000

    fiscal_income = sum_col("fiscal_income")
    stock_options = sum_col("option_profit") + sum_col("noneq_comp")
    dividends = sum_col("dividend")
    realized_gains = sum_col("kg_taxable")
    appreciated_stock = sum_col("donation")
    net_collateral = sum_col("value_borrowed")
    fed_inctax = sum_col("fed_income_tax")
    ca_inctax = sum_col("ca_income_tax")
    corp_profits = sum_col("w_pi")
    corp_taxes = sum_col("w_txt")

    metric = [
        "Wealth in 2019 (beginning of year)",
        "Wealth in 2025 (end of year)",
        "Gain in wealth during 2019-2025",
        "Wealth (average over 2019-2025)",
        "Fiscal individual income",
        "        Stock-options exercise + non-equity comp",
        "        Dividends",
        "        Realized capital gains",
        "Memo: Appreciated stock donated to charity",
        "Memo: Net collateral pledged",
        "Federal individual income tax",
        "California individual income tax",
        "Individual taxes / individual income",
        "Corporate profits",
        "Corporate taxes (federal)",
        "Corporate tax rate (effective)",
    ]
    total = [wealth_begin, wealth_end, wealth_gain, NA,
             fiscal_income, stock_options, dividends, realized_gains,
             appreciated_stock, net_collateral, fed_inctax, ca_inctax,
             (fed_inctax + ca_inctax) / fiscal_income,
             corp_profits, corp_taxes, corp_taxes / corp_profits]
    annual = [NA, NA, wealth_gain / 7, wealth_avg,
              fiscal_income / 7, stock_options / 7, dividends / 7, realized_gains / 7,
              appreciated_stock / 7, net_collateral / 7, fed_inctax / 7, ca_inctax / 7,
              (fed_inctax + ca_inctax) / fiscal_income,
              corp_profits / 7, corp_taxes / 7, corp_taxes / corp_profits]
    return {"panel": pd.DataFrame({"metric": metric, "total": total, "annual_avg": annual})}


def build_tab3(data_sec_top4):
    ids = ["larry-page", "sergey-brin", "mark-zuckerberg", "jensen-huang"]
    lbl = ["page", "brin", "zuckerberg", "huang"]
    d = data_sec_top4

    def pick(fid, yr, col):
        row = d[(d["forbes_id"] == fid) & (d["year"] == yr)]
        return float(row[col].iloc[0]) if len(row) == 1 else NA

    def rsum(values):
        s = 0.0
        for v in values:
            s += v
        return s

    rows = []
    for i, yr in enumerate(range(2019, 2026)):
        r = {"metric": f"CA income tax {2019 + i}"}
        r.update({l: pick(f, yr, "ca_income_tax") for f, l in zip(ids, lbl)})
        r["all_top4"] = rsum([r[l] for l in lbl])
        rows.append(r)
    panel = pd.DataFrame(rows)[["metric"] + lbl + ["all_top4"]]
    num_cols = lbl + ["all_top4"]
    avg_row = {"metric": "Average CA income tax 2019-2025",
               **{c: _rmean(panel[c]) for c in num_cols}}
    wb = {l: pick(f, 2018, "public_worth") for f, l in zip(ids, lbl)}
    we = {l: pick(f, 2025, "public_worth") for f, l in zip(ids, lbl)}
    wb_row = {"metric": "Wealth at the beginning of 2019", **wb, "all_top4": rsum(wb.values())}
    we_row = {"metric": "Wealth at end of 2025", **we, "all_top4": rsum(we.values())}
    totals = {c: rsum(panel[c].to_numpy(float)) for c in num_cols}
    ratio_row = {"metric": "Total CA income tax / wealth gain 2019-2025",
                 **{c: totals[c] / (we_row[c] - wb_row[c]) for c in num_cols}}
    full = pd.concat([panel, pd.DataFrame([avg_row, wb_row, we_row, ratio_row])], ignore_index=True)
    return {"panel": full}


def build_tab1(data_sec_agg_r, shortrunseries_r, longrunseries, shortrunseries, vintage=None):
    vintage = vintage or bsz_vintage()
    may = vintage == "may"
    agg = data_sec_agg_r[data_sec_agg_r["year"].isin(range(2022, 2026))]
    srs = shortrunseries_r["panel"]
    srs_a = srs[srs["year"].isin(range(2022, 2026))]
    denom_col = "AT" if may else "AY"     # CA GDP (May) / CA AGI (August)
    denom_1 = col_num(longrunseries, denom_col, range(48, 52))

    w = agg["forbes_worth"].to_numpy(float)
    panel_a = pd.DataFrame({
        "year": [str(y) for y in range(2022, 2026)],
        "n_billionaires": agg["n"].to_numpy(),
        "wealth_b": w,
        "annual_growth": np.concatenate([[NA], w[1:] / w[:-1] - 1]),
        "fraction_public": agg["forbes_public_worth"].to_numpy(float) / w,
        "top4_wealth_b": srs_a["top5_total_b"].to_numpy(float),
        "ca_gdp_b": denom_1,
        "wealth_per_gdp": w / denom_1,
    })
    if not may:
        # August's "2026 (July 1st)" row: literals and raw shortrunseries row 14.
        wealth_2026 = xls_cell(shortrunseries, "C14")
        top4_2026 = xls_cell(shortrunseries, f"{srs_col('top5_total', vintage)}14")
        denom_2026 = xls_cell(longrunseries, f"{denom_col}52")
        row_2026 = {
            "year": "2026 (July 1st)", "n_billionaires": 250, "wealth_b": wealth_2026,
            "annual_growth": 2 * (wealth_2026 / panel_a["wealth_b"].iloc[3] - 1),
            "fraction_public": 0.6, "top4_wealth_b": top4_2026,
            "ca_gdp_b": denom_2026, "wealth_per_gdp": wealth_2026 / denom_2026,
        }
        panel_a = pd.concat([panel_a, pd.DataFrame([row_2026])], ignore_index=True)

    growth_row = {
        "year": "Growth during 2023-2025", "n_billionaires": NA,
        "wealth_b": panel_a["wealth_b"].iloc[3] / panel_a["wealth_b"].iloc[0] - 1,
        "annual_growth": NA, "fraction_public": NA,
        "top4_wealth_b": panel_a["top4_wealth_b"].iloc[3] / panel_a["top4_wealth_b"].iloc[0] - 1,
        "ca_gdp_b": panel_a["ca_gdp_b"].iloc[3] / panel_a["ca_gdp_b"].iloc[0] - 1,
        "wealth_per_gdp": NA,
    }
    panel_a_full = pd.concat([panel_a, pd.DataFrame([growth_row])], ignore_index=True)
    panel_a_full["panel"] = "A. Recent nominal wealth growth of CA billionaires"

    lrs = longrunseries

    def num(col, row):
        return xls_cell(lrs, f"{col}{row}")

    W8 = num("W", 8)
    cur = lrs_current_row(vintage)
    W_cur = num("W", cur)
    defl_1982 = W8 / W_cur
    if may:
        AL_1982, AL_cur = num("AL", 8), num("AL", cur)
        wealth_1982 = num("AQ", 8) * defl_1982
        wealth_cur = num("AQ", cur)
        gdp_1982 = num("AT", 8) * defl_1982
        gdp_cur = num("AT", cur)
    else:
        AL_1982, AL_cur = num("AL", 8) * 5, num("AL", cur) * 5
        wealth_1982 = num("BT", 8)
        wealth_cur = num("BT", cur)
        gdp_1982 = num("BA", 8) * defl_1982
        gdp_cur = num("BA", cur) * (W_cur / W_cur)
    AI_1982, AI_cur = num("AI", 8), num("AI", cur)

    def make_year_row(label, AL, wealth_b, AI, gdp_b, round_gpf):
        n_fam_m = AI / 1000
        gpf = 1000 * gdp_b / n_fam_m
        if round_gpf:
            gpf = round(gpf, -2)      # R's round(x, -2); both round half to even
        return {"year": label, "families_top0002_k": AL, "wealth_top0002_b": wealth_b,
                "wealth_per_family_b": wealth_b / AL, "n_ca_families_m": n_fam_m,
                "ca_gdp_2025dollars_b": gdp_b, "gdp_per_family_k": gpf}

    cur_label = "2025" if may else "2026"
    n_years = 43 if may else 44
    round_gpf = not may
    r82 = make_year_row("1982", AL_1982, wealth_1982, AI_1982, gdp_1982, round_gpf)
    rcur = make_year_row(cur_label, AL_cur, wealth_cur, AI_cur, gdp_cur, round_gpf)
    ratio, ann = _long_run_compare(r82, rcur, n_years)
    panel_b = pd.DataFrame([r82, rcur, ratio, ann])
    return {"panel_a": panel_a_full, "panel_b": panel_b}
