# Shared fixtures for the test suite, each a clean data frame with the response
# the method under test needs.

# Right-censored survival, complete cases on the columns the tests use.
.fx_lung <- function() {
  stats::na.omit(
    survival::lung[, c("time", "status", "age", "sex", "ph.ecog", "inst")])
}

# Competing risks (plasma-cell malignancy vs death), a multi-state factor
# response whose first level is censoring.
.fx_mgus <- function() {
  d <- survival::mgus2
  d$etime <- with(d, ifelse(pstat == 1, ptime, futime))
  d$event <- with(d, factor(
    ifelse(pstat == 1, "pcm", ifelse(death == 1, "death", "censor")),
    levels = c("censor", "pcm", "death")))
  d
}

# Recurrent events (counting-process response) for Andersen-Gill.
.fx_bladder <- function() {
  survival::bladder2
}
