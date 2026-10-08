"""Python twin of R/export_contract.R: the export contract the comparison
layer reads (inputs.csv, outputs.csv; same schema as export/r/).

The comparison layer reads export/r/ only. py/run_export.py writes the same
two files to export/py/ so the parity test can compare them.
"""
import inspect

import pandas as pd

from compute_pareto import compute_fig8_laffer
from compute_tab5 import TAB5_DEFAULTS, score_tab5_cell

INPUT_COLS = ["input_id", "version", "description", "value", "unit", "label",
              "provenance", "source", "page"]


def export_contract_inputs(inp):
    fig8 = {k: p.default for k, p in inspect.signature(compute_fig8_laffer).parameters.items()}
    mobility = inspect.signature(score_tab5_cell).parameters["mobility_share"].default
    lv = inp["leavers"]

    def row(i, version, desc, value, unit, label, source, page):
        return [i, version, desc, float(value), unit, label, "public", source, page]

    rows = [
        row("n_billionaires", "both", "CA billionaires on the Forbes real-time list, 1 Jul 2026",
            inp["n0"], "count", "data", "Tab5!B6 (BSZ Table 5 row 1); GGSS p.4", 24),
        row("baseline_net_worth", "both", "Aggregate net worth, CA billionaires, 1 Jul 2026 (incl. non-US citizens)",
            inp["W0"], "$B", "data", "Tab5!C6; BSZ PDF p.24 (=90%*5%*$2307 billion); GGSS p.4", 24),
        row("tax_rate", "both", "Statutory one-time wealth tax rate",
            TAB5_DEFAULTS["wealth_tax_rate"], "rate", "data", "The Act; GGSS p.1", 24),
        row("avoidance_rate", "both", "Avoidance and evasion allowance (share of the base)",
            TAB5_DEFAULTS["avoidance_rate"], "share", "guesswork",
            "GGSS p.4 (\"a relatively small avoidance rate of 10%\"); BSZ PDF p.24", 24),
        row("mobility_share", "bsz", "Share of the avoidance allowance that is people leaving CA",
            mobility, "share", "guesswork",
            "BSZ PDF p.24 (\"half of the 10% avoidance takes the form of mobility\")", 24),
        row("sell_share", "bsz", "Share of the tax paid by selling assets",
            TAB5_DEFAULTS["realization_share"], "share", "guesswork",
            "BSZ PDF p.24 (\"paid one-third by selling assets\")", 24),
        row("gains_share", "bsz", "Capital-gain share of a sale (1 - basis share)",
            TAB5_DEFAULTS["ltcg_taxable"], "share", "research",
            "BSZ PDF p.24 (basis of 20%, CA billionaire wealth 80% unrealized gains)", 24),
        row("ca_cg_rate", "bsz", "Top CA income tax rate on realized gains",
            TAB5_DEFAULTS["ca_ltcg_rate"], "rate", "data", "Tab5!G6", 39),
        row("ca_inctax_billionaires", "bsz", "CA income tax paid by billionaires, 2019-2025 average",
            inp["C"], "$B/yr", "research",
            "Tab2!C14 (BSZ Table 2); BSZ PDF p.11 (\"average of $3 billion per year\")", 11),
        row("leavers_wealth", "bsz",
            "Wealth of the 7 named leavers in Table 5 rows 3-4 (Page, Thiel, Hankey, Kalanick, Brin, Zuckerberg, Fang)",
            sum(lv["wealth"]), "$B", "data", "Tab5!B20:B27 (Forbes 7/1/2026 values)", 39),
        row("leavers_annual_inctax", "bsz",
            "Annual CA income tax of the 7 named leavers (top 3 from SEC data, rest wealth-proportional)",
            sum(lv["annual_inctax_loss"]), "$B/yr", "data",
            "Tab5!F19+F24 (Tab3 row 13 SEC-based); BSZ PDF p.26", 26),
        row("pre2026_leavers_wealth", "bsz",
            "Wealth of the 4 pre-2026 leavers in the aggressive row (Page, Thiel, Hankey, Kalanick)",
            inp["W_pre"], "$B", "guesswork", "Tab5!B20:B23; BSZ PDF p.26 (a legal judgment on residency)", 26),
        row("semi_elasticity_permanent", "bsz", "Mobility semi-elasticity for a PERMANENT annual wealth tax",
            fig8["semi_elasticity_mobility"], "coefficient", "research",
            "Fig8!B8; BSZ PDF p.28 (Brulhart et al. 2022, \"around 10\")", 28),
        row("pareto_pct_wealth_increase", "bsz", "Wealth added by the Pareto extrapolation of missing small billionaires",
            inp["pct_wealth_increase"], "share", "research", "Pareto-missing!I23; BSZ PDF p.25", 25),
    ]
    return pd.DataFrame(rows, columns=INPUT_COLS)


def export_contract_outputs(tab5_printed):
    p = tab5_printed[tab5_printed["column"].isin(
        ["wealth_tax_revenue", "extra_ca_inctax_sales", "annual_ca_inctax_loss", "taxable_wealth"])]
    value = [r / (1 if s == 1 else s) for r, s in zip(p["reproduced"], p["scale"])]
    bsz = pd.DataFrame({
        "output_id": [f"tab5_row{r}_{c}" for r, c in zip(p["row"], p["column"])],
        "version": "bsz",
        "value": value,
        "unit": ["$B/yr" if c == "annual_ca_inctax_loss" else "$B" for c in p["column"]],
        "printed_value": p["printed"].to_numpy(),
        "printed_page": 39,
        "abs_diff": [abs(v - pr) for v, pr in zip(value, p["printed"])],
    })
    r1 = float(p.loc[(p["row"] == 1) & (p["column"] == "wealth_tax_revenue"), "reproduced"].iloc[0])
    ggss = pd.DataFrame({
        "output_id": ["ggss_scoring", "ggss_headline"],
        "version": "ggss",
        "value": [r1, r1],
        "unit": "$B",
        "printed_value": [104.0, 100.0],
        "printed_page": 4,
        "abs_diff": [abs(r1 - 104), abs(r1 - 100)],
    })
    return pd.concat([bsz, ggss], ignore_index=True)
