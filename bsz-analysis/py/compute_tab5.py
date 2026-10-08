"""Python twin of R/compute_tab5.R: Table 5, the one-time 5% CA wealth tax.

score_tab5_cell() estimates revenue at one setting of every guesswork input;
compute_tab5() is the reproduction (the workbook's four rows at its own
values); the explorer grid (site_exports.py) calls the same function at other
values. The two readings the workbook leaves implicit (the mobility share,
row 4's phase-in) are explained in the header of R/compute_tab5.R.
"""
import re

import pandas as pd

from compute_pareto import compute_pareto_summary
from vintage import bsz_vintage, tab5_const


def tab5_scoring_inputs(pareto_missing_r, tab2, tab3):
    pareto = compute_pareto_summary(pareto_missing_r)
    # R: tab2[grepl("^2019.*average", tab2$year), ] picks the average row.
    avg_row = tab2[tab2["year"].map(lambda s: bool(re.search(r"^2019.*average", str(s))))].iloc[0]
    avg_tax = tab3[tab3["metric"].map(lambda s: bool(re.search(r"^Average", str(s))))].iloc[0]
    C = float(avg_row["ca_inctax_estimated"])                      # Tab2!C14, $B/yr

    W0 = tab5_const("baseline_wealth")
    n0 = tab5_const("baseline_n")
    top4_wealth = (tab5_const("page_wealth_B") + tab5_const("brin_wealth_B")
                   + tab5_const("zuck_wealth_B") + tab5_const("huang_wealth_B"))
    top4_private = (tab5_const("page_private_B") + tab5_const("brin_private_B")
                    + tab5_const("zuck_private_B") + tab5_const("huang_private_B"))
    # income tax per $ of wealth outside the top 4's company wealth (Tab5!F18/B18)
    resid_rate = (C - avg_tax["all_top4"] / 1000) / (W0 - (top4_wealth - top4_private))

    pre_names = ["page", "thiel", "hankey", "kalanick"]
    pre_wealth = [tab5_const("page_wealth_B"), tab5_const("thiel_wealth_B"),
                  tab5_const("hankey_wealth_B"), tab5_const("kalanick_wealth_B")]
    pre_loss = ([avg_tax["page"] / 1000 + tab5_const("page_private_B") * resid_rate]
                + [w * resid_rate for w in pre_wealth[1:4]])
    post_names = ["brin", "zuckerberg", "fang"]
    post_wealth = [tab5_const("brin_wealth_B"), tab5_const("zuck_wealth_B"),
                   tab5_const("fang_wealth_B")]
    post_loss = [avg_tax["brin"] / 1000 + tab5_const("brin_private_B") * resid_rate,
                 avg_tax["zuckerberg"] / 1000 + tab5_const("zuck_private_B") * resid_rate,
                 tab5_const("fang_wealth_B") * resid_rate]

    # R's sum() over a short vector adds left to right, as sum() does here.
    return {
        "vintage": bsz_vintage(),
        "n0": n0,
        "W0": W0,
        "C": C,
        "pct_wealth_increase": pareto["pct_wealth_increase"],
        "pct_count_increase": pareto["pct_count_increase"],
        "fraction_in_phasein": pareto["fraction_in_phasein"],
        "pareto_b": pareto["pareto_b"],
        "pareto_extra_n": pareto["total_count_proj"] - pareto["total_count_emp"],
        "pareto_extra_wealth": pareto["total_wealth_proj"] - pareto["total_wealth_emp"],
        "resid_rate": float(resid_rate),
        "leavers": pd.DataFrame({
            "name": pre_names + post_names,
            "timing": ["pre-2026 (escapes the wealth tax)"] * 4
                      + ["post-2026 (pays it, then leaves)"] * 3,
            "wealth": [float(w) for w in pre_wealth + post_wealth],
            "annual_inctax_loss": [float(x) for x in pre_loss + post_loss],
        }),
        "W_pre": float(sum(pre_wealth)),
        "leaver_loss": float(sum(pre_loss) + sum(post_loss)),
        # what row 4 would lose with row 2's phase-in deduction (Tab5!F7 vs F9)
        "row4_phasein_gap": W0 * pareto["pct_wealth_increase"] * pareto["fraction_in_phasein"] * 0.025,
    }


def score_tab5_cell(inp, avoidance=0.10, mobility_share=0.50, avoidance_small=0.20,
                    sell_share=1 / 3, pareto=False, leavers=False, tax_rate=0.05,
                    phasein_rate=0.025, gains_share=0.80, ca_cg_rate=0.133):
    pw = inp["pct_wealth_increase"] if pareto else 0
    W = inp["W0"] * (1 + pw)
    n = inp["n0"] * ((1 + inp["pct_count_increase"]) if pareto else 1)
    taxable = ((1 - avoidance) * (inp["W0"] - (inp["W_pre"] if leavers else 0))
               + (1 - avoidance_small) * inp["W0"] * pw)
    # Row 2 subtracts the phase-in deduction; row 4 (pareto AND leavers) does
    # not (Tab5!F9). Literal workbook behaviour.
    phasein = inp["W0"] * pw * inp["fraction_in_phasein"] * phasein_rate if (pareto and not leavers) else 0
    revenue = tax_rate * taxable - phasein
    extra = revenue * sell_share * gains_share * ca_cg_rate
    loss = (-(avoidance * mobility_share) * inp["C"] * (1 + pw)
            - (inp["leaver_loss"] if leavers else 0))
    return {
        "n_billionaires": float(n),
        "wealth": float(W),
        "taxable_wealth": float(taxable),
        "avoidance_rate": float(1 - taxable / W),
        "wealth_tax_revenue": float(revenue),
        "extra_ca_inctax_sales": float(extra),
        "annual_ca_inctax_loss": float(loss),
    }


TAB5_DEFAULTS = dict(avoidance_rate=0.10, avoidance_small=0.20, wealth_tax_rate=0.05,
                     phasein_rate=0.025, realization_share=1 / 3, ltcg_taxable=0.80,
                     ca_ltcg_rate=0.133)


def compute_tab5(pareto_missing_r, tab2, tab3, **kw):
    a = {**TAB5_DEFAULTS, **kw}
    inp = tab5_scoring_inputs(pareto_missing_r, tab2, tab3)

    def cell(pareto, leavers):
        return score_tab5_cell(
            inp, avoidance=a["avoidance_rate"], mobility_share=0.50,
            avoidance_small=a["avoidance_small"], sell_share=a["realization_share"],
            pareto=pareto, leavers=leavers, tax_rate=a["wealth_tax_rate"],
            phasein_rate=a["phasein_rate"], gains_share=a["ltcg_taxable"],
            ca_cg_rate=a["ca_ltcg_rate"])

    rows = [cell(False, False), cell(True, False), cell(False, True), cell(True, True)]
    out = pd.DataFrame(rows)
    out.insert(0, "scenario", [f"Scenario {i}" for i in range(1, 5)])
    return out
