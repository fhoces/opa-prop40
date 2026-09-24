"""Python twin of R/income_tax_mc.R (Table 8, p.17).

numpy cannot reproduce R's Mersenne-Twister sample() draw stream, so this is
an INDEPENDENT Monte Carlo of the same algorithm (draw 212 of the top K
positions without replacement, sum their tax_by_rank), not a bit-for-bit
replay. Two scope reductions from the R side, both documented here rather
than silently applied:

1. Only the seven K values Table 8 actually prints (212, 250, 300, 400, 500,
   750, 1000) are simulated, not the full 37-point sweep - the full sweep's
   RNG-order-parity requirement (R/income_tax_mc.R's docstring) is specific
   to matching the authors' own script bit-for-bit, which is an R-only
   concern (see the R test that runs their script from a scratch copy).
2. n_sims defaults to 20,000 rather than 100,000: the vectorized
   without-replacement draw below materializes an (n_sims, K) array, and at
   K=1000 and n_sims=100,000 that is 800MB. 20,000 keeps every K's array
   under 200MB while still giving a tight enough Monte Carlo error for the
   parity tolerance used in tests/testthat/test-parity.R (documented there:
   +/-2 $B on MC-derived outputs, several times wider than this n_sims would
   need for the mean to be trustworthy on its own).
"""
import numpy as np

REPORTED_K = (212, 250, 300, 400, 500, 750, 1000)


def income_tax_mc_scale_factor(bracket_tax_ty23=11.1, total_pit_fy25=130.0):
    total_pit_ty23 = bracket_tax_ty23 / 0.114
    return total_pit_fy25 / total_pit_ty23


def _draw_without_replacement_sum(rng, tax_by_rank, K, n_billionaires, n_sims):
    if K == n_billionaires:
        # Deterministic: all K positions are drawn.
        total = tax_by_rank[:K].sum()
        return np.full(n_sims, total)
    keys = rng.random((n_sims, K))
    idx = np.argpartition(keys, n_billionaires, axis=1)[:, :n_billionaires]
    return tax_by_rank[idx].sum(axis=1)


def compute_income_tax_mc(tax_by_rank, seed=42, n_sims=20000, n_billionaires=212,
                           K_values=REPORTED_K, bracket_tax_ty23=11.1,
                           total_pit_fy25=130.0):
    scale_factor = income_tax_mc_scale_factor(bracket_tax_ty23, total_pit_fy25)
    rng = np.random.default_rng(seed)

    rows = []
    for K in K_values:
        sims = _draw_without_replacement_sum(rng, tax_by_rank, K, n_billionaires, n_sims)
        rows.append({
            "K": K,
            "mean_fy25": float(sims.mean()) * scale_factor,
            "median_fy25": float(np.median(sims)) * scale_factor,
            "p05_fy25": float(np.percentile(sims, 5)) * scale_factor,
            "p95_fy25": float(np.percentile(sims, 95)) * scale_factor,
            "sd": float(sims.std(ddof=1)),
        })
    return rows
