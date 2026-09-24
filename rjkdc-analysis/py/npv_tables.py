"""Python twin of R/npv_tables.R (Table 9, Table 10). Deterministic."""

NPV_TABLE9_SCENARIOS = {
    "central": {"label": "Central Scenario", "WT": 42.0, "C": 4.55},
    "six_confirmed": {"label": "Only 6 Confirmed Departures", "WT": 67.51, "C": 3.3},
    "lit_calibrated": {"label": "Literature Calibrated Departures", "WT": 35.0, "C": 5.8},
}
NPV_DISCOUNT_RATES = (0.015, 0.03, 0.045)


def compute_npv_table9(baseline=94.2, scenarios=None, r_values=NPV_DISCOUNT_RATES):
    scenarios = scenarios or NPV_TABLE9_SCENARIOS
    rows = []
    for name, s in scenarios.items():
        f = 1 - (s["WT"] / baseline)
        for r in r_values:
            annual_loss = f * s["C"]
            pv_lost = annual_loss / r
            npv = s["WT"] - pv_lost
            rows.append({
                "scenario": name, "label": s["label"], "WT": s["WT"], "C": s["C"],
                "f": f, "r": r, "annual_loss": annual_loss, "pv_lost": pv_lost, "npv": npv,
            })
    return rows


def compute_npv_table10(baseline=94.2, scenarios=None, r_values=NPV_DISCOUNT_RATES):
    scenarios = scenarios or NPV_TABLE9_SCENARIOS
    rows = []
    for name, s in scenarios.items():
        for r in r_values:
            x_star = (s["WT"] * r) / s["C"]
            rows.append({
                "scenario": name, "label": s["label"], "WT": s["WT"], "C": s["C"],
                "r": r, "break_even_pct": x_star,
            })
    return rows
