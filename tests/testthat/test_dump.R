test_that("dump", {
  store <- rnz::z_demo()

  dump <- capture.output(nzdump(store))

  expect_true(grepl("zarr", dump[1]))

  dump <- capture.output(nzdump(nc_file))

  expect_true(grepl("netcdf", dump[1]))

  expect_null(nzdump(NULL))

  expect_warning(nzdump("/borked"), "could't interpret")
})
