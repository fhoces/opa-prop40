"""Python twin of R/compute_top4taxes.R: per-year tax rates of the CA top 4,
2004-2025, and the 2004-2016 / 2017-2025 averages (sheet top4taxes).

The "top 4" changes composition in three phases: up to 2015 the
"Total (excluding Ellison)" row plus Ellison; 2016-2020 plus Ellison minus
Huang; from 2021 the total row alone.
"""
import numpy as np
import pandas as pd

INC_COMPONENTS = ["ca_inctax_per_income", "fed_inctax_per_income",
                  "sales_tax_per_income", "corp_tax_per_income",
                  "property_tax_per_income"]
W_COMPONENTS = ["ca_inctax_per_wealth", "fed_inctax_per_wealth",
                "sales_tax_per_wealth", "corp_tax_per_wealth",
                "property_tax_per_wealth"]

METRIC_COLS = ["ca_income_tax", "fed_income_tax", "sales_tax", "w_txt", "w_tax_ppent",
               "total_tax", "economic_income", "public_worth_avg"]


def _pick(d, forbes_id, yr, col):
    row = d[(d["forbes_id"] == forbes_id) & (d["year"] == yr)]
    return float(row[col].iloc[0]) if len(row) == 1 else np.nan


def _period_avg(panel, panel_cols, years):
    # Average each column over the years, then overwrite the two check cells
    # the way the sheet computes them: (avg total) - SUM(avg components), not
    # the mean of the per-year checks.
    sel = panel["year"].isin(years).to_numpy()
    out = {c: float(np.mean(panel[c].to_numpy()[sel])) for c in panel_cols}
    out["check_income_decomp"] = out["total_tax_per_income"] - _rsum([out[c] for c in INC_COMPONENTS])
    out["check_wealth_decomp"] = out["total_tax_per_wealth"] - _rsum([out[c] for c in W_COMPONENTS])
    return out


def _rsum(values):
    """R's sum(): left to right from 0."""
    s = 0.0
    for v in values:
        s += v
    return s


def compute_top4taxes(data_sec_top4):
    d = data_sec_top4

    def agg(yr):
        total = np.array([_pick(d, "Total (excluding Ellison)", yr, c) for c in METRIC_COLS])
        if yr <= 2015:
            ell = np.array([_pick(d, "larry-ellison", yr, c) for c in METRIC_COLS])
            return total + ell
        if yr <= 2020:
            ell = np.array([_pick(d, "larry-ellison", yr, c) for c in METRIC_COLS])
            hua = np.array([_pick(d, "jensen-huang", yr, c) for c in METRIC_COLS])
            return total + ell - hua
        return total

    yrs = np.arange(2004, 2026)
    mat = np.column_stack([agg(int(y)) for y in yrs])     # rows metrics, columns years
    m = dict(zip(METRIC_COLS, mat))
    ca_tax, fed_tax, sales_t = m["ca_income_tax"], m["fed_income_tax"], m["sales_tax"]
    corp_t, prop_t, total_t = m["w_txt"], m["w_tax_ppent"], m["total_tax"]
    econ_i, wealth = m["economic_income"], m["public_worth_avg"]

    C = total_t / econ_i
    D = ca_tax / econ_i
    E = fed_tax / econ_i
    F = sales_t / econ_i
    G = corp_t / econ_i
    H = prop_t / econ_i
    I = C - (D + E + F + G + H)
    J = total_t / wealth
    K = ca_tax / wealth
    L = fed_tax / wealth
    M = sales_t / wealth
    N = corp_t / wealth
    O = prop_t / wealth
    P = J - (K + L + M + N + O)
    R = econ_i / wealth

    panel = pd.DataFrame({
        "year": yrs,
        "total_tax_per_income": C, "ca_inctax_per_income": D, "fed_inctax_per_income": E,
        "sales_tax_per_income": F, "corp_tax_per_income": G, "property_tax_per_income": H,
        "check_income_decomp": I,
        "total_tax_per_wealth": J, "ca_inctax_per_wealth": K, "fed_inctax_per_wealth": L,
        "sales_tax_per_wealth": M, "corp_tax_per_wealth": N, "property_tax_per_wealth": O,
        "check_wealth_decomp": P,
        "income_per_wealth": R, "avg_wealth_m": wealth, "economic_income_m": econ_i,
    })
    panel_cols = [c for c in panel.columns if c != "year"]
    a1 = _period_avg(panel, panel_cols, range(2004, 2017))
    a2 = _period_avg(panel, panel_cols, range(2017, 2026))
    averages = pd.DataFrame([{"period": "2004-2016", **a1}, {"period": "2017-2025", **a2}])
    return {"panel": panel, "averages": averages}
