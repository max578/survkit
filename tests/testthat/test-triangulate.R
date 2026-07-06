# Cross-method triangulation.

test_that("methods that agree are not flagged", {
  skip_if_not_installed("flexsurv")
  tri <- survkit_triangulate(survival::Surv(time, status) ~ age + sex,
                             .fx_lung(), methods = c("weibull", "cox", "km"),
                             tau = 500, time_star = 300)
  expect_s3_class(tri, "survkit_triangulation")
  expect_setequal(tri$methods, c("weibull", "cox", "km"))
  # The three methods concur on the restricted mean of the lung data.
  expect_false(tri$flagged)
  expect_output(print(tri), "verdict")
})

test_that("a grossly misspecified family disagrees and is flagged", {
  skip_if_not_installed("flexsurv")
  # Strongly non-constant hazard: the exponential (constant hazard) mis-estimates
  # the restricted mean relative to the flexible spline.
  set.seed(1L)
  d <- data.frame(time = stats::rweibull(400, shape = 3, scale = 100),
                  status = 1L)
  tri <- survkit_triangulate(survival::Surv(time, status) ~ 1, d,
                             methods = c("exponential", "spline"), tau = 60)
  expect_true(tri$flagged)
})

test_that("triangulation drops a method whose backend is missing", {
  skip_if_not_installed("flexsurv")
  expect_warning(
    tri <- survkit_triangulate(survival::Surv(time, status) ~ age, .fx_lung(),
                               methods = c("cox", "km", "interval_censored"),
                               tau = 400),
    "dropped")
  expect_false("interval_censored" %in% tri$methods)
})

test_that("triangulation needs at least two methods that fit", {
  expect_error(
    survkit_triangulate(survival::Surv(time, status) ~ age, .fx_lung(),
                        methods = "cox", tau = 400),
    "at least two")
})
