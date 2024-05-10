z_dir <- system.file("extdata", "bcsd_obs_1999.zarr", package = "rnz")

z <- open_zarr(z_dir)

test_that("get_att", {
  expect_equal(
    get_att(z, -1, 2),
    "CF-1.0")

  expect_equal(
    get_att(z, -1, 2),
    get_att(z, "global", "Conventions"))

  expect_equal(get_att(z, 0, 3),
               "Latitude")

  expect_equal(get_att(z, 0, 3),
               get_att(z, "latitude", "long_name"))

})

test_that("get_var", {
  latitude <- get_var(z, 0)

  expect_equal(class(latitude), "array")

  expect_equal(dim(latitude), 33)

  pr <- get_var(z, "pr")

  expect_equal(dim(pr), c(12, 33, 81))
})
