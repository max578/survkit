# survkit

> A unified, extensible toolkit for time-to-event analysis.

`survkit` puts one clean interface over the established R survival stack —
parametric accelerated-failure-time models, Cox proportional hazards, competing
risks, recurrent events, frailty, and flexible splines — driven by an extensible
**method registry** so new estimators slot in without an API change. Every fit
returns a single typed object with consistent prediction, summary and tidying
methods, an **events-per-variable power gate** that flags models too small to
identify, and an optional **ensemble-manifest emitter** for composition with a
wider analytics stack.

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
survkit(survival::Surv(time, status) ~ age + sex, survival::lung, method = "cox")

# competing risks (Fine-Gray subdistribution hazard)
# event is a factor: first level = censoring
survkit(survival::Surv(etime, event) ~ age + sex, data, method = "fine_gray",
        cause = "pcm")
```

## The small-sample gate

Survival models identify from *events*, not rows. `survkit()` runs an
events-per-variable check on every fit and warns when a model is under-powered,
so you can simplify, penalise, or abstain rather than trust over-fit estimates:

```r
survkit_power(survival::Surv(time, status) ~ age + sex + ph.ecog, small_data)
#> $verdict        "underpowered"
#> $events_per_variable  7.3
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

## Licence

MIT © Max Moldovan.
