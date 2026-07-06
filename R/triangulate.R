# -- Cross-method triangulation -----------------------------------------------
# The signature move. Fit the same data under several methods, compare them on a
# decision-relevant quantity (the restricted mean, and optionally survival at a
# landmark), and read their spread as a misspecification signal: when honest
# models of the same data disagree on what a decision turns on, at least one of
# them is wrong about the shape of the hazard. The cross-paradigm pairing
# (frequentist survkit against a Bayesian fit) is owned one layer up; here the
# comparison is within the frequentist stack.

#' Triangulate a survival question across methods
#'
#' Fit the same data under several methods and compare them on the restricted
#' mean survival time (and, if a landmark time is given, on survival at that
#' time). The relative spread across methods is a model-misspecification signal:
#' when the methods disagree by more than `threshold`, the fit is flagged.
#'
#' @param formula A model formula with a `survival::Surv()` response.
#' @param data A data frame.
#' @param methods Character vector of registry keys to compare (default
#'   `c("weibull", "cox", "km")`). Methods whose backend is missing, or that fail
#'   to fit, are dropped with a warning.
#' @param tau Numeric horizon for the restricted mean. The default is the 90th
#'   percentile of the observed times.
#' @param time_star Optional landmark time; when given, survival at `time_star`
#'   is compared as well.
#' @param newdata Optional single covariate profile for the model-based
#'   quantities.
#' @param threshold Numeric relative-spread threshold above which the methods are
#'   flagged as disagreeing (default `0.1`, i.e. 10 percent).
#' @param ... Passed to each [survkit()] fit.
#'
#' @returns A `survkit_triangulation` list with the per-method quantities, the
#'   disagreement summary, and a logical `flagged`. It has a `print` method.
#' @examples
#' tri <- survkit_triangulate(survival::Surv(time, status) ~ age + sex,
#'                            survival::lung, methods = c("weibull", "cox", "km"),
#'                            tau = 500)
#' tri
#' @family model-fitting
#' @seealso [survkit_rmst()] for the quantity compared, [survkit()] for a single
#'   fit.
#' @export
survkit_triangulate <- function(formula, data, methods = c("weibull", "cox", "km"),
                                tau = NULL, time_star = NULL, newdata = NULL,
                                threshold = 0.1, ...) {
  if (is.null(tau)) {
    tau <- stats::quantile(.survkit_response_times(formula, data), 0.9,
                           names = FALSE, na.rm = TRUE)
  }

  # Fit each method, dropping any whose backend is missing or that errors. A
  # non-parametric method is fit marginally: it estimates the overall survival,
  # not one stratum per covariate value.
  fits <- lapply(methods, function(m) {
    spec <- tryCatch(.survkit_lookup(m), error = function(e) NULL)
    if (is.null(spec)) return(NULL)
    f <- if (identical(spec$kind, "nonparametric")) {
      stats::reformulate("1", response = deparse(formula[[2L]]))
    } else {
      formula
    }
    tryCatch(
      survkit(f, data, method = m, check_power = FALSE, ...),
      error = function(e) NULL)
  })
  names(fits) <- methods
  dropped <- methods[vapply(fits, is.null, logical(1))]
  if (length(dropped) > 0L) {
    warning("triangulation dropped: ", paste(dropped, collapse = ", "),
            call. = FALSE)
  }
  fits <- fits[!vapply(fits, is.null, logical(1))]
  if (length(fits) < 2L) {
    stop("triangulation needs at least two methods that fit.", call. = FALSE)
  }

  # Restricted mean per method, then survival at the landmark if requested.
  rmst <- do.call(rbind, lapply(names(fits), function(m) {
    r <- tryCatch(survkit_rmst(fits[[m]], tau = tau, newdata = newdata),
                  error = function(e) NULL)
    if (is.null(r)) return(NULL)
    data.frame(method = m, tau = tau, rmst = r$rmst[1L], stringsAsFactors = FALSE)
  }))
  surv <- NULL
  if (!is.null(time_star)) {
    surv <- do.call(rbind, lapply(names(fits), function(m) {
      s <- tryCatch(
        survkit_curve(fits[[m]], newdata = newdata, times = time_star),
        error = function(e) NULL)
      if (is.null(s)) return(NULL)
      data.frame(method = m, time = time_star, survival = s$value[1L],
                 stringsAsFactors = FALSE)
    }))
  }

  dis <- .survkit_disagreement(rmst$rmst, "rmst", threshold)
  if (!is.null(surv)) {
    dis <- rbind(dis, .survkit_disagreement(surv$survival, "survival", threshold))
  }

  structure(
    list(methods = names(fits), tau = tau, time_star = time_star,
         rmst = rmst, survival = surv, disagreement = dis,
         flagged = any(dis$flagged), threshold = threshold),
    class = "survkit_triangulation")
}

# Relative spread of a set of estimates: the range divided by the mean. A
# scale-free disagreement measure, flagged when it exceeds the threshold.
.survkit_disagreement <- function(values, quantity, threshold) {
  values <- values[is.finite(values)]
  spread <- if (length(values) > 1L) diff(range(values)) else 0
  relative <- if (length(values) > 0L && mean(values) != 0) {
    spread / abs(mean(values))
  } else {
    NA_real_
  }
  data.frame(
    quantity = quantity, spread = spread, relative = relative,
    flagged = isTRUE(relative > threshold), stringsAsFactors = FALSE)
}

# The time column of the Surv() response, for the default RMST horizon.
.survkit_response_times <- function(formula, data) {
  resp <- stats::model.response(stats::model.frame(formula, data))
  if (!inherits(resp, "Surv")) {
    stop("the formula response must be a `survival::Surv()` object.",
         call. = FALSE)
  }
  rm <- unclass(resp)
  rm[, if (ncol(rm) >= 3L) 2L else 1L]
}

#' @export
print.survkit_triangulation <- function(x, ...) {
  cat(sprintf("<survkit_triangulation> methods: %s\n",
              paste(x$methods, collapse = ", ")))
  cat(sprintf("  restricted mean at tau = %.4g\n", x$tau))
  print(x$rmst, row.names = FALSE)
  if (!is.null(x$survival)) {
    cat(sprintf("\n  survival at t = %.4g\n", x$time_star))
    print(x$survival, row.names = FALSE)
  }
  cat("\n  disagreement (relative spread):\n")
  print(x$disagreement, row.names = FALSE)
  verdict <- if (isTRUE(x$flagged)) {
    "DISAGREEMENT -- methods differ beyond threshold; suspect misspecification"
  } else {
    "agreement -- methods concur within threshold"
  }
  cat(sprintf("\n  verdict: %s\n", verdict))
  invisible(x)
}
