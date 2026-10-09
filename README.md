# survkit

> A unified, extensible toolkit for time-to-event analysis: one interface over
> the established R survival stack, with cross-method triangulation as the
> consistency check on top.

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/max578/survkit/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/max578/survkit/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/max578/survkit/graph/badge.svg)](https://app.codecov.io/gh/max578/survkit)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

`survkit` puts one clean interface over the established R survival stack —
parametric accelerated-failure-time models, Cox proportional hazards, competing
risks, recurrent events, frailty, flexible splines, and a non-parametric
Kaplan-Meier baseline — driven by an extensible **method registry** so new
estimators slot in without an API change. Every fit returns a single typed
object with consistent prediction, summary and tidying methods.

On top of the fits sits the value layer that makes survkit a methodology rather
than a wrapper:

* **Cross-method triangulation** (`survkit_triangulate()`) that reads
  disagreement between methods as a model-misspecification signal.
* **Decision-relevant estimands** — restricted mean survival time
  (`survkit_rmst()`) and cumulative incidence (`survkit_cuminc()`).
* **Predictive scoring** (`survkit_score()`) — concordance and the
  censoring-weighted Brier score with its index of prediction accuracy.
* An **events-per-variable power gate** that flags models too small to identify.
* A **registry conformance contract** (`survkit_validate_method()`).
* An optional **ensemble-manifest emitter** for composition with a wider
  analytics stack.

It stands alone — siblings are optional (`Suggests`, behind `requireNamespace()`
guards) and `R CMD check` is clean with none installed.

## Install

```r
# from a local clone
devtools::install("survkit")
```

`survival` is the only modelling dependency; `flexsurv`, `cmprsk`, `coxme`,
`flexsurvcure` and `icenReg` are optional backends, pulled only when a method
needs them.

## Quick start

```r
library(survkit)

# what can it fit?
survkit_methods()

# a Weibull accelerated-failure-time model
fit <- survkit(survival::Surv(time, status) ~ age + sex, survival::lung,
               method = "weibull")
fit
survkit_tidy(fit)                      # estimates, ratios, CIs
survkit_curve(fit, times = c(100, 300, 500))

# Cox proportional hazards on the same data
cox <- survkit(survival::Surv(time, status) ~ age + sex, survival::lung,
               method = "cox")

# competing risks (Fine-Gray subdistribution hazard)
# event is a factor: first level = censoring
mg <- survival::mgus2
mg$etime <- with(mg, ifelse(pstat == 1, ptime, futime))
mg$event <- with(mg, factor(ifelse(pstat == 1, "pcm",
                            ifelse(death == 1, "death", "censor")),
                            levels = c("censor", "pcm", "death")))
survkit(survival::Surv(etime, event) ~ age + sex, mg, method = "fine_gray",
        cause = "pcm")
```

## The small-sample gate

Survival models identify from *events*, not rows. `survkit()` runs an
events-per-variable check on every fit and warns when a model is under-powered,
so you can simplify, penalise, or abstain rather than trust over-fit estimates:

```r
small_data <- survival::lung[1:25, ]
survkit_power(survival::Surv(time, status) ~ age + sex + ph.ecog, small_data)
#> $verdict        "underpowered"
#> $events_per_variable  7.3
```

## Triangulate across methods

Fit the same question under several methods and let their disagreement flag a
model worth a closer look:

```r
survkit_triangulate(survival::Surv(time, status) ~ age + sex, survival::lung,
                    methods = c("weibull", "cox", "km"), tau = 500)
#> <survkit_triangulation> methods: weibull, cox, km
#>   restricted mean at tau = 500
#>    method tau     rmst
#>   weibull 500 311.6
#>       cox 500 312.7
#>        km 500 310.3
#>   verdict: agreement -- methods concur within threshold
```

## Decision-relevant summaries

```r
fit <- survkit(survival::Surv(time, status) ~ age, survival::lung, method = "km")
survkit_rmst(fit, tau = 365)                 # restricted mean survival time
survkit_score(cox, survival::lung, times = c(200, 400, 600))  # C-index, Brier, IPA
```

## Extending it

A new estimator is one registry call — no change to `survkit()`:

```r
survkit_register("my_method", kind = "parametric", backend = "somepkg",
                 fit = function(formula, data, ...) {
                   raw <- somepkg::fit(formula, data, ...)
                   list(raw = raw, coef = coef(raw), vcov = vcov(raw),
                        loglik = as.numeric(logLik(raw)),
                        n = nrow(data), n_events = NA_integer_,
                        kind = "parametric", backend = "somepkg")
                 })
```

## Contributing

Bug reports and suggestions are welcome through the
[issue tracker](https://github.com/max578/survkit/issues).

## Citation

```r
citation("survkit")
```

## Licence

MIT © Max Moldovan.
