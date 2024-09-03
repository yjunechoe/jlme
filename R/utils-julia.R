is_jl <- function(x, type) {
  inherits(x, "JuliaProxy") &&
    if (!missing(type)) { type %in% jl_supertypes(x) } else { TRUE }
}

jl_get <- function(x) {
  if (is_jl(x)) {
    x <- JuliaConnectoR::juliaGet(x)
    JL_attr <- grep(x = names(attributes(x)), "^JL[A-Z]+$", value = TRUE)
    attributes(x)[JL_attr] <- NULL
  }
  x
}

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
  vec <- unlist(JuliaConnectoR::juliaGet(supertypes))
  gsub("\\{.*\\}$", "", vec)
}

list2tuple <- function(x) {
  stopifnot(is.list(x), all(nzchar(names(x))))
  JuliaConnectoR::juliaLet("NamedTuple(x.namedelements)", x = x)
}
