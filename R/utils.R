`%||%` <- function(lhs, rhs) if (is.null(lhs)) rhs else lhs

jl_format <- function(x, ...) {
  JuliaConnectoR::juliaCall("JuliaFormatter.format_text", x, align_matrix = TRUE, ...)
}

is_fct_custom_contrast <- function(x) {
  is.factor(x) && !is.null(attr(x, "contrasts"))
}
