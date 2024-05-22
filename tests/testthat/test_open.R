z <- z_demo()

test_that("open example", {
  bcsd <- open_zarr(z)

  expect_equal(class(bcsd), c("ZarrGroup", "R6"))

  zarr <- pizzarr::DirectoryStore$new(z)

  bcsd <- open_zarr(zarr)

  expect_equal(class(bcsd), c("ZarrGroup", "R6"))
})

vcr::use_cassette("open_http", {
  test_that("open http", {
    url <- "https://raw.githubusercontent.com/DOI-USGS/rnz/main/inst/extdata/bcsd.zarr/"

    z <- open_zarr(url)

    expect_equal(class(z), c("ZarrGroup", "R6"))
  })
})
