# Emit an ensemble manifest from a fitted model

Produce a draw ensemble for orchestra composition. Coefficients are
drawn from their Gaussian sampling approximation (mean = estimate,
covariance = `vcov`), and the result is shaped to the ensemble-manifest
contract (a parameter draw frame with provenance) so a
`pesto_ensemble_manifest`-compatible adapter can consume it.

## Usage

``` r
as_survkit_manifest(
  fit,
  n_draws = 200L,
  times = NULL,
  newdata = NULL,
  seed = NULL
)
```

## Arguments

- fit:

  A
  [survkit_fit](https://max578.github.io/survkit/reference/survkit_fit.md).

- n_draws:

  Integer number of draws (default `200L`).

- times:

  Optional numeric time grid for the survival outputs. `NULL` (default)
  emits a parameters-only manifest.

- newdata:

  Optional single covariate profile (one row) for the survival outputs.
  Required for the per-draw survival ensemble.

- seed:

  Optional integer RNG seed (recorded in the manifest).

## Value

A
[survkit_manifest](https://max578.github.io/survkit/reference/survkit_manifest.md)
object.

## Details

When `times` and a single-profile `newdata` are given and the fit is
parametric, spline or cure, the `outputs` slot carries a genuine
per-draw survival ensemble: the draws come from the backend's own
sampling distribution and each draw's survival is evaluated through the
fitted distribution function, so `params` and `outputs` share the same
draws. For a Cox-family or non-parametric fit a per-draw survival
ensemble would also need the baseline-hazard uncertainty, so `outputs`
instead holds the maximum-likelihood survival curve marked with
`draw = 0`.

## See also

[survkit_manifest](https://max578.github.io/survkit/reference/survkit_manifest.md)
for the returned class,
[`survkit()`](https://max578.github.io/survkit/reference/survkit.md) for
the fit.

## Examples

``` r
fit <- survkit(survival::Surv(time, status) ~ age, survival::lung, method = "weibull")
m <- as_survkit_manifest(fit, n_draws = 50L, seed = 1L)
nrow(m@params)
#> [1] 50
```
