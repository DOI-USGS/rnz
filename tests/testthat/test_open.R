test_that("open example", {
  skip_if_not_installed("pizzarr")

  z <- z_demo()

  bcsd <- open_nz(z, backend = "pizzarr")

  expect_equal(class(bcsd), c("ZarrGroup", "R6"))

  zarr <- pizzarr::DirectoryStore$new(z)

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

  nc <- system.file("extdata", "bcsd_obs_1999.nc", package = "rnz")

  expect_warning(bcsd <- open_nz(nc), "Failed to open as zarr")

  expect_equal(class(bcsd), "NetCDF")

  expect_silent(open_nz(nc, backend = "RNetCDF"))

})
