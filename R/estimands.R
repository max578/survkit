# -- Decision-relevant estimands ----------------------------------------------
# Two summaries that live above any single fit: the non-parametric cumulative
# incidence of competing events (the Aalen-Johansen estimator, via a multi-state
# survfit), and the restricted mean survival time (the area under the survival
# curve to a horizon). Both are the quantities a decision actually turns on, and
# both read straight off the established survival machinery.

#' Cumulative incidence for competing risks
#'
#' The Aalen-Johansen estimator of the cumulative incidence function for each
#' competing event, computed from a multi-state `survival::survfit()`. Unlike one
#' minus a cause-specific Kaplan-Meier, this accounts for the competing events
#' and so sums, across causes, to the overall failure probability.
#'
#' @param formula A model formula whose response is a multi-state
#'   `survival::Surv(time, event)` with `event` a factor whose first level is
#'   censoring. The right-hand side is `1` or grouping variables.
#' @param data A data frame.
#' @param ... Passed to `survival::survfit()`.
#'
#' @returns A data frame with `time`, `group` (the stratum, or `"all"`),
#'   `cause`, `cif` (the cumulative incidence) and `cif_se` (its standard error).
#' @examples
#' mg <- survival::mgus2
#' mg$etime <- with(mg, ifelse(pstat == 1, ptime, futime))
#' mg$event <- with(mg, factor(ifelse(pstat == 1, "pcm",
#'                             ifelse(death == 1, "death", "censor")),
#'                             levels = c("censor", "pcm", "death")))
#' ci <- survkit_cuminc(survival::Surv(etime, event) ~ 1, mg)
#' head(ci)
#' @family model-fitting
#' @seealso [survkit()] with `method = "fine_gray"` for a regression on the
#'   subdistribution hazard.
#' @export
survkit_cuminc <- function(formula, data, ...) {
  raw <- survival::survfit(formula, data = data, ...)
  if (is.null(raw$states)) {
    stop(paste0("survkit_cuminc() needs a multi-state `Surv(time, event)` ",
                "response with `event` a factor (first level censoring)."),
         call. = FALSE)
  }

  # Every state except the event-free "(s0)" is a competing event; its column of
  # the state-occupancy matrix is that event's cumulative incidence.
  event_states <- setdiff(raw$states, "(s0)")
  cols <- match(event_states, colnames(raw$pstate))
  se <- raw$std.err
  grp <- if (is.null(raw$strata)) {
    rep("all", length(raw$time))
  } else {
    rep(names(raw$strata), raw$strata)
  }

  out <- do.call(rbind, lapply(seq_along(event_states), function(k) {
    j <- cols[k]
    data.frame(
      time = raw$time, group = grp, cause = event_states[k],
      cif = raw$pstate[, j],
      cif_se = if (is.null(se)) NA_real_ else se[, j],
      stringsAsFactors = FALSE)
  }))
  rownames(out) <- NULL
  out
}

#' Restricted mean survival time
#'
#' The restricted mean survival time (RMST) to a horizon `tau`: the area under
#' the survival curve on `[0, tau]`, a decision-relevant summary that stays
#' defined when the median is not reached. Parametric, spline and cure fits use
#' the backend's own RMST with its delta-method interval; Cox-family and
#' non-parametric fits use the area under `survival::survfit()` with its standard
#' error.
#'
#' @param fit A [survkit_fit].
#' @param tau Numeric horizon (a single positive time) the mean is restricted to.
#' @param newdata A data frame of covariate profiles for the model-based fits.
#'   The default is the backend's reference profile.
#'
#' @returns A data frame with `tau`, `group` (or `profile`), `rmst`, `se`,
#'   `conf_low` and `conf_high`.
#' @examples
#' fit <- survkit(survival::Surv(time, status) ~ 1, survival::lung, method = "km")
#' survkit_rmst(fit, tau = 365)
#' @family model-fitting
#' @seealso [survkit_curve()] for the curve the mean integrates.
#' @export
survkit_rmst <- function(fit, tau, newdata = NULL) {
  .survkit_check_tau(tau)

  # Parametric / spline / cure: the backend's own restricted mean and interval.
  if (fit@kind %in% c("parametric", "spline", "cure") &&
      requireNamespace("flexsurv", quietly = TRUE)) {
    s <- summary(fit@fit, type = "rmst", t = tau, newdata = newdata,
                 ci = TRUE, tidy = TRUE)
    return(data.frame(
      tau = tau, profile = seq_len(nrow(s)), rmst = s$est,
      se = NA_real_, conf_low = s$lcl, conf_high = s$ucl,
      stringsAsFactors = FALSE))
  }

  # Cox-family / non-parametric: area under the survfit curve to tau.
  sf <- if (identical(fit@kind, "nonparametric")) {
    fit@fit
  } else {
    .survkit_survfit(fit@fit, newdata)
  }
  .survkit_rmst_from_survfit(sf, tau)
}

# Restricted mean and its standard error from a survfit, read off the survival
# package's own `rmean` table so the number matches the reference implementation.
.survkit_rmst_from_survfit <- function(sf, tau) {
  tab <- summary(sf, rmean = tau)$table
  if (is.null(dim(tab))) {
    tab <- matrix(tab, nrow = 1L, dimnames = list("all", names(tab)))
  }
  cn <- colnames(tab)
  i_rm <- which(grepl("rmean", cn) & !grepl("se", cn))
  i_se <- which(grepl("rmean", cn) & grepl("se", cn))
  rmean <- as.numeric(tab[, i_rm])
  se <- if (length(i_se) > 0L) as.numeric(tab[, i_se]) else rep(NA_real_, length(rmean))
  z <- stats::qnorm(0.975)
  data.frame(
    tau = tau, group = rownames(tab), rmst = rmean, se = se,
    conf_low = rmean - z * se, conf_high = rmean + z * se,
    stringsAsFactors = FALSE)
}

# A horizon must be a single positive time.
.survkit_check_tau <- function(tau) {
  if (!is.numeric(tau) || length(tau) != 1L || is.na(tau) || tau <= 0) {
    stop("`tau` must be a single positive time.", call. = FALSE)
  }
  invisible(TRUE)
}
