"""Exploration, not registered: power of per-question multinomial outcomes in place of the lean index.

Usage: python3 comparison/survey/power/explore/multinomial.py   (writes explore/multinomial.md)

Each focus question's answer is one of three categories: the BSZ value, the JR value, or neutral
("About equally credible" and "Unsure" together; the first is 0 to 6% of answers in the simulated
pilot, too thin for its own category). The test for one question is a multinomial logit of the
answer on T with entry-point fixed effects, H0 that both T coefficients are 0, a likelihood-ratio
test with 2 degrees of freedom. With m focus questions the level is 0.05/m (Bonferroni; the
Romano-Wolf step-down the plan uses sits at or below this bound).

The analytic N comes from the noncentral chi-square with 2 df and noncentrality N w^2, where w is
Cohen's w of the arm-by-answer table. A Monte Carlo of the estimator itself checks it.

Three alternatives:
  A. A directional shift: the power appendix's latent model (sim.py: lean theta ~ N(0, tau^2),
     question offsets A_K, cut 0.5, index SD 0.5), shifted by the beta that gives 0.5 SD (or 0.3 SD)
     on the lean index. This is the effect the lean index is built for.
  B. Less uncertainty, no direction: treatment moves D points of the neutral share to the two values,
     half to each. The mean lean, and so the lean index, does not move.
  C. The simulated pilot's own arm-by-answer shares (50 per arm, simulated respondents, older
     wording): an illustration only, not an effect size to plan on.
"""
import os

import numpy as np
import pandas as pd
from scipy import stats

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
rng = np.random.default_rng(20261018)
ALPHA, POWER = 0.05, 0.80
Q = ["share_lost", "horizon", "income_level", "court", "moved_out"]
QNAME = {"share_lost": "share of income tax lost", "horizon": "how long it is counted",
         "income_level": "yearly income tax", "court": "court discount", "moved_out": "moved out in time"}
# the power appendix's model (comparison/survey/power/sim.py)
A_K = np.array([0.3, -0.2, 0.5, -0.4, 0.0])
CUT = 0.5
P_EXPL = 0.6
CATS = ["BSZ", "neutral", "JR"]


# ---------- the appendix's calibration, repeated: tau for an index SD of 0.5, beta for d on the index
def draw_latent(n, beta, tau):
    T = rng.permutation(np.arange(n) % 2)
    lat = rng.normal(0, tau, n)[:, None] + A_K[None, :] + (beta * T)[:, None] + rng.normal(0, 1, (n, 5))
    y = np.where(lat > CUT, 1, np.where(lat < -CUT, -1, 0))
    return y, T


taus = np.linspace(0.1, 1.5, 29)
sds = np.array([draw_latent(100000, 0.0, t)[0].mean(1).std() for t in taus])
TAU = float(np.interp(0.5, sds, taus))


def index_d(beta, n=400000):
    y, T = draw_latent(n, beta, TAU)
    li = y.mean(1)
    return (li[T == 1].mean() - li[T == 0].mean()) / li[T == 0].std()


betas = np.linspace(0.05, 1.2, 24)
dd = np.array([index_d(b, 100000) for b in betas])
BETA = {d: float(np.interp(d, dd, betas)) for d in (0.3, 0.5)}
S = np.sqrt(1 + TAU ** 2)   # marginal SD of a latent answer


def probs_latent(k, shift):
    """BSZ, neutral, JR shares on question k at a latent shift (theta integrated out)."""
    hi = 1 - stats.norm.cdf((CUT - A_K[k] - shift) / S)
    lo = stats.norm.cdf((-CUT - A_K[k] - shift) / S)
    return np.array([hi, 1 - hi - lo, lo])


# ---------- analytic N
def mult(m=1):
    return stats.norm.ppf(1 - ALPHA / (2 * m)) + stats.norm.ppf(POWER)


def n_mean(d, m=1):
    """N for a standardized difference in means (half treated), Bonferroni over m."""
    return int(np.ceil((2 * mult(m) / d) ** 2))


def w2(p0, p1):
    """Cohen's w^2 of the 2 x C table with equal arms."""
    pbar = (p0 + p1) / 2
    return float(np.sum((p1 - p0) ** 2 / (4 * pbar)))


def n_chi2(w2_, df=2, m=1):
    crit = stats.chi2.ppf(1 - ALPHA / m, df)
    lo, hi = 2, 10 ** 7
    if w2_ <= 0:
        return np.inf
    while lo < hi:
        mid = (lo + hi) // 2
        if 1 - stats.ncx2.cdf(crit, df, mid * w2_) >= POWER:
            hi = mid
        else:
            lo = mid + 1
    return lo


def d_y(p0, p1):
    """Standardized effect on the coded answer y (+1 BSZ, 0 neutral, -1 JR), the plan's S3 scale."""
    m0, m1 = p0[0] - p0[2], p1[0] - p1[2]
    v0 = p0[0] + p0[2] - m0 ** 2
    return (m1 - m0) / np.sqrt(v0)


# ---------- Monte Carlo of the registered-style estimator: MNLogit with entry FE, LR test of T
def lr_test(ycat, T, E):
    """LR statistic for T in a 3-category multinomial logit with entry FE, by Newton on the full model."""
    def fit(X):
        n, k = X.shape
        Y = np.eye(3)[ycat][:, 1:]           # base category 0
        b = np.zeros((k, 2))
        for _ in range(50):
            eta = X @ b
            ex = np.exp(np.column_stack([np.zeros(n), eta]))
            P = ex / ex.sum(1, keepdims=True)
            g = (X.T @ (Y - P[:, 1:])).T.ravel()
            H = np.zeros((2 * k, 2 * k))
            for a in range(2):
                for c in range(2):
                    wgt = P[:, a + 1] * ((a == c) - P[:, c + 1])
                    H[a * k:(a + 1) * k, c * k:(c + 1) * k] = -(X * wgt[:, None]).T @ X
            step = np.linalg.solve(H - 1e-9 * np.eye(2 * k), g)
            b = b - step.reshape(2, k).T
            if np.abs(step).max() < 1e-8:
                break
        eta = X @ b
        ex = np.exp(np.column_stack([np.zeros(n), eta]))
        P = ex / ex.sum(1, keepdims=True)
        return np.log(P[np.arange(n), ycat]).sum()
    one = np.ones_like(T, float)
    full = fit(np.column_stack([one, T, E]))
    rest = fit(np.column_stack([one, E]))
    return 2 * (full - rest)


def mc_power(p0, p1, N, m=1, reps=1000):
    crit = stats.chi2.ppf(1 - ALPHA / m, 2)
    rej = 0
    for _ in range(reps):
        T = rng.permutation(np.arange(N) % 2)
        E = (rng.random(N) < P_EXPL).astype(float)
        u = rng.random(N)
        p = np.where(T[:, None] == 1, p1[None, :], p0[None, :]).cumsum(1)
        ycat = (u[:, None] > p).sum(1)
        if len(np.unique(ycat)) < 3:
            continue        # a category never chosen: the test is not run (counts as no rejection)
        rej += lr_test(ycat, T.astype(float), E) > crit
    return rej / reps


lines = ["# Per-question multinomial outcomes: power (exploration, not registered)", "",
         f"Model calibration repeated from the power appendix: tau = {TAU:.3f} (index SD 0.5); the latent "
         f"shift for 0.5 SD on the lean index is {BETA[0.5]:.3f}, for 0.3 SD {BETA[0.3]:.3f}.", "",
         f"The lean index (H1) needs **{n_mean(0.5)}** responses for 0.5 SD and **{n_mean(0.3)}** for 0.3 SD "
         "(analytic; the appendix's simulated 349 for 0.3 SD matches the formula's 349).", ""]

# A. directional shift
rows = []
for d in (0.5, 0.3):
    for k, q in enumerate(Q):
        p0, p1 = probs_latent(k, 0.0), probs_latent(k, BETA[d])
        rows.append({"index effect": f"{d} SD", "question": QNAME[q],
                     "control BSZ/neutral/JR": "/".join(f"{x:.0%}" for x in p0),
                     "treated": "/".join(f"{x:.0%}" for x in p1),
                     "w": np.sqrt(w2(p0, p1)),
                     "N multinomial, m=1": n_chi2(w2(p0, p1)), "m=2": n_chi2(w2(p0, p1), m=2),
                     "m=3": n_chi2(w2(p0, p1), m=3), "m=5": n_chi2(w2(p0, p1), m=5),
                     "N coded y (S3 scale), m=1": n_mean(d_y(p0, p1))})
A = pd.DataFrame(rows)

# B. less uncertainty, no direction
rows = []
for D in (0.10, 0.15, 0.20):
    for k, q in enumerate(Q):
        p0 = probs_latent(k, 0.0)
        p1 = p0 + np.array([D / 2, -D, D / 2])
        rows.append({"neutral share falls by": f"{D:.0%} pts", "question": QNAME[q],
                     "control BSZ/neutral/JR": "/".join(f"{x:.0%}" for x in p0),
                     "w": np.sqrt(w2(p0, p1)),
                     "N multinomial, m=1": n_chi2(w2(p0, p1)), "m=2": n_chi2(w2(p0, p1), m=2),
                     "m=3": n_chi2(w2(p0, p1), m=3), "m=5": n_chi2(w2(p0, p1), m=5)})
B = pd.DataFrame(rows)
# the lean index and S1 under B: the index does not move; the neutral share over five questions does
y0, _ = draw_latent(200000, 0.0, TAU)
neutral_sd = (y0 == 0).mean(1).std()
B_S1 = {D: n_mean(D / neutral_sd) for D in (0.10, 0.15, 0.20)}

# C. the simulated pilot's shares
pil = pd.read_csv(os.path.join(ROOT, "feedback", "008-2026-10-17-rct-pilot", "pilot", "responses.csv"))
rows = []
for q in Q:
    a = pil[q].map({"BSZ": 0, "equal": 1, "unsure": 1, "JR": 2})
    p0 = np.bincount(a[pil.arm == "control"], minlength=3) / (pil.arm == "control").sum()
    p1 = np.bincount(a[pil.arm == "treatment"], minlength=3) / (pil.arm == "treatment").sum()
    rows.append({"question": QNAME[q], "control BSZ/neutral/JR": "/".join(f"{x:.0%}" for x in p0),
                 "treated": "/".join(f"{x:.0%}" for x in p1), "w": np.sqrt(w2(p0, p1)),
                 "N multinomial, m=1": n_chi2(w2(p0, p1)), "m=3": n_chi2(w2(p0, p1), m=3),
                 "N coded y, m=1": n_mean(abs(d_y(p0, p1))) if abs(d_y(p0, p1)) > 0.01 else np.inf})
C = pd.DataFrame(rows)

# Monte Carlo checks of the analytic N: one A row, one B row, one C row
checks = []
for label, p0, p1 in [("A, 0.5 SD, " + QNAME[Q[0]], probs_latent(0, 0.0), probs_latent(0, BETA[0.5])),
                      ("B, 15 pts, " + QNAME[Q[1]], probs_latent(1, 0.0), probs_latent(1, 0.0) + np.array([.075, -.15, .075]))]:
    for m in (1, 3):
        N = n_chi2(w2(p0, p1), m=m)
        checks.append({"case": label, "m": m, "analytic N": N, "simulated power at that N": mc_power(p0, p1, N, m)})
K = pd.DataFrame(checks)


def md(df):
    df = df.copy()
    for c in df.columns:
        if df[c].dtype.kind == "f":
            df[c] = df[c].map(lambda x: "never" if np.isinf(x) else (f"{x:.2f}" if x < 10 else f"{x:,.0f}"))
        elif df[c].dtype.kind == "i":
            df[c] = df[c].map(lambda x: f"{x:,}")
    return df.to_markdown(index=False)


lines += ["## A. A directional shift (what the lean index is built for)", "",
          "Responses needed for 80% power on one question's multinomial test, Bonferroni over m focus "
          "questions; last column: the same question coded -1/0/+1, as in S3.", "", md(A), "",
          "## B. Less uncertainty, no direction (the lean index cannot see this)", "",
          "The lean index has no power here at any N (its mean does not move). S1, the share of "
          "the five answers that are neutral, catches it if the drop is on every question: "
          + ", ".join(f"{D:.0%} pts needs {n:,}" for D, n in B_S1.items()) + ".", "", md(B), "",
          "## C. The simulated pilot's shares (illustration only: 50 per arm, simulated respondents, older wording)",
          "", md(C), "", "## Monte Carlo check of the analytic N (1,000 samples each)", "", md(K), ""]
open(os.path.join(HERE, "multinomial.md"), "w").write("\n".join(lines))
print("\n".join(lines))
