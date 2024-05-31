print(system.time({
  jlme_setup(restart = TRUE, verbose = TRUE)
}))

library(broom)
library(broom.mixed)

expect_similar_models <- function(x, y, ignore_names = FALSE) {
  deframe <- function(df) {
    df <- tidy(df)
    if (ignore_names) return(df$estimate)
    vec <- signif(stats::setNames(df$estimate, df$term), 1)
    vec[order(names(vec))]
  }
  if (is.list(x) && length(x) == 2 && missing(y)) {
    y <- x[[2]]
    x <- x[[1]]
  }
  expect_equal(deframe(x), deframe(y))
}

test_that("reproduces `lm()` and `lmer()` outputs", {

  fm1 <- mpg ~ hp
  jmod1 <- jlm(fm1, mtcars)
  expect_s3_class(jmod1, "jlme")
  expect_s3_class(tidy(jmod1), "data.frame")
  expect_s3_class(glance(jmod1), "data.frame")
  rmod1 <- lm(fm1, mtcars)
  expect_similar_models(jmod1, rmod1)

  fm2 <- Reaction ~ Days + (Days | Subject)
  jmod2 <- jlmer(fm2, lme4::sleepstudy, REML = TRUE)
  expect_s3_class(jmod2, "jlme")
  expect_s3_class(tidy(jmod2), "data.frame")
  expect_s3_class(glance(jmod2), "data.frame")
  rmod2 <- lme4::lmer(fm2, lme4::sleepstudy)
  expect_similar_models(jmod2, rmod2)

  fm3 <- r2 ~ Anger + (1|id)
  jmod3 <- jlmer(fm3, lme4::VerbAgg, family = "binomial")
  rmod3 <- lme4::glmer(fm3, lme4::VerbAgg, family = "binomial")
  expect_similar_models(jmod3, rmod3)

})

test_that("preserves contrasts", {

  df <- mtcars[, c("mpg", "cyl", "am")]

  rj_fit <- function(df) {
    fm <- mpg ~ cyl * am
    list(r = lm(fm, df), j = jlm(fm, df))
  }

  # Numeric covariates
  expect_similar_models(rj_fit(df))

  # Default contrasts
  df$cyl <- as.factor(df$cyl)
  expect_similar_models(rj_fit(df))
  df$am <- as.factor(df$am)
  expect_similar_models(rj_fit(df))

  # Custom contrasts (sum)
  contrasts(df$am) <- contr.sum(2)
  expect_similar_models(rj_fit(df))

  # Custom contrasts (helmert; named)
  contrasts(df$cyl) <- contr.helmert(3)
  colnames(contrasts(df$cyl)) <- c("4vs6", "4&6vs8")
  expect_similar_models(rj_fit(df))

})

test_that("formula conversions work", {

  if (requireNamespace("JuliaFormulae", quietly = TRUE)) {
    zcp <- Reaction ~ Days + (1 + Days || Subject)
    j_zcp <- jlmer(zcp, lme4::sleepstudy, REML = TRUE)
    r_zcp <- lme4::lmer(zcp, lme4::sleepstudy)
    expect_similar_models(j_zcp, r_zcp)

    protect <- Reaction ~ I(Days + 100) + (1 | Subject)
    j_protect <- jlmer(protect, lme4::sleepstudy, REML = TRUE)
    r_protect <- lme4::lmer(protect, lme4::sleepstudy)
    expect_similar_models(j_protect, r_protect, ignore_names = TRUE)

    interactions <- mpg ~ am + cyl + am:cyl
    j_interactions <- jlm(interactions, mtcars)
    r_interactions <- lm(interactions, mtcars)
    expect_similar_models(j_interactions, r_interactions)
  } else {
    cat("Skipping formula conversion test - JuliaFormulae not installed.\n")
  }

})

stop_julia()
