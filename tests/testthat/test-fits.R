# Every registered method fits and returns a typed survkit_fit.

test_that("all seven parametric families fit and are typed", {
  skip_if_not_installed("flexsurv")
  df <- .fx_lung()
  n_ev <- as.integer(sum(df$status == 2L))
  families <- c("exponential", "weibull", "lognormal", "loglogistic",
                "gompertz", "generalized_gamma", "gamma")
  for (m in families) {
    fit <- survkit(survival::Surv(time, status) ~ age + sex, df, method = m,
                   warn_underpowered = FALSE)
    expect_true(S7::S7_inherits(fit, survkit_fit), info = m)
    expect_identical(fit@method, m)
    expect_identical(fit@kind, "parametric")
    expect_true(is.finite(fit@loglik), info = m)
    expect_identical(fit@n_events, n_ev)
  }
})

test_that("spline, Cox and ridge-Cox fit", {
  skip_if_not_installed("flexsurv")
  df <- .fx_lung()
  sp <- survkit(survival::Surv(time, status) ~ age, df, method = "spline",
                warn_underpowered = FALSE)
  expect_identical(sp@kind, "spline")

  cx <- survkit(survival::Surv(time, status) ~ age + sex, df, method = "cox",
                warn_underpowered = FALSE)
  expect_identical(cx@ratio_type, "HR")
  expect_length(coef(cx), 2L)

  cr <- survkit(survival::Surv(time, status) ~ age + sex + ph.ecog, df,
                method = "cox_ridge", warn_underpowered = FALSE)
  expect_identical(cr@kind, "cox")
  expect_length(coef(cr), 3L)
})

test_that("the Kaplan-Meier baseline fits with no coefficients", {
  df <- .fx_lung()
  km <- survkit(survival::Surv(time, status) ~ 1, df, method = "km")
  expect_identical(km@kind, "nonparametric")
  expect_length(coef(km), 0L)
  expect_identical(km@n_events, as.integer(sum(df$status == 2L)))
})

test_that("shared frailty fits via coxme", {
  skip_if_not_installed("coxme")
  df <- .fx_lung()
  fit <- survkit(survival::Surv(time, status) ~ age + (1 | inst), df,
                 method = "frailty", warn_underpowered = FALSE)
  expect_identical(fit@kind, "frailty")
  expect_true(length(coef(fit)) >= 1L)
})

test_that("competing-risks cause-specific and Fine-Gray fit", {
  df <- .fx_mgus()
  cs <- survkit(survival::Surv(etime, pstat) ~ age + sex, df,
                method = "cause_specific", warn_underpowered = FALSE)
  expect_identical(cs@kind, "competing")

  fg <- survkit(survival::Surv(etime, event) ~ age + sex, df,
                method = "fine_gray", cause = "pcm", warn_underpowered = FALSE)
  expect_identical(fg@kind, "competing")
  expect_true(fg@n_events > 0L)
})

test_that("recurrent-event Andersen-Gill fits on a counting-process response", {
  b <- .fx_bladder()
  fit <- survkit(survival::Surv(start, stop, event) ~ rx + number, b,
                 method = "andersen_gill", id = id, warn_underpowered = FALSE)
  expect_identical(fit@kind, "recurrent")
  expect_length(coef(fit), 2L)
})

test_that("optional-backend methods are registered even when absent", {
  m <- survkit_methods()
  expect_true(all(c("cure", "interval_censored") %in% m$method))
  # When the backend is missing, survkit() errors with an install hint.
  if (!requireNamespace("icenReg", quietly = TRUE)) {
    expect_error(
      survkit(survival::Surv(time, status) ~ age, .fx_lung(),
              method = "interval_censored", warn_underpowered = FALSE),
      "icenReg")
  }
})

test_that("the mixture cure model fits and separates its auxiliaries", {
  skip_if_not_installed("flexsurvcure")
  fit <- survkit(survival::Surv(time, status) ~ age, .fx_lung(), method = "cure",
                 warn_underpowered = FALSE)
  expect_identical(fit@kind, "cure")
  tab <- survkit_tidy(fit)
  # theta / shape / scale are auxiliary and never exponentiated into a ratio.
  expect_true(any(tab$component == "auxiliary"))
  expect_true(all(is.na(tab$ratio[tab$component == "auxiliary"])))
})

test_that("interval-censored regression fits and keeps its baseline auxiliary", {
  skip_if_not_installed("icenReg")
  utils::data(miceData, package = "icenReg", envir = environment())
  fit <- survkit(survival::Surv(l, u, type = "interval2") ~ grp, miceData,
                 method = "interval_censored", warn_underpowered = FALSE)
  expect_identical(fit@kind, "interval")
  tab <- survkit_tidy(fit)
  # log_shape / log_scale are the baseline auxiliaries, not covariate ratios.
  aux <- tab[tab$component == "auxiliary", ]
  expect_true(all(c("log_shape", "log_scale") %in% aux$term))
  expect_true(all(is.na(aux$ratio)))
  expect_identical(tab$ratio_type[tab$term == "grpge"], "HR")
})
