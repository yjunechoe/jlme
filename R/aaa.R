#' @keywords internal
.jlme <- new.env(parent = emptyenv())

julia_cli <- function(x) {
  utils::tail(system2("julia", x, stdout = TRUE), 1L)
}
julia_detect_cores <- function() {
  as.integer(julia_cli('-q -e "println(Sys.CPU_THREADS);"'))
}
is_setup <- function() isTRUE(.jlme$is_setup)

#' Check Julia requirements for jlme
#'
#' @return Boolean
#' @export
#' @examples
#' julia_setup_ok()
julia_setup_ok <- function() {
  JuliaConnectoR::juliaSetupOk()
}

#' Check Julia requirements for jlme
#'
#' @return Boolean
#' @export
#' @examples
#' if (FALSE) stop_julia()
stop_julia <- function() {
  JuliaConnectoR::stopJulia()
  .jlme$is_setup <- FALSE
}

#' Set up Julia connection for jlme
#'
#' @param ... Unused
#' @param restart Whether to run `stop_julia()` first, before attempting setup
#' @param threads Number of threads
#'
#' @return Boolean
#' @export
#' @examples
#' if (interactive()) jlme_setup()
jlme_setup <- function(..., restart = FALSE, threads = NULL) {
  stopifnot(julia_setup_ok())
  if (restart) stop_julia()
  start_julia(..., threads = threads)
  load_libs()
}

start_julia <- function(..., max_threads = 7L, threads = NULL) {
  JULIA_NUM_THREADS <- Sys.getenv("JULIA_NUM_THREADS")
  if (!nzchar(JULIA_NUM_THREADS)) JULIA_NUM_THREADS <- NULL
  nthreads <- threads %||% JULIA_NUM_THREADS %||%
    (min(max_threads, julia_detect_cores() - 1L))
  if (is.null(.jlme$is_setup)) stop_julia()
  if (is_setup()) {
    stop("There is already a connection to Julia established. Run `stop_julia()` first.")
  }
  msg <- sprintf("Starting Julia with %i thread(s).", nthreads)
  if (isTRUE(list(...)$startup)) packageStartupMessage(msg) else message(msg)
  if (nthreads > 1) {
    Sys.setenv("JULIA_NUM_THREADS" = nthreads)
    suppressMessages(JuliaConnectoR::startJuliaServer())
    Sys.setenv("JULIA_NUM_THREADS" = JULIA_NUM_THREADS %||% "")
  } else {
    suppressMessages(JuliaConnectoR::startJuliaServer())
  }
  .jlme$is_setup <- TRUE
  invisible(TRUE)
}

load_libs <- function() {
  JuliaConnectoR::juliaEval("
    using JuliaFormatter;
    using StatsModels;
    using GLM;
    using MixedModels;
  ")
  invisible(TRUE)
}

#' Binding to the GLM.jl namespace
#' @export
GLM <- new.env(parent = emptyenv())

delayedAssign("GLM", local({
  if (is_setup()) JuliaConnectoR::juliaImport("GLM")
}))

#' Binding to the MixedModels.jl namespace
#' @export
MixedModels <- new.env(parent = emptyenv())

delayedAssign("MixedModels", local({
  if (is_setup()) JuliaConnectoR::juliaImport("MixedModels")
}))
