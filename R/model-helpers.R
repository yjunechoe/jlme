#' Helpers for interacting with Julia model objects
#'
#' @name jlme-model-helpers
#' @param x Julia model object
#' @return An appropriate R object
#' @examples
#' x <- jlmer(r2 ~ Anger + (1 | id), lme4::VerbAgg, family = "binomial")
#'
#' # `propertynames()` lists properties accessible via `$`
#' propertynames(x)
#'
#' # `issingular()` reports whether model has singular fit
#' issingular(x)
NULL

#' @rdname jlme-model-helpers
propertynames <- function(x) {
  stopifnot(is_jl(x))
  nm <- JuliaConnectoR::juliaGet(JuliaConnectoR::juliaCall("propertynames", x))
  sort(as.character(nm))
}

#' @rdname jlme-model-helpers
issingular <- function(x) {
  stopifnot(is_jl(x, "MixedModel"))
  JuliaConnectoR::juliaCall("MixedModels.issingular", x)
}
