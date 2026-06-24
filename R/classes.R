# -- S7 classes ---------------------------------------------------------------
# A single typed result (`survkit_fit`) for every method, so every downstream
# verb -- print, summary, predict, tidy, the manifest emitter -- has one shape to
# work against regardless of which backend produced the fit. A second class
# (`survkit_manifest`) carries the ensemble-manifest emission for orchestra
# composition; it is self-contained so the package stays standalone.

#' The fitted-model class
#'
#' An S7 object returned by [survkit()]. It normalises every backend's output to
#' one shape: the method and kind, the raw backend fit (kept for backend-specific
#' follow-up), the coefficient vector and covariance, the log-likelihood, the
#' sample and event counts, and the small-sample power verdict.
#'
#' @param method Character method name (a registry key, e.g. `"weibull"`).
#' @param kind Character method family (`"parametric"`, `"cox"`,
#'   `"competing"`, `"recurrent"`, `"frailty"`, `"spline"`).
#' @param backend Character name of the package that produced the fit.
#' @param fit The raw backend fit object.
#' @param coefficients Named numeric coefficient vector.
#' @param vcov Coefficient covariance matrix (or `NULL`).
#' @param loglik Numeric log-likelihood (or `NA`).
#' @param n Integer number of observations.
#' @param n_events Integer number of events (non-censored).
#' @param power A `list` power verdict from [survkit_power()].
#' @param formula The model formula.
#' @param call The originating call.
#'
#' @return A `survkit_fit` S7 object.
#' @export
survkit_fit <- S7::new_class(
  "survkit_fit",
  properties = list(
    method = S7::class_character,
    kind = S7::class_character,
    backend = S7::class_character,
    fit = S7::class_any,
    coefficients = S7::class_numeric,
    vcov = S7::new_property(S7::class_any, default = NULL),
    loglik = S7::new_property(S7::class_numeric, default = NA_real_),
    n = S7::class_integer,
    n_events = S7::class_integer,
    power = S7::new_property(S7::class_list, default = list()),
    formula = S7::new_property(S7::class_any, default = NULL),
    call = S7::new_property(S7::class_any, default = NULL)
  )
)

#' The ensemble-manifest class
#'
#' A self-contained, manifest-compatible emission for orchestra composition: a
#' draw ensemble of parameters and predicted survival, with provenance. Produced
#' by [as_survkit_manifest()]; convertible to a `pesto_ensemble_manifest` when
#' that contract is available (see the manifest emitter).
#'
#' @param params Data frame of parameter draws (`n_draw` rows).
#' @param outputs Data frame of predicted survival draws on a time grid.
#' @param time_grid Numeric vector of evaluation times.
#' @param method Character method name.
#' @param emitter_version Character package version that emitted the manifest.
#' @param seed Integer RNG seed.
#'
#' @return A `survkit_manifest` S7 object.
#' @export
survkit_manifest <- S7::new_class(
  "survkit_manifest",
  properties = list(
    params = S7::new_property(S7::class_data.frame, default = quote(data.frame())),
    outputs = S7::new_property(S7::class_any, default = NULL),
    time_grid = S7::new_property(S7::class_numeric, default = numeric(0)),
    method = S7::class_character,
    emitter_version = S7::class_character,
    seed = S7::new_property(S7::class_integer, default = NA_integer_)
  )
)
