# -- Internal utilities -------------------------------------------------------

# Null-coalescing helper (kept internal to avoid a hard rlang dependency).
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0L) b else a

# Require a backend package, with a message that points at the install and the
# method that needs it.
.survkit_require <- function(backend, method) {
  if (!requireNamespace(backend, quietly = TRUE)) {
    stop(sprintf("method '%s' needs the '%s' package. Install it with install.packages('%s').",
                 method, backend, backend), call. = FALSE)
  }
  invisible(TRUE)
}
