# -- Ensemble-manifest emission -----------------------------------------------
# Orchestra composition without coupling. A fitted model is turned into a draw
# ensemble (a Gaussian approximation of the sampling distribution of the
# coefficients), shaped like the `pesto_ensemble_manifest` contract (C2) so the
# composition layer can wrap it without survkit importing any sibling. The
# emission is self-contained: it produces a `survkit_manifest` that carries the
# manifest fields, and stays available with no orchestra package installed.

#' Emit an ensemble manifest from a fitted model
#'
#' Produce a draw ensemble for orchestra composition. Coefficients are drawn from
#' their Gaussian sampling approximation (mean = estimate, covariance = `vcov`),
#' and the result is shaped to the ensemble-manifest contract (a parameter draw
#' frame with provenance) so a `pesto_ensemble_manifest`-compatible adapter can
#' consume it.
#'
#' When `times` and a single-profile `newdata` are given and the fit is
#' parametric, spline or cure, the `outputs` slot carries a genuine per-draw
#' survival ensemble: the draws come from the backend's own sampling
#' distribution and each draw's survival is evaluated through the fitted
#' distribution function, so `params` and `outputs` share the same draws. For a
#' Cox-family or non-parametric fit a per-draw survival ensemble would also need
#' the baseline-hazard uncertainty, so `outputs` instead holds the
#' maximum-likelihood survival curve marked with `draw = 0`.
#'
#' @param fit A [survkit_fit].
#' @param n_draws Integer number of draws (default `200L`).
#' @param times Optional numeric time grid for the survival outputs. `NULL`
#'   (default) emits a parameters-only manifest.
#' @param newdata Optional single covariate profile (one row) for the survival
#'   outputs. Required for the per-draw survival ensemble.
#' @param seed Optional integer RNG seed (recorded in the manifest).
#'
#' @returns A [survkit_manifest] object.
#'
#' @examples
#' fit <- survkit(survival::Surv(time, status) ~ age, survival::lung, method = "weibull")
#' m <- as_survkit_manifest(fit, n_draws = 50L, seed = 1L)
#' nrow(m@params)
#'
#' @seealso [survkit_manifest] for the returned class, [survkit()] for the fit.
#' @export
as_survkit_manifest <- function(fit, n_draws = 200L, times = NULL,
                                 newdata = NULL, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  est <- fit@coefficients
  if (length(est) == 0L) {
    stop("the fit has no coefficients to draw from.", call. = FALSE)
  }

  # Prefer a genuine per-draw survival ensemble; fall back to Gaussian parameter
  # draws plus the maximum-likelihood curve when the ensemble is not available.
  grid <- numeric(0)
  ens <- NULL
  if (!is.null(times)) {
    grid <- as.numeric(times)
    ens <- .survkit_surv_ensemble(fit, grid, newdata, n_draws)
  }

  outputs <- NULL
  if (!is.null(ens)) {
    draws <- ens$coef_draws
    outputs <- ens$outputs
  } else {
    draws <- .survkit_draw_coef(est, fit@vcov, n_draws)
    if (!is.null(times)) {
      pt <- tryCatch(survkit_curve(fit, newdata = newdata, times = grid),
                     error = function(e) NULL)
      if (!is.null(pt)) {
        names(pt)[names(pt) == "value"] <- "survival"
        pt$draw <- 0L
        outputs <- pt
      }
    }
  }

  params <- data.frame(real_name = paste0("r", seq_len(nrow(draws))),
                       draws, check.names = FALSE, stringsAsFactors = FALSE)
  survkit_manifest(
    params = params, outputs = outputs, time_grid = grid,
    method = fit@method,
    emitter_version = as.character(utils::packageVersion("survkit")),
    seed = if (is.null(seed)) NA_integer_ else as.integer(seed))
}

# Per-draw survival ensemble for a flexsurv-backed fit. Uses the backend's own
# sampler to draw from the asymptotic normal of the estimates, then evaluates
# each draw's survival through the fitted distribution function so the parameter
# draws and the survival draws are one consistent ensemble. Returns NULL (the
# caller then falls back) unless the fit is flexsurv-backed and a single-profile
# `newdata` is supplied.
.survkit_surv_ensemble <- function(fit, times, newdata, n_draws) {
  if (!fit@kind %in% c("parametric", "spline", "cure")) {
    return(NULL)
  }
  if (is.null(newdata) || !requireNamespace("flexsurv", quietly = TRUE)) {
    return(NULL)
  }
  raw <- fit@fit
  dfns <- tryCatch(raw$dfns, error = function(e) NULL)
  if (is.null(dfns) || is.null(dfns$p)) {
    return(NULL)
  }
  nb <- tryCatch(
    flexsurv::normboot.flexsurvreg(raw, B = n_draws, newdata = newdata),
    error = function(e) NULL)
  if (is.null(nb) || is.null(attr(nb, "rawsim"))) {
    return(NULL)
  }

  # Each row of `nb` holds the natural distribution parameters for one draw at
  # the requested profile; evaluate survival = 1 - F(t) through the backend's
  # own distribution function.
  param_names <- colnames(nb)
  surv <- vapply(seq_len(nrow(nb)), function(b) {
    args <- c(list(times), stats::setNames(as.list(nb[b, ]), param_names))
    1 - as.numeric(do.call(dfns$p, args))
  }, numeric(length(times)))

  outputs <- data.frame(
    draw = rep(seq_len(nrow(nb)), each = length(times)),
    time = rep(times, times = nrow(nb)),
    survival = as.numeric(surv), profile = 1L, stringsAsFactors = FALSE)
  list(outputs = outputs, coef_draws = as.data.frame(attr(nb, "rawsim")))
}

# Gaussian draw of coefficients; uses MASS when available, else independent
# normals on the diagonal (a documented degradation, not a silent one).
.survkit_draw_coef <- function(est, vcov, n_draws) {
  p <- length(est)
  if (!is.null(vcov) && all(dim(as.matrix(vcov)) == p) &&
      requireNamespace("MASS", quietly = TRUE)) {
    z <- MASS::mvrnorm(n_draws, mu = est, Sigma = as.matrix(vcov))
  } else {
    sds <- if (is.null(vcov)) rep(1, p) else sqrt(pmax(diag(as.matrix(vcov)), 0))
    z <- matrix(stats::rnorm(n_draws * p, rep(est, each = n_draws),
                             rep(sds, each = n_draws)), nrow = n_draws)
  }
  z <- matrix(z, nrow = n_draws)
  colnames(z) <- names(est) %||% paste0("b", seq_len(p))
  as.data.frame(z)
}
