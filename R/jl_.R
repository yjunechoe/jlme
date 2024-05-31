jl_formula <- function(x) {
  stopifnot(is.character(x) || inherits(x, "formula"))
  s <- deparse1(x)
  res <- tryCatch(
    jl_evalf("@formula(%s)", s),
    error = function(e) {
      if (requireNamespace("JuliaFormulae", quietly = TRUE)) {
        jl_evalf("@formula(%s)", deparse1(JuliaFormulae::julia_formula(x)))
      } else {
        e$message <- gsub("Stacktrace:.*$", "", e$message)
        e
      }
    }
  )
  if (inherits(res, "condition")) {
    res$call <- sys.call()
    stop(res)
  } else {
    res
  }
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
