# Fit a time-to-event model

One interface over the established survival stack. `method` selects an
estimator from the registry
([`survkit_methods()`](https://max578.github.io/survkit/reference/survkit_methods.md));
the appropriate backend is checked, a small-sample power gate runs
([`survkit_power()`](https://max578.github.io/survkit/reference/survkit_power.md)),
and the fit is returned as a single typed object
([survkit_fit](https://max578.github.io/survkit/reference/survkit_fit.md))
with consistent `print`, `summary`, `coef`, `vcov`, `predict` and
[`tidy()`](https://generics.r-lib.org/reference/tidy.html) methods.

## Usage

``` r
survkit(
  formula,
  data,
  method = "weibull",
  ...,
  check_power = TRUE,
  warn_underpowered = TRUE,
  on_underpowered = c("warn", "abstain")
)
```

## Arguments

- formula:

  A model formula, e.g. `survival::Surv(time, status) ~ x`.

- data:

  A data frame.

- method:

  Character registry key (default `"weibull"`); see
  [`survkit_methods()`](https://max578.github.io/survkit/reference/survkit_methods.md).

- ...:

  Passed to the backend estimator.

- check_power:

  Logical; run the events-per-variable gate (default `TRUE`).

- warn_underpowered:

  Logical; warn when the gate flags the model under-powered (default
  `TRUE`). Ignored when `on_underpowered = "abstain"`.

- on_underpowered:

  One of `"warn"` (default) or `"abstain"`. `"warn"` preserves the
  historical behaviour: the model is fitted regardless, with a warning
  when `warn_underpowered` is `TRUE`. `"abstain"` declines to fit at all
  when the gate flags the model under-powered, returning a
  [`survkit_refusal()`](https://max578.github.io/survkit/reference/survkit_refusal.md)
  instead – the typed token an orchestra-level caller can recognise via
  `is_orchestra_decline()`.

## Value

A
[survkit_fit](https://max578.github.io/survkit/reference/survkit_fit.md)
object, or a
[`survkit_refusal()`](https://max578.github.io/survkit/reference/survkit_refusal.md)
when `on_underpowered = "abstain"` and the power gate is not satisfied.

## Details

The left-hand side of `formula` is a
[`survival::Surv()`](https://rdrr.io/pkg/survival/man/Surv.html)
response. Extra arguments in `...` pass straight to the backend
estimator, so any backend option remains reachable.

## See also

[`survkit_methods()`](https://max578.github.io/survkit/reference/survkit_methods.md)
for the registry,
[`survkit_power()`](https://max578.github.io/survkit/reference/survkit_power.md)
for the gate.

Other model-fitting:
[`is_survkit_refusal()`](https://max578.github.io/survkit/reference/is_survkit_refusal.md),
[`survkit_cuminc()`](https://max578.github.io/survkit/reference/survkit_cuminc.md),
[`survkit_power()`](https://max578.github.io/survkit/reference/survkit_power.md),
[`survkit_refusal()`](https://max578.github.io/survkit/reference/survkit_refusal.md),
[`survkit_rmst()`](https://max578.github.io/survkit/reference/survkit_rmst.md),
[`survkit_score()`](https://max578.github.io/survkit/reference/survkit_score.md),
[`survkit_triangulate()`](https://max578.github.io/survkit/reference/survkit_triangulate.md)

## Examples

``` r
df <- survival::lung
fit <- survkit(survival::Surv(time, status) ~ age + sex, df, method = "weibull")
fit
#> <survkit_fit> method = weibull (parametric, via flexsurv)
#>   n = 228   events = 165
#>   power: ok (82.5 events/predictor)
#>   coefficients:
#>   shape   scale     age     sex 
#>  0.2823  6.2749 -0.0123  0.3821 
coef(fit)
#>       shape       scale         age         sex 
#>  0.28229534  6.27485306 -0.01225703  0.38208514 
```
