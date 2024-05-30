test_that("open example", {
  skip_if_not_installed("pizzarr")

  expect_error(z_demo("bork"))

  expect_error(open_nz(z_path, backend = "bork"))

  bcsd <- open_nz(z_path, backend = "pizzarr")

  expect_equal(class(bcsd), c("ZarrGroup", "R6"))

  zarr <- pizzarr::DirectoryStore$new(z_path)

  bcsd <- open_nz(zarr)

  expect_equal(class(bcsd), c("ZarrGroup", "R6"))
})

test_that("open http", {
  skip_if_not_installed("pizzarr")

  skip_if_offline(host = "raw.githubusercontent.com")

  url <- "https://raw.githubusercontent.com/DOI-USGS/rnz/main/inst/extdata/bcsd.zarr/"

  z <- rnz::open_nz(url)

  expect_equal(class(z), c("ZarrGroup", "R6"))
})

test_that("open netcdf", {
  skip_if_not_installed("RNetCDF")

  expect_message(expect_warning(bcsd <- open_nz(nc_file), "Failed to open as zarr"), "Opened as NetCDF")

  expect_equal(class(bcsd), "NetCDF")

  expect_silent(open_nz(nc_file, backend = "RNetCDF"))

})
