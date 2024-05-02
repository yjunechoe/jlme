#' Fit a fixed-effects regression model using GLM.jl
#'
#' @param formula A formula written in Julia syntax
#' @param data A data frame
#' @param family A distribution family
#' @param contrasts A Julia dictionary of contrasts
#'   Inferred from `data` by default.
#' @param ... Additional options to `fit()`, called in Julia
#'
#' @return A julia model object of class `jlme`
#' @export
#'
#' @examples
#' jlme_setup(restart = TRUE)
#'
#' lm(mpg ~ hp, mtcars)
#' jlm(mpg ~ hp, mtcars)
#'
#' x <- mtcars
#' x$cyl_sum <- factor(x$cyl)
#' contrasts(x$cyl_sum) <- contr.sum(3)
#' lm(mpg ~ cyl_sum, x)
#' jlm(mpg ~ cyl_sum, x)
#'
#' x$cyl_helm <- factor(x$cyl)
#' contrasts(x$cyl_helm) <- contr.helmert(3)
#' colnames(contrasts(x$cyl_helm)) <- c("4vs6", "4&6vs8")
#' lm(mpg ~ cyl_helm, x)
#' jlm(mpg ~ cyl_helm, x)
#'
#' stop_julia()
jlm <- function(formula, data, family = NULL,
                contrasts = jl_contrasts(data), ...) {

  args_list <- c(
    list(
      "StatsModels.fit",
      jl_evalf("GLM.GeneralizedLinearModel"),
      jl_formula(formula),
      jl_data(data)
    ),
    family %||% jl_family(),
    if (!is.null(contrasts)) list(contrasts = contrasts),
    list(...)
  )

  mod <- do.call(JuliaConnectoR::juliaCall, args_list)

  class(mod) <- c("jlme", class(mod))
  mod

}

#' Fit a mixed-effects regression model using MixedModels.jl
#'
#' @inheritParams jlm
#'
#' @return A julia model object of class `jlme`
#' @export
#'
#' @examples
#' jlme_setup(restart = TRUE)
#' library(lme4)
#'
#' lmer(Reaction ~ Days + (Days | Subject), sleepstudy)
#' jlmer(Reaction ~ Days + (Days | Subject), sleepstudy)
#' jlmer(Reaction ~ Days + (Days | Subject), sleepstudy, REML = TRUE)
#'
#' glmer(r2 ~ Anger + Gender + (1 | id), VerbAgg, family = "binomial")
#' jlmer(r2 ~ Anger + Gender + (1 | id), VerbAgg, family = "binomial")
#'
#' stop_julia()
jlmer <- function(formula, data, family = NULL,
                  contrasts = jl_contrasts(data), ...) {

  model <- jl_evalf(
    "MixedModels.%sLinearMixedModel",
    if (!is.null(family)) "Generalized" else ""
  )

  args_list <- c(
    list(
      "StatsModels.fit",
      model,
      jl_formula(formula),
      jl_data(data)
    ),
    if (!is.null(family)) list(jl_family(family)),
    if (!is.null(contrasts)) list(contrasts = contrasts),
    list(...)
  )

  mod <- do.call(JuliaConnectoR::juliaCall, args_list)

  class(mod) <- c("jlme", class(mod))
  mod

}

#' @export
print.jlme <- function(x, ...) {
  cat(format(x, ...))
  invisible(x)
}

#' @export
format.jlme <- function(x, ...) {
  header <- paste0("<Julia object of type ", JuliaConnectoR::juliaLet("typeof(x).name.wrapper", x = x), ">")
  if (JuliaConnectoR::juliaLet("x isa MixedModel", x = x)) {
    formula <- JuliaConnectoR::juliaLet("repr(x.formula)", x = x)
    re <- gsub("\n\n$", "\n", showobj_reformat(JuliaConnectoR::juliaCall("VarCorr", x)))
    fe <- showobj_reformat(JuliaConnectoR::juliaCall("coeftable", x))
    body <- paste0(re, fe)
  } else {
    formula <- JuliaConnectoR::juliaLet("repr(x.mf.f)", x = x)
    body <- showobj_reformat(JuliaConnectoR::juliaCall("coeftable", x))
  }
  paste0(header, "\n\n", formula, "\n\n", body)
}

showobj_reformat <- function(x) {
  paste0(trimws(utils::capture.output(print(x))[-1], whitespace = "[\n]"), collapse = "\n")
}
