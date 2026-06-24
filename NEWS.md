# survkit 0.0.0.9000 (development)

First development scaffold.

## Features

* `survkit()` — one interface over the survival stack, dispatching through an
  extensible method registry.
* Built-in methods: parametric AFT (`exponential`, `weibull`, `lognormal`,
  `loglogistic`, `gompertz`, `generalized_gamma`, `gamma`), `spline`
  (Royston-Parmar), `cox`, `frailty`, `cause_specific` and `fine_gray`
  (competing risks), `andersen_gill` (recurrent events), with `cure` and
  `interval_censored` registered against optional backends.
* `survkit_register()` / `survkit_methods()` — add a method with one call; the
  public API does not change.
* Typed `survkit_fit` (S7) with consistent `print`, `summary`, `coef`, `vcov`,
  `logLik`, `predict`, `survkit_tidy()` and `survkit_curve()`.
* `survkit_power()` — the events-per-variable gate; `survkit()` runs it on every
  fit and warns when a model is under-powered (the honest small-sample posture).
* `as_survkit_manifest()` — a self-contained, ensemble-manifest-shaped emission
  for composition with a wider analytics stack; no sibling package required.

## Known refinements (for follow-up)

* `survkit_tidy()` lists every backend parameter, so for parametric fits the
  table includes the location / ancillary parameters alongside the covariate
  effects. A per-kind tidy that separates covariate effects (hazard / time
  ratios) from ancillary parameters is the next refinement.
* `cure` and `interval_censored` need their optional backends installed
  (`flexsurvcure`, `icenReg`); they are registered and discoverable now.
