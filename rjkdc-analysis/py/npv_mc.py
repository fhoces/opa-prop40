"""Python twin of R/npv_mc.R. Independent numpy RNG (not bit-parity with R);
MC summaries must agree within Monte Carlo error, analytic mean must match
exactly (it's a closed form, no RNG)."""
import math

import numpy as np


def compute_npv_mc_ssrn(seed=2026, n_sims=100000, baseline_revenue=94.2,
                         wt_min=35, wt_max=67.51, c_min=3.3, c_max=5.8,
                         r_min=0.015, r_max=0.045):
    rng = np.random.default_rng(seed)
    wt = rng.uniform(wt_min, wt_max, n_sims)
    c_income = rng.uniform(c_min, c_max, n_sims)
    r_discount = rng.uniform(r_min, r_max, n_sims)

    f = 1 - (wt / baseline_revenue)
    annual_loss = f * c_income
    pv_lost = annual_loss / r_discount
    npv = wt - pv_lost
    return {"npv": npv, "summary": npv_mc_summary(npv)}


def compute_npv_mc_nber(seed=2026, n_sims=100000, wt_min=0, wt_max=72,
                         f_min=0.30, f_max=0.60, c_min=3.3, c_max=5.8,
                         rg_min=0.015, rg_max=0.045):
    rng = np.random.default_rng(seed)
    wt = rng.uniform(wt_min, wt_max, n_sims)
    f = rng.uniform(f_min, f_max, n_sims)
    c_income = rng.uniform(c_min, c_max, n_sims)
    rg_discount = rng.uniform(rg_min, rg_max, n_sims)

    npv = wt - (f * c_income) / rg_discount
    return {"npv": npv, "summary": npv_mc_summary(npv)}


def npv_mc_summary(npv):
    return {
        "n": len(npv),
        "mean": float(np.mean(npv)),
        "median": float(np.median(npv)),
        "sd": float(np.std(npv, ddof=1)),
        "p05": float(np.percentile(npv, 5)),
        "p95": float(np.percentile(npv, 95)),
        "pct_negative": float(100 * np.mean(npv < 0)),
    }


def npv_mc_analytic_mean(wt_min, wt_max, c_min, c_max, rate_min, rate_max,
                          f_mode="ssrn", baseline_revenue=None, f_min=None, f_max=None):
    e_wt = (wt_min + wt_max) / 2
    e_c = (c_min + c_max) / 2
    e_inv_rate = math.log(rate_max / rate_min) / (rate_max - rate_min)
    if f_mode == "ssrn":
        e_f = 1 - e_wt / baseline_revenue
    else:
        e_f = (f_min + f_max) / 2
    return e_wt - e_f * e_c * e_inv_rate
