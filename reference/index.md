# Package index

## Fitting

One interface over the survival stack.

- [`survkit()`](https://max578.github.io/survkit/reference/survkit.md) :
  Fit a time-to-event model
- [`survkit_fit()`](https://max578.github.io/survkit/reference/survkit_fit.md)
  : Represent a fitted survival model
- [`predict.survkit_fit`](https://max578.github.io/survkit/reference/predict.survkit_fit.md)
  : Predict from the raw backend fit
- [`survkit_tidy()`](https://max578.github.io/survkit/reference/survkit_tidy.md)
  : Tidy a fitted model into a coefficient table
- [`survkit_curve()`](https://max578.github.io/survkit/reference/survkit_curve.md)
  : Predict survival curves for a fit

## Decision-relevant estimands

The quantities a decision turns on.

- [`survkit_rmst()`](https://max578.github.io/survkit/reference/survkit_rmst.md)
  : Compute the restricted mean survival time
- [`survkit_cuminc()`](https://max578.github.io/survkit/reference/survkit_cuminc.md)
  : Compute cumulative incidence for competing risks

## Triangulation and scoring

Cross-method consistency checks.

- [`survkit_triangulate()`](https://max578.github.io/survkit/reference/survkit_triangulate.md)
  : Triangulate a survival question across methods
- [`survkit_score()`](https://max578.github.io/survkit/reference/survkit_score.md)
  : Score a fit's predictions
- [`survkit_power()`](https://max578.github.io/survkit/reference/survkit_power.md)
  : Assess a fit's small-sample power (events per variable)

## The method registry

The extension point and its contract.

- [`survkit_register()`](https://max578.github.io/survkit/reference/survkit_register.md)
  : Register a survival method
- [`survkit_methods()`](https://max578.github.io/survkit/reference/survkit_methods.md)
  : List the registered methods
- [`survkit_contract()`](https://max578.github.io/survkit/reference/survkit_contract.md)
  : Describe the registry conformance contract
- [`survkit_validate_method()`](https://max578.github.io/survkit/reference/survkit_validate_method.md)
  : Validate a registered method against the contract

## Composition

Emission to the ensemble-manifest contract.

- [`as_survkit_manifest()`](https://max578.github.io/survkit/reference/as_survkit_manifest.md)
  : Emit an ensemble manifest from a fitted model
- [`survkit_manifest()`](https://max578.github.io/survkit/reference/survkit_manifest.md)
  : Represent an ensemble-manifest emission

## Refusals

The typed result returned when a method declines to answer.

- [`survkit_refusal()`](https://max578.github.io/survkit/reference/survkit_refusal.md)
  : A classed refusal from the small-sample power gate
- [`is_survkit_refusal()`](https://max578.github.io/survkit/reference/is_survkit_refusal.md)
  : Is an object a survkit power-gate refusal?
