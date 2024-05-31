jl_evalf <- function(x, ...) {
  if (is.null(x)) return(NULL)
  dots <- list(...)
  if (length(dots) == 0) {
    JuliaConnectoR::juliaEval(x)
  } else {
    JuliaConnectoR::juliaEval(sprintf(x, ...))
  }
}

jl_io <- function(verbose) {
  if (verbose) "" else "io=devnull"
}

jl_pkg_installed <- function(x, ..., verbose = interactive()) {
  jl_evalf('!isnothing(Pkg.status("%1$s"; %2$s))', x, jl_io(verbose))
}

jl_pkg_add <- function(x, ..., verbose = interactive()) {
  if (!jl_pkg_installed(x, verbose = verbose)) {
    jl_evalf('Pkg.add("%2$s"; %1$s); using %2$s', jl_io(verbose), x)
  }
}

check_jl_installed <- function(x, add = TRUE, ..., verbose = interactive()) {
  if (add) {
    jl_pkg_add(x, verbose = verbose)
  } else {
    stopifnot(jl_pkg_installed(x, verbose = verbose))
  }
}

sanitize_jl_error <- function(e, .call) {
  e$message <- gsub("Stacktrace:.*$", "", e$message)
  e$call <- .call
  e
}
