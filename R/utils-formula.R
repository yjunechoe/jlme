to_jl_formula_str <- function(x) {
  x <- use_zerocorr(x)
  x <- use_protect(x)
}

use_protect <- function(x) {
  if ("I" %in% all.names(x)) {
    rrapply::rrapply(
      x,
      condition = function(x, .xpos) {
        identical(x, quote(I)) &&
          (tail(.xpos, 1) == 1)
      },
      f = returnq(protect),
      how = "replace"
    )
  }
}

use_zerocorr <- function(x) {
  if ("||" %in% all.names(x)) {
    x <- rrapply::rrapply(x, is_parens_outside_doublebar, returnq(zerocorr), how = "replace")
    x <- rrapply::rrapply(x, is_doublebar_inside_parens, returnq(`|`), how = "replace")
  }
  x
}

#' @keywords internal
returnq <- function(x) {
  eval(substitute(function(...) quote(x)))
}

#' @keywords internal
is_parens_outside_doublebar <- function(x, .xsiblings) {
  identical(x, quote(`(`)) &&
    identical(.xsiblings[[2]][[1]], quote(`||`))
}

#' @keywords internal
is_doublebar_inside_parens <- function(x, .xparents, n = 1) {
  identical(x, quote(`||`)) && {
    object <- evalq(object, parent.frame(n))
    doublebar_parent <- as.integer(head(.xparents, -2))
    list(object[[doublebar_parent]][[1]]) %in% expression(`(`, zerocorr)
  }
}
