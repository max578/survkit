# Internal helpers and the load-time wiring.

test_that("registering the built-ins populates the whole catalogue", {
  .survkit_register_builtins()
  m <- survkit_methods()
  expect_true(nrow(m) >= 17L)
  expect_true(all(c("exponential", "weibull", "lognormal", "loglogistic",
                    "gompertz", "generalized_gamma", "gamma", "spline", "km",
                    "cox", "cox_ridge", "frailty", "cause_specific",
                    "fine_gray", "andersen_gill", "cure", "interval_censored")
                  %in% m$method))
})

test_that("the AFT ratio-type map splits proportional-hazards from time-scale", {
  expect_identical(.survkit_aft_ratio_type("exp"), "HR")
  expect_identical(.survkit_aft_ratio_type("gompertz"), "HR")
  expect_identical(.survkit_aft_ratio_type("weibull"), "TR")
  expect_identical(.survkit_aft_ratio_type("lnorm"), "TR")
})

test_that("the coefficient sampler degrades without a covariance", {
  est <- c(a = 1, b = -2)
  draws <- .survkit_draw_coef(est, NULL, 30L)
  expect_identical(nrow(draws), 30L)
  expect_setequal(names(draws), c("a", "b"))
})

test_that("the empty registry returns an empty typed frame", {
  reg <- .survkit_registry
  old <- as.list(reg)
  on.exit({
    rm(list = ls(reg), envir = reg)
    for (nm in names(old)) assign(nm, old[[nm]], envir = reg)
  }, add = TRUE)
  rm(list = ls(reg), envir = reg)
  m <- survkit_methods()
  expect_identical(nrow(m), 0L)
  expect_true(all(c("method", "kind", "backend", "available", "note")
                  %in% names(m)))
})
