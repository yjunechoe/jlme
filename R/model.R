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
#' @examplesIf check_julia_ok()
#' \donttest{
#' jlme_setup(restart = TRUE)
#'
#' # Fixed effects models
#' lm(mpg ~ hp, mtcars)
#' jlm(mpg ~ hp, mtcars)
#'
#' # Auto-handling of contrasts
#' x <- mtcars
#' x$cyl_helm <- factor(x$cyl)
#' contrasts(x$cyl_helm) <- contr.helmert(3)
#' colnames(contrasts(x$cyl_helm)) <- c("4vs6", "4&6vs8")
#' lm(mpg ~ cyl_helm, x)
#' jlm(mpg ~ cyl_helm, x)
#'
#' # Mixed effects models
#' library(lme4)
#'
#' glmer(r2 ~ Anger + Gender + (1 | id), VerbAgg, family = "binomial")
#' jlmer(r2 ~ Anger + Gender + (1 | id), VerbAgg, family = "binomial")
#'
#' # Set optimizer options via `optsum`
#' jlmer(
#'   r2 ~ Anger + Gender + (1 | id), VerbAgg, family = "binomial",
#'   optsum = list(
#'     optimizer = jl(":LN_NELDERMEAD"),
#'     maxfeval = 10L
#'   )
#' )
#'
#' stop_julia()
#' }
jlm <- function(formula, data, family = "gaussian",
                contrasts = jl_contrasts(data), ...) {

  ensure_setup()

  args_list <- c(
    list(
      "StatsModels.fit",
      jl("GLM.GeneralizedLinearModel"),
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

#' @rdname jlm
#' @param fit Whether to fit the model. If `FALSE`, returns the unfit model object.
#' @param optsum A list of values to set for the optimizer. See `$optsum` of unfit
#'   model for possible options.
#' @param progress Whether to print model fitting progress. Defaults to `interactive()`
#' @export
jlmer <- function(formula, data, family = NULL,
                  contrasts = jl_contrasts(data),
                  ...,
                  fit = TRUE,
                  optsum = list(),
                  progress = interactive()) {

  ensure_setup()

  model_fun <- sprintf(
    "MixedModels.%sLinearMixedModel",
    if (!is.null(family)) "Generalized" else ""
  )

  args_list <- c(
    list(
      model_fun,
      jl_formula(formula),
      jl_data(data)
    ),
    if (!is.null(family)) list(jl_family(family)),
    if (!is.null(contrasts)) list(contrasts = contrasts)
  )

  model <- do.call(JuliaConnectoR::juliaCall, args_list)

  stopifnot(
    "Unused in `optsum`" = all(names(optsum) %in% propertynames(model$optsum))
  )
  optsum_keys <- lapply(names(optsum), as.symbol)
  for (i in seq_along(optsum)) {
    JuliaConnectoR::juliaCall("setfield!", model$optsum, optsum_keys[[i]], optsum[[i]])
  }

  if (!fit) {
    return(model)
  }

  fit_args <- utils::modifyList(
    list(
      model,
      progress = progress
    ),
    list(...)
  )
  do.call(JuliaConnectoR::juliaFun("fit!"), fit_args)

  # Singular fit message
  if (issingular(model)) {
    message("! Singular fit")
  }

  class(model) <- c("jlme", class(model))
  model

}

is_jlmer <- function(x) {
  is_jl(x, "MixedModel")
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
