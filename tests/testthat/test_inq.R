test_that("inq", {
  skip_if_not_installed("pizzarr")

  expect_null(inq_nz_source(NULL))

  expect_equal(inq_nz_source(z_path), inq_nz_source(zarr_test))

  expect_equal(inq_nz_source(zarr_test),
               list(ndims = 3L,
                    nvars = 5L,
                    ngatts = 30L,
                    format = "DirectoryStore"))

  expect_equal(inq_grp(zarr_test),
               list(grps = list(),
                    name = "/",
                    fullname = "/",
                    dimids = c(0, 1, 2),
                    varids = c(0, 1, 2, 3, 4),
                    ngatts = 30L))

  expect_null(inq_grp(NULL))

  expect_equal(inq_dim(zarr_test, 0),
               list(id = 0, name = "latitude", length = 33L))

  expect_equal(inq_dim(zarr_test, 0),
               inq_dim(zarr_test, "latitude"))

  expect_null(inq_dim(NULL))

  expect_error(inq_dim(zarr_test, "nope"), "dimension not found")

  expect_equal(inq_var(zarr_test, "pr"),
               list(id = 2, name = "pr", type = "<f4",
                    ndims = 3L, dimids = c(2,0,1), natts = 4L))

  expect_equal(inq_var(zarr_test, "pr"),
               inq_var(zarr_test, 2))

  expect_error(inq_var(zarr_test, c(1,2)))

  expect_null(inq_var(NULL))

  expect_equal(inq_att(zarr_test, "pr", "units"),
               list(id = 3, name = "units", type = "character", length = 1L))

  expect_error(inq_att(zarr_test, 2, 4), "index")

  expect_equal(inq_att(zarr_test, 2, 3),
               inq_att(zarr_test, "pr", "units"))

  expect_equal(inq_att(zarr_test, -1, 2),
               list(id = 2, name = "Conventions", type = "character", length = 1L))

  expect_equal(inq_att(zarr_test, -1, 2),
               inq_att(zarr_test, "global", "Conventions"))

  expect_error(inq_att(zarr_test, "pr", "br"), "attribute not found")

  expect_null(inq_att(NULL))

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

  expect_equal(inq_nz_source(r), list(ndims = 3L, nvars = 4L, ngatts = 0L, format = "MemoryStore"))

  expect_equal(inq_dim(r, 0), list(id = 0, name = "x", length = 2))

  expect_equal(inq_dim(r, 1), list(id = 1, name = "y", length = 3))

  expect_equal(inq_dim(r, 2), list(id = 2, name = "t", length = 5))

  expect_equal(inq_var(r, 0)$dimids, c(0, 1, 2))

  expect_equal(inq_var(r, 1)$dimids, c(0, 1))

  expect_equal(inq_var(r, 2)$dimids, c(0, 1))

  expect_equal(inq_var(r, 3)$dimids, c(2))

  out <- nzdump(r)

  expect_equal(out,
               c("zarr {", "dimensions:", "x = 2 ;", "y = 3 ;", "t = 5 ;", "variables:",
                 "\t<f8 data(x, y, t) ;", "\t<f8 i(x, y) ;", "\t<f8 j(x, y) ;",
                 "\t<f8 t(t) ;", "", "// global attributes:", "}"))


})

test_that("inq netcdf", {

  expect_s3_class(nc, "NetCDF")

  inq <- inq_nz_source(nc)

  expect_equal(inq, inq_nz_source(nc_file))

  expect_equal(inq[1:3],
               inq_nz_source(zarr_test)[1:3])

  inq <- inq_grp(nc)

  expect_equal(inq[2:9], inq_grp(nc_file)[2:9])

  expect_equal(inq[2:5],
               inq_grp(zarr_test)[1:4])

  inq <- inq_dim(nc, 0)

  expect_equal(inq, inq_dim(nc_file, "latitude"))

  expect_equal(inq[1:3], inq_dim(zarr_test, "latitude")[1:3])

  inq <- inq_var(nc, 0)

  expect_equal(inq, inq_var(nc_file, 0))

  expect_equal(inq, inq_var(nc_file, "latitude"))

  expect_equal(inq[c(1:2, 4:6)],
               inq_var(zarr_test, "latitude")[c(1:2, 4:6)])

  inq <- inq_att(nc, 0, 0)

  expect_equal(inq, inq_att(nc_file, 0, 0))

  expect_equal(inq, inq_att(nc_file, "latitude", "standard_name"))

  # TODO get more inq_att to match up?
  expect_equal(inq[c(2)],
               inq_att(zarr_test, "latitude", "standard_name")[c(2)])
})
