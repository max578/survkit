# Predict survival curves for a fit

Backend-aware predictions over a time grid for one or more covariate
profiles. Parametric, spline and cure fits use the backend's own
distribution function and support every `type`; Cox-family and
non-parametric fits use
[`survival::survfit()`](https://rdrr.io/pkg/survival/man/survfit.html)
and support the survival curve.

## Usage

``` r
survkit_curve(
  fit,
  newdata = NULL,
  times = NULL,
  type = c("survival", "hazard", "cumhaz", "quantile")
)
```

## Arguments

- fit:

  A
  [survkit_fit](https://max578.github.io/survkit/reference/survkit_fit.md).

- newdata:

  A data frame of covariate profiles. The default is the backend's
  reference profile.

- times:

  Numeric times at which to evaluate. The default is an automatic grid
  from the backend.

- type:

  Character quantity to predict: `"survival"` (default), `"hazard"`,
  `"cumhaz"` or `"quantile"`. The last three need a parametric, spline
  or cure fit.

## Value

A data frame with `time`, `value` (named for `type` when returned by the
backend) and a `profile` index.

## See also

[`survkit_tidy()`](https://max578.github.io/survkit/reference/survkit_tidy.md)
for the coefficient table,
[`survkit_rmst()`](https://max578.github.io/survkit/reference/survkit_rmst.md)
for the restricted mean.

Other fit-methods:
[`survkit_tidy()`](https://max578.github.io/survkit/reference/survkit_tidy.md)

## Examples

``` r
fit <- survkit(survival::Surv(time, status) ~ age, survival::lung, method = "weibull")
head(survkit_curve(fit, times = c(100, 300, 500)))
#>   time     value profile
#> 1  100 0.8594618       1
#> 2  300 0.5250282       1
#> 3  500 0.2827438       1
```
