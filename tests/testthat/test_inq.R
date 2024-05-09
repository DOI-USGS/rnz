z <- system.file("extdata", "bcsd_obs_1999.zarr", package = "rnz")

test_that("inq store", {
  expect_error(inq_store(z), "z must be a zarr group")

  expect_equal(inq_store(open_zarr(z)),
               list(ndims = 3L,
                    nvars = 5L,
                    ngatts = 30L,
                    format = "DirectoryStore"))

})

test_that("inq grp", {

  expect_equal(inq_grp(open_zarr(z)),
               list(grps = list(),
                    name = "/",
                    fullname = "/",
                    dimids = c(0, 1, 2),
                    varids = c(0, 1, 2, 3, 4),
                    ngatts = 30L))
})
