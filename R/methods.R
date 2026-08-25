# -- Methods on survkit_fit ---------------------------------------------------
# One consistent surface over every backend. Base generics (coef, vcov, logLik,
# AIC, predict) are wired through S7; richer verbs (survkit_tidy, survkit_curve)
# are plain exported functions so no extra generic dependency is pulled in.

#' @export
S7::method(print, survkit_fit) <- function(x, ...) {
  cat(sprintf("<survkit_fit> method = %s (%s, via %s)\n",
              x@method, x@kind, x@backend))
  cat(sprintf("  n = %s   events = %s\n", x@n, x@n_events))
  v <- x@power$verdict %||% "unchecked"
  if (identical(v, "underpowered")) {
    cat(sprintf("  power: UNDERPOWERED (%.1f events/predictor)\n",
                x@power$events_per_variable))
  } else if (identical(v, "ok")) {
    cat(sprintf("  power: ok (%.1f events/predictor)\n",
                x@power$events_per_variable))
  }
  cf <- x@coefficients
  if (length(cf)) {
    cat("  coefficients:\n")
    print(round(cf, 4L))
  }
  invisible(x)
}

#' @export
S7::method(coef, survkit_fit) <- function(object, ...) object@coefficients

#' @export
S7::method(vcov, survkit_fit) <- function(object, ...) object@vcov

#' @export
S7::method(logLik, survkit_fit) <- function(object, ...) {
  ll <- object@loglik
  df <- length(object@coefficients)
  structure(ll, df = df, nobs = object@n, class = "logLik")
}

#' Predict from the raw backend fit
#'
#' Delegate to `stats::predict()` on the backend object underlying a
#' [survkit_fit] (e.g. `predict.coxph()`, `predict.survreg()`), passing `...`
#' straight through. For a backend-independent survival, hazard or quantile
#' prediction on a common time grid, use [survkit_curve()] instead.
#'
#' @name predict.survkit_fit
#' @param object A [survkit_fit].
#' @param ... Passed to the backend's `predict` method.
#' @returns Whatever the backend's `predict` method returns.
#' @examples
#' fit <- survkit(survival::Surv(time, status) ~ age + sex, survival::lung,
#'                method = "cox")
#' head(predict(fit, type = "lp"))
#' @seealso [survkit_curve()] for a backend-independent prediction grid.
S7::method(predict, survkit_fit) <- function(object, ...) {
  stats::predict(object@fit, ...)
}

# Summarise a fitted model: prints the fit header then the coefficient table,
# and returns the table invisibly.
#' @export
S7::method(summary, survkit_fit) <- function(object, ...) {
  print(object)
  tab <- survkit_tidy(object)
  cat("\n")
  print(tab, row.names = FALSE)
  invisible(tab)
}

#' Tidy a fitted model into a coefficient table
#'
#' Return the coefficient table with standard errors, the exponentiated effect
#' and Wald confidence intervals. Covariate rows and baseline distribution
#' parameters are separated by a `component` column, and the `ratio_type` column
#' records whether a covariate effect reads as a hazard ratio (proportional
#' hazards) or a time ratio (accelerated failure time). Auxiliary parameters (a
#' log-scale, a shape) are never exponentiated into the ratio column, so a
#' parametric fit no longer reports a meaningless "ratio" for its scale.
#'
#' @param fit A [survkit_fit].
#' @param conf_level Confidence level for the Wald interval (default `0.95`).
#'
#' @returns A data frame with columns `term`, `component`
#'   (`"covariate"` / `"auxiliary"`), `estimate`, `std_error`, `ratio_type`,
#'   `ratio`, `conf_low` and `conf_high`. For auxiliary parameters `ratio_type`,
#'   `ratio` and the interval are `NA`.
#' @examples
#' fit <- survkit(survival::Surv(time, status) ~ age + sex, survival::lung, method = "cox")
#' survkit_tidy(fit)
#' @family fit-methods
#' @seealso [survkit_curve()] for predicted survival.
#' @export
survkit_tidy <- function(fit, conf_level = 0.95) {
  est <- fit@coefficients
  empty <- data.frame(
    term = character(0), component = character(0), estimate = numeric(0),
    std_error = numeric(0), ratio_type = character(0), ratio = numeric(0),
    conf_low = numeric(0), conf_high = numeric(0), stringsAsFactors = FALSE)
  if (length(est) == 0L) {
    return(empty)
  }

  # Standard errors from the covariance diagonal, when it is conformable.
  vc <- fit@vcov
  se <- if (!is.null(vc) && all(dim(as.matrix(vc)) == length(est))) {
    sqrt(diag(as.matrix(vc)))
  } else {
    rep(NA_real_, length(est))
  }

  # Split baseline distribution parameters from covariate effects, and only
  # exponentiate the covariate effects into a ratio.
  is_aux <- names(est) %in% fit@aux_pars
  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  ratio <- ifelse(is_aux, NA_real_, exp(est))
  conf_low <- ifelse(is_aux, NA_real_, exp(est - z * se))
  conf_high <- ifelse(is_aux, NA_real_, exp(est + z * se))
  data.frame(
    term = names(est),
    component = ifelse(is_aux, "auxiliary", "covariate"),
    estimate = unname(est), std_error = unname(se),
    ratio_type = ifelse(is_aux, NA_character_, fit@ratio_type),
    ratio = unname(ratio),
    conf_low = unname(conf_low), conf_high = unname(conf_high),
    stringsAsFactors = FALSE)
}

#' Predict survival curves for a fit
#'
#' Backend-aware predictions over a time grid for one or more covariate
#' profiles. Parametric, spline and cure fits use the backend's own distribution
#' function and support every `type`; Cox-family and non-parametric fits use
#' `survival::survfit()` and support the survival curve.
#'
#' @param fit A [survkit_fit].
#' @param newdata A data frame of covariate profiles. The default is the
#'   backend's reference profile.
#' @param times Numeric times at which to evaluate. The default is an automatic
#'   grid from the backend.
#' @param type Character quantity to predict: `"survival"` (default),
#'   `"hazard"`, `"cumhaz"` or `"quantile"`. The last three need a parametric,
#'   spline or cure fit.
#'
#' @returns A data frame with `time`, `value` (named for `type` when returned by
#'   the backend) and a `profile` index.
#' @examplesIf requireNamespace("flexsurv", quietly = TRUE)
#' fit <- survkit(survival::Surv(time, status) ~ age, survival::lung, method = "weibull")
#' head(survkit_curve(fit, times = c(100, 300, 500)))
#' @family fit-methods
#' @seealso [survkit_tidy()] for the coefficient table, [survkit_rmst()] for the
#'   restricted mean.
#' @export
survkit_curve <- function(fit, newdata = NULL, times = NULL,
                          type = c("survival", "hazard", "cumhaz", "quantile")) {
  type <- match.arg(type)

  # Non-parametric: the raw object is already a survfit.
  if (identical(fit@kind, "nonparametric")) {
    return(.survkit_curve_survfit(fit@fit, times, type))
  }

  # Parametric / spline / cure: the backend's own distribution function.
  if (fit@kind %in% c("parametric", "spline", "cure") &&
      requireNamespace("flexsurv", quietly = TRUE)) {
    s <- summary(fit@fit, newdata = newdata, t = times, type = type,
                 tidy = TRUE, ci = FALSE)
    names(s)[names(s) == "est"] <- "value"
    s$profile <- if ("strata" %in% names(s)) s$strata else 1L
    keep <- intersect(c("time", "quantile", "value", "profile"), names(s))
    return(s[, keep, drop = FALSE])
  }

  # Cox-family: survfit on the raw fit.
  sf <- .survkit_survfit(fit@fit, newdata)
  .survkit_curve_survfit(sf, times, type)
}

# Turn a survfit object into a tidy per-profile curve. Non-parametric and
# Cox-family fits share this path; only the survival and cumulative-hazard
# quantities are available here (the richer types need a parametric fit).
.survkit_curve_survfit <- function(sf, times, type = "survival") {
  if (!type %in% c("survival", "cumhaz")) {
    stop(sprintf(paste0("type '%s' needs a parametric, spline or cure fit; a ",
                        "survfit-based method offers 'survival' and 'cumhaz'."),
                 type), call. = FALSE)
  }
  ss <- summary(sf, times = times %||% sf$time, extend = TRUE)
  mat <- if (identical(type, "cumhaz")) {
    if (!is.null(ss$cumhaz)) ss$cumhaz else -log(ss$surv)
  } else {
    ss$surv
  }
  if (is.null(dim(mat))) {
    return(data.frame(time = ss$time, value = as.numeric(mat), profile = 1L,
                      stringsAsFactors = FALSE))
  }
  do.call(rbind, lapply(seq_len(ncol(mat)), function(j) {
    data.frame(time = ss$time, value = mat[, j], profile = j,
               stringsAsFactors = FALSE)
  }))
}
