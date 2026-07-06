# Predictive scoring: discrimination and calibration-accuracy.

test_that("scoring a Cox fit is sane and matches survival::concordance", {
  df <- .fx_lung()
  fit <- survkit(survival::Surv(time, status) ~ age + sex, df, method = "cox",
                 warn_underpowered = FALSE)
  sc <- survkit_score(fit, df, times = c(200, 400, 600))
  expect_true(all(c("time", "cindex", "brier", "ipa") %in% names(sc)))
  expect_true(all(sc$cindex > 0.5 & sc$cindex < 0.8))
  expect_true(all(sc$brier > 0 & sc$brier < 0.25))
  # In-sample, the model beats the covariate-free reference (IPA > 0).
  expect_true(all(sc$ipa > 0))
  # The concordance matches the reference implementation on the fit's own risk.
  ref <- survival::concordance(fit@fit)$concordance
  expect_equal(sc$cindex[3L], ref, tolerance = 0.05)
})

test_that("scoring works for a parametric fit", {
  skip_if_not_installed("flexsurv")
  df <- .fx_lung()
  fit <- survkit(survival::Surv(time, status) ~ age + sex, df, method = "weibull",
                 warn_underpowered = FALSE)
  sc <- survkit_score(fit, df, times = c(200, 400))
  expect_true(all(sc$cindex > 0.5))
  expect_true(all(is.finite(sc$brier)))
})

test_that("scoring rejects a multi-state (non-right-censored) response", {
  mg <- .fx_mgus()
  fg <- survkit(survival::Surv(etime, event) ~ age, mg, method = "fine_gray",
                cause = "pcm", warn_underpowered = FALSE)
  expect_error(survkit_score(fg, mg, times = 60), "right-censored")
})
