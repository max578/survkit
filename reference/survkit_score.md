# Score a fit's predictions

Evaluate a fitted model's predictions at one or more horizons: the
concordance index (discrimination) and the
inverse-probability-of-censoring-weighted Brier score with its index of
prediction accuracy (calibration and accuracy against a covariate-free
Kaplan-Meier reference).

## Usage

``` r
survkit_score(fit, data, times)
```

## Arguments

- fit:

  A
  [survkit_fit](https://max578.github.io/survkit/reference/survkit_fit.md)
  with a right-censored `survival::Surv(time, status)` response.

- data:

  A data frame carrying the response and covariates to score on
  (in-sample if it is the training data, out-of-sample otherwise).

- times:

  Numeric horizons at which to score.

## Value

A data frame with `time`, `cindex` (Harrell's C using predicted risk at
that horizon), `brier` (IPCW Brier) and `ipa` (index of prediction
accuracy).

## Details

The inverse-probability-of-censoring-weighted Brier score at horizon
\\t\\ is \$\$BS(t) = \frac{1}{n}\sum\_{i=1}^n \Big\[ \frac{\big(0 - \hat
S(t \mid x_i)\big)^2}{\hat G(T_i)} \mathbf{1}(T_i \le t, \delta_i = 1) +
\frac{\big(1 - \hat S(t \mid x_i)\big)^2}{\hat G(t)} \mathbf{1}(T_i \>
t) \Big\]\$\$ where \\\hat S(\cdot \mid x_i)\\ is the predicted survival
probability, \\\hat G\\ is the Kaplan-Meier estimator of the *censoring*
survival function, and the index of prediction accuracy is \\IPA(t) =
1 - BS(t) / BS_0(t)\\ against a covariate-free reference \\BS_0\\.

## References

Graf E, Schmoor C, Sauerbrei W, Schumacher M. Assessment and comparison
of prognostic classification schemes for survival data. *Statistics in
Medicine* 1999; 18(17-18): 2529-2545.
[doi:10.1002/(SICI)1097-0258(19990915/30)18:17/18\<2529::AID-SIM274\>3.0.CO;2-5](https://doi.org/10.1002/%28SICI%291097-0258%2819990915/30%2918%3A17/18%3C2529%3A%3AAID-SIM274%3E3.0.CO%3B2-5)

## See also

[`survkit_curve()`](https://max578.github.io/survkit/reference/survkit_curve.md)
for the predictions scored here.

Other model-fitting:
[`is_survkit_refusal()`](https://max578.github.io/survkit/reference/is_survkit_refusal.md),
[`survkit()`](https://max578.github.io/survkit/reference/survkit.md),
[`survkit_cuminc()`](https://max578.github.io/survkit/reference/survkit_cuminc.md),
[`survkit_power()`](https://max578.github.io/survkit/reference/survkit_power.md),
[`survkit_refusal()`](https://max578.github.io/survkit/reference/survkit_refusal.md),
[`survkit_rmst()`](https://max578.github.io/survkit/reference/survkit_rmst.md),
[`survkit_triangulate()`](https://max578.github.io/survkit/reference/survkit_triangulate.md)

## Examples

``` r
fit <- survkit(survival::Surv(time, status) ~ age + sex, survival::lung,
               method = "cox")
survkit_score(fit, survival::lung, times = c(200, 400, 600))
#>   time   cindex     brier        ipa
#> 1  200 0.602853 0.2094928 0.03700922
#> 2  400 0.602853 0.2318152 0.01245320
#> 3  600 0.602853 0.1646295 0.01890319
```
