"""Entry point for the Python twin: runs every step and writes
export/py/inputs.csv + export/py/outputs.csv, matching the schema and
row ids of export/r/{inputs,outputs}.csv exactly (same input_id/output_id
values) so tests/testthat/test-parity.R can join on them.

Run from opposing-analysis/:  /opt/anaconda3/bin/python3 py/run_export.py
"""
import csv
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))

from rauh_repo import rauh_workbook_path, rauh_nber_final_csv  # noqa: E402
from pareto import compute_pareto_fit, compute_pareto_income_schedule  # noqa: E402
from income_tax_mc import compute_income_tax_mc, REPORTED_K  # noqa: E402
from revenue_chain import (  # noqa: E402
    extract_calculations_preferred, extract_calculations_expanded, compute_revenue_chain,
)
from npv_tables import compute_npv_table9  # noqa: E402
from npv_mc import compute_npv_mc_ssrn, compute_npv_mc_nber, npv_mc_analytic_mean  # noqa: E402
from nber_final import extract_nber_final, compute_nber_ceiling  # noqa: E402

INPUT_FIELDS = ["input_id", "version", "description", "value", "unit", "label",
                 "provenance", "source", "page"]
OUTPUT_FIELDS = ["output_id", "version", "value", "unit", "printed_value",
                  "printed_page", "abs_diff"]


def build_inputs(pareto_fit, revenue_chain, nber_ceiling):
    rows = [
        ("n_billionaires", "both", "CA billionaires in the domestic base", 212, "count", "data",
         "public", "CA_Billionaires_Revenues_and_Migration_final.xlsx!Summary_Preferred!D15", 11),
        ("baseline_net_worth", "both", "Aggregate net worth, 212 domestic billionaires", 1894.8,
         "$B", "data", "public",
         "CA_Billionaires_Revenues_and_Migration_final.xlsx!Summary_Preferred!E15", 11),
        ("tax_rate", "both", "Statutory wealth tax rate", 0.05, "rate", "data", "public",
         "CA_Billionaires_Revenues_and_Migration_final.xlsx!Calculations_Preferred!N3", 10),
        ("pareto_alpha", "both", "Pareto tail parameter fit to FTB AGI thresholds",
         pareto_fit["alpha"], "coefficient", "research", "public",
         "monte_carlo_sim.R:33-44 (FTB PIT Annual Report 2024, Table B-4A)", 15),
        ("bracket_tax_ty23", "both", "TY2023 tax liability, $10M+ AGI bracket", 11.1, "$B",
         "data", "public", "monte_carlo_sim.R:51 (FTB Table B-4A)", 15),
        ("total_pit_fy25", "both", "Total FY2024-25 PIT collections", 130.0, "$B", "data",
         "public", "monte_carlo_sim.R:89 (CA State Controller cash receipts)", 15),
        ("brulhart_semi_elasticity", "ssrn", "Migration semi-elasticity, Brulhart et al. (2022)",
         10.32, "coefficient", "research", "public", "Summary_Preferred!I8 (paper eq.12)", 13),
        ("wt_central_scenario", "ssrn",
         "Table 9 Central Scenario wealth tax revenue (literal input, not linked to Sec 4's chain)",
         42.0, "$B", "scenario", "public", "NPV_calculations_5.2.xlsx!B12", 19),
        ("npv_r_range", "ssrn", "Real discount rate (r) simulation range", "", "rate",
         "guesswork", "public", "NPV_dist.R:47 (paper eq.24 text; eq.18-20 instead specify r-g)", 20),
        ("q_litigation_survival", "nber",
         "Probability the Act survives constitutional challenge (ASC 740-10 more-likely-than-not)",
         0.50, "probability", "guesswork", "public",
         "NBER_2026_litigation_weighted/README.md (assumptions table); not an explicit "
         "multiplier in NPV_dist_v8.R - see MISMATCHES.md #5", ""),
        ("nber_growth_rate", "nber",
         "Growth applied to the Jan-1-2026 snapshot to the Dec-31-2026 valuation date", 0.07,
         "rate", "data", "author-shared",
         "final.csv (net_worth_usd_7pct column); NBER README assumptions table", ""),
        ("nber_ceiling_hardcoded", "nber",
         "wt_max literal in NPV_dist_v8.R (script uses this, not the value re-derived from final.csv)",
         72, "$B", "data", "author-shared", "NPV_dist_v8.R:19", ""),
        ("nber_ceiling_recomputed", "nber",
         "wt_max re-derived from final.csv: domestic total minus 7 removed_departed rows",
         nber_ceiling["ceiling_recomputed"], "$B", "derived", "author-shared",
         "py/nber_final.py:compute_nber_ceiling() from final.csv", ""),
        ("nber_international_net_worth", "nber",
         "28 international billionaires excluded from the domestic base",
         nber_ceiling["international_net_worth"], "$B", "data", "author-shared",
         "final.csv (panel == international, net_worth_usd)", ""),
    ]
    return [dict(zip(INPUT_FIELDS, r)) for r in rows]


def build_outputs(pareto_fit, income_tax_rows, revenue_chain, npv_table9,
                   npv_mc_ssrn_summary, npv_mc_nber_summary, nber_ceiling):
    by_k = {r["K"]: r for r in income_tax_rows}
    central9 = next(r for r in npv_table9 if r["scenario"] == "central" and r["r"] == 0.015)

    rows = [
        ("pareto_alpha", "both", pareto_fit["alpha"], "coefficient", 1.44, 15),
        ("income_tax_mc_k212", "both", by_k[212]["mean_fy25"], "$B", 5.76, 17),
        ("income_tax_mc_k300", "both", by_k[300]["mean_fy25"], "$B", 4.61, 17),
        ("income_tax_mc_k500", "both", by_k[500]["mean_fy25"], "$B", 3.31, 17),
        ("revenue_baseline", "both", revenue_chain["baseline_precise"], "$B", 94.20, 10),
        ("revenue_confirmed6", "both", revenue_chain["confirmed6_ceiling"], "$B", 67.51, 11),
        ("revenue_expanded10", "both", revenue_chain["expanded10_estimate"], "$B", 55.10, 13),
        ("revenue_literature_calibrated", "ssrn", revenue_chain["literature_calibrated"], "$B", 45.59, 14),
        ("table9_central_npv_r015", "ssrn", central9["npv"], "$B", -126.1, 19),
        ("npv_mc_ssrn_mean", "ssrn", npv_mc_ssrn_summary["mean"], "$B", -24.7, 20),
        ("npv_mc_ssrn_median", "ssrn", npv_mc_ssrn_summary["median"], "$B", -19.1, 20),
        ("npv_mc_ssrn_sd", "ssrn", npv_mc_ssrn_summary["sd"], "$B", 38.4, 20),
        ("npv_mc_ssrn_pct_negative", "ssrn", npv_mc_ssrn_summary["pct_negative"], "%", 71, 20),
        ("nber_domestic_grown", "nber", nber_ceiling["domestic_total_grown"], "$B", 100.9, ""),
        ("nber_ceiling", "nber", nber_ceiling["ceiling_recomputed"], "$B", 72.06, ""),
        ("nber_international", "nber", nber_ceiling["international_net_worth"], "$B", 146.3, ""),
        ("npv_mc_nber_mean", "nber", npv_mc_nber_summary["mean"], "$B", -38.9, ""),
        ("npv_mc_nber_median", "nber", npv_mc_nber_summary["median"], "$B", -35.3, ""),
        ("npv_mc_nber_pct_negative", "nber", npv_mc_nber_summary["pct_negative"], "%", 85.2, ""),
    ]
    out = []
    for output_id, version, value, unit, printed_value, printed_page in rows:
        abs_diff = abs(value - printed_value) if isinstance(printed_value, (int, float)) else ""
        out.append({
            "output_id": output_id, "version": version, "value": value, "unit": unit,
            "printed_value": printed_value, "printed_page": printed_page, "abs_diff": abs_diff,
        })
    return out


def write_csv(path, fields, rows):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(rows)


def main():
    workbook = rauh_workbook_path()
    final_csv = rauh_nber_final_csv()

    pareto_fit = compute_pareto_fit()
    sched = compute_pareto_income_schedule(pareto_fit)
    income_tax_rows = compute_income_tax_mc(sched["tax_by_rank"])

    calc_preferred = extract_calculations_preferred(workbook)
    calc_expanded = extract_calculations_expanded(workbook)
    revenue_chain = compute_revenue_chain(calc_preferred, calc_expanded)

    npv_table9 = compute_npv_table9()

    npv_ssrn = compute_npv_mc_ssrn()
    npv_nber = compute_npv_mc_nber()

    final_rows = extract_nber_final(final_csv)
    nber_ceiling = compute_nber_ceiling(final_rows)

    inputs = build_inputs(pareto_fit, revenue_chain, nber_ceiling)
    outputs = build_outputs(pareto_fit, income_tax_rows, revenue_chain, npv_table9,
                             npv_ssrn["summary"], npv_nber["summary"], nber_ceiling)

    write_csv("export/py/inputs.csv", INPUT_FIELDS, inputs)
    write_csv("export/py/outputs.csv", OUTPUT_FIELDS, outputs)

    analytic_ssrn = npv_mc_analytic_mean(35, 67.51, 3.3, 5.8, 0.015, 0.045,
                                          f_mode="ssrn", baseline_revenue=94.2)
    analytic_nber = npv_mc_analytic_mean(0, 72, 3.3, 5.8, 0.015, 0.045,
                                          f_mode="nber", f_min=0.30, f_max=0.60)
    print(f"pareto alpha={pareto_fit['alpha']:.4f} r2={pareto_fit['r_squared']:.4f}")
    print(f"revenue chain: {revenue_chain}")
    print(f"npv_mc_ssrn: {npv_ssrn['summary']}  analytic_mean={analytic_ssrn:.2f}")
    print(f"npv_mc_nber: {npv_nber['summary']}  analytic_mean={analytic_nber:.2f}")
    print(f"nber_ceiling: {nber_ceiling}")
    print("Wrote export/py/inputs.csv and export/py/outputs.csv")


if __name__ == "__main__":
    main()
