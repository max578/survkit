# Register a survival method

Add (or override) an estimator in the method registry. The `fit` closure
receives `(formula, data, ...)` and must return a list with `raw` (the
backend fit), `coef`, `vcov`, `loglik`, `n`, `n_events`, `kind` and
`backend` – build it with the package's internal normaliser or by hand.

## Usage

``` r
survkit_register(name, kind, backend, fit, note = "")
```

## Arguments

- name:

  Character key, e.g. `"weibull"`.

- kind:

  Character family: `"parametric"`, `"cox"`, `"competing"`,
  `"recurrent"`, `"frailty"`, `"spline"`, `"cure"`, `"interval"`.

- backend:

  Character name of the backend package the `fit` closure needs (checked
  via [`requireNamespace()`](https://rdrr.io/r/base/ns-load.html) before
  the fit runs).

- fit:

  A function `(formula, data, ...)` returning the normalised list.

- note:

  Character one-line description (shown by
  [`survkit_methods()`](https://max578.github.io/survkit/reference/survkit_methods.md)).

## Value

Invisibly, the method name.

## See also

[`survkit_methods()`](https://max578.github.io/survkit/reference/survkit_methods.md)
to list what is registered.

Other method-registry:
[`survkit_contract()`](https://max578.github.io/survkit/reference/survkit_contract.md),
[`survkit_methods()`](https://max578.github.io/survkit/reference/survkit_methods.md),
[`survkit_validate_method()`](https://max578.github.io/survkit/reference/survkit_validate_method.md)

## Examples

``` r
# register a trivial exponential alias backed by survival::survreg
survkit_register("exp_survreg", "parametric", "survival",
  fit = function(formula, data, ...) {
    raw <- survival::survreg(formula, data = data, dist = "exponential", ...)
    list(raw = raw, coef = stats::coef(raw), vcov = stats::vcov(raw),
         loglik = as.numeric(stats::logLik(raw)),
         n = nrow(data), n_events = NA_integer_,
         kind = "parametric", backend = "survival")
  })
"exp_survreg" %in% survkit_methods()$method
#> [1] TRUE
```
