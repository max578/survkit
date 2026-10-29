# Represent a fitted survival model

An S7 object returned by
[`survkit()`](https://max578.github.io/survkit/reference/survkit.md). It
normalises every backend's output to one shape: the method and kind, the
raw backend fit (kept for backend-specific follow-up), the coefficient
vector and covariance, the log-likelihood, the sample and event counts,
and the small-sample power verdict.

## Usage

``` r
survkit_fit(
  method = character(0),
  kind = character(0),
  backend = character(0),
  fit = NULL,
  coefficients = integer(0),
  vcov = NULL,
  loglik = NA_real_,
  n = integer(0),
  n_events = integer(0),
  ratio_type = NA_character_,
  aux_pars = character(0),
  power = list(),
  formula = NULL,
  call = NULL
)
```

## Arguments

- method:

  Character method name (a registry key, e.g. `"weibull"`).

- kind:

  Character method family: one of `"parametric"`, `"spline"`,
  `"nonparametric"`, `"cox"`, `"frailty"`, `"competing"`, `"recurrent"`,
  `"cure"` or `"interval"`.

- backend:

  Character name of the package that produced the fit.

- fit:

  The raw backend fit object.

- coefficients:

  Named numeric coefficient vector.

- vcov:

  Coefficient covariance matrix (or `NULL`).

- loglik:

  Numeric log-likelihood (or `NA`).

- n:

  Integer number of observations.

- n_events:

  Integer number of events (non-censored).

- ratio_type:

  Character code for how an exponentiated covariate coefficient reads:
  `"HR"` (hazard ratio), `"TR"` (time ratio), `"OR"` (odds ratio),
  `"probit"`, or `NA` when the fit has no such coefficients.

- aux_pars:

  Character names of the baseline distribution parameters (the auxiliary
  parameters the tidier keeps out of the ratio column).

- power:

  A `list` power verdict from
  [`survkit_power()`](https://max578.github.io/survkit/reference/survkit_power.md).

- formula:

  The model formula.

- call:

  The originating call.

## Value

A `survkit_fit` S7 object.

## See also

[`survkit()`](https://max578.github.io/survkit/reference/survkit.md)
(constructs this object),
[`survkit_tidy()`](https://max578.github.io/survkit/reference/survkit_tidy.md),
[`survkit_curve()`](https://max578.github.io/survkit/reference/survkit_curve.md)
(consume it).

## Examples

``` r
fit <- survkit(survival::Surv(time, status) ~ age + sex, survival::lung,
               method = "cox")
fit@method
#> [1] "cox"
fit@n_events
#> [1] 165
```
