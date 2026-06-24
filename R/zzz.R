# -- Load-time wiring ---------------------------------------------------------
# Register the S7 methods with the base generics and populate the built-in
# method registry. Both run once at namespace load.

.onLoad <- function(libname, pkgname) {
  S7::methods_register()
  .survkit_register_builtins()
  invisible(NULL)
}
