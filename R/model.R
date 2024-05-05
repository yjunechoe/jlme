#' Fit a (mixed-effects) regression model in Julia
#'
#' @param formula A formula written in Julia syntax. Can be a string or a
#'  language object.
#' @param data A data frame
#' @param family A distribution family
#' @param contrasts A Julia dictionary of contrasts
#'   Inferred from `data` by default.
#' @param ... Additional arguments to the `fit()` function called in Julia
#'
#' @return A julia model object of class `jlme`
#' @export
#'
#' @examples
#' jlme_setup(restart = TRUE)
#'
#' # Fixed effects models
#' lm(mpg ~ hp, mtcars)
#' jlm(mpg ~ hp, mtcars)
#'
#' # Auto-handling of contrasts
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
#' # Mixed effects models
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

#' @rdname jlm
#' @param progress Whether to print model fitting progress. Defaults to `TRUE`
#' @export
jlmer <- function(formula, data, family = NULL,
                  contrasts = jl_contrasts(data),
                  ..., progress = TRUE) {

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

is_jlmer <- function(x) {
  inherits(x, "JuliaProxy") &&
    JuliaConnectoR::juliaLet("x isa MixedModel", x = x)
}

#' @export
print.jlme <- function(x, type = NULL, ...) {
  if (is_jlmer(x) && !is.null(type)) {
    show_jlmer(x, type)
  } else {
    cat(format(x, ...))
  }
  invisible(x)
}

show_jlmer <- function(x, type = c("markdown", "latex", "html")) {
  type <- match.arg(type)
  JuliaConnectoR::juliaLet(
    sprintf('show(MIME("text/%s"), x)', type),
    x = x
  )
}

#' @export
format.jlme <- function(x, ...) {
  header <- paste0("<Julia object of type ", JuliaConnectoR::juliaLet("typeof(x).name.wrapper", x = x), ">")
  if (is_jlmer(x)) {
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
