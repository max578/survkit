# The events-per-variable power gate.

test_that("the gate passes a well-powered model", {
  p <- survkit_power(survival::Surv(time, status) ~ age + sex, .fx_lung())
  expect_identical(p$verdict, "ok")
  expect_false(p$underpowered)
  expect_true(p$events_per_variable >= 10)
})

test_that("the gate flags an under-powered model and survkit() warns", {
  df <- .fx_lung()[1:25, ]
  p <- survkit_power(survival::Surv(time, status) ~ age + sex + ph.ecog, df)
  expect_identical(p$verdict, "underpowered")
  expect_true(p$events_per_variable < 10)
  expect_true(is.character(p$advice))
  expect_warning(
    survkit(survival::Surv(time, status) ~ age + sex + ph.ecog, df,
            method = "cox"),
    "events per predictor")
})

test_that("a multi-state response gives an unknown verdict, not a guess", {
  df <- .fx_mgus()
  p <- survkit_power(survival::Surv(etime, event) ~ age + sex, df)
  expect_identical(p$verdict, "unknown")
  expect_true(is.na(p$events_per_variable))
})

test_that("check_power = FALSE skips the gate and never warns", {
  df <- .fx_lung()[1:25, ]
  expect_no_warning(
    fit <- survkit(survival::Surv(time, status) ~ age + sex + ph.ecog, df,
                   method = "cox", check_power = FALSE))
  expect_identical(fit@power$verdict, "unchecked")
})

test_that("on_underpowered = 'abstain' returns a classed refusal, not a fit", {
  df <- .fx_lung()[1:25, ]
  decl <- survkit(survival::Surv(time, status) ~ age + sex + ph.ecog, df,
                   method = "cox", on_underpowered = "abstain")
  expect_s3_class(decl, "survkit_refusal")
  expect_true(any(grepl("_(refusal|abstention)$", class(decl))))
  expect_true(decl$underpowered)
  expect_identical(decl$min_epv, 10)
  expect_true(decl$events_per_variable < 10)
  expect_true(is.character(decl$reason))
})

test_that("print.survkit_refusal dispatches for a caller (not just inside the namespace)", {
  df <- .fx_lung()[1:25, ]
  decl <- survkit(survival::Surv(time, status) ~ age + sex + ph.ecog, df,
                   method = "cox", on_underpowered = "abstain")
  expect_identical(getS3method("print", "survkit_refusal", envir = baseenv()),
                   survkit:::print.survkit_refusal)
  expect_output(print(decl), "survkit_refusal")
})

test_that("on_underpowered = 'abstain' still fits a well-powered model", {
  fit <- survkit(survival::Surv(time, status) ~ age + sex, .fx_lung(),
                 method = "cox", on_underpowered = "abstain")
  expect_true(S7::S7_inherits(fit, survkit_fit))
})
