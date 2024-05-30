test_that("get_att", {
  skip_if_not_installed("pizzarr")

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

  expect_equal(get_att(nc_file, "latitude", "long_name"),
               get_att(z, "latitude", "long_name"))

  expect_equal(get_att(nc_file, -1, "Conventions"),
               get_att(z, -1, "Conventions"))

  expect_equal(get_att(nc_file, "global", "Conventions"),
               get_att(z, "global", "Conventions"))

  expect_null(get_att(NULL))

})

test_that("get_var", {
  skip_if_not_installed("pizzarr")

  latitude <- get_var(z, 0)

  expect_equal(class(latitude), "array")

  expect_equal(dim(latitude), 33)

  pr <- get_var(z, "pr")

  expect_equal(dim(pr), c(12, 33, 81))

  expect_equal(get_var(nc_file, "latitude"),
               get_var(z, "latitude"))

  expect_null(get_var(NULL))

  expect_error(get_var(z, "pr", c(1)), "must specify count")

  expect_error(get_var(z, "pr", c(1, 1), c(1, 1)), "start and count must have length")

  expect_equal(get_var(z, "pr"),
               get_var(z, "pr", c(1,1,1), c(-1, -1, -1)))

  pr_nc <- get_var(nc_file, "pr")

  pr <- pr |> aperm(c(3,2,1))

  expect_true(all(pr == pr_nc, na.rm = TRUE))

  expect_equal(get_var(nc, var = "pr",
                       start = c(1,1,5), count = c(3,3,1)),

               get_var(z, var = "pr",
                       start = c(5, 1, 1), count = c(1, 3, 3)) |>
                 aperm(c(3, 2, 1))) # TODO #3
})
