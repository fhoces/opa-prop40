"""Power analysis for the survey experiment's pre-analysis plan.

Usage: python3 comparison/survey/power/sim.py   (writes into comparison/survey/power/out/)

Writes the figures, a macros file (every number the write-up quotes) and the tables.
The registered estimator is OLS with entry-point fixed effects and HC2 standard errors. The tests of
each family are adjusted with the Romano-Wolf step-down procedure: studentized statistics, and a pairs
bootstrap that redraws respondents within each entry-point stratum. The analytic thresholds use the
Bonferroni bound, which is at or above the Romano-Wolf threshold. Monte Carlo simulations of the
registered estimator check the formulas and give the Romano-Wolf thresholds.
"""
import os
import time

for _v in ("OPENBLAS_NUM_THREADS", "OMP_NUM_THREADS", "MKL_NUM_THREADS", "VECLIB_MAXIMUM_THREADS"):
    os.environ.setdefault(_v, "1")   # thousands of tiny matrix solves: one thread is much faster
from math import comb  # noqa: E402

import numpy as np  # noqa: E402
from scipy import stats  # noqa: E402
import matplotlib  # noqa: E402

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.ticker import PercentFormatter  # noqa: E402

START = time.time()
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "out")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(20261016)


def lap(msg):
    print(f"[{time.time() - START:6.0f} s] {msg}", flush=True)


ALPHA, POWER = 0.05, 0.80
K = 5            # required questions in the lean index
KWORD = {5: "five", 6: "six", 7: "seven"}[K]
KORD = {5: "fifth", 6: "sixth", 7: "seventh"}[K]
D_TARGET = 0.5   # standardized effect an analysis must be able to detect before it is run
D_FIG = (0.1, 0.3, 0.5)  # true standardized effects on the index shown in Figure 1, one panel each
D_MAG = (0.1, 0.2, 0.3, 0.4, 0.5)  # effects translated into index units in Table 1
B_REG = 2000     # bootstrap draws in the registered Romano-Wolf adjustment
B_SIM = 199      # bootstrap draws inside each simulated sample, for speed; ALPHA * (B_SIM + 1) is whole
P_EXPL = 0.6     # assumed share entering through the explorer (forms 3 and 4); the rest through share (5 and 6)
SHARES0 = (0.5, 0.5, P_EXPL)   # expertise, prior exposure, entry point (explorer = 1)


# ---------- analytic ----------
def mult(alpha=ALPHA, power=POWER, m=1):
    """z_{1 - alpha/(2m)} + z_{power}: the MDE multiplier with a Bonferroni bound over m tests."""
    return stats.norm.ppf(1 - alpha / (2 * m)) + stats.norm.ppf(power)


def mde_main(N, m=1):
    """Standardized MDE of a treatment effect in the full sample, N respondents, half treated."""
    return 2 * mult(m=m) / np.sqrt(N)


def mde_within(N, p, m=1):
    """Standardized MDE of the treatment effect inside a subgroup holding share p of the sample."""
    return 2 * mult(m=m) / np.sqrt(N * p)


def mde_diff(N, p, m=1):
    """Standardized MDE of the difference between two subgroups' treatment effects."""
    return 2 * mult(m=m) / np.sqrt(N * p * (1 - p))


def n_star(kind, d=D_TARGET, p=1.0, m=1):
    """Smallest N at which the analysis's standardized MDE is at most d."""
    base = (2 * mult(m=m) / d) ** 2
    if kind == "within":
        base /= p
    elif kind == "diff":
        base /= p * (1 - p)
    return int(np.ceil(base))


# ---------- data-generating process ----------
# Respondent i has a latent lean theta_i ~ N(0, tau^2). On question k, the latent answer is
# theta_i + a_k + beta * T_i + e_ik, e ~ N(0, 1). It is coded +1 (BSZ value) above c, -1 (JR value)
# below -c, and 0 (equally credible or unsure) in between.
A_K = np.array([0.3, -0.2, 0.5, -0.4, 0.0, 0.2])[:K]
assert len(A_K) == K
CUT = 0.5


def draw(N, beta, tau, p_sub=0.5, het=0.0):
    T = rng.permutation(np.arange(N) % 2)
    G = (rng.random(N) < p_sub).astype(float)            # a pre-treatment subgroup
    E = (rng.random(N) < P_EXPL).astype(int)               # entry point, two strata: explorer 1, share 0
    theta = rng.normal(0, tau, N)
    shift = (beta + het * (G - p_sub)) * T
    lat = theta[:, None] + A_K[None, :] + shift[:, None] + rng.normal(0, 1, (N, K))
    y = np.where(lat > CUT, 1, np.where(lat < -CUT, -1, 0))
    return y, T, G, E


def draw_dims(N, beta, tau, shares=SHARES0, het=0.0, het2=0.0):
    """The same population with all three binary dimensions G1, G2, G3, independent of each other. G3 is
    the entry point (explorer 1, share 0), which is also the stratum E. het is a difference in the latent shift across the halves of G1; het2 a two-way
    difference across the four cells of G1 and G2 (each cell gets +-het2/4)."""
    T = rng.permutation(np.arange(N) % 2)
    G = (rng.random((N, 3)) < np.asarray(shares)).astype(int)
    E = G[:, 2]
    theta = rng.normal(0, tau, N)
    shift = (beta + het * (G[:, 0] - shares[0]) + het2 * (G[:, 0] - 0.5) * (G[:, 1] - 0.5)) * T
    lat = theta[:, None] + A_K[None, :] + shift[:, None] + rng.normal(0, 1, (N, K))
    y = np.where(lat > CUT, 1, np.where(lat < -CUT, -1, 0))
    return y, T, E, G


def hc2_t(X, y, j):
    XtX_inv = np.linalg.inv(X.T @ X)
    b = XtX_inv @ X.T @ y
    e = y - X @ b
    h = np.einsum("ij,jk,ik->i", X, XtX_inv, X)
    meat = (X * (e ** 2 / (1 - h))[:, None]).T @ X
    V = XtX_inv @ meat @ XtX_inv
    return b[j] / np.sqrt(V[j, j])


def design(T, E, G=None):
    cols = [np.ones_like(T, float), T.astype(float), (E == 1).astype(float)]
    if G is not None:
        cols += [G, T * G]
    return np.column_stack(cols)


def crit(N, k, m=1):
    return stats.t.ppf(1 - ALPHA / (2 * m), N - k)


# ---------- Romano-Wolf step-down, vectorized ----------
# Every regressor is a function of the respondent's fine cell: arm T (2) x stratum E (2) x G1, G2, G3
# (8), 32 cells, of which the 16 with E equal to G3 can hold respondents. OLS and HC2 then need only, per cell, the count of respondents and the sums of y and
# y^2. A bootstrap sample is a vector of counts over the distinct (cell, answers) types, so B samples
# are a B x types matrix and every regression of a family runs on all of them at once.
NC = 32
_CI = np.arange(NC)
CT = (_CI % 2).astype(float)
CE = (_CI // 2) % 2
CG = np.column_stack([((_CI // 4) >> j) & 1 for j in range(3)]).astype(float)
VALID = CE == CG[:, 2]
X0 = np.column_stack([np.ones(NC), CT, (CE == 1).astype(float)])
PAIRS = ((0, 1), (0, 2), (1, 2))


def prune(X, mask, r):
    """Drop the columns that are collinear inside the regression's cells. The entry-point dimension is
    the stratum, so its indicator repeats the stratum dummy, which is dropped. Returns X and the tested
    column."""
    rows = (mask > 0) & VALID
    keep = []
    for j in range(X.shape[1]):
        if np.linalg.matrix_rank(X[rows][:, keep + [j]]) == len(keep) + 1:
            keep.append(j)
    assert r in keep
    return X[:, keep], keep.index(r)


def family(kind):
    """Cell designs of one family's regressions, in groups of consecutive regressions of the same shape:
    X (S, C, p), subsample masks (S, C), tested column."""
    one = np.ones(NC)
    if kind == "full":
        regs = [(X0, one, 1)]
    elif kind == "diff1":   # H2 to H4: T x Gj in the H1 equation, one regression per dimension
        regs = [(np.column_stack([X0, CG[:, j], CT * CG[:, j]]), one, 4) for j in range(3)]
    elif kind == "diff2":   # T x Ga x Gb in the saturated equation, one regression per pair
        regs = [(np.column_stack([X0, CG[:, a], CG[:, b], CG[:, a] * CG[:, b], CT * CG[:, a], CT * CG[:, b],
                                  CT * CG[:, a] * CG[:, b]]), one, 8) for a, b in PAIRS]
    elif kind == "h5cell":  # H5: the H1 equation inside experts (G1 = 1) without prior exposure (G2 = 1)
        regs = [(X0, ((CG[:, 0] == 1) & (CG[:, 1] == 1)).astype(float), 1)]
    else:                   # the H1 equation inside each cell of each combination
        if kind == "cell1":
            m = [CG[:, j] == g for j in range(3) for g in (0, 1)]
        elif kind == "cell2":
            m = [(CG[:, a] == x) & (CG[:, b] == z) for a, b in PAIRS for x in (0, 1) for z in (0, 1)]
        else:               # cell3
            m = [(CG[:, 0] == x) & (CG[:, 1] == z) & (CG[:, 2] == v) for x in (0, 1) for z in (0, 1) for v in (0, 1)]
        regs = [(X0, mi.astype(float), 1) for mi in m]
    groups = []
    for X, mask, r in regs:
        Xp, rp = prune(X, mask, r)
        if groups and groups[-1][2] == rp and groups[-1][0][-1].shape == Xp.shape:
            groups[-1][0].append(Xp)
            groups[-1][1].append(mask)
        else:
            groups.append(([Xp], [mask], rp))
    return [(np.stack(Xs), np.array(ms, float), r) for Xs, ms, r in groups]


FAMILY = {k: family(k) for k in ("full", "diff1", "diff2", "cell1", "cell2", "cell3", "h5cell")}
FAMILY["h5"] = FAMILY["diff1"] + FAMILY["h5cell"]   # H2 to H4 joined by H5: tests 0 to 2, then H5


def boot_stats(cell, Y, B):
    """Cell counts n (B+1, C) and outcome sums S1, S2 (B+1, C, L). Row 0 is the sample. Rows 1 to B are
    pairs-bootstrap samples, each redrawing every stratum's respondents with replacement."""
    lo = Y.min()
    base = Y.max() - lo + 1
    key = cell * base ** Y.shape[1] + ((Y - lo) * base ** np.arange(Y.shape[1])).sum(1)
    _, first, inv, cnt = np.unique(key, return_index=True, return_inverse=True, return_counts=True)
    U = len(cnt)
    tcell = cell[first]
    W = np.zeros((B + 1, U))
    W[0] = cnt
    for s in range(2):
        cols = np.flatnonzero(CE[tcell] == s)
        n_s = int(cnt[cols].sum())
        if B == 0 or n_s == 0:
            continue
        if n_s > 4 * len(cols):   # many respondents per type: draw type counts directly
            W[1:, cols] = rng.multinomial(n_s, cnt[cols] / n_s, size=B)
        else:                     # few: redraw respondents
            rows = np.flatnonzero(CE[cell] == s)
            pick = inv[rows[rng.integers(0, n_s, (B, n_s))]]
            W[1:] += np.bincount((np.arange(B)[:, None] * U + pick).ravel(), minlength=B * U).reshape(B, U)
    oh = np.zeros((U, NC))
    oh[np.arange(U), tcell] = 1
    Yt = Y[first].astype(float)
    L = Yt.shape[1]
    n = W @ oh
    S1 = (W @ (oh[:, :, None] * Yt[:, None, :]).reshape(U, NC * L)).reshape(B + 1, NC, L)
    S2 = (W @ (oh[:, :, None] * (Yt ** 2)[:, None, :]).reshape(U, NC * L)).reshape(B + 1, NC, L)
    return n, S1, S2


def coef_se(n, S1, S2, kind):
    """Tested coefficient, its HC2 standard error (both B+1 x S*L) and residual df (S*L) per test."""
    parts = [coef_se_group(n, S1, S2, *g) for g in FAMILY[kind]]
    return tuple(np.concatenate([p[i] for p in parts], axis=-1) for i in range(3))


def coef_se_group(n, S1, S2, X, masks, r):
    S, C, p = X.shape
    B1, _, L = S1.shape
    w = masks[:, None, :] * n[None]                                    # (S, B1, C)
    XX = (X[:, :, :, None] * X[:, :, None, :]).reshape(S, C, p * p)
    M = (w @ XX).reshape(S, B1, p, p)
    try:
        Minv = np.linalg.inv(M)
    except np.linalg.LinAlgError:   # a draw with an empty arm in some cell: drop that draw
        Minv = np.linalg.pinv(M)
        Minv[np.linalg.matrix_rank(M) < p] = np.nan
    A = Minv @ X.transpose(0, 2, 1)[:, None]                          # (S, B1, p, C)
    h = (A * X.transpose(0, 2, 1)[:, None]).sum(2)                     # leverage of each cell
    s1 = masks[:, None, :, None] * S1[None]
    s2 = masks[:, None, :, None] * S2[None]
    beta = A @ s1                                                      # (S, B1, p, L)
    f = X[:, None] @ beta                                              # fitted value of each cell
    rss = np.maximum(s2 - 2 * f * s1 + w[..., None] * f ** 2, 0)
    lev = np.where(w > 0, A[:, :, r, :] ** 2 / np.maximum(1 - h, 1e-12), 0)
    se = np.sqrt((lev[..., None] * rss).sum(2))                        # (S, B1, L)
    b = beta[:, :, r, :]
    df = np.repeat(w[:, 0].sum(1) - p, L)
    return b.transpose(1, 0, 2).reshape(B1, S * L), se.transpose(1, 0, 2).reshape(B1, S * L), df


def romano_wolf(b, se, alpha=ALPHA):
    """Step-down rejections. b, se: row 0 the sample, rows 1 to B the bootstrap samples."""
    with np.errstate(divide="ignore", invalid="ignore"):
        t0 = np.nan_to_num(np.abs(b[0] / se[0]))
        ts = np.abs((b[1:] - b[0]) / se[1:])                           # centered: mimics the null
    ts = ts[np.isfinite(ts).all(1)]
    o = np.argsort(-t0)
    mx = np.maximum.accumulate(ts[:, o][:, ::-1], axis=1)[:, ::-1]     # max over the tests not yet passed
    p = np.maximum.accumulate(((mx >= t0[o]).sum(0) + 1) / (len(ts) + 1))
    rej = np.empty(len(t0), bool)
    rej[o] = p <= alpha
    return rej


def run_family(kind, N, beta=0.0, het=0.0, het2=0.0, shares=SHARES0, B=B_SIM):
    """One simulated sample: Romano-Wolf and Bonferroni rejections for every test of the family.
    kind "questions": the K question-level tests. "q5": each question inside each half of each
    dimension. Otherwise a heterogeneity family on the lean index."""
    y, T, E, G = draw_dims(N, beta, TAU, shares, het, het2)
    cell = T + 2 * E + 4 * (G[:, 0] + 2 * G[:, 1] + 4 * G[:, 2])
    Y = y if kind in ("questions", "q5") else y.sum(1, keepdims=True)
    n, S1, S2 = boot_stats(cell, Y, B)
    if Y.shape[1] == 1:
        S1, S2 = S1 / K, S2 / K ** 2
    b, se, df = coef_se(n, S1, S2, {"questions": "full", "q5": "cell1"}.get(kind, kind))
    with np.errstate(divide="ignore", invalid="ignore"):
        bonf = np.nan_to_num(np.abs(b[0] / se[0])) > stats.t.ppf(1 - ALPHA / (2 * len(df)), df)
    return romano_wolf(b, se), bonf


# ---------- calibration: tau that gives the assumed index SD (0.5) ----------
def index_sd(tau, n=200000):
    y, T, G, E = draw(n, 0.0, tau)
    return y.mean(1).std()


taus = np.linspace(0.1, 1.5, 15)
sds = np.array([index_sd(t, 40000) for t in taus])
TAU = float(np.interp(0.5, sds, taus))
SD_INDEX = index_sd(TAU)
y0, _, _, _ = draw(200000, 0.0, TAU)
SD_Q = y0.std(0).mean()
corr = np.corrcoef(y0.T)
RHO = corr[np.triu_indices(K, 1)].mean()


def effects(beta, tau=TAU, n=400000):
    """Population effects (raw and standardized) of a latent shift beta, on the index and per question."""
    y1, T, G, E = draw(n, beta, tau)
    d_index = (y1[T == 1].mean(1).mean() - y1[T == 0].mean(1).mean())
    d_q = (y1[T == 1].mean(0) - y1[T == 0].mean(0))
    sd_i = y1[T == 0].mean(1).std()
    sd_q = y1[T == 0].std(0)
    return d_index / sd_i, d_q / sd_q


# latent shift that gives a standardized index effect of d, and one that gives a mean standardized
# question effect of d
betas = np.linspace(0.05, 1.0, 20)
cal = [effects(b, n=60000) for b in betas]
d_idx = np.array([c[0] for c in cal])
d_qm = np.array([c[1].mean() for c in cal])
assert d_qm.max() > D_TARGET, "the calibration grid must bracket the question-level target"
BETA = {d: float(np.interp(d, d_idx, betas)) for d in D_FIG}
BETA_Q = {d: float(np.interp(d, d_qm, betas)) for d in (0.3, D_TARGET)}
EFF = {d: effects(BETA[d]) for d in D_FIG}
BETA_STAR = BETA[D_TARGET]
D_IDX_STAR, D_Q_STAR = EFF[D_TARGET]
D_Q_MEAN = float(np.mean(D_Q_STAR))
lap("calibration done")


# ---------- simulations of the main test and the question family ----------
REPS = 2000
REPS_HET = 1000
Ns = np.array([30, 60, 100, 150, 200, 300, 400, 600, 800, 1000])


def sim_power_main(N, beta, reps=REPS, questions=True):
    """Power of H1, and Romano-Wolf over the K questions: question 1, any question, average question."""
    rej_i = rej_any = 0
    rej_q = np.zeros(K)
    for _ in range(reps):
        y, T, E, G = draw_dims(N, beta, TAU)
        X = design(T, E)
        rej_i += abs(hc2_t(X, y.mean(1), 1)) > crit(N, X.shape[1])
        if questions:
            cell = T + 2 * E + 4 * (G[:, 0] + 2 * G[:, 1] + 4 * G[:, 2])
            r = romano_wolf(*coef_se(*boot_stats(cell, y, B_SIM), "full")[:2])
            rej_q += r
            rej_any += r.any()
    return rej_i / reps, rej_q[0] / reps, rej_any / reps, rej_q.mean() / reps


print("calibrating done: tau", TAU, "index sd", SD_INDEX, "question sd", SD_Q, "rho", RHO)
sims = {d: np.array([sim_power_main(N, BETA[d]) for N in Ns]) for d in D_FIG}
main = sims[D_TARGET]
size = np.array([sim_power_main(N, 0.0, questions=False)[0] for N in Ns])
lap("main simulations done")

# ---------- heterogeneity by order ----------
# The candidate dimensions, all binary and asked or recorded before treatment. Email is asked before
# treatment but is not registered as a dimension, so it is descriptive and not one of them. An
# order-k analysis crosses k dimensions into
# 2^k cells. Its families: the effect inside every cell of every combination (C(D,k) 2^k tests) and
# the k-way difference of effects for every combination (C(D,k) tests).
DIMS = ["expertise (Yes or Somewhat, against No)", "prior exposure (No, against Yes or Not sure)",
        "entry point (explorer, against share)"]
D = len(DIMS)
assert D == CG.shape[1]
P_UNEQ = 0.25    # unequal example: expertise split 25/75
ORDERS = (1, 2, 3)


def fam(k, kind):
    """Tests in a family. The one-dimension differences (H2 to H4) share their family with H5."""
    return comb(D, k) * (2 ** k if kind == "cell" else 1) + (1 if (k, kind) == (1, "diff") else 0)


def factor(k, kind, shares):
    """Variance factor F: Var = F * 4 sigma^2 / N. Cell: 1 / smallest cell share. k-way difference:
    sum over cells of 1 / s_c, which for independent dimensions is prod_j 1 / (p_j (1 - p_j))."""
    if kind == "cell":
        return 1 / np.prod([min(q, 1 - q) for q in shares])
    return float(np.prod([1 / (q * (1 - q)) for q in shares]))


def shares_for(k, kind, unequal=False):
    """Shares that set an order-k family's bound. Cells: the k most uneven dimensions, which make the
    family's smallest cell. Differences: the first k dimensions, the combination that carries the effect."""
    s = [P_UNEQ if unequal else SHARES0[0]] + list(SHARES0[1:])
    if kind == "cell":
        return sorted(s, key=lambda q: min(q, 1 - q))[:k]
    return s[:k]


def n_star_order(k, kind, d=D_TARGET, unequal=False):
    m = fam(k, kind)
    return int(np.ceil(factor(k, kind, shares_for(k, kind, unequal)) * (2 * mult(m=m) / d) ** 2))


def power_factor(N, d, F, m):
    se = 2 * np.sqrt(F / np.asarray(N, float))
    return stats.norm.cdf(d / se - stats.norm.ppf(1 - ALPHA / (2 * m)))


# latent het that gives a standardized one-dimension difference in index effects of d
hets = np.linspace(0.1, 2.5, 25)


def diff_d(het, p, n=200000):
    y, T, E, G = draw_dims(n, 0.0, TAU, shares=(p, 0.5, P_EXPL), het=het)
    G = G[:, 0]
    idx = y.mean(1)
    sd = idx[T == 0].std()
    e1 = idx[(T == 1) & (G == 1)].mean() - idx[(T == 0) & (G == 1)].mean()
    e0 = idx[(T == 1) & (G == 0)].mean() - idx[(T == 0) & (G == 0)].mean()
    return (e1 - e0) / sd


d_het = np.array([diff_d(h, 0.5, 60000) for h in hets])
d_het_u = np.array([diff_d(h, P_UNEQ, 60000) for h in hets])
assert d_het.min() < 0.3 and D_TARGET < d_het.max(), "the calibration grid must bracket the targets"
# one refinement on a large draw each: the calibration grid is noisy, most of all for the 25/75 split
HET = {d: (lambda h: h * d / diff_d(h, 0.5, 2000000))(float(np.interp(d, d_het, hets))) for d in (0.3, D_TARGET)}
HET_UNEQ = (lambda h: h * D_TARGET / diff_d(h, P_UNEQ, 2000000))(float(np.interp(D_TARGET, d_het_u, hets)))
HET_STAR = HET[D_TARGET]


# k = 2: two independent 50/50 dimensions, a two-way difference of effects (the coefficient on
# T x G1 x G2 in the saturated model), Romano-Wolf over the C(D,2) pairs
def diff2_d(h, n=400000):
    y, T, E, G = draw_dims(n, 0.0, TAU, het2=h)
    G1, G2 = G[:, 0], G[:, 1]
    idx = y.mean(1)
    sd = idx[T == 0].std()
    eff = {(a, b): idx[(T == 1) & (G1 == a) & (G2 == b)].mean() - idx[(T == 0) & (G1 == a) & (G2 == b)].mean()
           for a in (0, 1) for b in (0, 1)}
    return (eff[1, 1] - eff[1, 0] - eff[0, 1] + eff[0, 0]) / sd


hets2 = np.linspace(0.1, 2.0, 20)
d_het2 = np.array([diff2_d(h, 120000) for h in hets2])
assert d_het2.min() < 0.3 and D_TARGET < d_het2.max(), "the calibration grid must bracket the targets"
HET2 = {}
for d in (0.3, D_TARGET):
    h = float(np.interp(d, d_het2, hets2))
    HET2[d] = h * d / diff2_d(h, 2000000)    # one refinement on a large draw: the grid is noisy
HET2_STAR = HET2[D_TARGET]
M1 = fam(1, "diff")
M2 = fam(2, "diff")
lap("heterogeneity calibration done")


def sim_power_het(kind, N, reps=REPS_HET, **dgp):
    """Share of replications in which Romano-Wolf rejects the family's first test, the one that
    carries the difference (the other dimensions or pairs carry none)."""
    return np.mean([run_family(kind, N, **dgp)[0][0] for _ in range(reps)])


Ns_h = np.array([100, 200, 400, 600, 800, 1000, 1200])
het_pow = {0.5: np.array([sim_power_het("h5", N, het=HET_STAR) for N in Ns_h]),
           P_UNEQ: np.array([sim_power_het("h5", N, het=HET_UNEQ, shares=(P_UNEQ, 0.5, P_EXPL)) for N in Ns_h])}
Ns_h2 = np.array([500, 1000, 1500, 2000, 2500, 3000, 4000])
het2_pow = np.array([sim_power_het("diff2", N, het2=HET2_STAR) for N in Ns_h2])
lap("heterogeneity figure simulations done")


def analytic_power(mde_fn, N, d, **kw):
    # power when the true standardized effect is d: Phi(d / se - z_crit), se = mde / mult
    m = kw.pop("m", 1)
    se = mde_fn(N, **kw, m=m) / mult(m=m)
    return stats.norm.cdf(d / se - stats.norm.ppf(1 - ALPHA / (2 * m)))


# ---------- Romano-Wolf thresholds ----------
# For each family and target, power (the average share of the family's targeted tests that are
# rejected) is simulated at a grid of N around the Bonferroni bound. A weighted straight line through
# Phi^{-1}(power) against sqrt(N), the shape of the normal power curve, gives the N with 80% power.
REPS_THR = 500
GRID = (0.5, 0.65, 0.8, 0.95, 1.1)   # grid of N as multiples of the Bonferroni bound
ROUND = 10                           # thresholds are rounded up to a multiple of this
MQ = 2 * D * K


def probit_fit(pts, reps):
    """N with 80% power from {N: power}, and its simulation standard error."""
    N = np.array(sorted(pts))
    pw = np.clip([pts[n] for n in N], 0.5 / reps, 1 - 0.5 / reps)
    z = stats.norm.ppf(pw)
    w = reps * stats.norm.pdf(z) ** 2 / (pw * (1 - pw))
    Xf = np.column_stack([np.ones(len(N)), np.sqrt(N)])
    cov = np.linalg.inv(Xf.T @ (Xf * w[:, None]))
    a, b = cov @ Xf.T @ (w * z)
    zt = stats.norm.ppf(POWER)
    ns = ((zt - a) / b) ** 2
    g = np.array([-2 * (zt - a) / b ** 2, -2 * (zt - a) ** 2 / b ** 3])
    return ns, float(np.sqrt(g @ cov @ g))


def rw_threshold(kind, bound, which, **dgp):
    """Romano-Wolf and simulated Bonferroni thresholds for one family and effect pattern."""
    pts_rw, pts_bf = {}, {}

    def add(N):
        rw = bf = 0.0
        for _ in range(REPS_THR):
            r, b = run_family(kind, N, **dgp)
            rw += r[which].mean()
            bf += b[which].mean()
        pts_rw[N], pts_bf[N] = rw / REPS_THR, bf / REPS_THR

    for f in GRID:
        add(int(round(f * bound)))
    for _ in range(3):   # extend the grid if 80% lies outside it
        ns, se = probit_fit(pts_rw, REPS_THR)
        if min(pts_rw) <= ns <= max(pts_rw):
            break
        add(int(round(min(max(ns, 0.5 * min(pts_rw)), 1.5 * max(pts_rw)))))
    ns, se = probit_fit(pts_rw, REPS_THR)
    nb, _ = probit_fit(pts_bf, REPS_THR)
    return {"rw": ns, "se": se, "bonf_sim": nb, "bound": bound, "pts": pts_rw}


ALL = slice(None)
THR_SPEC = {   # name: (family, effect pattern, Bonferroni bound, tests whose power counts)
    "q5": ("questions", dict(beta=BETA_Q[D_TARGET]), n_star("main", d=D_TARGET, m=K), ALL),
    "q3": ("questions", dict(beta=BETA_Q[0.3]), n_star("main", d=0.3, m=K), ALL),
    "qi5": ("questions", dict(beta=BETA[D_TARGET]), n_star("main", d=D_Q_MEAN, m=K), ALL),
    "qi3": ("questions", dict(beta=BETA[0.3]), n_star("main", d=float(np.mean(EFF[0.3][1])), m=K), ALL),
    "qh5": ("q5", dict(beta=BETA_Q[D_TARGET]), n_star("within", d=D_TARGET, p=0.5, m=MQ), ALL),
    "qh3": ("q5", dict(beta=BETA_Q[0.3]), n_star("within", d=0.3, p=0.5, m=MQ), ALL),
    "qhi5": ("q5", dict(beta=BETA[D_TARGET]), n_star("within", d=D_Q_MEAN, p=0.5, m=MQ), ALL),
    "c1u": ("cell1", dict(beta=BETA[D_TARGET], shares=(P_UNEQ, 0.5, P_EXPL)),
            n_star_order(1, "cell", unequal=True), [1]),
    "d1u": ("h5", dict(het=HET_UNEQ, shares=(P_UNEQ, 0.5, P_EXPL)), n_star_order(1, "diff", unequal=True), [0]),
}
for d, tag in ((D_TARGET, "5"), (0.3, "3")):
    for k in (1, 2, 3):
        THR_SPEC[f"c{k}_{tag}"] = (f"cell{k}", dict(beta=BETA[d]), n_star_order(k, "cell", d=d), ALL)
    THR_SPEC[f"d1_{tag}"] = ("h5", dict(het=HET[d]), n_star_order(1, "diff", d=d), [0])
    THR_SPEC[f"d2_{tag}"] = ("diff2", dict(het2=HET2[d]), n_star_order(2, "diff", d=d), [0])

# H5 in the family of H2 to H4 (M1 tests), with a treatment effect on everyone, so that H5 carries d* and
# H2 to H4 carry none. The subgroup is the cell of two independent dimensions: 50/50 each gives the main
# share of a quarter; sqrt(1/2) each gives the sensitivity share of a half.
M5 = M1
P_H5, P_H5_HI = 0.25, 0.5
SH_H5_HI = (np.sqrt(P_H5_HI), np.sqrt(P_H5_HI), P_EXPL)


def n_star_h5(p=P_H5, d=D_TARGET, m=M5):
    return n_star("within", d=d, p=p, m=m)


THR_SPEC["h5_5"] = ("h5", dict(beta=BETA[D_TARGET]), n_star_h5(), [3])
THR_SPEC["h5_3"] = ("h5", dict(beta=BETA[0.3]), n_star_h5(d=0.3), [3])
THR_SPEC["h5hi"] = ("h5", dict(beta=BETA[D_TARGET], shares=SH_H5_HI), n_star_h5(p=P_H5_HI), [3])

THR = {}
for name, (kind, dgp, bound, which) in THR_SPEC.items():
    THR[name] = rw_threshold(kind, bound, which, **dgp)
    r = THR[name]
    lap(f"threshold {name}: Romano-Wolf {r['rw']:.0f} (se {r['se']:.0f}), Bonferroni simulated "
        f"{r['bonf_sim']:.0f}, bound {bound:,}")


def rw_n(name):
    """Romano-Wolf threshold, rounded up; the bound if simulation error puts it above the bound."""
    r = THR[name]
    return min(int(np.ceil(r["rw"] / ROUND) * ROUND), r["bound"])


def rw_fam(names):
    """Threshold of a family whose tests have different effect patterns: the largest of them."""
    n = max(rw_n(x) for x in names)
    b = max(THR[x]["bound"] for x in names)
    return n, (f"{b:,}$^{{\\dagger}}$" if n == b else f"{n:,}")


ONE = {"5": ("d1_5", "h5_5"), "3": ("d1_3", "h5_3")}   # tier 2b: H2 to H4 and H5


def rw_cell(name):
    """Table entry: the Romano-Wolf threshold, or the bound with a dagger where the bound is kept."""
    r = THR[name]
    return f"{r['bound']:,}$^{{\\dagger}}$" if rw_n(name) == r["bound"] else f"{rw_n(name):,}"


RW_ERR = max(r["se"] / r["rw"] for r in THR.values())
BONF_RATIO = np.array([r["bonf_sim"] / r["bound"] for r in THR.values()])
RW_RATIO = np.array([rw_n(n) / THR[n]["bound"] for n in THR if not n.startswith(("d", "h5"))])   # questions, cells
N_CAPPED = sum(int(np.ceil(r["rw"] / ROUND) * ROUND) > r["bound"] for r in THR.values())

# ---------- figures ----------
plt.rcParams.update({"font.size": 9, "font.family": "serif"})
fig, axes = plt.subplots(len(D_FIG), 1, figsize=(5.6, 8.4), sharex=True)
NN = np.linspace(20, 1050, 300)
for ax, d in zip(axes, D_FIG):
    di, dq = EFF[d]
    res = sims[d]
    ax.plot(NN, analytic_power(mde_main, NN, di), color="#673ab7", label="Lean index, analytic")
    ax.plot(Ns, res[:, 0], "o", color="#673ab7", ms=4, label="Lean index, simulated")
    ax.plot(NN, analytic_power(mde_main, NN, dq[0], m=K), color="#e08a00",
            label=f"One question, Bonferroni bound over {K}, analytic")
    ax.plot(Ns, res[:, 1], "s", color="#e08a00", ms=4, label="One question, Romano-Wolf, simulated")
    ax.axhline(POWER, color="grey", lw=0.6, ls="--")
    ax.set_title(f"True effect on the index: {d:.1f} SD, about {d * SD_INDEX:.2f} index points", fontsize=9)
    ax.set_ylabel("Power")
    ax.set_ylim(0, 1.02)
    ax.yaxis.set_major_formatter(PercentFormatter(1.0, decimals=0))
axes[0].legend(frameon=False, fontsize=7.5, loc="upper left", bbox_to_anchor=(0, 0.74))
axes[-1].set_xlabel("Total responses N (half treated)")
fig.tight_layout()
fig.savefig(os.path.join(OUT, "power_main.pdf"))

fig, ax = plt.subplots(figsize=(5.6, 3.3))
NN = np.linspace(50, 4300, 400)
for k, unequal, xs, ys, c, lab in (
        (1, False, Ns_h, het_pow[0.5], "#673ab7", "One dimension, 50/50"),
        (1, True, Ns_h, het_pow[P_UNEQ], "#e08a00", f"One dimension, {int(100 * P_UNEQ)}/{int(100 - 100 * P_UNEQ)}"),
        (2, False, Ns_h2, het2_pow, "#2e7d32", "Two dimensions, 50/50 each")):
    F = factor(k, "diff", shares_for(k, "diff", unequal))
    ax.plot(NN, power_factor(NN, D_TARGET, F, fam(k, "diff")), color=c, label=f"{lab}, Bonferroni bound")
    ax.plot(xs, ys, "o", color=c, ms=4, label=f"{lab}, Romano-Wolf, simulated")
ax.axhline(POWER, color="grey", lw=0.6, ls="--")
ax.set_xlabel("Total responses N (half treated)")
ax.set_ylabel("Power")
ax.set_ylim(0, 1.02)
ax.yaxis.set_major_formatter(PercentFormatter(1.0, decimals=0))
ax.legend(frameon=False, fontsize=6.5, loc="lower right")
fig.tight_layout()
fig.savefig(os.path.join(OUT, "power_het.pdf"))

fig, ax = plt.subplots(figsize=(5.6, 3.9))
dd = np.linspace(0.2, 1.0, 100)
rows_plot = [(lambda x: n_star("main", d=x), "H1: lean index", "#673ab7", "-", None),
             (lambda x: n_star("main", d=x, m=K), f"Each question (bound over {K})", "#e08a00", "-", "q"),
             (lambda x: n_star_order(1, "diff", d=x), "One-dimension differences and H5 (bound)", "#c62828", "-",
              "d1_"),
             (lambda x: n_star_order(2, "diff", d=x), "Two-way differences (bound)", "#c62828", "--", "d2_"),
             (lambda x: n_star_order(3, "diff", d=x), "Three-way difference (one test)", "#c62828", ":", None)]
for fn, lab, c, ls, key in rows_plot:
    ax.plot(dd, [fn(x) for x in dd], color=c, ls=ls, label=lab)
    if key:
        pts = ([rw_fam(ONE["3"])[0], rw_fam(ONE["5"])[0]] if key == "d1_" else [rw_n(f"{key}3"), rw_n(f"{key}5")])
        ax.plot([0.3, D_TARGET], pts, "o", color=c, ms=4)
ax.plot([], [], "o", color="black", ms=4, label="Romano-Wolf, simulated")
ax.set_yscale("log")
ax.set_xlabel("Smallest standardized effect the analysis must detect, d")
ax.set_ylabel("Responses needed, N*")
ax.legend(frameon=False, fontsize=7, ncol=2, loc="upper center", bbox_to_anchor=(0.5, -0.2))
fig.tight_layout()
fig.savefig(os.path.join(OUT, "nstar.pdf"), bbox_inches="tight")


def fmt(x):
    return f"{x:,}" if isinstance(x, (int, np.integer)) else str(x)


# ---------- thresholds table (the staged rule) ----------
ORD = {1: "one dimension", 2: "two dimensions", 3: "three dimensions"}
TABLE = [("0", "H1: lean index, full sample", 1, n_star("main"), "", n_star("main", d=0.3), ""),
         ("1", f"Each of the {KWORD} questions", K, rw_cell("q5"), n_star("main", m=K),
          rw_cell("q3"), n_star("main", d=0.3, m=K))]
for k, t in zip(ORDERS, ("2", "3", "4")):
    mc, md = fam(k, "cell"), fam(k, "diff")
    TABLE.append((t + "a", f"Effect inside each cell, {ORD[k]} at a time ({comb(D, k)} combination"
                  f"{'s' if comb(D, k) > 1 else ''}, {2 ** k} cells each)", mc,
                  rw_cell(f"c{k}_5"), n_star_order(k, "cell"), rw_cell(f"c{k}_3"), n_star_order(k, "cell", d=0.3)))
    lab = ("Difference between the two halves (H2 to H4) and H5, experts without prior exposure" if k == 1
           else f"{k}-way difference of effects, {ORD[k]} at a time" + (" (one test)" if md == 1 else ""))
    if k == 1:
        TABLE.append((t + "b", lab, md, rw_fam(ONE["5"])[1], n_star_order(k, "diff"),
                      rw_fam(ONE["3"])[1], n_star_order(k, "diff", d=0.3)))
    elif md > 1:
        TABLE.append((t + "b", lab, md, rw_cell(f"d{k}_5"), n_star_order(k, "diff"),
                      rw_cell(f"d{k}_3"), n_star_order(k, "diff", d=0.3)))
    else:
        TABLE.append((t + "b", lab, md, n_star_order(k, "diff"), "", n_star_order(k, "diff", d=0.3), ""))
TABLE.append(("5", "Each question inside each half, one dimension at a time", MQ, rw_cell("qh5"),
              n_star("within", d=D_TARGET, p=0.5, m=MQ), rw_cell("qh3"), n_star("within", d=0.3, p=0.5, m=MQ)))
lines = [" & ".join([t, lab, str(m)] + [fmt(x) for x in xs]) + " \\\\" for t, lab, m, *xs in TABLE]
head = ("\\begin{tabularx}{\\textwidth}{l X c rr rr}\n\\toprule\n"
        " & & & \\multicolumn{2}{c}{$d^{*} = 0.5$} & \\multicolumn{2}{c}{$d^{*} = 0.3$} \\\\\n"
        "\\cmidrule(lr){4-5} \\cmidrule(lr){6-7}\n"
        "Tier & Analysis & Tests $m$ & $N^{*}$ & Bound & $N^{*}$ & Bound \\\\\n\\midrule\n")
open(os.path.join(OUT, "thresholds.tex"), "w").write(head + "\n".join(lines) + "\n\\bottomrule\n\\end{tabularx}\n")

# ---------- thresholds by order of heterogeneity (Bonferroni bounds) ----------
olines = []
for k in ORDERS:
    row = [str(k), str(comb(D, k)), str(2 ** k)]
    for kind in ("cell", "diff"):
        m = fam(k, kind)
        row += [str(m), f"{mult(m=m):.2f}", f"{n_star_order(k, kind):,}", f"{n_star_order(k, kind, d=0.3):,}",
                f"{n_star_order(k, kind, unequal=True):,}"]
    olines.append(" & ".join(row) + " \\\\")
open(os.path.join(OUT, "orders.tex"), "w").write(
    "\\begin{tabular}{ccc rrrrr rrrrr}\n\\toprule\n"
    " & & & \\multicolumn{5}{c}{Effect inside one cell} & \\multicolumn{5}{c}{$k$-way difference of effects} \\\\\n"
    "\\cmidrule(lr){4-8} \\cmidrule(lr){9-13}\n"
    "$k$ & $\\binom{D}{k}$ & Cells & $m$ & $M$ & 0.5 & 0.3 & 0.5, unequal & $m$ & $M$ & 0.5 & 0.3 & 0.5, unequal \\\\\n"
    "\\midrule\n" + "\n".join(olines) + "\n\\bottomrule\n\\end{tabular}\n")


# ---------- summary: responses needed to detect 0.3 SD ----------
D_SUM = 0.3
D_Q_SUM = float(np.mean(EFF[D_SUM][1]))   # question-level effect that matches D_SUM on the index
srows = [("Main hypothesis H1: the lean index", 1, n_star("main", d=D_SUM), "", "", "", ""),
         (f"H1 by outcome, each of the {KWORD} questions. A: 0.3 SD on a question. B: the question-level "
          "effect that matches 0.3 SD on the index", K, rw_cell("q3"), n_star("main", d=D_SUM, m=K), K,
          rw_cell("qi3"), n_star("main", d=D_Q_SUM, m=K))]
for k in ORDERS:
    word = {1: "one dimension", 2: "two dimensions", 3: "three dimensions"}[k]
    lab = (f"Heterogeneity, {word} at a time ({comb(D, k)} combination{'s' if comb(D, k) > 1 else ''}). "
           f"A: the effect inside each of {2 ** k} cells. B: the "
           + ("difference between the two halves, in one family with H5" if k == 1 else f"{k}-way difference"))
    md = fam(k, "diff")
    b_cols = ((md, rw_fam(ONE["3"])[1], n_star_order(k, "diff", d=D_SUM)) if k == 1
              else (md, rw_cell(f"d{k}_3"), n_star_order(k, "diff", d=D_SUM)) if md > 1
              else (md, n_star_order(k, "diff", d=D_SUM), ""))
    srows.append((lab, fam(k, "cell"), rw_cell(f"c{k}_3"), n_star_order(k, "cell", d=D_SUM)) + b_cols)

slines = [f"{i} & {lab} & " + " & ".join(fmt(x) for x in xs) + " \\\\" for i, (lab, *xs) in enumerate(srows, 1)]
open(os.path.join(OUT, "summary.tex"), "w").write(
    "\\begin{tabularx}{\\textwidth}{c X rrr rrr}\n\\toprule\n"
    " & & \\multicolumn{3}{c}{A} & \\multicolumn{3}{c}{B} \\\\\n\\cmidrule(lr){3-5} \\cmidrule(lr){6-8}\n"
    " & Analysis & Tests $m$ & $N^{*}$ & Bound & Tests $m$ & $N^{*}$ & Bound \\\\\n\\midrule\n"
    + "\n".join(slines) + "\n\\bottomrule\n\\end{tabularx}\n")


# ---------- what the magnitudes mean on the index ----------
# One step on one answer (neutral to a study's value, or the other study's value to neutral) moves
# that respondent's index by 1/K. A switch from one study's value to the other's is two steps.
def pct0(x):
    return f"{int(100 * x + 0.5)}\\%"


def mag(d):
    delta = d * SD_INDEX                        # change in the mean index, in index points
    return {"delta": delta,
            "steps": K * delta,                 # one-step moves per treated respondent, on average
            "per100": 100 * K * delta,          # one-step moves per 100 treated respondents
            "all5": delta,                      # share moving all K answers one step
            "flip": delta / (2 / K),            # share switching one answer from one value to the other
            "n80": n_star("main", d=d)}


MAG = {d: mag(d) for d in D_MAG}
mlines = [f"{d:.1f} & {MAG[d]['delta']:.2f} & {MAG[d]['per100']:.0f} & {pct0(MAG[d]['all5'])} & "
          f"{pct0(MAG[d]['flip'])} & {MAG[d]['n80']:,} \\\\" for d in D_MAG]
open(os.path.join(OUT, "magnitudes.tex"), "w").write(
    "\\begin{tabular}{c c c c c r}\n\\toprule\n"
    "Effect & Index & One-step moves per & Share moving all & Share switching one & Responses for \\\\\n"
    f"(SD) & points & 100 treated & {KWORD} answers & answer to the & 80\\% power \\\\\n"
    " & & respondents & one step & other value & on H1 \\\\\n\\midrule\n"
    + "\n".join(mlines) + "\n\\bottomrule\n\\end{tabular}\n")


# ---------- macros ----------
def f2(x):
    return f"{x:.2f}"


def pc(x, dec=0):
    return f"{100 * x:.{dec}f}\\%"


mac = {
    "Mult": f2(mult()), "MultK": f2(mult(m=K)), "K": str(K), "KWord": KWORD, "KOrd": KORD, "MultThree": f2(mult(m=3)),
    "Tau": f2(TAU), "SDIndex": f2(SD_INDEX), "SDQ": f2(SD_Q), "Rho": f2(RHO),
    "BetaStar": f2(BETA_STAR), "DQMean": f2(D_Q_MEAN), "DQMin": f2(D_Q_STAR.min()), "DQMax": f2(D_Q_STAR.max()),
    "NStarMain": f"{n_star('main'):,}", "NStarQ": f"{n_star('main', m=K):,}",
    "NStarQEffective": f"{n_star('main', d=D_Q_MEAN, m=K):,}",
    "Reps": f"{REPS:,}", "RepsHet": f"{REPS_HET:,}",
    "SimPowMainTwoHundred": pc(main[list(Ns).index(200), 0]),
    "AnaPowMainTwoHundred": pc(analytic_power(mde_main, 200, D_IDX_STAR)),
    "SizeMin": pc(size.min(), 1), "SizeMax": pc(size.max(), 1), "NMin": str(Ns.min()),
    "SimPowQAnyTwoHundred": pc(main[list(Ns).index(200), 2]),
    "SimHetHalfEightHundred": pc(het_pow[0.5][list(Ns_h).index(800)]),
    "AnaHetHalfEightHundred": pc(power_factor(800, D_TARGET, factor(1, "diff", [0.5]), M1)),
    "SimHetTwoThreeThousand": pc(het2_pow[list(Ns_h2).index(3000)]),
    "AnaHetTwoThreeThousand": pc(power_factor(3000, D_TARGET, factor(2, "diff", [0.5, 0.5]), M2)),
    "PExpl": pc(P_EXPL), "PShare": pc(1 - P_EXPL),
    "NDims": str(D), "PUneq": f"{P_UNEQ:.2f}", "RepsHetTwo": f"{REPS_HET:,}",
    "NStarCellOne": f"{n_star_order(1, 'cell'):,}", "NStarCellTwo": f"{n_star_order(2, 'cell'):,}",
    "NStarCellThree": f"{n_star_order(3, 'cell'):,}",
    "NStarDiffOne": f"{n_star_order(1, 'diff'):,}", "NStarDiffTwo": f"{n_star_order(2, 'diff'):,}",
    "NStarDiffThree": f"{n_star_order(3, 'diff'):,}",
    "NStarDiffOneUneq": f"{n_star_order(1, 'diff', unequal=True):,}",
    "NStarDiffTwoUneq": f"{n_star_order(2, 'diff', unequal=True):,}",
    "NStarCellOneUneq": f"{n_star_order(1, 'cell', unequal=True):,}",
    "FamCellOne": str(fam(1, "cell")), "FamCellTwo": str(fam(2, "cell")), "FamCellThree": str(fam(3, "cell")),
    "FamDiffOne": str(fam(1, "diff")), "FamDiffTwo": str(fam(2, "diff")), "FamDiffThree": str(fam(3, "diff")),
    "FamQHalf": str(MQ),
    "DSum": f"{D_SUM:.1f}", "DQSum": f2(D_Q_SUM),
    "SimPowMainTwoHundredLow": pc(sims[0.1][list(Ns).index(200), 0]),
    "SimPowMainThousandLow": pc(sims[0.1][list(Ns).index(1000), 0]),
    "SimPowMainTwoHundredMid": pc(sims[0.3][list(Ns).index(200), 0]),
    "SimPowMainThousandMid": pc(sims[0.3][list(Ns).index(1000), 0]),
    "NStarMainLow": f"{n_star('main', d=0.1):,}", "NMax": f"{Ns.max():,}",
    "MDEMainFifty": f2(mde_main(50)), "MDEMainHundred": f2(mde_main(100)), "MDEMainTwoHundred": f2(mde_main(200)),
    "MDEMainFourHundred": f2(mde_main(400)),
    "Shrink": f2(np.sqrt(RHO + (1 - RHO) / K)), "DTarget": f2(D_TARGET),
    "NStarQHalfEff": f"{n_star('within', d=D_Q_MEAN, p=0.5, m=MQ):,}",
    "NStarMainThree": f"{n_star('main', d=0.3):,}",
    # Romano-Wolf
    "BReg": f"{B_REG:,}", "BSim": f"{B_SIM:,}", "RepsThr": f"{REPS_THR:,}", "NGrid": str(len(GRID)),
    "GridLo": pc(GRID[0]), "GridHi": pc(GRID[-1]), "RoundTo": str(ROUND), "RWErr": pc(RW_ERR),
    "BonfSimLo": pc(BONF_RATIO.min()), "BonfSimHi": pc(BONF_RATIO.max()),
    "RWRatioLo": pc(RW_RATIO.min()), "RWRatioHi": pc(RW_RATIO.max()),
    "NCapped": str(N_CAPPED), "NThr": str(len(THR)),
    "NStarQRW": f"{rw_n('q5'):,}", "NStarQEffRW": f"{rw_n('qi5'):,}", "NStarQHalfEffRW": f"{rw_n('qhi5'):,}",
    "NStarQHalfRW": f"{rw_n('qh5'):,}", "NStarQHalf": f"{n_star('within', d=D_TARGET, p=0.5, m=MQ):,}",
    "NStarCellOneRW": f"{rw_n('c1_5'):,}", "NStarCellTwoRW": f"{rw_n('c2_5'):,}",
    "NStarCellThreeRW": f"{rw_n('c3_5'):,}", "NStarDiffOneRW": f"{rw_fam(ONE['5'])[0]:,}",
    "NStarDiffTwoRW": f"{rw_n('d2_5'):,}", "NStarCellOneUneqRW": f"{rw_n('c1u'):,}",
    "NStarDiffOneUneqRW": f"{rw_n('d1u'):,}",
    "SimPowQAvgTwoHundred": pc(main[list(Ns).index(200), 3]),
    # H5
    "NStarHFiveHalfRW": f"{rw_n('h5hi'):,}", "NStarHFiveHalf": f"{n_star_h5(p=P_H5_HI):,}",
    "NStarHFiveUnadj": f"{n_star_h5(m=1):,}", "NStarHFiveHalfUnadj": f"{n_star_h5(p=P_H5_HI, m=1):,}",
}
for d, w in zip(D_MAG, ("Low", "LowMid", "Mid", "MidHigh", "High")):
    mac[f"Delta{w}"] = f2(MAG[d]["delta"])
    mac[f"Steps{w}"] = f2(MAG[d]["steps"])
    mac[f"PerHundred{w}"] = f"{MAG[d]['per100']:.0f}"
    mac[f"AllQ{w}"] = pct0(MAG[d]["all5"])
    mac[f"Flip{w}"] = pct0(MAG[d]["flip"])
with open(os.path.join(OUT, "macros.tex"), "w") as f:
    for k, v in mac.items():
        if v.replace(",", "").isdigit():
            v = v.replace(",", "{,}")   # a thousands comma without math-mode spacing ("2{,}681")
        f.write(f"\\newcommand{{\\{k}}}{{{v}}}\n")
print(open(os.path.join(OUT, "macros.tex")).read())
print(open(os.path.join(OUT, "thresholds.tex")).read())
print(open(os.path.join(OUT, "magnitudes.tex")).read())
print(open(os.path.join(OUT, "orders.tex")).read())
print(open(os.path.join(OUT, "summary.tex")).read())
print("Romano-Wolf thresholds (name: simulated, its standard error, simulated Bonferroni, bound):")
for name, r in THR.items():
    print(f"  {name}: {r['rw']:.0f} ({r['se']:.0f}), {r['bonf_sim']:.0f}, {r['bound']:,}")
lap("done")
