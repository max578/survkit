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

#' @export
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
#' Estimates with standard errors, hazard / time ratios (the exponentiated
#' coefficient) and Wald confidence intervals.
#'
#' @param fit A [survkit_fit].
#' @param conf_level Confidence level (default `0.95`).
#' @return A data frame: `term`, `estimate`, `std_error`, `ratio`,
#'   `conf_low`, `conf_high`.
#' @examples
#' fit <- survkit(survival::Surv(time, status) ~ age + sex, survival::lung, method = "cox")
#' survkit_tidy(fit)
#' @export
survkit_tidy <- function(fit, conf_level = 0.95) {
  est <- fit@coefficients
  if (length(est) == 0L) {
    return(data.frame(term = character(0), estimate = numeric(0)))
  }
  vc <- fit@vcov
  se <- if (!is.null(vc) && all(dim(as.matrix(vc)) == length(est))) {
    sqrt(diag(as.matrix(vc)))
  } else {
    rep(NA_real_, length(est))
  }
  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  data.frame(
    term = names(est), estimate = unname(est), std_error = unname(se),
    ratio = unname(exp(est)),
    conf_low = unname(exp(est - z * se)), conf_high = unname(exp(est + z * se)),
    stringsAsFactors = FALSE)
}

#' Predicted survival curves
#'
#' Backend-aware survival probabilities over a time grid for one or more
#' covariate profiles. Parametric and spline fits use the backend's own
#' survival function; Cox-family fits use `survival::survfit()`.
#'
#' @param fit A [survkit_fit].
#' @param newdata A data frame of covariate profiles (default: the backend's
#'   reference profile).
#' @param times Numeric times at which to evaluate (default: an automatic grid).
#' @return A data frame with `time`, `survival` and a `profile` index.
#' @examples
#' fit <- survkit(survival::Surv(time, status) ~ age, survival::lung, method = "weibull")
#' head(survkit_curve(fit, times = c(100, 300, 500)))
#' @export
survkit_curve <- function(fit, newdata = NULL, times = NULL) {
  if (fit@kind %in% c("parametric", "spline", "cure") &&
      requireNamespace("flexsurv", quietly = TRUE)) {
    s <- summary(fit@fit, newdata = newdata, t = times, type = "survival",
                 tidy = TRUE, ci = FALSE)
    names(s)[names(s) == "est"] <- "survival"
    s$profile <- if ("strata" %in% names(s)) s$strata else 1L
    return(s[, intersect(c("time", "survival", "profile"), names(s)), drop = FALSE])
  }
  # Cox-family: survfit on the raw fit
  sf <- survival::survfit(fit@fit, newdata = newdata)
  ss <- summary(sf, times = times %||% sf$time)
  if (is.null(dim(ss$surv))) {
    return(data.frame(time = ss$time, survival = as.numeric(ss$surv), profile = 1L))
  }
  out <- do.call(rbind, lapply(seq_len(ncol(ss$surv)), function(j) {
    data.frame(time = ss$time, survival = ss$surv[, j], profile = j)
  }))
  out
}
