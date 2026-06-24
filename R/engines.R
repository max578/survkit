# -- Backend engines ----------------------------------------------------------
# One small fit closure per backend method. Each takes (formula, data, ...),
# calls the established estimator, and returns a normalised list the registry and
# `survkit()` understand. Backends are checked for availability in survkit()
# (Suggests + requireNamespace), so these closures assume their backend is loaded.
# The raw fit is always retained for backend-specific follow-up.

# Common normaliser: pull coefficients, covariance, log-likelihood and counts in
# one shape via the generics every backend fit supports, with counts read from
# the survival response so they are exact regardless of backend.
.survkit_normalise <- function(raw, kind, backend, formula, data) {
  cf <- tryCatch(stats::coef(raw), error = function(e) numeric(0))
  vc <- tryCatch(stats::vcov(raw), error = function(e) NULL)
  ll <- tryCatch(as.numeric(stats::logLik(raw)), error = function(e) NA_real_)
  counts <- .survkit_counts(formula, data)
  list(raw = raw, coef = cf, vcov = vc, loglik = ll,
       n = counts$n, n_events = counts$n_events, kind = kind, backend = backend)
}

# Extract n and event count from the Surv() response on the left of `formula`.
.survkit_counts <- function(formula, data) {
  resp <- tryCatch(stats::model.response(stats::model.frame(formula, data)),
                   error = function(e) NULL)
  n <- nrow(data)
  n_events <- NA_integer_
  if (inherits(resp, "Surv")) {
    rm <- unclass(resp)
    status <- rm[, ncol(rm)]                       # last column is the event flag
    n <- nrow(rm)
    if (is.numeric(status)) {                      # 0/1 (or counting-process) status
      n_events <- as.integer(sum(status != 0, na.rm = TRUE))
    }                                              # multi-state factor status -> leave NA
  }
  list(n = as.integer(n), n_events = n_events)
}

# Parametric accelerated-failure-time families (flexsurv).
.survkit_make_flexsurv <- function(dist) {
  force(dist)
  function(formula, data, ...) {
    raw <- flexsurv::flexsurvreg(formula, data = data, dist = dist, ...)
    .survkit_normalise(raw, "parametric", "flexsurv", formula, data)
  }
}

# Royston-Parmar flexible spline (flexsurv).
.survkit_fit_spline <- function(formula, data, k = 2L, scale = "hazard", ...) {
  raw <- flexsurv::flexsurvspline(formula, data = data, k = k, scale = scale, ...)
  .survkit_normalise(raw, "spline", "flexsurv", formula, data)
}

# Cox proportional hazards (survival).
.survkit_fit_cox <- function(formula, data, ...) {
  raw <- survival::coxph(formula, data = data, ...)
  .survkit_normalise(raw, "cox", "survival", formula, data)
}

# Mixed-effects Cox / frailty (coxme); formula carries the random term, e.g.
# `Surv(t, d) ~ x + (1 | block)`.
.survkit_fit_frailty <- function(formula, data, ...) {
  raw <- coxme::coxme(formula, data = data, ...)
  .survkit_normalise(raw, "frailty", "coxme", formula, data)
}

# Competing risks -- cause-specific hazard (survival): the user encodes the cause
# of interest in the Surv() status; this is a Cox fit for that cause.
.survkit_fit_cause_specific <- function(formula, data, ...) {
  raw <- survival::coxph(formula, data = data, ...)
  .survkit_normalise(raw, "competing", "survival", formula, data)
}

# Competing risks -- Fine-Gray subdistribution hazard. The response is a
# multi-state `Surv(time, event)` with `event` a factor whose first level is
# censoring; `cause` names the competing event of interest. survival::finegray
# builds the weighted risk set, then a weighted Cox fit gives the subdistribution
# hazard ratios.
.survkit_fit_fine_gray <- function(formula, data, cause, ...) {
  if (missing(cause)) {
    stop("fine_gray needs `cause` -- the competing-event level of interest.",
         call. = FALSE)
  }
  fg <- survival::finegray(formula, data = data, etype = cause)
  rhs <- deparse(formula[[3L]], width.cutoff = 500L)
  fit_formula <- stats::reformulate(rhs, response = "survival::Surv(fgstart, fgstop, fgstatus)")
  raw <- survival::coxph(fit_formula, data = fg, weights = fg$fgwt, ...)
  out <- .survkit_normalise(raw, "competing", "survival", formula, data)
  out$n_events <- as.integer(sum(fg$fgstatus))
  out
}

# Recurrent events -- Andersen-Gill (survival); the response is a counting-process
# `Surv(start, stop, status)`.
.survkit_fit_andersen_gill <- function(formula, data, id = NULL, ...) {
  raw <- survival::coxph(formula, data = data, id = id, ...)
  .survkit_normalise(raw, "recurrent", "survival", formula, data)
}

# Cure model (flexsurvcure) -- backend optional; registered so the method is
# discoverable, with an informative error until the backend is installed.
.survkit_fit_cure <- function(formula, data, dist = "weibull", ...) {
  raw <- flexsurvcure::flexsurvcure(formula, data = data, dist = dist, ...)
  .survkit_normalise(raw, "cure", "flexsurvcure", formula, data)
}

# Interval-censored (icenReg) -- backend optional; discoverable, informative
# error until installed.
.survkit_fit_interval <- function(formula, data, model = "ph", dist = "weibull", ...) {
  raw <- icenReg::ic_par(formula, data = data, model = model, dist = dist, ...)
  .survkit_normalise(raw, "interval", "icenReg", formula, data)
}
