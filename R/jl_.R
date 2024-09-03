#' Helpers for converting model specifications in R to Julia equivalents
#'
#' @name jl-helpers
#' @keywords internal
#' @return A Julia object of type `<JuliaProxy>`
#'
#' @examplesIf check_julia_ok()
#' \donttest{
#' jlme_setup(restart = TRUE)
#'
#' # (general) Use `jl()` to evaluate arbitrary Julia expressions from string
#' jl("1 .+ [1,3]")
#'
#' # `jl()` takes elements in `...` that you can reference in the expression
#' jl("1 .+ a", a = c(1L, 3L)) # Named arguments are introduced as variables
#' jl("1 .+ %s", "[1,2]") # Unnamed arguments are interpolated via `sprintf()`
#'
#' # Use `is_jl()` to test if object is a Julia (`<JuliaProxy>`) object
#' is_jl(jl("1"))
#'
#'
#' # (modelling) set up model data in R
#' x <- mtcars
#' x$cyl_helm <- factor(x$cyl)
#' contrasts(x$cyl_helm) <- contr.helmert(3)
#' colnames(contrasts(x$cyl_helm)) <- c("4vs6", "4&6vs8")
#'
#' # Formula conversion with
#' julia_formula <- jl_formula(mpg ~ am * cyl_helm)
#' julia_formula
#'
#' # Data frame conversion
#' julia_data <- jl_data(x)
#' julia_data
#'
#' # Contrasts construction (`show_code = TRUE` pretty prints the Julia code)
#' julia_contrasts <- jl_contrasts(x, show_code = TRUE)
#' julia_contrasts
#'
#' # Family conversion
#' julia_family <- jl_family("binomial")
#' julia_family
#'
#' stop_julia()
#' }
NULL

#' @rdname jl-helpers
#' @param x An object
#' @param type Type of Julia object to additional test for
#' @export
is_jl <- function(x, type) {
  inherits(x, "JuliaProxy") &&
    if (!missing(type)) { type %in% jl_supertypes(x) } else { TRUE }
}


#' @rdname jl-helpers
#' @param expr A string of Julia code
#' @param ... Elements interpolated into `expr`.
#'    - If all named, elements are introduced as Julia variables in the `expr`
#'    - If all unnamed, elements are interpolated into `expr` via [sprintf()]
#' @param .R Whether to simplify and return as R object, if possible.
#' @param .passthrough Whether to return `expr` as-is if it's already a Julia
#'   object. Mostly for internal use.
#' @export
jl <- function(expr, ..., .R = FALSE, .passthrough = FALSE) {
  if (is_jl(expr) && .passthrough) return(expr)
  dots <- list(...)
  stopifnot(is.character(expr) && length(expr) == 1L)
  if (is.null(dots)) {
    # eval if no dots
    out <- JuliaConnectoR::juliaEval(expr)
  } else {
    dots_names <- names(dots)
    stopifnot(all(nzchar(dots_names)))
    if (is.null(dots_names)) {
      # sprintf for unnamed dots
      s_interpolated <- do.call(sprintf, c(fmt = expr, dots))
      out <- JuliaConnectoR::juliaEval(s_interpolated)
    } else {
      # let block for named dots
      out <- do.call(JuliaConnectoR::juliaLet, c(expr = expr, dots))
    }
  }
  # resolve `.R` and return as R or Julia
  if (!.R && !is_jl(out)) {
    out <- JuliaConnectoR::juliaPut(out)
  }
  if (.R && is_jl(out)) {
    out <- jl_get(out)
  }
  out
}

#' @rdname jl-helpers
#' @param formula A string or formula object
#' @export
jl_formula <- function(formula) {
  x <- formula
  if (is_jl(x)) return(x)
  x <- JuliaFormulae::julia_formula(x)
  res <- tryCatch(
    jl("@formula(%s)", deparse1(x)),
    error = function(e) {
      sanitize_jl_error(e, sys.call(1))
    }
  )
  if (inherits(res, "condition")) {
    stop(res)
  } else {
    res
  }
}

#' @rdname jl-helpers
#' @param df A data frame
#' @param cols A subset of columns to make contrast specifiations for
#' @param show_code Whether to print corresponding Julia code as a side-effect
#' @export
jl_contrasts <- function(df, cols = NULL, show_code = FALSE) {
  if (is_jl(df)) return(NULL)
  dict <- construct_contrasts(df, cols = cols)
  if (show_code) {
    cat(dict)
  }
  if (!is.null(dict)) {
    jl(dict)
  } else {
    NULL
  }
}

#' @rdname jl-helpers
#' @export
jl_data <- function(df) {
  if (is_jl(df)) return(df)
  fct_cols <- Filter(is.factor, df)
  df[, colnames(fct_cols)] <- lapply(fct_cols, as.character)
  JuliaConnectoR::juliaPut(df)
}

#' @rdname jl-helpers
#' @param family The distributional family as string or `<family>` object
#' @export
jl_family <- function(family = c("gaussian", "binomial", "poisson")) {
  if (is_jl(family)) return(family)
  if (inherits(family, "family")) {
    family <- family$family
  }
  if (is.character(family)) {
    family <- match.arg(family)
    family <- switch(
      family,
      "gaussian" = "Normal",
      "binomial" = "Bernoulli",
      "poisson"  = "Poisson"
    )
    family <- jl("GLM.%s()", family)
    family
  } else {
    stop("Invalid input to the `family` argument.")
  }
}
