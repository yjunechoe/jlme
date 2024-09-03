jl_io <- function(verbose) {
  if (verbose) "" else "io=devnull"
}

jl_pkg_installed <- function(x, ..., verbose = interactive()) {
  jl('!isnothing(Pkg.status("%1$s"; %2$s))', x, jl_io(verbose), .R = TRUE)
}

jl_pkg_add <- function(x, ..., verbose = interactive()) {
  if (!jl_pkg_installed(x, verbose = verbose)) {
    jl('Pkg.add("%2$s"; %1$s); using %2$s', jl_io(verbose), x)
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

jl_supertypes <- function(x) {
  supertypes <- JuliaConnectoR::juliaLet("
    let
        T = typeof(x)
        supertypes = []
        while T != Any
            T = supertype(T)
            push!(supertypes, T)
        end
        supertypes
    end
  ", x = x)
  vec <- unlist(jl_get(supertypes))
  gsub("\\{.*\\}$", "", vec)
}

jl_format <- function(x, ...) {
  JuliaConnectoR::juliaCall("JuliaFormatter.format_text", x, align_matrix = TRUE, ...)
}
