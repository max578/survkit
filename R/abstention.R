# -- Small-sample power gate --------------------------------------------------
# Survival models identify from EVENTS, not rows: a trial with 500 censored
# subjects and 4 deaths carries four data points for the hazard. The
# events-per-variable (EPV) heuristic (Peduzzi et al. 1995; >= 10 events per
# predictor) is the standard guard. survkit() runs it on every fit and records
# the verdict so a caller can choose to simplify, penalise, or abstain rather
# than trust over-fit coefficients -- the honest small-sample posture.

#' Small-sample power gate (events per variable)
#'
#' Assess whether a survival model is identifiable from the available events.
#' Returns the event count, the predictor count, the events-per-variable ratio
#' and a verdict; [survkit()] attaches this to every fit and warns when a model
#' is under-powered.
#'
#' @param formula A model formula with a `survival::Surv()` response.
#' @param data A data frame.
#' @param min_epv Numeric events-per-variable floor (default `10`).
#'
#' @return A list: `n`, `n_events`, `n_predictors`, `events_per_variable`,
#'   `min_epv`, `underpowered` (logical), `verdict` (`"ok"` / `"underpowered"` /
#'   `"unknown"`) and `advice`.
#'
#' @examples
#' df <- data.frame(time = rexp(40), status = rbinom(40, 1, 0.3),
#'                  x1 = rnorm(40), x2 = rnorm(40))
#' survkit_power(survival::Surv(time, status) ~ x1 + x2, df)$verdict
#'
#' @export
survkit_power <- function(formula, data, min_epv = 10) {
  counts <- .survkit_counts(formula, data)
  n_pred <- length(attr(stats::terms(formula), "term.labels"))
  epv <- if (is.na(counts$n_events) || n_pred == 0L) {
    NA_real_
  } else {
    counts$n_events / n_pred
  }
  underpowered <- isTRUE(epv < min_epv)
  list(
    n = counts$n, n_events = counts$n_events, n_predictors = n_pred,
    events_per_variable = epv, min_epv = min_epv, underpowered = underpowered,
    verdict = if (is.na(epv)) "unknown" else if (underpowered) "underpowered" else "ok",
    advice = if (underpowered) {
      sprintf(paste0("only %.1f events per predictor (< %g): coefficients and ",
                     "standard errors are unreliable -- prefer a simpler model, a ",
                     "penalised fit, or abstain."), epv, min_epv)
    } else {
      NA_character_
    })
}
