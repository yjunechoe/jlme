stop_julia()

test_that("Setup functions", {

  expect_type(
    check_julia_ok(),
    "logical"
  )

  suppressMessages({
    expect_message({
      jlme_status()
    })
  })

})

stop_julia()
