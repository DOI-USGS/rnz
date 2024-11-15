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

  expect_equal(dim(pr), c(81, 33, 12))

  expect_equal(get_var(nc_file, "latitude"),
               get_var(z, "latitude"))

  expect_null(get_var(NULL))

  expect_error(get_var(z, "pr", c(1)), "must specify count")

  expect_error(get_var(z, "pr", c(1, 1), c(1, 1)), "start and count must have length")

  expect_equal(get_var(z, "pr"),
               get_var(z, "pr", c(1,1,1), c(-1, -1, -1)))

  pr_nc <- get_var(nc_file, "pr")

  expect_true(all(pr == pr_nc, na.rm = TRUE))

  expect_equal(get_var(nc, var = "pr",
                       start = c(1,1,5), count = c(3,3,1)),

               get_var(z, var = "pr",
                         start = c(5, 1, 1), count = c(1, 3, 3)))

  expect_equal(get_var(nc, var = "pr",
                       start = c(1,1,5), count = c(3,3,1), collapse = FALSE),

               get_var(z, var = "pr",
                       start = c(5, 1, 1), count = c(1, 3, 3), collapse = FALSE))
})

test_that("get dimid order", {

  z_latitude <- get_var(z, "latitude")

  z_longitude <- get_var(z, "longitude")

  n_latitude <- get_var(nc, "latitude")

  n_longitude <- get_var(nc, "longitude")

  expect_equal(z_latitude, n_latitude)

  expect_equal(z_longitude, n_longitude)

  z_latitude <- get_var(z, "latitude", 1, 10)

  z_longitude <- get_var(z, "longitude", 1, 20)

  n_latitude <- get_var(nc, "latitude", 1, 10)

  n_longitude <- get_var(nc, "longitude", 1, 20)

  expect_equal(z_latitude, n_latitude)

  expect_equal(z_longitude, n_longitude)

  z_pr <- get_var(z, "pr")

  n_pr <- get_var(nc, "pr")

  expect_equal(z_pr, n_pr)

  # say we want an xy slice first find the xy dimids
  x_dimid <- inq_var(z, "longitude")$dimid
  y_dimid <- inq_var(z, "latitude")$dimid
  t_dimid <- inq_var(z, "time")$dimid
  pr_dimid <- inq_var(z, "pr")$dimid

  dimid_order <- match(c(x_dimid, y_dimid, t_dimid), pr_dimid)

  # now select a full x y slice for 1 t
  z_pr <- get_var(z, "pr",
                  start = c(1, 1, 1)[dimid_order],
                  count = c(NA, NA, 1)[dimid_order])

  x_dimid <- inq_var(nc, "longitude")$dimid
  y_dimid <- inq_var(nc, "latitude")$dimid
  t_dimid <- inq_var(nc, "time")$dimid
  pr_dimid <- inq_var(nc, "pr")$dimid

  dimid_order <- match(c(x_dimid, y_dimid, t_dimid), pr_dimid)

  n_pr <- get_var(nc, "pr",
                  start = c(1, 1, 1)[dimid_order],
                  count = c(NA, NA, 1)[dimid_order])

  expect_equal(z_pr, n_pr)
})
