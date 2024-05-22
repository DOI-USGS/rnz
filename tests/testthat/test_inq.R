test_that("inq store", {
  z <- open_zarr(z_demo())

  expect_error(inq_store(z_demo), "z must be a zarr group")

  expect_equal(inq_store(z),
               list(ndims = 3L,
                    nvars = 5L,
                    ngatts = 30L,
                    format = "DirectoryStore"))

})

test_that("inq grp", {

  z <- open_zarr(z_demo())

  expect_equal(inq_grp(z),
               list(grps = list(),
                    name = "/",
                    fullname = "/",
                    dimids = c(0, 1, 2),
                    varids = c(0, 1, 2, 3, 4),
                    ngatts = 30L))
})

test_that("inq dim", {
  z <- open_zarr(z_demo())

  expect_equal(inq_dim(z, 0),
               list(id = 0, name = "latitude", length = 33L))

  expect_equal(inq_dim(z, 0),
               inq_dim(z, "latitude"))
})


test_that("inq var", {
  z <- open_zarr(z_demo())

  expect_equal(inq_var(z, "pr"),
               list(id = 2, name = "pr", type = "<f4",
                    ndims = 3L, dimids = c(2,0,1), natts = 4L))

  expect_equal(inq_var(z, "pr"),
               inq_var(z, 2))

  expect_error(inq_var(z, c(1,2)))
})


test_that("inq att", {
  z <- open_zarr(z_demo())

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



test_that("inq dim when no coord var", {
  # inspiration
  # "https://usgs.osn.mghpcc.org/mdmf/gdp/hawaii_present.zarr"

  s <- pizzarr::MemoryStore$new()

  r <- pizzarr::zarr_create_group(store = s)

  a <- array(data=1:30, dim=c(2, 3, 5))
  i <- array(data=1:2, dim=c(2, 1))
  j <- array(data=1:3, dim=c(3, 1))
  t <- array(data=1:5, dim=c(5, 1))

  r$create_dataset("data", data = a, shape=dim(a))
  r$create_dataset("i", data = i, shape=dim(i))
  r$create_dataset("j", data = j, shape=dim(j))
  r$create_dataset("t", data = t, shape=dim(t))

  r$get_item("data")$get_attrs()$set_item("_ARRAY_DIMENSIONS", list("x", "y", "t"))

  r$get_item("i")$get_attrs()$set_item("_ARRAY_DIMENSIONS", list("x", "y"))
  r$get_item("j")$get_attrs()$set_item("_ARRAY_DIMENSIONS", list("x", "y"))
  r$get_item("t")$get_attrs()$set_item("_ARRAY_DIMENSIONS", list("t"))

  expect_equal(inq_store(r), list(ndims = 3L, nvars = 4L, ngatts = 0L, format = "MemoryStore"))

  expect_equal(inq_dim(r, 0), list(id = 0, name = "x", length = 2))

  expect_equal(inq_dim(r, 1), list(id = 1, name = "y", length = 3))

  expect_equal(inq_dim(r, 2), list(id = 2, name = "t", length = 5))

  expect_equal(inq_var(r, 0)$dimids, c(0, 1, 2))

  expect_equal(inq_var(r, 1)$dimids, c(0, 1))

  expect_equal(inq_var(r, 2)$dimids, c(0, 1))

  expect_equal(inq_var(r, 3)$dimids, c(2))

  out <- zdump(r)

  expect_equal(out,
               c("zarr {", "dimensions:", "x = 2 ;", "y = 3 ;", "t = 5 ;", "variables:",
                 "\t<f8 data(x, y, t) ;", "\t<f8 i(x, y) ;", "\t<f8 j(x, y) ;",
                 "\t<f8 t(t) ;", "", "// global attributes:", "}"))


})
