# A classed refusal from the small-sample power gate

Construct the typed "will not fit" token
[`survkit()`](https://max578.github.io/survkit/reference/survkit.md)
returns when `on_underpowered = "abstain"` and the events-per-variable
gate
([`survkit_power()`](https://max578.github.io/survkit/reference/survkit_power.md))
flags the model as under-powered. Not signalled as a condition –
returned as an ordinary value, so a caller inspects it with
[`is_survkit_refusal()`](https://max578.github.io/survkit/reference/is_survkit_refusal.md)
rather than a [`tryCatch()`](https://rdrr.io/r/base/conditions.html).

## Usage

``` r
survkit_refusal(power)
```

## Arguments

- power:

  A power-gate result from
  [`survkit_power()`](https://max578.github.io/survkit/reference/survkit_power.md),
  already flagged `underpowered`.

## Value

A classed list with class
`c("survkit_refusal", "orchestra_refusal", "error", "condition")` and
elements `reason`, `n`, `n_events`, `n_predictors`,
`events_per_variable`, `min_epv`, `underpowered` (always `TRUE`),
`message`.

## See also

[`survkit()`](https://max578.github.io/survkit/reference/survkit.md),
[`survkit_power()`](https://max578.github.io/survkit/reference/survkit_power.md),
[`is_survkit_refusal()`](https://max578.github.io/survkit/reference/is_survkit_refusal.md).

Other model-fitting:
[`is_survkit_refusal()`](https://max578.github.io/survkit/reference/is_survkit_refusal.md),
[`survkit()`](https://max578.github.io/survkit/reference/survkit.md),
[`survkit_cuminc()`](https://max578.github.io/survkit/reference/survkit_cuminc.md),
[`survkit_power()`](https://max578.github.io/survkit/reference/survkit_power.md),
[`survkit_rmst()`](https://max578.github.io/survkit/reference/survkit_rmst.md),
[`survkit_score()`](https://max578.github.io/survkit/reference/survkit_score.md),
[`survkit_triangulate()`](https://max578.github.io/survkit/reference/survkit_triangulate.md)

## Examples

``` r
df <- data.frame(time = rexp(20), status = rbinom(20, 1, 0.2),
                 x1 = rnorm(20), x2 = rnorm(20))
p <- survkit_power(survival::Surv(time, status) ~ x1 + x2, df)
r <- survkit_refusal(p)
is_survkit_refusal(r)
#> [1] TRUE
```
