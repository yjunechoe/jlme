skip_conditionally <- function() {
  if (!nzchar(Sys.which("julia"))) {
    testthat::skip("No Julia installation detected.")
  }
  if (!JuliaConnectoR::juliaSetupOk()) {
    testthat::skip("Julia installed but not discoverable via {JuliaConnectoR}.")
  }
  if (!julia_version_compatible()) {
    testthat::skip("Julia version >=1.8 required.")
  }
  invisible()
}
