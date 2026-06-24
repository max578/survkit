# Core fits across backends, on the bundled survival::lung dataset.

skip_if_no <- function(pkg) testthat::skip_if_not_installed(pkg)

test_that("the registry is populated and reports backend availability", {
  m <- survkit_methods()
  expect_true(all(c("weibull", "cox", "fine_gray", "cure") %in% m$method))
  expect_true(is.logical(m$available))
  expect_setequal(unique(m$kind),
                  c("parametric", "spline", "cox", "frailty", "competing",
                    "recurrent", "cure", "interval"))
})

test_that("parametric and Cox fits return a typed survkit_fit", {
  skip_if_no("flexsurv")
  df <- survival::lung
  for (m in c("weibull", "lognormal", "cox")) {
    fit <- survkit(survival::Surv(time, status) ~ age + sex, df,
                   method = m, warn_underpowered = FALSE)
    expect_true(S7::S7_inherits(fit, survkit_fit))
    expect_identical(fit@method, m)
    expect_true(length(coef(fit)) >= 2L)
    expect_true(is.finite(fit@loglik))
    expect_identical(fit@n_events, 165L)
  }
})

test_that("survkit_tidy returns a coefficient table with ratios and CIs", {
  fit <- survkit(survival::Surv(time, status) ~ age + sex, survival::lung,
                 method = "cox", warn_underpowered = FALSE)
  tab <- survkit_tidy(fit)
  expect_true(all(c("term", "estimate", "ratio", "conf_low", "conf_high") %in% names(tab)))
  expect_equal(tab$ratio, exp(tab$estimate))
})

test_that("the power gate flags an under-powered model", {
  df <- survival::lung[1:25, ]
  p <- survkit_power(survival::Surv(time, status) ~ age + sex + ph.ecog, df)
  expect_identical(p$verdict, "underpowered")
  expect_true(p$events_per_variable < 10)
  expect_warning(
    survkit(survival::Surv(time, status) ~ age + sex + ph.ecog, df, method = "cox"),
    "events per predictor")
})

test_that("an unknown method errors helpfully", {
  expect_error(survkit(survival::Surv(time, status) ~ age, survival::lung,
                       method = "does_not_exist"), "unknown method")
})

test_that("the manifest emitter produces a draw ensemble", {
  fit <- survkit(survival::Surv(time, status) ~ age, survival::lung,
                 method = "weibull", warn_underpowered = FALSE)
  m <- as_survkit_manifest(fit, n_draws = 40L, seed = 1L)
  expect_true(S7::S7_inherits(m, survkit_manifest))
  expect_identical(nrow(m@params), 40L)
  expect_true("real_name" %in% names(m@params))
})

test_that("the registry is user-extensible", {
  survkit_register("my_exp", "parametric", "survival",
    fit = function(formula, data, ...) {
      raw <- survival::survreg(formula, data = data, dist = "exponential", ...)
      list(raw = raw, coef = stats::coef(raw), vcov = stats::vcov(raw),
           loglik = as.numeric(stats::logLik(raw)), n = nrow(data),
           n_events = NA_integer_, kind = "parametric", backend = "survival")
    })
  expect_true("my_exp" %in% survkit_methods()$method)
  fit <- survkit(survival::Surv(time, status) ~ age, survival::lung,
                 method = "my_exp", warn_underpowered = FALSE)
  expect_true(S7::S7_inherits(fit, survkit_fit))
})

test_that("competing-risks Fine-Gray fits on a multi-state response", {
  df <- survival::mgus2
  df$etime <- with(df, ifelse(pstat == 1, ptime, futime))
  df$event <- with(df, factor(ifelse(pstat == 1, "pcm", ifelse(death == 1, "death", "censor")),
                              levels = c("censor", "pcm", "death")))
  fit <- survkit(survival::Surv(etime, event) ~ age + sex, df,
                 method = "fine_gray", cause = "pcm", warn_underpowered = FALSE)
  expect_true(S7::S7_inherits(fit, survkit_fit))
  expect_identical(fit@kind, "competing")
})
