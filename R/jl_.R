jl_formula <- function(x) {
  stopifnot(inherits(x, "formula"))
  x <- deparse(x)
  JuliaConnectoR::juliaEval(sprintf("@formula(%s)", x))
}

jl_contrasts <- function(df, cols = NULL, ..., show_code = FALSE) {
  dict <- construct_contrasts(df, cols = cols)
  if (show_code) {
    cat(dict)
    return(invisible(NULL))
  }
  if (is.null(dict)) {
    return(NULL)
  } else {
    JuliaConnectoR::juliaEval(dict)
  }
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
    family <- JuliaConnectoR::juliaCall(sprintf("GLM.%s", family))
  } else if (inherits(family, "JuliaProxy")) {
    family
  } else {
    stop("Invalid input to the `family` argument.")
  }
}
