"""Python twin of R/compute_pareto.R: the Pareto-missing sheet (columns D-L),
its summary cells (I22-I24, J22-J23, I29) and the Fig8/Fig9 Laffer curve.

Vectors are numpy arrays; R's NA is NaN. R's c(x[-1], 0) (shift up, pad the
last cell with 0) is np.append(x[1:], 0).
"""
import numpy as np
import pandas as pd


def compute_pareto_missing(pareto_inputs, anchor_threshold=4.5):
    d = pareto_inputs
    for c in ("threshold_b", "n_above_threshold_emp", "wealth_above_threshold"):
        assert c in d.columns
    A = d["threshold_b"].to_numpy(float)
    B = d["n_above_threshold_emp"].to_numpy(float)
    C = d["wealth_above_threshold"].to_numpy(float)
    n = len(A)

    pareto_b_emp = C / (B * A)

    # Excel treats the cell below the last row as 0; replicate.
    next_C = np.append(C[1:], 0.0)
    next_B = np.append(B[1:], 0.0)
    next_A = np.append(A[1:], np.nan)
    wealth_in_bracket = C - next_C
    actual_density = B - next_B
    with np.errstate(divide="ignore", invalid="ignore"):
        avg_wealth_in_bracket_emp = wealth_in_bracket / actual_density

    anchor = np.flatnonzero(A == anchor_threshold)
    if len(anchor) != 1:
        raise ValueError(f"Anchor threshold {anchor_threshold} not present uniquely in threshold_b")
    a = int(anchor[0])                      # 0-based; R's anchor_i is a + 1
    D23 = np.mean(pareto_b_emp[a:n])        # average Pareto b above anchor
    D24 = D23 / (D23 - 1)                   # corresponding Pareto a

    n_above_threshold_proj = B.copy()
    below = np.arange(a)                    # R: seq_len(anchor_i - 1)
    n_above_threshold_proj[below] = B[a] * (A[a] / A[below]) ** D24

    next_H = np.append(n_above_threshold_proj[1:], 0.0)
    projected_density = n_above_threshold_proj - next_H

    projected_wealth_in_bracket = wealth_in_bracket.copy()
    for i in below:
        projected_wealth_in_bracket[i] = (
            D23 * n_above_threshold_proj[i] * (A[i] - next_A[i] * (A[i] / next_A[i]) ** D24)
        )
    with np.errstate(divide="ignore", invalid="ignore"):
        avg_wealth_in_bracket_proj = projected_wealth_in_bracket / projected_density

    pareto_b_proj = pareto_b_emp.copy()
    pareto_b_proj[below] = D23

    return pd.DataFrame({
        "threshold_b": A,
        "n_above_threshold_emp": B,
        "wealth_above_threshold": C,
        "pareto_b_emp": pareto_b_emp,
        "wealth_in_bracket": wealth_in_bracket,
        "actual_density": actual_density,
        "avg_wealth_in_bracket_emp": avg_wealth_in_bracket_emp,
        "n_above_threshold_proj": n_above_threshold_proj,
        "projected_wealth_in_bracket": projected_wealth_in_bracket,
        "projected_density": projected_density,
        "avg_wealth_in_bracket_proj": avg_wealth_in_bracket_proj,
        "pareto_b_proj": pareto_b_proj,
    })


def pareto_n_above(threshold, anchor_threshold, anchor_count, pareto_a):
    return anchor_count * (anchor_threshold / threshold) ** pareto_a


def pareto_wealth_in_bracket(lo, hi, anchor_threshold, anchor_count, pareto_a, pareto_b):
    H_lo = pareto_n_above(lo, anchor_threshold, anchor_count, pareto_a)
    return pareto_b * H_lo * (lo - hi * (lo / hi) ** pareto_a)


def compute_pareto_summary(pareto_missing_r, anchor_threshold=4.5, phasein_lo=1.0, phasein_hi=1.1):
    d = pareto_missing_r
    a = int(np.flatnonzero(d["threshold_b"].to_numpy() == anchor_threshold)[0])
    anchor_count = d["n_above_threshold_emp"].iloc[a]
    pareto_b = np.mean(d["pareto_b_emp"].to_numpy()[a:])
    pareto_a = pareto_b / (pareto_b - 1)

    # R's sum(x, na.rm = TRUE) is np.nansum.
    total_wealth_emp = np.nansum(d["wealth_in_bracket"])              # E22
    total_count_emp = np.nansum(d["actual_density"])                  # F22
    total_wealth_proj = np.nansum(d["projected_wealth_in_bracket"])   # I22
    total_count_proj = np.nansum(d["projected_density"])              # J22

    pct_wealth_increase = total_wealth_proj / total_wealth_emp - 1    # I23
    pct_count_increase = total_count_proj / total_count_emp - 1       # J23

    wealth_in_phasein = pareto_wealth_in_bracket(
        phasein_lo, phasein_hi, anchor_threshold=anchor_threshold,
        anchor_count=anchor_count, pareto_a=pareto_a, pareto_b=pareto_b)   # I29
    fraction_in_phasein = wealth_in_phasein / (total_wealth_proj - total_wealth_emp)  # I24

    return {
        "pareto_a": float(pareto_a),
        "pareto_b": float(pareto_b),
        "total_wealth_emp": float(total_wealth_emp),
        "total_count_emp": float(total_count_emp),
        "total_wealth_proj": float(total_wealth_proj),
        "total_count_proj": float(total_count_proj),
        "pct_wealth_increase": float(pct_wealth_increase),
        "pct_count_increase": float(pct_count_increase),
        "wealth_in_phasein": float(wealth_in_phasein),
        "fraction_in_phasein": float(fraction_in_phasein),
    }


def compute_fig8_laffer(semi_elasticity_mobility=10, current_inctax_per_wealth=0.002,
                        current_wealth_tax_base=2000, deconcentration_elasticity=15,
                        rate_step=0.001, max_rate=0.20):
    # R's seq(0, max_rate, by = rate_step) computes from + (0:n) * by and caps
    # the result at `to` (pmin); the same expression gives the same doubles
    # (np.arange with a float step would accumulate instead).
    n = int(max_rate / rate_step + 1e-10)
    rates = np.minimum(0 + np.arange(n + 1) * rate_step, max_rate)
    base = current_wealth_tax_base * np.exp(-(rates - current_inctax_per_wealth) * semi_elasticity_mobility)
    ref_pow = (1 - current_inctax_per_wealth) ** deconcentration_elasticity
    return pd.DataFrame({
        "tax_rate": rates,
        "mechanical_tax_revenue": rates * current_wealth_tax_base,
        "wealth_tax_base": base,
        "actual_tax_revenue": rates * base,
        "long_run_tax_revenue": rates * base * (1 - rates) ** deconcentration_elasticity / ref_pow,
    })
