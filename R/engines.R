# -- Backend engines ----------------------------------------------------------
# One small fit closure per backend method. Each takes (formula, data, ...),
# calls the established estimator, and returns a normalised list the registry and
# `survkit()` understand. Backends are checked for availability in survkit()
# (Suggests + requireNamespace), so these closures assume their backend is loaded.
# The raw fit is always retained for backend-specific follow-up.

# Common normaliser: pull coefficients, covariance, log-likelihood and counts in
# one shape via the generics every backend fit supports, with counts read from
# the survival response so they are exact regardless of backend. `ratio_type`
# records how the exponentiated covariate coefficient should be read (a hazard
# ratio for proportional-hazards fits, a time ratio for accelerated-failure-time
# fits) and `aux_pars` names the baseline distribution parameters so the tidier
# can keep them out of the ratio column.
.survkit_normalise <- function(raw, kind, backend, formula, data,
                               ratio_type = "HR", aux_pars = character(0)) {
  cf <- tryCatch(stats::coef(raw), error = function(e) numeric(0))
  vc <- tryCatch(stats::vcov(raw), error = function(e) NULL)
  ll <- tryCatch(as.numeric(stats::logLik(raw)), error = function(e) NA_real_)
  counts <- .survkit_counts(formula, data)
  list(raw = raw, coef = cf, vcov = vc, loglik = ll,
       n = counts$n, n_events = counts$n_events, kind = kind, backend = backend,
       ratio_type = ratio_type, aux_pars = aux_pars)
}

# The baseline distribution-parameter names of a flexsurv fit (e.g. `shape`,
# `scale`). These are the auxiliary parameters, separated from covariate effects
# by the tidier; covariate coefficients that model an ancillary parameter (named
# like `shape(age)`) are not in this set and stay covariates.
.survkit_flexsurv_aux <- function(raw) {
  p <- tryCatch(raw$dlist$pars, error = function(e) NULL)
  if (is.character(p)) p else character(0)
}

# Covariate-effect interpretation per flexsurv family. flexsurv models covariates
# on the location parameter: for the proportional-hazards families (exponential,
# Gompertz) exp(beta) is a hazard ratio; for the accelerated-failure-time
# families (Weibull, log-normal, log-logistic, generalized gamma, gamma) it is a
# time ratio.
.survkit_aft_ratio_type <- function(dist) {
  if (dist %in% c("exp", "gompertz")) "HR" else "TR"
}

# Extract n and event count from the Surv() response on the left of `formula`.
.survkit_counts <- function(formula, data) {
  resp <- tryCatch(stats::model.response(stats::model.frame(formula, data)),
                   error = function(e) NULL)
  n <- nrow(data)
  n_events <- NA_integer_
  if (inherits(resp, "Surv")) {
    rm <- unclass(resp)
    n <- nrow(rm)
    # A multi-state response (competing risks) has several event states; pooling
    # them into one count would misread the power, so leave the count NA and let
    # each competing engine set its own cause-specific count.
    if (is.null(attr(resp, "states"))) {
      status <- rm[, ncol(rm)]                     # last column is the event flag
      if (is.numeric(status)) {                    # 0/1 (or counting-process) status
        n_events <- as.integer(sum(status != 0, na.rm = TRUE))
      }
    }
  }
  list(n = as.integer(n), n_events = n_events)
}

# Parametric accelerated-failure-time families (flexsurv).
.survkit_make_flexsurv <- function(dist) {
  force(dist)
  ratio <- .survkit_aft_ratio_type(dist)
  function(formula, data, ...) {
    raw <- flexsurv::flexsurvreg(formula, data = data, dist = dist, ...)
    .survkit_normalise(raw, "parametric", "flexsurv", formula, data,
                       ratio_type = ratio, aux_pars = .survkit_flexsurv_aux(raw))
  }
}

# Royston-Parmar flexible spline (flexsurv). The covariate interpretation follows
# the spline scale: proportional hazards, proportional odds, or a normal (probit)
# link.
.survkit_fit_spline <- function(formula, data, k = 2L, scale = "hazard", ...) {
  raw <- flexsurv::flexsurvspline(formula, data = data, k = k, scale = scale, ...)
  ratio <- switch(scale, hazard = "HR", odds = "OR", normal = "probit",
                  NA_character_)
  .survkit_normalise(raw, "spline", "flexsurv", formula, data,
                     ratio_type = ratio, aux_pars = .survkit_flexsurv_aux(raw))
}

# Cox proportional hazards (survival). `model = TRUE` retains the model frame so
# survival curves and scoring on new data work after the fit closure returns.
.survkit_fit_cox <- function(formula, data, ...) {
  raw <- survival::coxph(formula, data = data, model = TRUE, ...)
  .survkit_normalise(raw, "cox", "survival", formula, data, ratio_type = "HR")
}

# Ridge-penalised Cox (survival): shrinkage for the few-events regime, where the
# unpenalised partial-likelihood estimates are unreliable. Every predictor enters
# a single `survival::ridge()` term with a shared penalty; larger `theta` shrinks
# harder. Dependency-free -- it is still the survival package.
.survkit_fit_cox_ridge <- function(formula, data, theta = 1, ...) {
  labels <- attr(stats::terms(formula), "term.labels")
  if (length(labels) == 0L) {
    stop("cox_ridge needs at least one predictor to penalise.", call. = FALSE)
  }
  rhs <- sprintf("survival::ridge(%s, theta = %g)",
                 paste(labels, collapse = ", "), theta)
  fit_formula <- stats::reformulate(rhs, response = deparse(formula[[2L]]))
  raw <- survival::coxph(fit_formula, data = data, model = TRUE, ...)
  .survkit_normalise(raw, "cox", "survival", formula, data, ratio_type = "HR")
}

# Kaplan-Meier survival and Nelson-Aalen cumulative hazard (survival): a
# non-parametric baseline the model-based fits are read against. No coefficients;
# the fitted curve lives in the raw survfit object.
.survkit_fit_km <- function(formula, data, ...) {
  raw <- survival::survfit(formula, data = data, ...)
  counts <- .survkit_counts(formula, data)
  list(raw = raw, coef = numeric(0), vcov = NULL, loglik = NA_real_,
       n = counts$n, n_events = counts$n_events, kind = "nonparametric",
       backend = "survival", ratio_type = NA_character_,
       aux_pars = character(0))
}

# Mixed-effects Cox / frailty (coxme); formula carries the random term, e.g.
# `Surv(t, d) ~ x + (1 | block)`.
.survkit_fit_frailty <- function(formula, data, ...) {
  raw <- coxme::coxme(formula, data = data, ...)
  .survkit_normalise(raw, "frailty", "coxme", formula, data, ratio_type = "HR")
}

# Competing risks -- cause-specific hazard (survival): the user encodes the cause
# of interest in the Surv() status; this is a Cox fit for that cause.
.survkit_fit_cause_specific <- function(formula, data, ...) {
  raw <- survival::coxph(formula, data = data, model = TRUE, ...)
  .survkit_normalise(raw, "competing", "survival", formula, data,
                     ratio_type = "HR")
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
  out <- .survkit_normalise(raw, "competing", "survival", formula, data,
                            ratio_type = "HR")
  out$n_events <- as.integer(sum(fg$fgstatus))
  out
}

# Recurrent events -- Andersen-Gill (survival); the response is a counting-process
# `Surv(start, stop, status)`. Note the event count sums status over intervals,
# not subjects.
.survkit_fit_andersen_gill <- function(formula, data, id = NULL, ...) {
  raw <- survival::coxph(formula, data = data, id = id, model = TRUE, ...)
  .survkit_normalise(raw, "recurrent", "survival", formula, data,
                     ratio_type = "HR")
}

# Cure model (flexsurvcure) -- backend optional; registered so the method is
# discoverable, with an informative error until the backend is installed. The
# mixture-cure covariate effects mix a cure-fraction logistic with a latency
# distribution, so no single ratio type is declared.
.survkit_fit_cure <- function(formula, data, dist = "weibull", ...) {
  raw <- flexsurvcure::flexsurvcure(formula, data = data, dist = dist, ...)
  .survkit_normalise(raw, "cure", "flexsurvcure", formula, data,
                     ratio_type = NA_character_,
                     aux_pars = .survkit_flexsurv_aux(raw))
}

# Interval-censored (icenReg) -- backend optional; discoverable, informative
# error until installed. The covariate interpretation follows the model type.
.survkit_fit_interval <- function(formula, data, model = "ph", dist = "weibull", ...) {
  raw <- icenReg::ic_par(formula, data = data, model = model, dist = dist, ...)
  ratio <- switch(model, ph = "HR", po = "OR", aft = "TR", NA_character_)
  aux <- tryCatch(names(raw$baseline), error = function(e) character(0))
  .survkit_normalise(raw, "interval", "icenReg", formula, data,
                     ratio_type = ratio, aux_pars = aux %||% character(0))
}
