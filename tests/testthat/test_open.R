z <- z_demo()

test_that("open example", {
  bcsd <- open_zarr(z)

  expect_equal(class(bcsd), c("ZarrGroup", "R6"))

  zarr <- pizzarr::DirectoryStore$new(z)

  bcsd <- open_zarr(zarr)

  expect_equal(class(bcsd), c("ZarrGroup", "R6"))
})
