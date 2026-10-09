# -- Predictive scoring -------------------------------------------------------
# What makes a wedge credible is measuring whether the predictions are any good.
# This scores a fit on held-out (or in-sample) data at a set of horizons:
# discrimination by Harrell's concordance, and calibration-and-accuracy by the
# inverse-probability-of-censoring-weighted Brier score (Graf et al. 1999) with
# its index of prediction accuracy (one minus the Brier relative to a
# covariate-free Kaplan-Meier). Right-censored responses only.

#' Score a fit's predictions
#'
#' Evaluate a fitted model's predictions at one or more horizons: the concordance
#' index (discrimination) and the inverse-probability-of-censoring-weighted Brier
#' score with its index of prediction accuracy (calibration and accuracy against
#' a covariate-free Kaplan-Meier reference).
#'
#' @param fit A [survkit_fit] with a right-censored `survival::Surv(time, status)`
#'   response.
#' @param data A data frame carrying the response and covariates to score on
#'   (in-sample if it is the training data, out-of-sample otherwise).
#' @param times Numeric horizons at which to score.
#'
#' @returns A data frame with `time`, `cindex` (Harrell's C using predicted risk
#'   at that horizon), `brier` (IPCW Brier) and `ipa` (index of prediction
#'   accuracy).
#'
#' @details
#' The inverse-probability-of-censoring-weighted Brier score at horizon
#' \eqn{t} is
#' \deqn{BS(t) = \frac{1}{n}\sum_{i=1}^n \Big[
#'   \frac{\big(0 - \hat S(t \mid x_i)\big)^2}{\hat G(T_i)}
#'   \mathbf{1}(T_i \le t, \delta_i = 1) +
#'   \frac{\big(1 - \hat S(t \mid x_i)\big)^2}{\hat G(t)}
#'   \mathbf{1}(T_i > t) \Big]}
#' where \eqn{\hat S(\cdot \mid x_i)} is the predicted survival probability,
#' \eqn{\hat G} is the Kaplan-Meier estimator of the *censoring* survival
#' function, and the index of prediction accuracy is
#' \eqn{IPA(t) = 1 - BS(t) / BS_0(t)} against a covariate-free reference
#' \eqn{BS_0}.
#'
#' @references
#' Graf E, Schmoor C, Sauerbrei W, Schumacher M. Assessment and comparison of
#' prognostic classification schemes for survival data. *Statistics in
#' Medicine* 1999; 18(17-18): 2529-2545.
#' \doi{10.1002/(SICI)1097-0258(19990915/30)18:17/18<2529::AID-SIM274>3.0.CO;2-5}
#'
#' @examples
#' fit <- survkit(survival::Surv(time, status) ~ age + sex, survival::lung,
#'                method = "cox")
#' survkit_score(fit, survival::lung, times = c(200, 400, 600))
#' @family model-fitting
#' @seealso [survkit_curve()] for the predictions scored here.
#' @export
survkit_score <- function(fit, data, times) {
  resp <- stats::model.response(stats::model.frame(fit@formula, data))
  rc <- .survkit_right_censored(resp)

  surv_mat <- .survkit_predict_matrix(fit, data, times)
  brier <- .survkit_brier(surv_mat, rc$time, rc$status, times)

  # Reference Brier: the covariate-free Kaplan-Meier survival for everyone.
  mfit <- survival::survfit(survival::Surv(rc$time, rc$status) ~ 1)
  m_surv <- .survkit_step_surv(mfit)
  null_mat <- matrix(rep(vapply(times, m_surv, numeric(1)), each = length(rc$time)),
                     nrow = length(rc$time))
  brier_null <- .survkit_brier(null_mat, rc$time, rc$status, times)
  ipa <- 1 - brier / brier_null

  # Marker is predicted survival at the horizon: survival::concordance reads a
  # larger marker as a longer survival time, so a higher predicted survival
  # scores concordant with a longer observed time.
  cindex <- vapply(seq_along(times), function(k) {
    df <- data.frame(.time = rc$time, .status = rc$status,
                     marker = surv_mat[, k])
    tryCatch(
      survival::concordance(
        survival::Surv(.time, .status) ~ marker, data = df)$concordance,
      error = function(e) NA_real_)
  }, numeric(1))

  data.frame(time = times, cindex = cindex, brier = brier, ipa = ipa,
             stringsAsFactors = FALSE)
}

# Per-subject predicted survival on the time grid, as an n-by-length(times)
# matrix, using each backend's own prediction machinery.
.survkit_predict_matrix <- function(fit, data, times) {
  if (identical(fit@kind, "nonparametric")) {
    s <- .survkit_curve_survfit(fit@fit, times, "survival")
    return(matrix(s$value, nrow = nrow(data), ncol = length(times),
                  byrow = TRUE))
  }
  if (fit@kind %in% c("parametric", "spline", "cure") &&
      requireNamespace("flexsurv", quietly = TRUE)) {
    sm <- summary(fit@fit, newdata = data, t = times, type = "survival",
                  ci = FALSE)
    return(t(vapply(sm, function(d) d$est, numeric(length(times)))))
  }
  sf <- .survkit_survfit(fit@fit, data)
  ss <- summary(sf, times = times, extend = TRUE)
  surv <- ss$surv
  if (is.null(dim(surv))) {
    surv <- matrix(surv, nrow = length(times))
  }
  t(surv)
}

# IPCW Brier score at each horizon: subjects who die by t contribute their
# squared error weighted by one over the censoring survival at their event time;
# subjects still at risk at t contribute weighted by the censoring survival at t;
# subjects censored before t drop out (weight zero).
.survkit_brier <- function(surv_mat, time, status, times) {
  cfit <- survival::survfit(survival::Surv(time, 1 - status) ~ 1)
  g <- .survkit_step_surv(cfit)
  g_ti <- pmax(vapply(time, g, numeric(1)), 1e-8)
  n <- length(time)

  vapply(seq_along(times), function(k) {
    t <- times[k]
    sk <- surv_mat[, k]
    g_t <- max(g(t), 1e-8)
    died <- time <= t & status == 1
    at_risk <- time > t
    w <- numeric(n)
    contrib <- numeric(n)
    w[died] <- 1 / g_ti[died]
    contrib[died] <- (0 - sk[died])^2
    w[at_risk] <- 1 / g_t
    contrib[at_risk] <- (1 - sk[at_risk])^2
    mean(w * contrib)
  }, numeric(1))
}

# Right-continuous survival step function of a one-sample survfit.
.survkit_step_surv <- function(sfit) {
  stats::stepfun(sfit$time, c(1, sfit$surv))
}

# Pull time and 0/1 status from a two-column right-censored Surv response.
.survkit_right_censored <- function(resp) {
  if (!inherits(resp, "Surv")) {
    stop("scoring needs a `survival::Surv()` response.", call. = FALSE)
  }
  rm <- unclass(resp)
  if (ncol(rm) != 2L) {
    stop(paste0("scoring supports a right-censored `Surv(time, status)` ",
                "response only."), call. = FALSE)
  }
  status <- rm[, 2L]
  if (!is.numeric(status) || any(!status %in% c(0, 1), na.rm = TRUE)) {
    stop("the status must be 0/1 (right-censored).", call. = FALSE)
  }
  list(time = rm[, 1L], status = as.integer(status))
}
