#' Helpers for interacting with Julia model objects and functions
#'
#' @name jlme-model-helpers
#'
#' @param x Julia model object
#'
#' @return An appropriate R object
#'
#' @examplesIf check_julia_ok()
#' \donttest{
#' jlme_setup(restart = TRUE)
#'
#' x <- jlmer(r2 ~ Anger + (1 | id), lme4::VerbAgg, family = "binomial")
#'
#' # `propertynames()` lists properties accessible via `$`
#' propertynames(x)
#'
#' # `issingular()` reports whether model has singular fit
#' issingular(x)
#'
#' stop_julia()
#' }
NULL

#' @rdname jlme-model-helpers
#' @export
propertynames <- function(x) {
  stopifnot(is_jl(x))
  nm <- jl_get(JuliaConnectoR::juliaCall("propertynames", x))
  sort(as.character(nm))
}

#' @rdname jlme-model-helpers
#' @export
issingular <- function(x) {
  stopifnot(is_jl(x, "MixedModel"))
  JuliaConnectoR::juliaCall("MixedModels.issingular", x)
}
