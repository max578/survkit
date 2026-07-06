# The ensemble-manifest emission.

test_that("a parameters-only manifest is a draw ensemble with provenance", {
  skip_if_not_installed("flexsurv")
  fit <- survkit(survival::Surv(time, status) ~ age, .fx_lung(),
                 method = "weibull", warn_underpowered = FALSE)
  m <- as_survkit_manifest(fit, n_draws = 40L, seed = 1L)
  expect_true(S7::S7_inherits(m, survkit_manifest))
  expect_identical(nrow(m@params), 40L)
  expect_true("real_name" %in% names(m@params))
  expect_identical(m@seed, 1L)
  expect_identical(m@method, "weibull")
})

test_that("a parametric fit yields a genuine per-draw survival ensemble", {
  skip_if_not_installed("flexsurv")
  skip_if_not_installed("MASS")
  fit <- survkit(survival::Surv(time, status) ~ age + sex, .fx_lung(),
                 method = "weibull", warn_underpowered = FALSE)
  m <- as_survkit_manifest(fit, n_draws = 200L, times = c(100, 300, 500),
                           newdata = data.frame(age = 60, sex = 1), seed = 7L)
  expect_identical(nrow(m@outputs), 600L)              # 200 draws x 3 times
  expect_setequal(unique(m@outputs$draw), 1:200)
  expect_true(all(m@outputs$survival >= 0 & m@outputs$survival <= 1))
  # Ensemble mean tracks the maximum-likelihood curve (an independent check).
  pt <- survkit_curve(fit, newdata = data.frame(age = 60, sex = 1),
                      times = c(100, 300, 500))
  ens <- tapply(m@outputs$survival, m@outputs$time, mean)
  expect_equal(as.numeric(ens), pt$value, tolerance = 0.03)
})

test_that("a Cox fit falls back to the maximum-likelihood curve, marked", {
  fit <- survkit(survival::Surv(time, status) ~ age + sex, .fx_lung(),
                 method = "cox", warn_underpowered = FALSE)
  m <- as_survkit_manifest(fit, n_draws = 50L, times = c(200, 400),
                           newdata = data.frame(age = 60, sex = 1), seed = 1L)
  expect_identical(nrow(m@params), 50L)
  expect_true(all(m@outputs$draw == 0L))              # MLE curve, not per-draw
})

test_that("the manifest errors on a coefficient-free fit", {
  km <- survkit(survival::Surv(time, status) ~ 1, .fx_lung(), method = "km")
  expect_error(as_survkit_manifest(km), "no coefficients")
})
