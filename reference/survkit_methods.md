# List the registered methods

List the registered methods

## Usage

``` r
survkit_methods()
```

## Value

A data frame of `method`, `kind`, `backend`, `available` (is the backend
installed) and `note`.

## See also

[`survkit_register()`](https://max578.github.io/survkit/reference/survkit_register.md)
to add a method.

Other method-registry:
[`survkit_contract()`](https://max578.github.io/survkit/reference/survkit_contract.md),
[`survkit_register()`](https://max578.github.io/survkit/reference/survkit_register.md),
[`survkit_validate_method()`](https://max578.github.io/survkit/reference/survkit_validate_method.md)

## Examples

``` r
survkit_methods()
#>               method          kind      backend available
#> 1      andersen_gill     recurrent     survival      TRUE
#> 2     cause_specific     competing     survival      TRUE
#> 3                cox           cox     survival      TRUE
#> 4          cox_ridge           cox     survival      TRUE
#> 5               cure          cure flexsurvcure      TRUE
#> 6        exponential    parametric     flexsurv      TRUE
#> 7          fine_gray     competing     survival      TRUE
#> 8            frailty       frailty        coxme      TRUE
#> 9              gamma    parametric     flexsurv      TRUE
#> 10 generalized_gamma    parametric     flexsurv      TRUE
#> 11          gompertz    parametric     flexsurv      TRUE
#> 12 interval_censored      interval      icenReg      TRUE
#> 13                km nonparametric     survival      TRUE
#> 14       loglogistic    parametric     flexsurv      TRUE
#> 15         lognormal    parametric     flexsurv      TRUE
#> 16            spline        spline     flexsurv      TRUE
#> 17           weibull    parametric     flexsurv      TRUE
#>                                                         note
#> 1                            recurrent events, Andersen-Gill
#> 2                     competing risks, cause-specific hazard
#> 3                                   Cox proportional hazards
#> 4  ridge-penalised Cox (shrinkage for the few-events regime)
#> 5                      mixture cure model (optional backend)
#> 6                  parametric AFT, flexsurvreg(dist = 'exp')
#> 7                 competing risks, Fine-Gray subdistribution
#> 8                         mixed-effects Cox / shared frailty
#> 9                parametric AFT, flexsurvreg(dist = 'gamma')
#> 10            parametric AFT, flexsurvreg(dist = 'gengamma')
#> 11            parametric AFT, flexsurvreg(dist = 'gompertz')
#> 12           interval-censored regression (optional backend)
#> 13       Kaplan-Meier / Nelson-Aalen non-parametric baseline
#> 14              parametric AFT, flexsurvreg(dist = 'llogis')
#> 15               parametric AFT, flexsurvreg(dist = 'lnorm')
#> 16                            Royston-Parmar flexible spline
#> 17             parametric AFT, flexsurvreg(dist = 'weibull')
```
