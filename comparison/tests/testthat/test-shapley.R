# The decomposition: steps add up exactly, whatever the method or horizon setting.
k   <- read_contracts()
res <- build_all(k)
br  <- res$bridge; en <- res$ends

test_that("Shapley steps sum exactly to the total gap, every setting and output", {
  for (st in unique(en$horizon_setting)) for (o in c("a", "b")) {
    e <- en[en$horizon_setting == st & en$output == o, ]
    b <- br[br$horizon_setting == st & br$output == o, ]
    expect_equal(sum(b$shapley), e$rauh_model - e$bsz_model, tolerance = 1e-10,
                 label = paste(st, o, "Shapley"))
    expect_equal(sum(b$sequential), e$rauh_model - e$bsz_model, tolerance = 1e-10,
                 label = paste(st, o, "sequential"))
  }
})

test_that("the full chain closes: GGSS printed -> BSZ -> the steps -> JR September 2026", {
  for (o in c("a", "b")) {
    e <- en[en$horizon_setting == "own" & en$output == o, ]
    ggss <- res$endpoints$value[res$endpoints$endpoint_id == "ggss_headline"]
    b <- br[br$horizon_setting == "own" & br$output == o, ]
    chain <- e$bsz_model + sum(b$shapley) + e$rauh_residual
    expect_equal(chain, e$rauh_own, tolerance = 1e-12, label = o)
    expect_lt(abs(e$rauh_residual), 1e-9)
  }
})

test_that("inputs that do not enter output (a) get exactly zero", {
  b <- br[br$horizon_setting == "own" & br$output == "a", ]
  for (id in c("income_loss_share", "income_level", "horizon", "discount_rate", "asset_sales"))
    expect_equal(b$shapley[b$step_id == id], 0, label = id)
})

test_that("with a common horizon the horizon is not a step", {
  b <- br[br$horizon_setting == "common_20" & br$output == "b", ]
  expect_equal(b$shapley[b$step_id == "horizon"], 0)
  expect_equal(b$sequential[b$step_id == "horizon"], 0)
})

test_that("Shapley matches a brute-force average over all orders on a small game", {
  bi <- bridge_inputs(k)
  pl <- c("noncitizens", "confirmed_departures", "litigation_survival", "avoidance")
  sh <- shapley_bridge(bi$sup, bi$rauh, pl, "a")
  perms <- function(v) if (length(v) <= 1) list(v) else
    do.call(c, lapply(seq_along(v), function(i) lapply(perms(v[-i]), function(p) c(v[i], p))))
  avg <- Reduce(`+`, lapply(perms(pl), function(o) sequential_bridge(bi$sup, bi$rauh, o, "a")[pl])) / 24
  expect_equal(sh, avg, tolerance = 1e-10)
})

test_that("every step is labelled and tied to a DISPUTES row or flagged as not one", {
  st <- bridge_steps()
  expect_true(all(nzchar(st$kind)))
  # rows 1 and 4 are disputes with the March 2026 version only (the September headline predicts
  # no departures from an elasticity), so they are not steps; row 9 is the litigation weight
  # row 10 is the discount rate (a dial since 2026-10-15)
  expect_setequal(setdiff(st$disputes_row, "(not a row)"), as.character(c(2, 3, 5, 6, 7, 8, 9, 10)))
  dis <- readLines(file.path(comparison_root(), "comparison", "DISPUTES.md"), encoding = "UTF-8")
  for (r in setdiff(st$disputes_row, "(not a row)"))
    expect_true(any(startsWith(dis, paste0("| ", r, " | "))), label = paste("DISPUTES row", r))
  expect_true(all(grepl("data|research|guesswork|scenario", st$kind)))
  # every kind is one of the kinds the pages define, or "A vs B" of two of them
  kinds <- c("data", "research", "guesswork", "guesswork on data", "scenario", "derived")
  expect_true(all(unlist(strsplit(st$kind, " vs ", fixed = TRUE)) %in% kinds))
})

test_that("the switchboard grid is score_common() at every mix of switches", {
  bi <- bridge_inputs(k); ids <- bridge_steps()$step_id
  sb <- res$switchboard
  g <- sb[sb$horizon_setting == "own" & sb$output == "b", ]
  # bit i-1 of the mask is input i in the bridge's order
  full <- 2L^length(ids) - 1L
  for (m in c(0L, 1L, 16L, 5L, full, 734L, 512L, 1536L)) {
    on <- ids[bitwAnd(m, 2^(seq_along(ids) - 1)) > 0]
    expect_equal(g$value[g$mask == m], score_common(switch_inputs(bi$sup, bi$rauh, on))[["b"]],
                 tolerance = 1e-12, label = paste("mask", m))
  }
  # with a common horizon the horizon bit is never set
  hbit <- 2L^(match("horizon", ids) - 1L)
  c20 <- sb[sb$horizon_setting == "common_20", ]
  expect_true(all(bitwAnd(c20$mask, hbit) == 0))
  # the Shapley steps are the average marginal effects over this same grid: they add up to
  # the difference between its two corners
  b <- br[br$horizon_setting == "own" & br$output == "b", ]
  expect_equal(sum(b$shapley), g$value[g$mask == full] - g$value[g$mask == 0], tolerance = 1e-10)
})
