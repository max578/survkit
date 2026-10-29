# Predict from the raw backend fit

Delegate to [`stats::predict()`](https://rdrr.io/r/stats/predict.html)
on the backend object underlying a
[survkit_fit](https://max578.github.io/survkit/reference/survkit_fit.md)
(e.g. `predict.coxph()`, `predict.survreg()`), passing `...` straight
through. For a backend-independent survival, hazard or quantile
prediction on a common time grid, use
[`survkit_curve()`](https://max578.github.io/survkit/reference/survkit_curve.md)
instead.

## Arguments

- object:

  A
  [survkit_fit](https://max578.github.io/survkit/reference/survkit_fit.md).

- ...:

  Passed to the backend's `predict` method.

## Value

Whatever the backend's `predict` method returns.

## See also

[`survkit_curve()`](https://max578.github.io/survkit/reference/survkit_curve.md)
for a backend-independent prediction grid.

## Examples

``` r
fit <- survkit(survival::Surv(time, status) ~ age + sex, survival::lung,
               method = "cox")
head(predict(fit, type = "lp"))
#> [1] 0.39950470 0.29723270 0.09268872 0.10973405 0.16087005 0.39950470
```
