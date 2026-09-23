# The decomposition: steps add up exactly, whatever the method or horizon setting.
k   <- read_contracts()
res <- build_all(k)
br  <- res$bridge; en <- res$ends

test_that("Shapley steps sum exactly to the total gap, every setting and output", {
  for (st in unique(en$horizon_setting)) for (o in c("a", "b")) {
    e <- en[en$horizon_setting == st & en$output == o, ]
    b <- br[br$horizon_setting == st & br$output == o, ]
    expect_equal(sum(b$shapley), e$rauh_model - e$supporting_model, tolerance = 1e-10,
                 label = paste(st, o, "Shapley"))
    expect_equal(sum(b$sequential), e$rauh_model - e$supporting_model, tolerance = 1e-10,
                 label = paste(st, o, "sequential"))
  }
})

test_that("the full chain closes: GGSS printed -> ... -> Rauh SSRN -> NBER", {
  e <- en[en$horizon_setting == "own" & en$output == "a", ]
  ggss <- res$endpoints$value[res$endpoints$endpoint_id == "ggss_headline"]
  b <- br[br$horizon_setting == "own" & br$output == "a", ]
  chain <- ggss + (e$supporting_model - ggss) + sum(b$shapley) + e$rauh_residual
  expect_equal(chain, e$rauh_own, tolerance = 1e-12)
  expect_equal(chain + e$nber_step, e$nber_own, tolerance = 1e-12)
})

test_that("inputs that do not enter output (a) get exactly zero", {
  b <- br[br$horizon_setting == "own" & br$output == "a", ]
  for (id in c("income_proportional", "income_level", "horizon", "asset_sales"))
    expect_equal(b$shapley[b$step_id == id], 0, label = id)
})

test_that("with a common horizon the horizon is not a step", {
  b <- br[br$horizon_setting == "common_20" & br$output == "b", ]
  expect_equal(b$shapley[b$step_id == "horizon"], 0)
  expect_equal(b$sequential[b$step_id == "horizon"], 0)
})

test_that("Shapley matches a brute-force average over all orders on a small game", {
  bi <- bridge_inputs(k)
  pl <- c("noncitizens", "confirmed_departures", "one_time_as_permanent", "avoidance")
  sh <- shapley_bridge(bi$sup, bi$rauh, pl, "a")
  perms <- function(v) if (length(v) <= 1) list(v) else
    do.call(c, lapply(seq_along(v), function(i) lapply(perms(v[-i]), function(p) c(v[i], p))))
  avg <- Reduce(`+`, lapply(perms(pl), function(o) sequential_bridge(bi$sup, bi$rauh, o, "a")[pl])) / 24
  expect_equal(sh, avg, tolerance = 1e-10)
})

test_that("every step is labelled and tied to a DISPUTES row or flagged as not one", {
  st <- bridge_steps()
  expect_true(all(nzchar(st$kind)))
  expect_setequal(setdiff(st$disputes_row, "(not a row)"),
                  as.character(1:8))
  expect_true(all(grepl("data|research|guesswork|scenario", st$kind)))
})
