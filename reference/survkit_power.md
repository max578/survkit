# Assess a fit's small-sample power (events per variable)

Assess whether a survival model is identifiable from the available
events. Returns the event count, the predictor count, the
events-per-variable ratio and a verdict.
[`survkit()`](https://max578.github.io/survkit/reference/survkit.md)
attaches this to every fit and warns when a model is under-powered.

## Usage

``` r
survkit_power(formula, data, min_epv = 10)
```

## Arguments

- formula:

  A model formula with a
  [`survival::Surv()`](https://rdrr.io/pkg/survival/man/Surv.html)
  response.

- data:

  A data frame.

- min_epv:

  Numeric events-per-variable floor (default `10`).

## Value

A list: `n`, `n_events`, `n_predictors`, `events_per_variable`,
`min_epv`, `underpowered` (logical), `verdict` (`"ok"` /
`"underpowered"` / `"unknown"`) and `advice`.

## Details

The event count comes from the last column of the
[`survival::Surv()`](https://rdrr.io/pkg/survival/man/Surv.html)
response. When that column is a multi-state factor (competing risks) the
event count cannot be read as a single 0/1 flag, so the verdict is
`"unknown"` rather than a guess. For a counting-process response
(recurrent events) the count is the number of event rows, not the number
of distinct subjects.

## References

Peduzzi P, Concato J, Kemper E, Holford TR, Feinstein AR. A simulation
study of the number of events per variable in logistic regression
analysis. *Journal of Clinical Epidemiology* 1996; 49(12): 1373-1379.
[doi:10.1016/S0895-4356(96)00236-3](https://doi.org/10.1016/S0895-4356%2896%2900236-3)

## See also

[`survkit()`](https://max578.github.io/survkit/reference/survkit.md),
which runs this gate on every fit.

Other model-fitting:
[`is_survkit_refusal()`](https://max578.github.io/survkit/reference/is_survkit_refusal.md),
[`survkit()`](https://max578.github.io/survkit/reference/survkit.md),
[`survkit_cuminc()`](https://max578.github.io/survkit/reference/survkit_cuminc.md),
[`survkit_refusal()`](https://max578.github.io/survkit/reference/survkit_refusal.md),
[`survkit_rmst()`](https://max578.github.io/survkit/reference/survkit_rmst.md),
[`survkit_score()`](https://max578.github.io/survkit/reference/survkit_score.md),
[`survkit_triangulate()`](https://max578.github.io/survkit/reference/survkit_triangulate.md)

## Examples

``` r
df <- data.frame(time = rexp(40), status = rbinom(40, 1, 0.3),
                 x1 = rnorm(40), x2 = rnorm(40))
survkit_power(survival::Surv(time, status) ~ x1 + x2, df)$verdict
#> [1] "underpowered"
```
