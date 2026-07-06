# -- The entry point ----------------------------------------------------------

#' Fit a time-to-event model
#'
#' One interface over the established survival stack. `method` selects an
#' estimator from the registry ([survkit_methods()]); the appropriate backend is
#' checked, a small-sample power gate runs ([survkit_power()]), and the fit is
#' returned as a single typed object ([survkit_fit]) with consistent `print`,
#' `summary`, `coef`, `vcov`, `predict` and [tidy()] methods.
#'
#' The left-hand side of `formula` is a `survival::Surv()` response. Extra
#' arguments in `...` pass straight to the backend estimator, so any backend
#' option remains reachable.
#'
#' @param formula A model formula, e.g. `survival::Surv(time, status) ~ x`.
#' @param data A data frame.
#' @param method Character registry key (default `"weibull"`); see
#'   [survkit_methods()].
#' @param ... Passed to the backend estimator.
#' @param check_power Logical; run the events-per-variable gate (default `TRUE`).
#' @param warn_underpowered Logical; warn when the gate flags the model
#'   under-powered (default `TRUE`).
#'
#' @return A [survkit_fit] object.
#'
#' @examples
#' df <- survival::lung
#' fit <- survkit(survival::Surv(time, status) ~ age + sex, df, method = "weibull")
#' fit
#' coef(fit)
#'
#' @family model-fitting
#' @seealso [survkit_methods()] for the registry, [survkit_power()] for the gate.
#' @export
survkit <- function(formula, data, method = "weibull", ...,
                    check_power = TRUE, warn_underpowered = TRUE) {
  spec <- .survkit_lookup(method)
  .survkit_require(spec$backend, method)

  power <- if (isTRUE(check_power)) {
    survkit_power(formula, data)
  } else {
    list(verdict = "unchecked")
  }
  if (isTRUE(check_power) && isTRUE(power$underpowered) && isTRUE(warn_underpowered)) {
    warning("survkit(): ", power$advice, call. = FALSE)
  }

  res <- spec$fit(formula, data, ...)
  survkit_fit(
    method = method, kind = res$kind, backend = res$backend, fit = res$raw,
    coefficients = res$coef %||% numeric(0), vcov = res$vcov,
    loglik = res$loglik %||% NA_real_,
    n = as.integer(res$n %||% NA_integer_),
    n_events = as.integer(res$n_events %||% NA_integer_),
    ratio_type = res$ratio_type %||% NA_character_,
    aux_pars = res$aux_pars %||% character(0),
    power = power, formula = formula, call = match.call())
}
