test_that("dump", {
  store <- rnz::z_demo()

  dump <- capture.output(nzdump(store))

  expect_true(grepl("zarr", dump[1]))

  nc <- system.file("extdata", "bcsd_obs_1999.nc", package = "rnz")

  dump <- capture.output(nzdump(nz))

  expect_true(grepl("netcdf", dump[1]))
})
