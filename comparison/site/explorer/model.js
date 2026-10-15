/* The common estimating function, in the browser.
 *
 * A port of comparison/R/model.R for the explorer's two slider panels: annuity(),
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

  // annuity(r, H): the value of 1 a year for H years at the one common rate r (the data
  // file's input vectors carry it as r). H = Infinity is a perpetuity, 1 / r.
  function annuity(r, H) {
    if (H === Infinity) return 1 / r;
    if (H === 0) return 0;
    return (1 - Math.pow(1 + r, -H)) / r;
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
    var A = annuity(x.r, x.H);
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
    annuity: annuity,
    scoreCommon: scoreCommon,
    sliderInputs: sliderInputs,
    panelValue: panelValue,
    num: num
  };
})(typeof window !== "undefined" ? window : globalThis);
