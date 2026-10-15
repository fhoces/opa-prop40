/* The common estimating function, in the browser.
 *
 * A port of comparison/R/model.R for the explorer's two slider panels: expected_annuity(),
 * score_common(), slider_inputs() and slider_value(). The R code is the definition; the
 * Python twin (comparison/py/bridge.py) mirrors it, and comparison/tests/testthat/test-site.R
 * runs this file with node over comparison/export/r/slider_sample.csv and checks every value
 * to 1e-9. Every number it uses (the two input vectors, the horizon settings, which
 * arguments each slider moves) comes from assets/comparison-data.js, the
 * data file comparison/R/site.R writes; nothing is typed here.
 *
 * No modules and no build step: the page loads it with <script src="model.js">, and it puts
 * one object, ComparisonModel, on window (or on the global object under node).
 */
(function (root) {
  "use strict";

  // Gauss-Legendre nodes and weights on [-1, 1] (Newton's method on the Legendre
  // polynomial). The annuity's integrand is smooth on the rate range, so 40 nodes give the
  // integral to machine precision, the accuracy R's integrate() reaches with rel.tol 1e-12.
  function gaussLegendre(n) {
    var x = [], w = [];
    for (var i = 1; i <= n; i++) {
      var z = Math.cos(Math.PI * (i - 0.25) / (n + 0.5)), pp = 0;
      for (var it = 0; it < 100; it++) {
        var p1 = 1, p2 = 0;
        for (var j = 1; j <= n; j++) {
          var p3 = p2; p2 = p1;
          p1 = ((2 * j - 1) * z * p2 - (j - 1) * p3) / j;
        }
        pp = n * (z * p1 - p2) / (z * z - 1);
        var dz = p1 / pp;
        z -= dz;
        if (Math.abs(dz) < 1e-16) break;
      }
      x.push(z); w.push(2 / ((1 - z * z) * pp * pp));
    }
    return { x: x, w: w };
  }
  var GL = gaussLegendre(40);

  // expected_annuity(H, r_min, r_max): the value of 1 a year for H years, averaged over a
  // discount rate uniform between r_min and r_max. H = Infinity is a perpetuity (closed form).
  function expectedAnnuity(H, rMin, rMax) {
    if (H === Infinity) return Math.log(rMax / rMin) / (rMax - rMin);
    if (H === 0) return 0;
    var mid = (rMax + rMin) / 2, half = (rMax - rMin) / 2, s = 0;
    for (var i = 0; i < GL.x.length; i++) {
      var r = mid + half * GL.x[i];
      s += GL.w[i] * (1 - Math.pow(1 + r, -H)) / r;
    }
    return s * half / (rMax - rMin);
  }

  // score_common(x): the same formulas as model.R, line for line.
  function scoreCommon(x) {
    var Wn = (x.W_core + x.W_noncit) * (1 - x.re);
    var D = (1 - x.lam) * x.dep_b + x.lam * x.dep_j;
    var d_conf = D / Wn;
    var R0 = x.tau * Wn;
    var S = 1 - d_conf;
    var WT = R0 * (1 - x.alpha) * S * x.q;
    var X = WT * x.s * x.g * x.t_cg;
    var f = x.alpha * x.m + x.own * x.L / x.C + x.f0;
    var A = expectedAnnuity(x.H, x.r_min, x.r_max);
    var PV = f * x.C * A;
    return { a: WT, b: WT + X - PV, R0: R0, S: S, d_conf: d_conf, D: D, X: X, f: f, annual_loss: f * x.C,
             annuity: A, PV: PV };
  }

  // The data file writes the perpetuity as the string "Inf".
  function num(v) { return v === "Inf" ? Infinity : v; }
  function vec(o) { var x = {}; for (var k in o) x[k] = num(o[k]); return x; }

  // slider_inputs(from, to, positions): positions[id] in 0..steps, 0 = from's value,
  // steps = to's value. Numeric inputs: (1 - p/steps) * from + (p/steps) * to; a slider that
  // moves two arguments moves both. The horizon: the horizon settings in order from from's
  // horizon to to's.
  function sliderInputs(S, from, to, positions) {
    var x = {}, k;
    for (k in from) x[k] = from[k];
    var lad = S.horizons.map(num);
    if (!(from.H <= to.H)) lad = lad.slice().reverse();
    S.inputs.forEach(function (inp) {
      var p = positions[inp.id] || 0, mx = inp.max, t = p / mx;
      if (inp.id === "confirmed_departures") {   // three stops, from the ladder
        var k = from.dep_b <= to.dep_b ? p : mx - p;
        x.dep_b = S.ladder.dep_b[k]; x.dep_j = S.ladder.dep_j[k]; x.L = S.ladder.L[k];
        return;
      }
      inp.input.forEach(function (nm) {
        if (nm === "H") x.H = lad[p];
        else x[nm] = (1 - t) * from[nm] + t * to[nm];
      });
    });
    return x;
  }

  // slider_value(panel, positions): output (b) at the positions.
  function panelValue(S, panel, positions) {
    var bsz = vec(S.values.bsz), rj = vec(S.values.rjkdc);
    var from = panel === "bsz" ? bsz : rj, to = panel === "bsz" ? rj : bsz;
    var x = sliderInputs(S, from, to, positions);
    return { value: scoreCommon(x).b, x: x };
  }

  root.ComparisonModel = {
    expectedAnnuity: expectedAnnuity,
    scoreCommon: scoreCommon,
    sliderInputs: sliderInputs,
    panelValue: panelValue,
    num: num
  };
})(typeof window !== "undefined" ? window : globalThis);
