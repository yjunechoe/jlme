loadNamespace("broom")
loadNamespace("broom.mixed")

mod_deframe <- function(df, ignore_names) {
  df <- tidy(df) # resolves to appropriate method for {base}, {lme4}, {jlme}
  if (ignore_names) return(df$estimate)
  vec <- signif(stats::setNames(df$estimate, df$term), 1)
  vec[order(names(vec))]
}

expect_similar_models <- function(x, y, ignore_names = FALSE) {
  if (is.list(x) && length(x) == 2 && missing(y)) {
    y <- x[[2]]
    x <- x[[1]]
  }
  x_res <- mod_deframe(x, ignore_names)
  y_res <- mod_deframe(y, ignore_names)
  expect_equal(x_res, y_res)
}
