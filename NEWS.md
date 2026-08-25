# survkit (development version)

* `survkit()` gains an `on_underpowered = c("warn", "abstain")` argument.
  `"warn"` preserves the historical behaviour (fit anyway, with a warning);
  `"abstain"` declines to fit an under-powered model and instead returns a
  [survkit_refusal()] -- a typed, classed token (`c("survkit_refusal",
  "orchestra_refusal", "error", "condition")`) recognisable to a leader-side
  gate via `is_orchestra_decline()`, rather than a bare `warning()` plus a
  fitted model regardless of the power gate's verdict.

# survkit 0.1.0

First public release. The registry-dispatched facade of the development scaffold
gains its value layer: the decision-relevant estimands and the cross-method
honesty checks that make survkit a methodology rather than a wrapper.

## Breaking changes

* `survkit_tidy()` no longer exponentiates a parametric fit's baseline
  parameters into a meaningless ratio, and it now labels each covariate effect
  by scale. The output gains a `component` column (`"covariate"` /
  `"auxiliary"`) and a `ratio_type` column (`"HR"` / `"TR"` / `"OR"` / probit).

  ```r
  # before: shape and scale were listed as covariates with a bogus "ratio"
  #   term  estimate  ratio
  #   scale 6.27      531.0        <- exponentiated log-scale intercept
  #   sex   0.38      1.47         <- a time ratio, unlabelled

  # after: auxiliaries are separated, covariates carry their ratio type
  #   term  component  estimate  ratio_type  ratio
  #   scale auxiliary  6.27      <NA>        NA
  #   sex   covariate  0.38      TR          1.47
  ```

* `survkit_curve()` returns its predicted quantity in a column named `value`
  (was `survival`), because the function now predicts hazard, cumulative hazard
  and quantiles as well as survival.

## New features

* `survkit_triangulate()` fits the same data under several methods and reads
  their relative spread on the restricted mean (and, optionally, survival at a
  landmark) as a model-misspecification signal.
* `survkit_rmst()` computes the restricted mean survival time to a horizon, with
  the backend's interval for parametric fits and the survival package's standard
  error for Cox-family and non-parametric fits.
* `survkit_cuminc()` gives the Aalen-Johansen cumulative incidence of each
  competing event.
* `survkit_score()` scores predictions with Harrell's concordance and the
  inverse-probability-of-censoring-weighted Brier score and its index of
  prediction accuracy.
* `survkit_contract()` and `survkit_validate_method()` expose and check the
  registry conformance contract every `fit` closure must honour.
* New methods in the registry: `km` (Kaplan-Meier / Nelson-Aalen non-parametric
  baseline) and `cox_ridge` (ridge-penalised Cox for the few-events regime).
* `survkit_curve()` gains a `type` argument (`"survival"`, `"hazard"`,
  `"cumhaz"`, `"quantile"`).
* `as_survkit_manifest()` now emits a genuine per-draw survival ensemble for
  parametric, spline and cure fits (the draws and the survival share one sample);
  Cox-family fits emit the maximum-likelihood curve marked `draw = 0`.

## Minor improvements and fixes

* The power gate returns `"unknown"` for a multi-state (competing-risks)
  response rather than pooling the competing events into one misleading count.
* Cox-family fits retain their model frame (`model = TRUE`), so survival curves
  and scoring on new data work reliably.
* `survkit_fit` carries `ratio_type` and `aux_pars` so the tidier can separate
  covariate effects from baseline parameters for any backend.
