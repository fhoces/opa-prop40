"""Python twin of R/pareto.R. Deterministic (no RNG); must match R to 1e-9."""
import numpy as np

PARETO_THRESHOLDS = np.array([1e6, 2e6, 3e6, 4e6, 5e6, 10e6])
PARETO_FILER_COUNTS = np.array([131400, 43900, 24700, 16700, 12200, 4729])


def compute_pareto_fit(thresholds=PARETO_THRESHOLDS, filer_counts=PARETO_FILER_COUNTS):
    x = np.log(thresholds)
    y = np.log(filer_counts)
    # OLS via numpy.polyfit, mirroring R's lm(log(filer_counts) ~ log(thresholds)).
    slope, intercept = np.polyfit(x, y, 1)
    alpha = -slope
    a = np.exp(intercept)
    y_hat = intercept + slope * x
    ss_res = np.sum((y - y_hat) ** 2)
    ss_tot = np.sum((y - np.mean(y)) ** 2)
    r_squared = 1 - ss_res / ss_tot
    return {
        "alpha": float(alpha),
        "r_squared": float(r_squared),
        "A": float(a),
        "thresholds": thresholds,
        "filer_counts": filer_counts,
    }


def compute_pareto_income_schedule(pareto_fit, n_filers=4729, bracket_tax_ty23=11.1,
                                    n_billionaires=212):
    alpha = pareto_fit["alpha"]
    a = pareto_fit["A"]
    ranks = np.arange(1, n_filers + 1)
    incomes = (a / ranks) ** (1 / alpha)
    income_shares = incomes / incomes.sum()
    tax_by_rank = income_shares * bracket_tax_ty23

    continuous_top_share = (n_billionaires / n_filers) ** ((alpha - 1) / alpha)
    discrete_top_share = income_shares[:n_billionaires].sum()
    rescale_factor = continuous_top_share / discrete_top_share
    tax_by_rank = tax_by_rank * rescale_factor

    return {
        "tax_by_rank": tax_by_rank,
        "continuous_top_share": float(continuous_top_share),
        "discrete_top_share": float(discrete_top_share),
        "rescale_factor": float(rescale_factor),
        "top_212_tax_ty23": float(tax_by_rank[:n_billionaires].sum()),
    }
