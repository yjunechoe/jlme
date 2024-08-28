#' Parametric bootstrap for Julia mixed effects models
#'
#' @param x A Julia MixedModel of class `jlme`
#' @param nsim Number of simulations
#' @param seed Seed for the random number generator (Random.MersenneTwister)
#' @param ... Not implemented
#' @param ftol_rel A convergence criterion. Defaults to a reduced-precision
#'  target of 1e-8.
#'
#' @return MixedModels.parametricboostrap() output as object of class `jlmeboot`
#' @export
#'
#' @examples
#' jmod <- jlmer(Reaction ~ Days + (Days | Subject), lme4::sleepstudy)
#' tidy(jmod)
#'
#' samp <- parametricbootstrap(jmod, nsim = 100L, seed = 42L)
#' samp
#'
#' tidy(samp)
parametricbootstrap <- function(x, nsim, seed, ...,
                                ftol_rel = 1e-8) {
  stopifnot(is_jlmer(x))
  if (!"Random" %in% loaded_libs()) {
    jl_evalf('Pkg.add("Random"; io=devnull); using Random;')
  }
  rng <- jl_evalf("Random.MersenneTwister(%i)", as.integer(seed))
  nsim <- jl_evalf("%i", as.integer(nsim))
  opts <- jl_evalf("(;ftol_rel=%f)", as.double(ftol_rel))

  args_list <- list(
    "MixedModels.parametricbootstrap",
    rng, nsim, x,
    optsum_overrides = opts
  )

  samp <- do.call(JuliaConnectoR::juliaCall, args_list)

  class(samp) <- c("jlmeboot", class(samp))
  attr(samp, "jmod") <- x
  samp

}

#' @rdname jlme_tidiers
#' @method tidy jlmeboot
#' @export
tidy.jlmeboot <- function(x, effects = c("var_model", "ran_pars", "fixed"),
                          ...) {

  stopifnot(
    "`x` must be output of `parametricbootstrap()`" = inherits(x, "jlmeboot")
  )
  effects <- match.arg(effects)

  res_list <- jl_get(JuliaConnectoR::juliaCall("MixedModels.shortestcovint", x))
  res <- do.call(rbind.data.frame, res_list)

  res$group[res$group == "residual"] <- "Residual"
  res$names[res$group == "Residual"] <- "Observation"
  res$effect <- ifelse(res$type == "β", "fixed", "ran_pars")
  res$term <- res$names
  res$term[res$type == "σ"] <- paste0("sd__", res$term[res$type == "σ"])
  res$term[res$type == "ρ"] <- paste0("cor__", res$term[res$type == "ρ"])
  res$term[res$type == "ρ"] <- gsub(x = res$term[res$type == "ρ"], ", ", ".")
  res$term <- gsub(" & ", ":", res$term)
  res$term <- gsub(": ", "", res$term)
  names(res)[names(res) %in% c("lower", "upper")] <- c("conf.low", "conf.high")

  tidied <- tidy(attr(x, "jmod"))
  keys <- c("effect", "group", "term")

  combined <- maybe_as_tibble(merge(
    tidied[, c(keys, "estimate")],
    res[, c(keys, "conf.low", "conf.high")]
  ))
  combined <- combined[match(tidied$term, combined$term),]

  switch(effects,
    var_model = combined,
    combined[combined$effect == effects, ]
  )

}
