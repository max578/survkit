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
#' and a verdict. [survkit()] attaches this to every fit and warns when a model
#' is under-powered.
#'
#' @details
#' The event count comes from the last column of the `survival::Surv()` response.
#' When that column is a multi-state factor (competing risks) the event count
#' cannot be read as a single 0/1 flag, so the verdict is `"unknown"` rather than
#' a guess. For a counting-process response (recurrent events) the count is the
#' number of event rows, not the number of distinct subjects.
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
#' @family model-fitting
#' @seealso [survkit()], which runs this gate on every fit.
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

# -- Typed refusal --------------------------------------------------------
# When a caller asks survkit() to abstain rather than warn on an
# under-powered fit, the EPV gate's verdict is handed back as a classed
# refusal instead of a fitted model. The class vector ends in "_refusal" so
# a leader-side gate can recognise it via the shared naming convention
# (`is_orchestra_decline()`, ORCHESTRA_dev/integration/refusal_contract.R)
# without depending on survkit's namespace.

#' A classed refusal from the small-sample power gate
#'
#' Construct the typed "will not fit" token [survkit()] returns when
#' `on_underpowered = "abstain"` and the events-per-variable gate
#' ([survkit_power()]) flags the model as under-powered. Not signalled as a
#' condition -- returned as an ordinary value, so a caller inspects it with
#' [is_survkit_refusal()] rather than a `tryCatch()`.
#'
#' @param power A power-gate result from [survkit_power()], already flagged
#'   `underpowered`.
#'
#' @return A classed list with class `c("survkit_refusal", "orchestra_refusal",
#'   "error", "condition")` and elements `reason`, `n`, `n_events`,
#'   `n_predictors`, `events_per_variable`, `min_epv`, `underpowered`
#'   (always `TRUE`), `message`.
#'
#' @examples
#' df <- data.frame(time = rexp(20), status = rbinom(20, 1, 0.2),
#'                  x1 = rnorm(20), x2 = rnorm(20))
#' p <- survkit_power(survival::Surv(time, status) ~ x1 + x2, df)
#' r <- survkit_refusal(p)
#' is_survkit_refusal(r)
#'
#' @family model-fitting
#' @seealso [survkit()], [survkit_power()], [is_survkit_refusal()].
#' @export
survkit_refusal <- function(power) {
  structure(
    list(
      reason = "underpowered",
      n = power$n, n_events = power$n_events,
      n_predictors = power$n_predictors,
      events_per_variable = power$events_per_variable,
      min_epv = power$min_epv, underpowered = TRUE,
      message = power$advice),
    class = c("survkit_refusal", "orchestra_refusal", "error", "condition"))
}

#' Is an object a survkit power-gate refusal?
#'
#' @param x Any object.
#' @return A single logical.
#'
#' @examples
#' is_survkit_refusal(42)
#'
#' @family model-fitting
#' @seealso [survkit_refusal()].
#' @export
is_survkit_refusal <- function(x) {
  inherits(x, "survkit_refusal")
}

#' @export
print.survkit_refusal <- function(x, ...) {
  cat("<survkit_refusal>\n")
  cat("  reason:", x$reason, "\n")
  cat(sprintf("  events per predictor: %.1f (< %g)\n",
              x$events_per_variable, x$min_epv))
  cat(" ", x$message, "\n")
  invisible(x)
}
