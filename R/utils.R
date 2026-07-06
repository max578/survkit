# -- Internal utilities -------------------------------------------------------

# Null-coalescing helper (kept internal to avoid a hard rlang dependency).
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0L) b else a

# Survival curve from a fitted model, omitting `newdata` when it is NULL: passing
# an explicit `newdata = NULL` sends survfit down its reconstruction path, which
# needs the covariates in scope, whereas omitting it uses the reference profile.
.survkit_survfit <- function(raw, newdata = NULL) {
  if (is.null(newdata)) {
    survival::survfit(raw)
  } else {
    survival::survfit(raw, newdata = newdata)
  }
}

# Require a backend package, with a message that points at the install and the
# method that needs it.
.survkit_require <- function(backend, method) {
  if (!requireNamespace(backend, quietly = TRUE)) {
    stop(sprintf("method '%s' needs the '%s' package. Install it with install.packages('%s').",
                 method, backend, backend), call. = FALSE)
  }
  invisible(TRUE)
}
