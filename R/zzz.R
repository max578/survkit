# -- Load-time wiring ---------------------------------------------------------
# Register the S7 methods with the base generics and populate the built-in
# method registry. Both run once at namespace load.

.onLoad <- function(libname, pkgname) {
  S7::methods_register()
  .survkit_register_builtins()
  # `S7::method(print, survkit_fit) <- ...` (R/methods.R) creates a local
  # `print` generic that shadows base::print inside this namespace, so a
  # plain NAMESPACE `S3method(print, *)` entry resolved at load time binds
  # against the local generic rather than base's -- the method never
  # dispatches for a caller in another environment. Register explicitly
  # against base's table so print.survkit_refusal is found from anywhere.
  registerS3method("print", "survkit_refusal", print.survkit_refusal,
                    envir = baseenv())
  invisible(NULL)
}
