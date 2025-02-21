# # NOTE: this compares a zarr copy and a netcdf copy of the same data.
# # while these are the same data, they are not in the same axis order.
#
# # in zarr, the x, y, t dimensions are in 3, 2, 1 order
# c(inq_var(z, "longitude")$dimid,
#   inq_var(z, "latitude")$dimid,
#   inq_var(z, "time")$dimid)
# inq_var(z, "pr")$dimid
#
# # in netcdf, the x, y, t dimensions are in 1, 2, 3 order
# c(inq_var(nc, "longitude")$dimid,
#   inq_var(nc, "latitude")$dimid,
#   inq_var(nc, "time")$dimid)
# inq_var(nc, "pr")$dimid

test_that("get_att", {
  skip_if_not_installed("pizzarr")

  expect_equal(
    get_att(zarr_test, -1, 2),
    "CF-1.0")

  expect_equal(
    get_att(zarr_test, -1, 2),
    get_att(zarr_test, "global", "Conventions"))

  expect_equal(get_att(zarr_test, 0, 3),
               "Latitude")

  expect_equal(get_att(zarr_test, 0, 3),
               get_att(zarr_test, "latitude", "long_name"))

  expect_equal(get_att(nc_file, "latitude", "long_name"),
               get_att(zarr_test, "latitude", "long_name"))

  expect_equal(get_att(nc_file, -1, "Conventions"),
               get_att(zarr_test, -1, "Conventions"))

  expect_equal(get_att(nc_file, "global", "Conventions"),
               get_att(zarr_test, "global", "Conventions"))

  expect_null(get_att(NULL))

})

test_that("get_var", {
  skip_if_not_installed("pizzarr")

  latitude <- get_var(zarr_test, 0)

  expect_equal(class(latitude), "array")

  expect_equal(dim(latitude), 33)

  time <- get_var(zarr_test, "time")

  expect_equal(dim(time), 12)

  longitude <- get_var(zarr_test, "longitude")

  expect_equal(class(longitude), "array")

  expect_equal(dim(longitude), 81)

  pr_inq <- inq_var(zarr_test, "pr")

  # T, Y, X (some hardcoding for tests)
  expect_equal(pr_inq$dimids, c(2, 0, 1))

  pr <- get_var(zarr_test, "pr")

  expect_equal(dim(pr), c(dim(time), dim(latitude), dim(longitude)))

  expect_equal(get_var(nc_file, "latitude"),
               get_var(zarr_test, "latitude"))

  expect_null(get_var(NULL))

  expect_error(get_var(zarr_test, "pr", c(1)), "must specify count")

  expect_error(get_var(zarr_test, "pr", c(1, 1), c(1, 1)), "start and count must have length")

  expect_equal(get_var(zarr_test, "pr"),
               get_var(zarr_test, "pr", c(1,1,1), c(-1, -1, -1)))

  pr_nc <- get_var(nc_file, "pr")

  # need to permute order from zarr
  # axis order is switched in metadata in zarr AND in the array
  expect_true(all(aperm(pr, c(3, 2, 1)) == pr_nc, na.rm = TRUE))

  expect_equal(get_var(nc, var = "pr",
                       start = c(1,1,5), count = c(3,3,1)),

               aperm(get_var(zarr_test, var = "pr",
                         start = c(5, 1, 1), count = c(1, 3, 3)), c(2, 1)))

  expect_equal(get_var(nc, var = "pr",
                       start = c(1,1,5), count = c(3,3,1), collapse = FALSE),

               aperm(get_var(zarr_test, var = "pr",
                       start = c(5, 1, 1), count = c(1, 3, 3),
                       collapse = FALSE), c(3, 2, 1)))
})

test_that("get dimid order", {

  z_latitude <- get_var(zarr_test, "latitude")

  z_longitude <- get_var(zarr_test, "longitude")

  n_latitude <- get_var(nc, "latitude")

  n_longitude <- get_var(nc, "longitude")

  expect_equal(z_latitude, n_latitude)

  expect_equal(z_longitude, n_longitude)

  z_latitude <- get_var(zarr_test, "latitude", 1, 10)

  z_longitude <- get_var(zarr_test, "longitude", 1, 20)

  n_latitude <- get_var(nc, "latitude", 1, 10)

  n_longitude <- get_var(nc, "longitude", 1, 20)

  expect_equal(z_latitude, n_latitude)

  expect_equal(z_longitude, n_longitude)

  z_pr <- get_var(zarr_test, "pr")

  n_pr <- get_var(nc, "pr")

  expect_equal(aperm(z_pr, c(3, 2, 1)), n_pr)

  # say we want an xy slice first find the xy dimids
  x_dimid <- inq_var(zarr_test, "longitude")$dimid
  y_dimid <- inq_var(zarr_test, "latitude")$dimid
  t_dimid <- inq_var(zarr_test, "time")$dimid
  pr_dimid <- inq_var(zarr_test, "pr")$dimid

  dimid_order <- match(c(x_dimid, y_dimid, t_dimid), pr_dimid)

  # now select a full x y slice for 1 t
  z_pr <- get_var(zarr_test, "pr",
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

  expect_equal(aperm(z_pr, c(2, 1)), n_pr)
})

test_that("scale offset", {
  temp_test <- tempdir()

  file.copy(z_path, temp_test, recursive = TRUE)

  path <- file.path(temp_test, basename(z_path))

  z <- rnz::open_nz(path)

  z$get_item("pr")$get_attrs()$set_item("scale_factor", 0.1)

  expect_equal(get_var(nc_file, "pr"),
               aperm(get_var(z, "pr"), c(3,2,1)))

  expect_equal(get_var(nc_file, "pr"),
               aperm(get_var(z, "pr", unpack = TRUE), c(3,2,1)) * 10)

  z$get_item("pr")$get_attrs()$set_item("add_offset", 100)

  expect_equal(get_var(nc_file, "pr"),
               aperm((get_var(z, "pr", unpack = TRUE) - 100) * 10,
                     c(3, 2, 1)))
})
