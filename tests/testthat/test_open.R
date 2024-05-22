test_that("open example", {
  z <- z_demo()

  bcsd <- open_zarr(z)

  expect_equal(class(bcsd), c("ZarrGroup", "R6"))

  zarr <- pizzarr::DirectoryStore$new(z)

  bcsd <- open_zarr(zarr)

  expect_equal(class(bcsd), c("ZarrGroup", "R6"))
})

test_that("open http", {
  skip_if_offline(host = "https://raw.githubusercontent.com")

  url <- "https://raw.githubusercontent.com/DOI-USGS/rnz/main/inst/extdata/bcsd.zarr/"

  z <- rnz::open_zarr(url)

  expect_equal(class(z), c("ZarrGroup", "R6"))
})
