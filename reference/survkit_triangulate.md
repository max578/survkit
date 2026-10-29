# Triangulate a survival question across methods

Fit the same data under several methods and compare them on the
restricted mean survival time (and, if a landmark time is given, on
survival at that time). The relative spread across methods is a
model-misspecification signal: when the methods disagree by more than
`threshold`, the fit is flagged.

## Usage

``` r
survkit_triangulate(
  formula,
  data,
  methods = c("weibull", "cox", "km"),
  tau = NULL,
  time_star = NULL,
  newdata = NULL,
  threshold = 0.1,
  ...
)
```

## Arguments

- formula:

  A model formula with a
  [`survival::Surv()`](https://rdrr.io/pkg/survival/man/Surv.html)
  response.

- data:

  A data frame.

- methods:

  Character vector of registry keys to compare (default
  `c("weibull", "cox", "km")`). Methods whose backend is missing, or
  that fail to fit, are dropped with a warning.

- tau:

  Numeric horizon for the restricted mean. The default is the 90th
  percentile of the observed times.

- time_star:

  Optional landmark time; when given, survival at `time_star` is
  compared as well.

- newdata:

  Optional single covariate profile for the model-based quantities.

- threshold:

  Numeric relative-spread threshold above which the methods are flagged
  as disagreeing (default `0.1`, i.e. 10 percent).

- ...:

  Passed to each
  [`survkit()`](https://max578.github.io/survkit/reference/survkit.md)
  fit.

## Value

A `survkit_triangulation` list with the per-method quantities, the
disagreement summary, and a logical `flagged`. It has a `print` method.

## See also

[`survkit_rmst()`](https://max578.github.io/survkit/reference/survkit_rmst.md)
for the quantity compared,
[`survkit()`](https://max578.github.io/survkit/reference/survkit.md) for
a single fit.

Other model-fitting:
[`is_survkit_refusal()`](https://max578.github.io/survkit/reference/is_survkit_refusal.md),
[`survkit()`](https://max578.github.io/survkit/reference/survkit.md),
[`survkit_cuminc()`](https://max578.github.io/survkit/reference/survkit_cuminc.md),
[`survkit_power()`](https://max578.github.io/survkit/reference/survkit_power.md),
[`survkit_refusal()`](https://max578.github.io/survkit/reference/survkit_refusal.md),
[`survkit_rmst()`](https://max578.github.io/survkit/reference/survkit_rmst.md),
[`survkit_score()`](https://max578.github.io/survkit/reference/survkit_score.md)

## Examples

``` r
tri <- survkit_triangulate(survival::Surv(time, status) ~ age + sex,
                           survival::lung, methods = c("weibull", "cox", "km"),
                           tau = 500)
tri
#> $methods
#> [1] "weibull" "cox"     "km"     
#> 
#> $tau
#> [1] 500
#> 
#> $time_star
#> NULL
#> 
#> $rmst
#>    method tau     rmst
#> 1 weibull 500 311.5567
#> 2     cox 500 312.7260
#> 3      km 500 310.3344
#> 
#> $survival
#> NULL
#> 
#> $disagreement
#>   quantity  spread    relative flagged
#> 1     rmst 2.39158 0.007676662   FALSE
#> 
#> $flagged
#> [1] FALSE
#> 
#> $threshold
#> [1] 0.1
#> 
#> attr(,"class")
#> [1] "survkit_triangulation"
```
