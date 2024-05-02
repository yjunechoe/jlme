jl_evalf <- function(x, ...) {
  if (is.null(x)) return(NULL)
  dots <- list(...)
  if (length(dots) == 0) {
    JuliaConnectoR::juliaEval(x)
  } else {
    JuliaConnectoR::juliaEval(sprintf(x, ...))
  }
}

jl_formula <- function(x) {
  if (inherits(x, "formula")) {
    x <- deparse(x)
  }
  jl_evalf("@formula(%s)", x)
}

jl_contrasts <- function(df, cols = NULL, ..., show_code = FALSE) {
  dict <- construct_contrasts(df, cols = cols)
  if (show_code) {
    cat(dict)
    return(invisible(NULL))
  }
  jl_evalf(dict)
}

jl_data <- function(df) {
  fct_cols <- Filter(is.factor, df)
  df[, colnames(fct_cols)] <- lapply(fct_cols, as.character)
  df
}

jl_family <- function(family = c("gaussian", "binomial", "poisson")) {
  if (is.character(family)) {
    family <- match.arg(family)
    family <- switch(
      family,
      "gaussian" = "Normal",
      "binomial" = "Bernoulli",
      "poisson"  = "Poisson"
    )
    family <- jl_evalf("GLM.%s()", family)
  } else if (inherits(family, "JuliaProxy")) {
    family
  } else {
    stop("Invalid input to the `family` argument.")
  }
}
