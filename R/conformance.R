# -- Registry conformance contract --------------------------------------------
# The registry is only as trustworthy as the closures put into it. This is the
# contract every registered `fit` closure must honour, and a checker that fits a
# method on a fixture and confirms the returned object meets it. It is survkit's
# analogue of a backend conformance test: a new estimator is welcome, but it must
# return the one shape the rest of the toolkit relies on.

# The fields a normalised fit result must carry, with a predicate each must
# satisfy. `raw` may be any object; the rest are typed.
.survkit_contract <- list(
  raw = function(v) TRUE,
  coef = function(v) is.numeric(v),
  vcov = function(v) is.null(v) || is.matrix(as.matrix(v)),
  loglik = function(v) is.numeric(v) && length(v) == 1L,
  n = function(v) is.numeric(v) && length(v) == 1L,
  n_events = function(v) is.numeric(v) && length(v) == 1L,
  kind = function(v) is.character(v) && length(v) == 1L,
  backend = function(v) is.character(v) && length(v) == 1L
)

#' Describe the registry conformance contract
#'
#' Return the field-level contract that every registered `fit` closure must
#' honour: the names of the fields a normalised fit result carries, so that
#' `survkit()` and every downstream verb can rely on one shape. Use
#' [survkit_validate_method()] to check a specific method against it.
#'
#' @returns A character vector of the required field names.
#' @examples
#' survkit_contract()
#' @family method-registry
#' @seealso [survkit_validate_method()], [survkit_register()].
#' @export
survkit_contract <- function() {
  names(.survkit_contract)
}

#' Validate a registered method against the contract
#'
#' Fit a registered method on the supplied data and check that its normalised
#' result honours the registry contract ([survkit_contract()]): every required
#' field is present and of the right type. When the method's backend is not
#' installed the check is skipped rather than failed.
#'
#' @param name Character registry key to validate.
#' @param formula A model formula appropriate for the method (competing-risks and
#'   recurrent methods need the matching multi-state or counting-process
#'   response).
#' @param data A data frame to fit on.
#' @param ... Passed to the method's `fit` closure.
#'
#' @returns A list with `method`, `ok` (`TRUE` / `FALSE`, or `NA` when skipped),
#'   `missing` (any absent fields), `failed` (fields failing their type check)
#'   and `reason` (why it was skipped, if it was).
#' @examples
#' survkit_validate_method("cox", survival::Surv(time, status) ~ age,
#'                         survival::lung)
#' @family method-registry
#' @seealso [survkit_contract()] for the contract, [survkit_register()] to add a
#'   method.
#' @export
survkit_validate_method <- function(name, formula, data, ...) {
  spec <- .survkit_lookup(name)
  if (!requireNamespace(spec$backend, quietly = TRUE)) {
    return(list(method = name, ok = NA, missing = character(0),
                failed = character(0),
                reason = sprintf("backend '%s' not installed", spec$backend)))
  }

  res <- tryCatch(spec$fit(formula, data, ...), error = function(e) e)
  if (inherits(res, "error")) {
    return(list(method = name, ok = FALSE, missing = character(0),
                failed = character(0),
                reason = sprintf("fit errored: %s", conditionMessage(res))))
  }

  required <- names(.survkit_contract)
  missing <- setdiff(required, names(res))
  present <- intersect(required, names(res))
  failed <- present[!vapply(present, function(f) {
    isTRUE(tryCatch(.survkit_contract[[f]](res[[f]]), error = function(e) FALSE))
  }, logical(1))]

  list(method = name, ok = length(missing) == 0L && length(failed) == 0L,
       missing = missing, failed = failed, reason = NA_character_)
}
