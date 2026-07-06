# Cumulative incidence and restricted mean survival time.

test_that("cumulative incidence is monotone and sums within one", {
  df <- .fx_mgus()
  ci <- survkit_cuminc(survival::Surv(etime, event) ~ 1, df)
  expect_setequal(unique(ci$cause), c("pcm", "death"))
  # each cause's CIF is non-decreasing in time.
  monotone <- tapply(ci$cif, ci$cause, function(x) all(diff(x) >= -1e-9))
  expect_true(all(monotone))
  # terminal incidence across causes is a probability.
  terminal <- tapply(ci$cif, ci$cause, function(x) x[length(x)])
  expect_lte(sum(terminal), 1 + 1e-8)
})

test_that("cumulative incidence supports grouping", {
  df <- .fx_mgus()
  ci <- survkit_cuminc(survival::Surv(etime, event) ~ sex, df)
  expect_true(length(unique(ci$group)) == 2L)
})

test_that("cumulative incidence needs a multi-state response", {
  expect_error(
    survkit_cuminc(survival::Surv(time, status) ~ 1, .fx_lung()),
    "multi-state")
})

test_that("restricted mean matches the area under the survival curve", {
  km <- survkit(survival::Surv(time, status) ~ 1, .fx_lung(), method = "km")
  r <- survkit_rmst(km, tau = 365)
  expect_true(is.finite(r$rmst))
  # Independent trapezoidal integral of the KM curve to tau as an oracle.
  sf <- survival::survfit(survival::Surv(time, status) ~ 1, .fx_lung())
  grid <- sort(unique(pmin(c(sf$time[sf$time <= 365], 365), 365)))
  s <- summary(sf, times = grid, extend = TRUE)$surv
  trap <- sum(diff(c(0, grid)) * c(1, s[-length(s)]))
  expect_equal(r$rmst, trap, tolerance = 0.02)
})

test_that("restricted mean works for a parametric fit with an interval", {
  skip_if_not_installed("flexsurv")
  w <- survkit(survival::Surv(time, status) ~ age, .fx_lung(),
               method = "weibull", warn_underpowered = FALSE)
  r <- survkit_rmst(w, tau = 365, newdata = data.frame(age = 60))
  expect_true(is.finite(r$rmst))
  expect_true(r$conf_low < r$rmst && r$rmst < r$conf_high)
})

test_that("a non-positive horizon is rejected", {
  km <- survkit(survival::Surv(time, status) ~ 1, .fx_lung(), method = "km")
  expect_error(survkit_rmst(km, tau = -1), "positive")
  expect_error(survkit_rmst(km, tau = c(1, 2)), "single")
})
