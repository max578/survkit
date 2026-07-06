# The consistent verb surface over survkit_fit.

test_that("tidy separates auxiliary parameters and labels the ratio", {
  skip_if_not_installed("flexsurv")
  df <- .fx_lung()
  w <- survkit(survival::Surv(time, status) ~ age + sex, df, method = "weibull",
               warn_underpowered = FALSE)
  tab <- survkit_tidy(w)
  expect_true(all(c("term", "component", "estimate", "std_error", "ratio_type",
                    "ratio", "conf_low", "conf_high") %in% names(tab)))
  # shape and scale are auxiliary: never a ratio.
  aux <- tab[tab$component == "auxiliary", ]
  expect_true(all(c("shape", "scale") %in% aux$term))
  expect_true(all(is.na(aux$ratio)))
  expect_true(all(is.na(aux$ratio_type)))
  # covariates are time ratios for an AFT family.
  cov <- tab[tab$component == "covariate", ]
  expect_true(all(cov$ratio_type == "TR"))
  expect_equal(cov$ratio, exp(cov$estimate))
})

test_that("Cox tidy gives hazard ratios for every covariate", {
  cx <- survkit(survival::Surv(time, status) ~ age + sex, .fx_lung(),
                method = "cox", warn_underpowered = FALSE)
  tab <- survkit_tidy(cx)
  expect_true(all(tab$component == "covariate"))
  expect_true(all(tab$ratio_type == "HR"))
  expect_equal(tab$ratio, exp(tab$estimate))
})

test_that("tidy of a coefficient-free fit is an empty typed frame", {
  km <- survkit(survival::Surv(time, status) ~ 1, .fx_lung(), method = "km")
  tab <- survkit_tidy(km)
  expect_identical(nrow(tab), 0L)
  expect_true("ratio_type" %in% names(tab))
})

test_that("print, summary and the base generics work", {
  cx <- survkit(survival::Surv(time, status) ~ age + sex, .fx_lung(),
                method = "cox", warn_underpowered = FALSE)
  expect_output(print(cx), "survkit_fit")
  expect_output(print(cx), "power")
  tab <- summary(cx)
  expect_true(is.data.frame(tab))
  expect_type(coef(cx), "double")
  expect_true(is.matrix(vcov(cx)))
  ll <- logLik(cx)
  expect_s3_class(ll, "logLik")
  expect_identical(attr(ll, "df"), 2L)
  expect_true(is.finite(AIC(cx)))
  expect_type(predict(cx, type = "lp"), "double")
})

test_that("survkit_curve returns survival, cumhaz and quantile types", {
  skip_if_not_installed("flexsurv")
  df <- .fx_lung()
  w <- survkit(survival::Surv(time, status) ~ age, df, method = "weibull",
               warn_underpowered = FALSE)
  s <- survkit_curve(w, newdata = data.frame(age = 60), times = c(100, 300, 500))
  expect_true(all(c("time", "value", "profile") %in% names(s)))
  expect_true(all(s$value >= 0 & s$value <= 1))
  h <- survkit_curve(w, newdata = data.frame(age = 60), times = c(100, 300),
                     type = "cumhaz")
  expect_true(all(h$value >= 0))
  q <- survkit_curve(w, newdata = data.frame(age = 60), type = "quantile")
  expect_true(nrow(q) > 0L)
})

test_that("survkit_curve for a survfit fit rejects the parametric-only types", {
  cx <- survkit(survival::Surv(time, status) ~ age, .fx_lung(), method = "cox",
                warn_underpowered = FALSE)
  s <- survkit_curve(cx, times = c(200, 400))
  expect_true(all(s$value >= 0 & s$value <= 1))
  expect_error(survkit_curve(cx, type = "quantile"), "parametric")
})

test_that("Cox survival curves carry one column per covariate profile", {
  cx <- survkit(survival::Surv(time, status) ~ age, .fx_lung(), method = "cox",
                warn_underpowered = FALSE)
  s <- survkit_curve(cx, newdata = data.frame(age = c(50, 70)),
                     times = c(200, 400))
  expect_setequal(unique(s$profile), c(1L, 2L))
})
