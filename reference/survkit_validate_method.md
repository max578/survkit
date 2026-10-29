# Validate a registered method against the contract

Fit a registered method on the supplied data and check that its
normalised result honours the registry contract
([`survkit_contract()`](https://max578.github.io/survkit/reference/survkit_contract.md)):
every required field is present and of the right type. When the method's
backend is not installed the check is skipped rather than failed.

## Usage

``` r
survkit_validate_method(name, formula, data, ...)
```

## Arguments

- name:

  Character registry key to validate.

- formula:

  A model formula appropriate for the method (competing-risks and
  recurrent methods need the matching multi-state or counting-process
  response).

- data:

  A data frame to fit on.

- ...:

  Passed to the method's `fit` closure.

## Value

A list with `method`, `ok` (`TRUE` / `FALSE`, or `NA` when skipped),
`missing` (any absent fields), `failed` (fields failing their type
check) and `reason` (why it was skipped, if it was).

## See also

[`survkit_contract()`](https://max578.github.io/survkit/reference/survkit_contract.md)
for the contract,
[`survkit_register()`](https://max578.github.io/survkit/reference/survkit_register.md)
to add a method.

Other method-registry:
[`survkit_contract()`](https://max578.github.io/survkit/reference/survkit_contract.md),
[`survkit_methods()`](https://max578.github.io/survkit/reference/survkit_methods.md),
[`survkit_register()`](https://max578.github.io/survkit/reference/survkit_register.md)

## Examples

``` r
survkit_validate_method("cox", survival::Surv(time, status) ~ age,
                        survival::lung)
#> $method
#> [1] "cox"
#> 
#> $ok
#> [1] TRUE
#> 
#> $missing
#> character(0)
#> 
#> $failed
#> character(0)
#> 
#> $reason
#> [1] NA
#> 
```
