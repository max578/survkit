# -- S7 classes ---------------------------------------------------------------
# A single typed result (`survkit_fit`) for every method, so every downstream
# verb -- print, summary, predict, tidy, the manifest emitter -- has one shape to
# work against regardless of which backend produced the fit. A second class
# (`survkit_manifest`) carries the ensemble-manifest emission for orchestra
# composition; it is self-contained so the package stays standalone.

#' Represent a fitted survival model
#'
#' An S7 object returned by [survkit()]. It normalises every backend's output to
#' one shape: the method and kind, the raw backend fit (kept for backend-specific
#' follow-up), the coefficient vector and covariance, the log-likelihood, the
#' sample and event counts, and the small-sample power verdict.
#'
#' @param method Character method name (a registry key, e.g. `"weibull"`).
#' @param kind Character method family: one of `"parametric"`, `"spline"`,
#'   `"nonparametric"`, `"cox"`, `"frailty"`, `"competing"`, `"recurrent"`,
#'   `"cure"` or `"interval"`.
#' @param backend Character name of the package that produced the fit.
#' @param fit The raw backend fit object.
#' @param coefficients Named numeric coefficient vector.
#' @param vcov Coefficient covariance matrix (or `NULL`).
#' @param loglik Numeric log-likelihood (or `NA`).
#' @param n Integer number of observations.
#' @param n_events Integer number of events (non-censored).
#' @param ratio_type Character code for how an exponentiated covariate
#'   coefficient reads: `"HR"` (hazard ratio), `"TR"` (time ratio), `"OR"`
#'   (odds ratio), `"probit"`, or `NA` when the fit has no such coefficients.
#' @param aux_pars Character names of the baseline distribution parameters (the
#'   auxiliary parameters the tidier keeps out of the ratio column).
#' @param power A `list` power verdict from [survkit_power()].
#' @param formula The model formula.
#' @param call The originating call.
#'
#' @return A `survkit_fit` S7 object.
#' @seealso [survkit()] (constructs this object), [survkit_tidy()],
#'   [survkit_curve()] (consume it).
#' @examples
#' fit <- survkit(survival::Surv(time, status) ~ age + sex, survival::lung,
#'                method = "cox")
#' fit@method
#' fit@n_events
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
    ratio_type = S7::new_property(S7::class_character, default = NA_character_),
    aux_pars = S7::new_property(S7::class_character, default = character(0)),
    power = S7::new_property(S7::class_list, default = list()),
    formula = S7::new_property(S7::class_any, default = NULL),
    call = S7::new_property(S7::class_any, default = NULL)
  )
)

#' Represent an ensemble-manifest emission
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
#' @seealso [as_survkit_manifest()], which constructs this object.
#' @examplesIf requireNamespace("flexsurv", quietly = TRUE)
#' fit <- survkit(survival::Surv(time, status) ~ age, survival::lung,
#'                method = "weibull")
#' man <- as_survkit_manifest(fit, n_draws = 50L)
#' man@method
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
