test_that("utils", {

  skip_if_not_installed("pizzarr")

  test_fun <- function(zarr) {

  expect_equal(get_all_dims(zarr),
               list(
                 latitude = list(name = "latitude"),
                 longitude = list(name = "longitude"),
                 pr = list(name = c("time", "latitude", "longitude")),
                 tas = list(name = c("time", "latitude", "longitude")),
                 time = list(name = "time")
               ))

    expect_equal(get_all_dims(zarr),
               list(
                 latitude = list(name = "latitude"),
                 longitude = list(name = "longitude"),
                 pr = list(name = c("time", "latitude", "longitude")),
                 tas = list(name = c("time", "latitude", "longitude")),
                 time = list(name = "time")
               ))

  expect_equal(get_array_dims(zarr, "pr", TRUE),
               list(name = c("time", "latitude", "longitude"),
                    length = c(12L, 33L, 81L)))

  expect_equal(get_array_dims(zarr, "pr", FALSE),
               list(name = c("time", "latitude", "longitude")))

  expect_equal(get_attributes(zarr, 0),
               list(
                 `_ARRAY_DIMENSIONS` = list("latitude"),
                 `_CoordinateAxisType` = "Lat",
                 axis = "Y",
                 bounds = "latitude_bnds",
                 long_name = "Latitude",
                 standard_name = "latitude",
                 units = "degrees_north"
               ))

  expect_equal(get_attributes(zarr, 0, noarray = TRUE),
               list(
                 `_CoordinateAxisType` = "Lat",
                 axis = "Y",
                 bounds = "latitude_bnds",
                 long_name = "Latitude",
                 standard_name = "latitude",
                 units = "degrees_north"
               ))

  expect_equal(get_coord_vars(zarr),
               c("latitude", "longitude", "time"))


  expect_equal(get_dim_size(zarr),
               list(
                 latitude = list(name = "latitude", length = 33L),
                 longitude = list(name = "longitude", length = 81L),
                 pr = list(name = c("time", "latitude", "longitude"), length = c(12L, 33L, 81L)),
                 tas = list(name = c("time", "latitude", "longitude"), length = c(12L, 33L, 81L)),
                 time = list(name = "time", length = 12L)
               ))

  expect_equal(get_rep_var(zarr, "latitude"),
               "latitude")

  expect_equal(get_unique_dims(zarr),
               c("latitude", "longitude", "time"))

  expect_equal(get_vars(zarr),
               c("latitude", "longitude", "pr", "tas", "time"))

  expect_equal(nodots(zarr$get_store()$listdir()),
               c("latitude", "longitude", "pr", "tas", "time"))

  expect_equal(var_char_to_id(zarr, "pr"), 2)

  expect_error(var_char_to_id(zarr, "br"), "variable br not found")

  expect_equal(att_char_to_id(zarr, "pr", "units"), 3)

  expect_equal(att_char_to_id(zarr, 2, "units"), 3)

  }

  test_fun(z)

  test_fun(zarr_consolidated)

})
