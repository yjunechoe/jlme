#' @keywords internal
.jlme <- new.env(parent = emptyenv())
is_setup <- function() isTRUE(.jlme$is_setup)
ensure_setup <- function() {
  if (!is_setup()) {
    jlme_setup(restart = FALSE)
  }
}

julia_cli <- function(x) {
  utils::tail(system2("julia", x, stdout = TRUE), 1L)
}

julia_version_compatible <- function() {
  as.package_version(julia_version()) >= "1.8"
}
julia_version <- function() {
  parse_julia_version(julia_cli("--version"))
}
parse_julia_version <- function(version) {
  gsub("^julia.version .*(\\d+\\.\\d+\\.\\d+).*$", "\\1", version)
}

julia_detect_cores <- function() {
  as.integer(julia_cli('-q -e "println(Sys.CPU_THREADS);"'))
}

#' @rdname jlme_setup
#' @export
stop_julia <- function() {
  JuliaConnectoR::stopJulia()
  .jlme$is_setup <- FALSE
  invisible(TRUE)
}

#' Set up Julia connection for jlme
#'
#' @param ... Unused
#' @param restart Whether to run `stop_julia()` first, before attempting setup
#' @param threads Number of threads to start Julia with. Defaults to `1`
#' @param verbose Whether to alert setup progress. Defaults to `interactive()`
#'
#' @return Invisibly returns `TRUE` on success
#' @export
#' @examplesIf interactive()
#' jlme_setup()
#' stop_julia()
jlme_setup <- function(..., restart = FALSE, threads = NULL,
                       verbose = interactive()) {
  stopifnot(
    "Failed to discover Julia installation" = JuliaConnectoR::juliaSetupOk(),
    "Julia version >=1.8 required." = julia_version_compatible()
  )
  if (restart) stop_julia()
  if (verbose) {
    .jlme_setup(..., threads = threads, verbose = verbose)
  } else {
    suppressMessages(.jlme_setup(..., threads = threads, verbose = verbose))
  }
  invisible(TRUE)
}

.jlme_setup <- function(..., threads = threads, verbose = FALSE) {
  start_julia(..., threads = threads)
  init_proj(verbose = verbose)
  load_libs()
  message("Successfully set up Julia connection.")
  invisible(TRUE)
}

start_julia <- function(..., threads = NULL) {
  JULIA_NUM_THREADS <- Sys.getenv("JULIA_NUM_THREADS")
  if (!nzchar(JULIA_NUM_THREADS)) JULIA_NUM_THREADS <- NULL
  nthreads <- threads %||% JULIA_NUM_THREADS %||% 1L
  if (is.null(.jlme$is_setup)) stop_julia()
  if (is_setup()) {
    stop("There is already a connection to Julia established. Run `stop_julia()` first.")
  }
  if (nthreads > 1) {
    message(sprintf("Starting Julia with %i threads ...", nthreads))
    Sys.setenv("JULIA_NUM_THREADS" = nthreads)
  } else {
    message(sprintf("Starting Julia (v%s) ...", julia_version()))
  }
  .jlme$port <- suppressMessages(JuliaConnectoR::startJuliaServer())
  Sys.setenv("JULIA_NUM_THREADS" = JULIA_NUM_THREADS %||% "")
  .jlme$is_setup <- TRUE
  invisible(TRUE)
}

init_proj <- function(..., verbose = FALSE) {
  jl_evalf('
    using Pkg;
    Pkg.activate(; temp=true, %1$s)
    Pkg.add(["JuliaFormatter", "StatsModels", "GLM", "MixedModels"]; %1$s)
  ', jl_io(verbose))
  .jlme$projdir <- dirname(jl_evalf("Base.active_project()"))
  invisible(TRUE)
}

load_libs <- function() {
  jl_evalf("
    using JuliaFormatter;
    using StatsModels;
    using GLM;
    using MixedModels;
  ")
  invisible(TRUE)
}
