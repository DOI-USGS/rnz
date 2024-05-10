z <- open_zarr(z_dir())

test_that("inq store", {
  expect_error(inq_store(z_dir), "z must be a zarr group")

  expect_equal(inq_store(z),
               list(ndims = 3L,
                    nvars = 5L,
                    ngatts = 30L,
                    format = "DirectoryStore"))

})

test_that("inq grp", {

  expect_equal(inq_grp(z),
               list(grps = list(),
                    name = "/",
                    fullname = "/",
                    dimids = c(0, 1, 2),
                    varids = c(0, 1, 2, 3, 4),
                    ngatts = 30L))
})

test_that("inq dim", {
  expect_equal(inq_dim(z, 0),
               list(id = 0, name = "latitude", length = 33L))

  expect_equal(inq_dim(z, 0),
               inq_dim(z, "latitude"))
})


test_that("inq var", {
  expect_equal(inq_var(z, "pr"),
               list(id = 2, name = "pr", type = "<f4",
                    ndims = 3L, dimids = numeric(0), natts = 5L))

  expect_equal(inq_var(z, "pr"),
               inq_var(z, 2))

  expect_error(inq_var(z, c(1,2)))
})


test_that("inq att", {
  expect_equal(inq_att(z, "pr", "units"),
               list(id = 3, name = "units", type = "character", length = 1L))

  expect_error(inq_att(z, 2, 4), "index")

  expect_equal(inq_att(z, 2, 3),
               inq_att(z, "pr", "units"))

  expect_equal(inq_att(z, -1, 2),
               list(id = 2, name = "Conventions", type = "character", length = 1L))

  expect_equal(inq_att(z, -1, 2),
               inq_att(z, "global", "Conventions"))

  expect_error(inq_att(z, "pr", "br"), "attribute not found")
})
