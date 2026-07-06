# -- Method registry ----------------------------------------------------------
# The extension point. Every estimator is a registry entry; `survkit()` is a thin
# dispatcher over it. Adding a method -- a new family, a new backend, a bespoke
# engine -- is one `survkit_register()` call and needs no change to the public
# API. This is what keeps the toolkit small at the core and open at the edges.

.survkit_registry <- new.env(parent = emptyenv())

#' Register a survival method
#'
#' Add (or override) an estimator in the method registry. The `fit` closure
#' receives `(formula, data, ...)` and must return a list with `raw` (the backend
#' fit), `coef`, `vcov`, `loglik`, `n`, `n_events`, `kind` and `backend` --
#' build it with the package's internal normaliser or by hand.
#'
#' @param name Character key, e.g. `"weibull"`.
#' @param kind Character family: `"parametric"`, `"cox"`, `"competing"`,
#'   `"recurrent"`, `"frailty"`, `"spline"`, `"cure"`, `"interval"`.
#' @param backend Character name of the backend package the `fit` closure needs
#'   (checked via `requireNamespace()` before the fit runs).
#' @param fit A function `(formula, data, ...)` returning the normalised list.
#' @param note Character one-line description (shown by [survkit_methods()]).
#'
#' @return Invisibly, the method name.
#' @examples
#' # register a trivial exponential alias backed by survival::survreg
#' survkit_register("exp_survreg", "parametric", "survival",
#'   fit = function(formula, data, ...) {
#'     raw <- survival::survreg(formula, data = data, dist = "exponential", ...)
#'     list(raw = raw, coef = stats::coef(raw), vcov = stats::vcov(raw),
#'          loglik = as.numeric(stats::logLik(raw)),
#'          n = nrow(data), n_events = NA_integer_,
#'          kind = "parametric", backend = "survival")
#'   })
#' "exp_survreg" %in% survkit_methods()$method
#' @family method-registry
#' @seealso [survkit_methods()] to list what is registered.
#' @export
survkit_register <- function(name, kind, backend, fit, note = "") {
  stopifnot(is.character(name), length(name) == 1L, is.function(fit))
  .survkit_registry[[name]] <- list(
    name = name, kind = kind, backend = backend, fit = fit, note = note)
  invisible(name)
}

#' List the registered methods
#'
#' @return A data frame of `method`, `kind`, `backend`, `available` (is the
#'   backend installed) and `note`.
#' @examples
#' survkit_methods()
#' @family method-registry
#' @seealso [survkit_register()] to add a method.
#' @export
survkit_methods <- function() {
  keys <- ls(.survkit_registry, sorted = TRUE)
  if (length(keys) == 0L) {
    return(data.frame(method = character(0), kind = character(0),
                      backend = character(0), available = logical(0),
                      note = character(0), stringsAsFactors = FALSE))
  }
  do.call(rbind, lapply(keys, function(k) {
    s <- .survkit_registry[[k]]
    data.frame(method = s$name, kind = s$kind, backend = s$backend,
               available = requireNamespace(s$backend, quietly = TRUE),
               note = s$note, stringsAsFactors = FALSE)
  }))
}

# Resolve a method, with a helpful message listing the alternatives.
.survkit_lookup <- function(name) {
  s <- .survkit_registry[[name]]
  if (is.null(s)) {
    stop(sprintf("unknown method '%s'. Registered: %s.",
                 name, paste(ls(.survkit_registry, sorted = TRUE), collapse = ", ")),
         call. = FALSE)
  }
  s
}

# Populate the built-in methods (called from .onLoad).
.survkit_register_builtins <- function() {
  parametric <- list(
    exponential = "exp", weibull = "weibull", lognormal = "lnorm",
    loglogistic = "llogis", gompertz = "gompertz",
    generalized_gamma = "gengamma", gamma = "gamma")
  for (nm in names(parametric)) {
    survkit_register(nm, "parametric", "flexsurv",
      fit = .survkit_make_flexsurv(parametric[[nm]]),
      note = sprintf("parametric AFT, flexsurvreg(dist = '%s')", parametric[[nm]]))
  }
  survkit_register("spline", "spline", "flexsurv",
    fit = .survkit_fit_spline, note = "Royston-Parmar flexible spline")
  survkit_register("km", "nonparametric", "survival",
    fit = .survkit_fit_km,
    note = "Kaplan-Meier / Nelson-Aalen non-parametric baseline")
  survkit_register("cox", "cox", "survival",
    fit = .survkit_fit_cox, note = "Cox proportional hazards")
  survkit_register("cox_ridge", "cox", "survival",
    fit = .survkit_fit_cox_ridge,
    note = "ridge-penalised Cox (shrinkage for the few-events regime)")
  survkit_register("frailty", "frailty", "coxme",
    fit = .survkit_fit_frailty, note = "mixed-effects Cox / shared frailty")
  survkit_register("cause_specific", "competing", "survival",
    fit = .survkit_fit_cause_specific, note = "competing risks, cause-specific hazard")
  survkit_register("fine_gray", "competing", "survival",
    fit = .survkit_fit_fine_gray, note = "competing risks, Fine-Gray subdistribution")
  survkit_register("andersen_gill", "recurrent", "survival",
    fit = .survkit_fit_andersen_gill, note = "recurrent events, Andersen-Gill")
  survkit_register("cure", "cure", "flexsurvcure",
    fit = .survkit_fit_cure, note = "mixture cure model (optional backend)")
  survkit_register("interval_censored", "interval", "icenReg",
    fit = .survkit_fit_interval, note = "interval-censored regression (optional backend)")
  invisible(NULL)
}
