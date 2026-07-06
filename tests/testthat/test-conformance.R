# The registry conformance contract.

test_that("the contract names the required fields", {
  fields <- survkit_contract()
  expect_true(all(c("raw", "coef", "vcov", "loglik", "n", "n_events", "kind",
                    "backend") %in% fields))
})

test_that("every built-in method honours the contract", {
  lung <- .fx_lung()
  mg <- .fx_mgus()
  bl <- .fx_bladder()
  cases <- list(
    list("exponential", survival::Surv(time, status) ~ age, lung, list()),
    list("weibull", survival::Surv(time, status) ~ age, lung, list()),
    list("spline", survival::Surv(time, status) ~ age, lung, list()),
    list("km", survival::Surv(time, status) ~ 1, lung, list()),
    list("cox", survival::Surv(time, status) ~ age, lung, list()),
    list("cox_ridge", survival::Surv(time, status) ~ age + sex, lung, list()),
    list("frailty", survival::Surv(time, status) ~ age + (1 | inst), lung, list()),
    list("cause_specific", survival::Surv(etime, pstat) ~ age, mg, list()),
    list("fine_gray", survival::Surv(etime, event) ~ age, mg, list(cause = "pcm")),
    list("andersen_gill", survival::Surv(start, stop, event) ~ rx, bl,
         list(id = quote(id)))
  )
  for (case in cases) {
    v <- do.call(survkit_validate_method,
                 c(list(case[[1L]], case[[2L]], case[[3L]]), case[[4L]]))
    # NA means the backend is not installed (a skip, not a failure).
    if (!is.na(v$ok)) {
      expect_true(v$ok,
                  info = sprintf("%s: missing %s, failed %s", case[[1L]],
                                 paste(v$missing, collapse = ","),
                                 paste(v$failed, collapse = ",")))
    }
  }
})

test_that("a malformed method is rejected with the offending fields named", {
  survkit_register("bad_method", "parametric", "survival",
    fit = function(formula, data, ...) {
      list(raw = NULL, coef = "not numeric", n = 10L)   # missing fields, wrong type
    })
  v <- survkit_validate_method("bad_method", survival::Surv(time, status) ~ age,
                               .fx_lung())
  expect_false(v$ok)
  expect_true("coef" %in% v$failed)
  expect_true(all(c("vcov", "loglik", "kind", "backend") %in% v$missing))
})

test_that("validating an uninstalled backend is skipped, not failed", {
  skip_if(requireNamespace("icenReg", quietly = TRUE),
          "icenReg is installed")
  v <- survkit_validate_method("interval_censored",
                               survival::Surv(time, status) ~ age, .fx_lung())
  expect_true(is.na(v$ok))
  expect_match(v$reason, "icenReg")
})
