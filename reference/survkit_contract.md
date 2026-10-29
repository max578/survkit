# Describe the registry conformance contract

Return the field-level contract that every registered `fit` closure must
honour: the names of the fields a normalised fit result carries, so that
[`survkit()`](https://max578.github.io/survkit/reference/survkit.md) and
every downstream verb can rely on one shape. Use
[`survkit_validate_method()`](https://max578.github.io/survkit/reference/survkit_validate_method.md)
to check a specific method against it.

## Usage

``` r
survkit_contract()
```

## Value

A character vector of the required field names.

## See also

[`survkit_validate_method()`](https://max578.github.io/survkit/reference/survkit_validate_method.md),
[`survkit_register()`](https://max578.github.io/survkit/reference/survkit_register.md).

Other method-registry:
[`survkit_methods()`](https://max578.github.io/survkit/reference/survkit_methods.md),
[`survkit_register()`](https://max578.github.io/survkit/reference/survkit_register.md),
[`survkit_validate_method()`](https://max578.github.io/survkit/reference/survkit_validate_method.md)

## Examples

``` r
survkit_contract()
#> [1] "raw"      "coef"     "vcov"     "loglik"   "n"        "n_events" "kind"    
#> [8] "backend" 
```
