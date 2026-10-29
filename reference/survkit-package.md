# survkit: A Unified, Extensible Toolkit for Time-to-Event Analysis

One clean interface over the established survival stack (parametric
accelerated-failure-time models, Cox proportional hazards, competing
risks, recurrent events, frailty, flexible splines and a non-parametric
Kaplan-Meier baseline), driven by an extensible method registry so new
estimators slot in without an API change. Fits return a single typed
object with consistent prediction, summary and tidying methods. On top
of the fits sit the value layer: cross-method triangulation that reads
disagreement as a misspecification signal, restricted mean survival time
and cumulative incidence, inverse-probability-of-censoring-weighted
predictive scoring, a small-sample power gate that abstains when events
are too few to identify the model, a registry conformance contract, and
an optional emitter to an ensemble-manifest contract for composition
with a wider analytics stack.

## See also

Useful links:

- <https://github.com/max578/survkit>

- <https://max578.github.io/survkit/>

- Report bugs at <https://github.com/max578/survkit/issues>

## Author

**Maintainer**: Max Moldovan <max.moldovan@gmail.com>
([ORCID](https://orcid.org/0000-0001-9680-8474))

Authors:

- Max Moldovan <max.moldovan@gmail.com>
  ([ORCID](https://orcid.org/0000-0001-9680-8474))
