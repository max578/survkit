# The registry, dispatch and extensibility.

test_that("the registry is populated and reports backend availability", {
  m <- survkit_methods()
  expect_true(all(c("weibull", "cox", "km", "cox_ridge", "fine_gray", "cure")
                  %in% m$method))
  expect_true(is.logical(m$available))
  expect_setequal(
    unique(m$kind),
    c("parametric", "spline", "nonparametric", "cox", "frailty", "competing",
      "recurrent", "cure", "interval"))
})

test_that("an unknown method errors helpfully", {
  expect_error(
    survkit(survival::Surv(time, status) ~ age, .fx_lung(),
            method = "does_not_exist"),
    "unknown method")
})

test_that("the registry is user-extensible without an API change", {
  survkit_register("my_exp", "parametric", "survival",
    fit = function(formula, data, ...) {
      raw <- survival::survreg(formula, data = data, dist = "exponential", ...)
      list(raw = raw, coef = stats::coef(raw), vcov = stats::vcov(raw),
           loglik = as.numeric(stats::logLik(raw)), n = nrow(data),
           n_events = NA_integer_, kind = "parametric", backend = "survival")
    })
  expect_true("my_exp" %in% survkit_methods()$method)
  fit <- survkit(survival::Surv(time, status) ~ age, .fx_lung(),
                 method = "my_exp", warn_underpowered = FALSE)
  expect_true(S7::S7_inherits(fit, survkit_fit))
})

test_that("registering overrides an existing key", {
  n_before <- nrow(survkit_methods())
  survkit_register("cox", "cox", "survival", fit = .survkit_fit_cox,
                   note = "re-registered")
  expect_identical(nrow(survkit_methods()), n_before)
  expect_identical(survkit_methods()$note[survkit_methods()$method == "cox"],
                   "re-registered")
})
