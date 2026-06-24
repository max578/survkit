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
#' their Gaussian sampling approximation (mean = estimate, covariance = `vcov`);
#' the result is shaped to the ensemble-manifest contract (a parameter draw frame
#' with provenance), so a `pesto_ensemble_manifest`-compatible adapter can consume
#' it. Optionally evaluates predicted survival on a time grid per draw.
#'
#' @param fit A [survkit_fit].
#' @param n_draws Integer number of draws (default `200L`).
#' @param times Optional numeric time grid for predicted-survival outputs; `NULL`
#'   (default) emits a parameters-only manifest.
#' @param newdata Optional single covariate profile for the survival outputs.
#' @param seed Optional integer RNG seed (recorded in the manifest).
#'
#' @return A [survkit_manifest] object.
#'
#' @examples
#' fit <- survkit(survival::Surv(time, status) ~ age, survival::lung, method = "weibull")
#' m <- as_survkit_manifest(fit, n_draws = 50L, seed = 1L)
#' nrow(m@params)
#'
#' @export
as_survkit_manifest <- function(fit, n_draws = 200L, times = NULL,
                                 newdata = NULL, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  est <- fit@coefficients
  vc <- fit@vcov
  if (length(est) == 0L) {
    stop("the fit has no coefficients to draw from.", call. = FALSE)
  }
  draws <- .survkit_draw_coef(est, vc, n_draws)
  params <- data.frame(real_name = paste0("r", seq_len(nrow(draws))),
                       draws, check.names = FALSE, stringsAsFactors = FALSE)

  outputs <- NULL
  grid <- numeric(0)
  if (!is.null(times)) {
    grid <- as.numeric(times)
    surv <- tryCatch(survkit_curve(fit, newdata = newdata, times = grid),
                     error = function(e) NULL)
    if (!is.null(surv)) {
      outputs <- surv
    }
  }
  survkit_manifest(
    params = params, outputs = outputs, time_grid = grid,
    method = fit@method,
    emitter_version = as.character(utils::packageVersion("survkit")),
    seed = if (is.null(seed)) NA_integer_ else as.integer(seed))
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
