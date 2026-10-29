# Compute cumulative incidence for competing risks

The Aalen-Johansen estimator of the cumulative incidence function for
each competing event, computed from a multi-state
[`survival::survfit()`](https://rdrr.io/pkg/survival/man/survfit.html).
Unlike one minus a cause-specific Kaplan-Meier, this accounts for the
competing events and so sums, across causes, to the overall failure
probability.

## Usage

``` r
survkit_cuminc(formula, data, ...)
```

## Arguments

- formula:

  A model formula whose response is a multi-state
  `survival::Surv(time, event)` with `event` a factor whose first level
  is censoring. The right-hand side is `1` or grouping variables.

- data:

  A data frame.

- ...:

  Passed to
  [`survival::survfit()`](https://rdrr.io/pkg/survival/man/survfit.html).

## Value

A data frame with `time`, `group` (the stratum, or `"all"`), `cause`,
`cif` (the cumulative incidence) and `cif_se` (its standard error).

## See also

[`survkit()`](https://max578.github.io/survkit/reference/survkit.md)
with `method = "fine_gray"` for a regression on the subdistribution
hazard.

Other model-fitting:
[`is_survkit_refusal()`](https://max578.github.io/survkit/reference/is_survkit_refusal.md),
[`survkit()`](https://max578.github.io/survkit/reference/survkit.md),
[`survkit_power()`](https://max578.github.io/survkit/reference/survkit_power.md),
[`survkit_refusal()`](https://max578.github.io/survkit/reference/survkit_refusal.md),
[`survkit_rmst()`](https://max578.github.io/survkit/reference/survkit_rmst.md),
[`survkit_score()`](https://max578.github.io/survkit/reference/survkit_score.md),
[`survkit_triangulate()`](https://max578.github.io/survkit/reference/survkit_triangulate.md)

## Examples

``` r
mg <- survival::mgus2
mg$etime <- with(mg, ifelse(pstat == 1, ptime, futime))
mg$event <- with(mg, factor(ifelse(pstat == 1, "pcm",
                            ifelse(death == 1, "death", "censor")),
                            levels = c("censor", "pcm", "death")))
ci <- survkit_cuminc(survival::Surv(etime, event) ~ 1, mg)
head(ci)
#>   time group cause         cif      cif_se
#> 1    1   all   pcm 0.000000000 0.000000000
#> 2    2   all   pcm 0.001446164 0.001021853
#> 3    3   all   pcm 0.001446164 0.001021853
#> 4    4   all   pcm 0.002169246 0.001251056
#> 5    5   all   pcm 0.002892329 0.001444071
#> 6    6   all   pcm 0.003615411 0.001613935
```
