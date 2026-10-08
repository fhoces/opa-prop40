"""Python twin of R/compute_shortrunseries.R: the shortrunseries sheet (panel
2018..2025, the 2025 summary block, the growth table).

Names keep the May Excel column letter as a prefix (C_wealth, S_cum_2019),
as in R; vintage.srs_col() gives the August letter actually read. Panel
vectors have 8 slots, 2018..2025; R's x[2] (2019) is x[1] here.
"""
import numpy as np
import pandas as pd

from excel_cells import xls_cells_col
from vintage import bsz_vintage, srs_col

NA = np.nan

# The five "top 5" billionaires, in Excel column order AJ..AN.
SRS_TOP5 = {
    "brin": "sergey-brin",
    "page": "larry-page",
    "zuck": "mark-zuckerberg",
    "ellison": "larry-ellison",
    "huang": "jensen-huang",
}


def _query_top5(top4, col, yrs):
    out = {}
    for name, fid in SRS_TOP5.items():
        vals = []
        for y in yrs:
            row = top4[(top4["forbes_id"] == fid) & (top4["year"] == y)]
            vals.append(float(row[col].iloc[0]) if len(row) == 1 else NA)
        out[name] = np.array(vals)
    return out


def _rmean(x):
    return float(np.mean(np.asarray(x, dtype=float)))


def srs_panel_columns(srs, agg, top4, m1, yrs, vintage=None):
    vintage = vintage or bsz_vintage()
    C_wealth = np.concatenate([[NA], agg["forbes_worth"].to_numpy(float)])
    K_ellison = xls_cells_col(srs, srs_col("K_ellison", vintage), range(6, 14))
    Q = xls_cells_col(srs, srs_col("Q_us_wealth", vintage), range(6, 14))

    # May's standalone "CA wealth, US citizens only" column B; August dropped
    # it and its formulas fall back to the all-CA total (see R).
    if vintage == "may":
        B = np.concatenate([[NA], xls_cells_col(srs, "B", range(7, 14))])
    else:
        B = C_wealth

    total_excl = top4[(top4["forbes_id"] == "Total (excluding Ellison)") & top4["year"].isin(yrs)]
    total_excl = total_excl.sort_values("year", kind="stable")
    E = total_excl["forbes_worth"].to_numpy(float) / 1000
    G = total_excl["public_worth"].to_numpy(float) / 1000
    H = G / E

    # D / F: only 2024 (= base) and 2025 (= base * 0.95) have formulas.
    D = np.full(8, NA)
    D[6] = C_wealth[6]
    D[7] = C_wealth[7] * (1 - 0.05)
    F = np.full(8, NA)
    F[6] = E[6]
    F[7] = E[7] * (1 - 0.05)

    J = np.concatenate([[NA], agg["n"].to_numpy(float)])

    L = K_ellison / C_wealth
    M = np.concatenate([[NA], C_wealth[1:] / C_wealth[:-1] - 1])
    N = C_wealth / C_wealth[1] - 1
    N[0] = NA
    O = np.full(8, NA)
    O[4:8] = C_wealth[4:8] / C_wealth[4] - 1
    P = np.full(8, NA)
    P[5:8] = C_wealth[5:8] / C_wealth[5] - 1

    R = np.concatenate([[NA], Q[1:] / Q[:-1] - 1])
    S = Q / Q[1] - 1
    S[0] = NA      # S6 empty in Excel
    S[1] = NA      # S7 empty (no formula)
    if vintage == "may":
        # May's S10 references B instead of Q (a typo in the sheet, kept).
        S[4] = B[4] / B[1] - 1
    T = np.full(8, NA)
    T[4:8] = Q[4:8] / Q[4] - 1

    V = B / Q

    # CA-tax columns from billionairesCAinctax rows 49 and 18 (R: match()).
    m1_year = m1["year"].to_numpy()
    idx = [int(np.flatnonzero(m1_year == y)[0]) for y in yrs]
    X = m1["ca_inctax_ca_billionaires_b"].to_numpy(float)[idx]
    Y = X / B
    Z = m1["ca_inctax_total_b"].to_numpy(float)[idx]
    AA = X / Z

    AE = total_excl["ca_income_tax"].to_numpy(float) / 1000
    AD = AE / G
    AF = AE / Z

    tax_b = {k: v / 1000 for k, v in _query_top5(top4, "ca_income_tax", yrs).items()}
    AG = tax_b["brin"] + tax_b["page"] + tax_b["zuck"]
    AH = tax_b["brin"] + tax_b["page"]

    return dict(B=B, C=C_wealth, D=D, E=E, F=F, G=G, H=H, J=J, K=K_ellison, L=L, M=M,
                N=N, O=O, P=P, Q=Q, R=R, S=S, T=T, V=V, X=X, Y=Y, Z=Z, AA=AA,
                AD=AD, AE=AE, AF=AF, AG=AG, AH=AH, tax_b=tax_b)


def srs_assemble_panel(cols, yrs):
    t = cols["tax_b"]
    return pd.DataFrame({
        "year": np.asarray(list(yrs)),
        "wealth_incl_nonus_b": cols["B"],
        "wealth_us_citizens_b": cols["C"],
        "wealth_w_avoid_b": cols["D"],
        "top5_total_b": cols["E"],
        "top5_w_avoid_b": cols["F"],
        "top5_company_wealth_b": cols["G"],
        "share_public": cols["H"],
        "n_ca_billionaires": cols["J"],
        "ellison_wealth_b": cols["K"],
        "share_ellison": cols["L"],
        "yoy_growth_wealth": cols["M"],
        "cum_growth_from_2019": cols["N"],
        "cum_growth_from_2022": cols["O"],
        "cum_growth_from_2023": cols["P"],
        "top5_incl_nonus_b": cols["Q"],
        "top5_yoy_growth": cols["R"],
        "top5_cum_growth_from_2019": cols["S"],
        "top5_cum_growth_from_2022": cols["T"],
        "share_ca_in_top5_b": cols["V"],
        "ca_inctax_billionaires_b": cols["X"],
        "ca_inctax_per_wealth": cols["Y"],
        "ca_inctax_total_b": cols["Z"],
        "ca_inctax_share_total": cols["AA"],
        "top5_sec_tax_rate": cols["AD"],
        "top5_sec_ca_inctax_b": cols["AE"],
        "top5_sec_share_of_total": cols["AF"],
        "top3_ca_inctax_sum_b": cols["AG"],
        "top2_ca_inctax_sum_b": cols["AH"],
        "brin_ca_inctax_b": t["brin"],
        "page_ca_inctax_b": t["page"],
        "zuck_ca_inctax_b": t["zuck"],
        "ellison_ca_inctax_b": t["ellison"],
        "huang_ca_inctax_b": t["huang"],
    })


def srs_summary_2025(cols, top4):
    """The 2025 summary block. Returned as R's nested list flattened the way
    unlist() names it ("top5_public_b.brin", "avg_2019_2025.X", ...), which is
    how the parity test compares it."""
    pub = {k: v[0] / 1000 for k, v in _query_top5(top4, "public_worth", [2025]).items()}
    tot = {k: v[0] / 1000 for k, v in _query_top5(top4, "forbes_worth", [2025]).items()}
    AG14 = pub["brin"] + pub["page"] + pub["zuck"]
    AH14 = pub["brin"] + pub["page"]
    AG17 = tot["brin"] + tot["page"] + tot["zuck"]
    AH17 = tot["brin"] + tot["page"]
    share = {k: pub[k] / tot[k] for k in SRS_TOP5}
    AG18, AH18 = AG14 / AG17, AH14 / AH17

    idx = slice(1, 8)          # R: 2:8 = 2019..2025
    X15 = _rmean(cols["X"][idx])
    avg = {
        "X": X15,
        "Y": _rmean(cols["Y"][idx]),
        "AA": _rmean(cols["AA"][idx]),
        "AD": _rmean(cols["AD"][idx]),
        "AE": _rmean(cols["AE"][idx]),
    }
    avg["AF"] = avg["AE"] / X15
    avg["AG"] = _rmean(cols["AG"][idx])
    avg["AH"] = _rmean(cols["AH"][idx])
    for letter, nm in zip(["AJ", "AK", "AL", "AM", "AN"], SRS_TOP5):
        avg[letter] = _rmean(cols["tax_b"][nm][idx])
    Q15 = cols["V"][7]

    AG16 = cols["AG"][7] / AG14
    AH16 = cols["AH"][7] / AH14
    share_tax = {nm: cols["tax_b"][nm][7] / pub[nm] for nm in SRS_TOP5}

    out = {}
    for k, v in {**pub, "top3": AG14, "top2": AH14}.items():
        out[f"top5_public_b.{k}"] = v
    for k, v in {**tot, "top3": AG17, "top2": AH17}.items():
        out[f"top5_total_b.{k}"] = v
    for k, v in {**share, "top3": AG18, "top2": AH18}.items():
        out[f"public_share.{k}"] = v
    for k, v in avg.items():
        out[f"avg_2019_2025.{k}"] = v
    for k, v in {"top3": AG16, "top2": AH16, **share_tax}.items():
        out[f"avg_share_2025_wealth.{k}"] = v
    out["share_top5_2025_in_total"] = Q15
    return {k: float(v) for k, v in out.items()}


def srs_growth(cols, yrs):
    base_years = np.array([2019, 2020, 2021, 2022, 2023, 2024], dtype=float)
    yrs = list(yrs)
    base_idx = [yrs.index(int(y)) for y in base_years]
    yrs_to_2025 = 2025 - base_years
    incl = cols["B"][7] / cols["B"][base_idx] - 1
    excl = cols["C"][7] / cols["C"][base_idx] - 1
    ann = (1 + excl) ** (1 / yrs_to_2025) - 1
    return pd.DataFrame({
        "base_year": base_years,
        "yrs_to_2025": yrs_to_2025,
        "total_growth_incl_nonus": incl,
        "total_growth_us_only": excl,
        "annualized_us_only": ann,
    })


def compute_shortrunseries(data_sec_agg_r, data_sec_top4, billionaires_ca_inctax_r, shortrunseries):
    yrs = range(2018, 2026)
    cols = srs_panel_columns(shortrunseries, data_sec_agg_r, data_sec_top4,
                             billionaires_ca_inctax_r["method1"], yrs)
    return {
        "panel": srs_assemble_panel(cols, yrs),
        "summary_2025": srs_summary_2025(cols, data_sec_top4),
        "growth": srs_growth(cols, yrs),
    }
