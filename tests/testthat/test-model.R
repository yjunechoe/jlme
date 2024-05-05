print(system.time({
  jlme_setup(restart = TRUE)
}))

test_that("model fitting works", {

  jmod1 <- jlm(mpg ~ hp, mtcars)
  expect_s3_class(jmod1, "jlme")
  expect_s3_class(tidy(jmod1), "data.frame")
  expect_s3_class(glance(jmod1), "data.frame")

  jmod2 <- jlmer(Reaction ~ Days + (Days | Subject), lme4::sleepstudy)
  expect_s3_class(jmod2, "jlme")
  expect_s3_class(tidy(jmod2), "data.frame")
  expect_s3_class(glance(jmod2), "data.frame")

})

stop_julia()
