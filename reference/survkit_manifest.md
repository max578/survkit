# Represent an ensemble-manifest emission

A self-contained, manifest-compatible emission for orchestra
composition: a draw ensemble of parameters and predicted survival, with
provenance. Produced by
[`as_survkit_manifest()`](https://max578.github.io/survkit/reference/as_survkit_manifest.md);
convertible to a `pesto_ensemble_manifest` when that contract is
available (see the manifest emitter).

## Usage

``` r
survkit_manifest(
  params = data.frame(),
  outputs = NULL,
  time_grid = numeric(0),
  method = character(0),
  emitter_version = character(0),
  seed = NA_integer_
)
```

## Arguments

- params:

  Data frame of parameter draws (`n_draw` rows).

- outputs:

  Data frame of predicted survival draws on a time grid.

- time_grid:

  Numeric vector of evaluation times.

- method:

  Character method name.

- emitter_version:

  Character package version that emitted the manifest.

- seed:

  Integer RNG seed.

## Value

A `survkit_manifest` S7 object.

## See also

[`as_survkit_manifest()`](https://max578.github.io/survkit/reference/as_survkit_manifest.md),
which constructs this object.

## Examples

``` r
fit <- survkit(survival::Surv(time, status) ~ age, survival::lung,
               method = "weibull")
man <- as_survkit_manifest(fit, n_draws = 50L)
man@method
#> [1] "weibull"
```
