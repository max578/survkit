# Compute the restricted mean survival time

The restricted mean survival time (RMST) to a horizon `tau`: the area
under the survival curve on `[0, tau]`, a decision-relevant summary that
stays defined when the median is not reached. Parametric, spline and
cure fits use the backend's own RMST with its delta-method interval;
Cox-family and non-parametric fits use the area under
[`survival::survfit()`](https://rdrr.io/pkg/survival/man/survfit.html)
with its standard error.

## Usage

``` r
survkit_rmst(fit, tau, newdata = NULL)
```

## Arguments

- fit:

  A
  [survkit_fit](https://max578.github.io/survkit/reference/survkit_fit.md).

- tau:

  Numeric horizon (a single positive time) the mean is restricted to.

- newdata:

  A data frame of covariate profiles for the model-based fits. The
  default is the backend's reference profile.

## Value

A data frame with `tau`, `group` (or `profile`), `rmst`, `se`,
`conf_low` and `conf_high`.

## Details

\$\$RMST(\tau) = \int_0^{\tau} S(t)\\dt\$\$ where \\S(t)\\ is the
(model-based or Kaplan-Meier) survival function. Restricting the
integral to \\\[0, \tau\]\\ keeps the summary defined and identifiable
from the observed follow-up even when the survival curve never crosses
one-half.

## See also

[`survkit_curve()`](https://max578.github.io/survkit/reference/survkit_curve.md)
for the curve the mean integrates.

Other model-fitting:
[`is_survkit_refusal()`](https://max578.github.io/survkit/reference/is_survkit_refusal.md),
[`survkit()`](https://max578.github.io/survkit/reference/survkit.md),
[`survkit_cuminc()`](https://max578.github.io/survkit/reference/survkit_cuminc.md),
[`survkit_power()`](https://max578.github.io/survkit/reference/survkit_power.md),
[`survkit_refusal()`](https://max578.github.io/survkit/reference/survkit_refusal.md),
[`survkit_score()`](https://max578.github.io/survkit/reference/survkit_score.md),
[`survkit_triangulate()`](https://max578.github.io/survkit/reference/survkit_triangulate.md)

## Examples

``` r
fit <- survkit(survival::Surv(time, status) ~ 1, survival::lung, method = "km")
survkit_rmst(fit, tau = 365)
#>   tau group     rmst       se conf_low conf_high
#> 1 365   all 263.2219 7.798859 247.9364  278.5073
```
