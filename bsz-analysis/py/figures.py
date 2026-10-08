"""Python twin of R/figures.R, the data only: each build_*() returns the data
frame behind the ggplot (a list of two for the two-panel patchwork figures,
in panel order), not the plot.

R stores the series labels as factors (their level order sets the legend and
the stacking); here they are plain strings in the same row order, which is
what the parity test compares.
"""
import numpy as np
import pandas as pd

from excel_cells import col_num, to_num_vec
from ingest_excel import read_sheet
from vintage import bsz_vintage


def _rep_each(labels, n):
    return [lab for lab in labels for _ in range(n)]


def _long(x, x_name, values, value_name, labels, label_name):
    n = len(x)
    return pd.DataFrame({
        x_name: np.concatenate([np.asarray(x)] * len(values)),
        value_name: np.concatenate([np.asarray(v, dtype=float) for v in values]),
        label_name: _rep_each(labels, n),
    })


def build_fig_a4(pareto_missing_r):
    d = pareto_missing_r
    a = _long(d["threshold_b"], "threshold", [d["pareto_b_emp"], d["pareto_b_proj"]], "pareto_b",
              ["Pareto b (Forbes data)", "Pareto b (projected)"], "series")
    b = _long(d["threshold_b"], "threshold", [d["actual_density"], d["projected_density"]], "density",
              ["Density (Forbes)", "Density (Pareto-projected)"], "series")
    return [a, b]


def build_fig_a3(billionaires_ca_inctax_r):
    at = billionaires_ca_inctax_r["all_taxes"]
    d = at[at["year"].isin(range(2019, 2026))]
    labels = ["CA income tax", "Federal income tax", "Corporate taxes", "Property + sales taxes"]
    pw = _long(d["year"], "year",
               [d["ca_inctax_per_public_wealth"], d["fed_inctax_per_public_wealth"],
                d["corp_per_public_wealth"], d["prop_sales_per_public_wealth"]], "share", labels, "tax")
    pei = _long(d["year"], "year",
                [d["ca_inctax_per_econ_income"], d["fed_inctax_per_econ_income"],
                 d["corp_per_econ_income"], d["prop_sales_per_econ_income"]], "share", labels, "tax")
    return [pw, pei]


def build_fig_a2(shortrunseries_r):
    p = shortrunseries_r["panel"]
    d = p[p["year"].isin(range(2019, 2026))]
    return _long(d["year"], "year", [d["ca_inctax_share_total"], d["top5_sec_share_of_total"]], "share",
                 ["All CA billionaires", "Top 5 (SEC filings)"], "series")


def build_fig_a1(xlsx_path=None):
    # Block 2 of rtb_2026_industry: rows 22-34, columns A and G-I.
    raw = read_sheet("rtb_2026_industry", path=xlsx_path, range=(22, 1, 34, 9))
    raw.columns = ["industry"] + [f"c{i}" for i in range(2, raw.shape[1] + 1)]
    d = raw.copy()
    d["top4_public"] = to_num_vec(d["c9"])    # col I
    d["other_public"] = to_num_vec(d["c7"])   # col G
    d["private"] = to_num_vec(d["c8"])        # col H
    d["total"] = d["top4_public"] + d["other_public"] + d["private"]
    d = d[d["total"].notna() & (d["total"] > 0)]
    # R: d[order(d$total, decreasing = TRUE), ] (stable for ties)
    d = d.sort_values("total", ascending=False, kind="stable")
    n = len(d)
    return pd.DataFrame({
        "industry": list(d["industry"]) * 3,
        "share": np.concatenate([d["top4_public"], d["other_public"], d["private"]]),
        "component": _rep_each(["Public stock (Top 4)", "Public stock (other)", "Private stock"], n),
    })


def build_fig8(fig8_laffer_r):
    d = fig8_laffer_r
    return _long(d["tax_rate"], "rate",
                 [d["mechanical_tax_revenue"], d["actual_tax_revenue"], d["long_run_tax_revenue"]],
                 "revenue",
                 ["Mechanical (no behavior)", "Short-run (with mobility)",
                  "Long-run (mobility + deconcentration)"], "series")


def build_fig7(top4taxes_r, data_dina):
    d = top4taxes_r["panel"]
    yrs = d["year"]
    # data_dina K = US total tax / economic income, S = CA income tax /
    # economic income; rows 6..27 = 2004..2025.
    dina_K = col_num(data_dina, "K", range(6, 28))
    dina_S = col_num(data_dina, "S", range(6, 28))
    a = _long(yrs, "year", [d["total_tax_per_income"], dina_K], "value",
              ["Top 4 (CA billionaires)", "US average"], "series")
    b = _long(yrs, "year", [d["ca_inctax_per_income"], dina_S], "value",
              ["Top 4 (CA billionaires)", "CA average"], "series")
    return [a, b]


def build_fig6(top4taxes_r):
    d = top4taxes_r["panel"]
    a = _long(d["year"], "year", [d["total_tax_per_wealth"], d["ca_inctax_per_wealth"]], "value",
              ["Total taxes / wealth", "CA income tax / wealth"], "series")
    b = _long(d["year"], "year", [d["total_tax_per_income"], d["ca_inctax_per_income"]], "value",
              ["Total taxes / income", "CA income tax / income"], "series")
    return [a, b]


def build_fig5(data_sec_top4):
    t = data_sec_top4[data_sec_top4["forbes_id"] == "Total (excluding Ellison)"]
    d = t[t["year"].isin(range(2019, 2026))].sort_values("year", kind="stable")
    begin = float(t.loc[t["year"] == 2018, "public_worth"].iloc[0])
    end = float(t.loc[t["year"] == 2025, "public_worth"].iloc[0])

    def rsum(col):
        s = 0.0
        for v in d[col].to_numpy(float):
            s += v
        return s

    fiscal_income = rsum("fiscal_income") / 1000
    econ_income = rsum("economic_income") / 1000
    wealth_gain = (end - begin) / 1000
    ca_inctax = rsum("ca_income_tax") / 1000
    fed_inctax = rsum("fed_income_tax") / 1000
    corp_tax = rsum("total_tax") / 1000 - ca_inctax - fed_inctax
    wealth_tax_5p = 0.05 * end / 1000

    net_fi = fiscal_income - ca_inctax - fed_inctax
    net_ei = econ_income - ca_inctax - fed_inctax - corp_tax
    net_wg = wealth_gain - wealth_tax_5p
    components = ["Net of taxes", "CA income tax", "Federal income tax", "Corporate taxes",
                  "5% wealth tax"]
    return pd.DataFrame({
        "bar": _rep_each(["Fiscal Income", "Economic Income", "Wealth Gain"], 5),
        "component": components * 3,
        "value": [net_fi, ca_inctax, fed_inctax, 0, 0,
                  net_ei, ca_inctax, fed_inctax, corp_tax, 0,
                  net_wg, ca_inctax, fed_inctax, corp_tax, wealth_tax_5p],
    })


def build_fig4(billionaires_ca_inctax_r):
    at = billionaires_ca_inctax_r["all_taxes"]
    d = at[at["year"].isin(range(2019, 2026))]
    return _long(d["year"], "year",
                 [d["ca_inctax_per_total_wealth"], d["fed_inctax_per_total_wealth"],
                  d["corp_per_total_wealth"], d["prop_sales_per_total_wealth"]], "share",
                 ["CA income tax", "Federal income tax", "Corporate taxes", "Property + sales taxes"],
                 "tax")


def build_fig3(shortrunseries_r):
    p = shortrunseries_r["panel"]
    d = p[p["year"].isin(range(2019, 2026))]
    labels = ["All CA billionaires", "Top 5 (SEC filings)"]
    a = _long(d["year"], "year", [d["ca_inctax_billionaires_b"], d["top5_sec_ca_inctax_b"]], "value",
              labels, "series")
    b = _long(d["year"], "year", [d["ca_inctax_per_wealth"], d["top5_sec_tax_rate"]], "value",
              labels, "series")
    return [a, b]


def build_fig2(longrunseries, vintage=None):
    vintage = vintage or bsz_vintage()
    rows = range(8, 52)       # 1982-2025 in both vintages

    def num(col):
        return col_num(longrunseries, col, rows)

    year = num("A")
    if vintage == "may":
        wealth_b, gdp_per_fam, us_share, ca_share = num("AZ"), num("BE"), num("AV"), num("AW")
    else:
        wealth_b, gdp_per_fam, us_share, ca_share = num("BJ"), num("BP"), num("BF"), num("BG")
    a = _long(year, "year", [wealth_b, gdp_per_fam], "value",
              ["CA top .0002% wealth ($B, 2025 $)", "CA GDP per family ($100K, 2025 $)"], "series")
    b = _long(year, "year", [us_share, ca_share], "share",
              ["US (top 400)", "California (top 45)"], "region")
    return [a, b]


def build_fig1(shortrunseries_r):
    p = shortrunseries_r["panel"]
    d = p[p["year"].isin(range(2019, 2026))]
    return _long(d["year"], "year", [d["wealth_us_citizens_b"], d["top5_total_b"]], "wealth",
                 ["All CA billionaires", "Top 4 (Page, Brin, Zuck, Huang)"], "series")
