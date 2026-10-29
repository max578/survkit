# Tidy a fitted model into a coefficient table

Return the coefficient table with standard errors, the exponentiated
effect and Wald confidence intervals. Covariate rows and baseline
distribution parameters are separated by a `component` column, and the
`ratio_type` column records whether a covariate effect reads as a hazard
ratio (proportional hazards) or a time ratio (accelerated failure time).
Auxiliary parameters (a log-scale, a shape) are never exponentiated into
the ratio column, so a parametric fit no longer reports a meaningless
"ratio" for its scale.

## Usage

``` r
survkit_tidy(fit, conf_level = 0.95)
```

## Arguments

- fit:

  A
  [survkit_fit](https://max578.github.io/survkit/reference/survkit_fit.md).

- conf_level:

  Confidence level for the Wald interval (default `0.95`).

## Value

A data frame with columns `term`, `component` (`"covariate"` /
`"auxiliary"`), `estimate`, `std_error`, `ratio_type`, `ratio`,
`conf_low` and `conf_high`. For auxiliary parameters `ratio_type`,
`ratio` and the interval are `NA`.

## See also

[`survkit_curve()`](https://max578.github.io/survkit/reference/survkit_curve.md)
for predicted survival.

Other fit-methods:
[`survkit_curve()`](https://max578.github.io/survkit/reference/survkit_curve.md)

## Examples

``` r
fit <- survkit(survival::Surv(time, status) ~ age + sex, survival::lung, method = "cox")
survkit_tidy(fit)
#>   term component    estimate   std_error ratio_type    ratio  conf_low
#> 1  age covariate  0.01704533 0.009223273         HR 1.017191 0.9989686
#> 2  sex covariate -0.51321852 0.167457962         HR 0.598566 0.4310936
#>   conf_high
#> 1 1.0357467
#> 2 0.8310985
```
