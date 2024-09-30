skip_conditionally()

system.time({
  print(JuliaConnectoR::startJuliaServer())
})

test_that("Basic interop functions work", {

  # `jl()` eval string
  expect_true(is_jl(jl("1")))
  expect_equal(
    jl("1 .+ [1, 3]", .R = TRUE),
    1 + c(1, 3)
  )
  expect_equal(
    jl("1 .+ [1, 3]", .R = TRUE),
    jl_get(jl("1 .+ [1, 3]"))
  )

  # round-trip
  expect_equal(
    1L,
    jl_get(jl_put(1L))
  )

  # `jl()` interpolation
  expect_equal(
    jl("%i", 1, .R = TRUE),
    jl("x", x = 1L, .R = TRUE)
  )

  # Auto protect vectors unless `I()`
  dict <- jl_get(jl_dict(a = 1, b = I(2)))
  expect_equal(
    sapply(dict$values, attr, "JLDIM"),
    list(1, NULL)
  )

  # Auto splice
  expect_equal(
    dict,
    jl_get(jl_dict(list(a = 1, b = I(2))))
  )

})

stop_julia()
