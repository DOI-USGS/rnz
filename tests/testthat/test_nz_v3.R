test_that("v3 dimension discovery and zarr.json filtering", {
  skip_if_not_installed("pizzarr")

  z <- make_v3_dim_fixture()

  # zarr.json must NOT be reported as a variable.
  expect_false("zarr.json" %in% get_vars(z))

  src <- inq_nz_source(z)
  expect_equal(src$ndims, 3L)
  expect_equal(src$nvars, 4L)  # data + x + y + t, no zarr.json

  dim_names <- vapply(0:2, function(i) inq_dim(z, i)$name, character(1))
  expect_setequal(dim_names, c("x", "y", "t"))

  v <- inq_var(z, "data")
  expect_equal(v$ndims, 3L)
  expect_equal(length(v$dimids), 3L)

  out <- nzdump(z)
  expect_true(any(grepl("data\\(x, y, t\\)", out)))
})

test_that("_FillValue attribute takes precedence over storage fill_value", {
  skip_if_not_installed("pizzarr")

  z <- make_v2_fillvalue_fixture()
  v <- get_var(z, "v")

  # _FillValue = -999 cell must be masked.
  expect_true(is.nan(v[1, 2]) || is.na(v[1, 2]))
  # storage fill_value = -1 cell must NOT be masked.
  expect_false(is.nan(v[2, 2]) || is.na(v[2, 2]))
  expect_equal(v[2, 2], -1)
})

test_that("_nczarr_attr is suppressed from attribute listings", {
  skip_if_not_installed("pizzarr")

  z <- make_v2_nczarr_attr_fixture()

  expect_equal(inq_var(z, "v")$natts, 2L)

  out <- nzdump(z)
  expect_false(any(grepl("_nczarr_attr", out)))
})

test_that("inq_att consults _nczarr_attr.types for attribute type", {
  skip_if_not_installed("pizzarr")

  z <- make_v2_nczarr_attr_fixture()

  expect_equal(inq_att(z, "v", "scale_factor")$type, "<f4")
  expect_equal(inq_att(z, "v", "add_offset")$type,   "<f8")
})

test_that("is_nz() detects NZ-1.0 convention declarations", {
  skip_if_not_installed("pizzarr")

  expect_true(rnz:::is_nz(make_v2_conventions_fixture("NZ-1.0",
                                                      key = "conventions")))
  expect_true(rnz:::is_nz(make_v2_conventions_fixture("CF-1.8 NZ-1.0",
                                                      key = "Conventions")))
  expect_false(rnz:::is_nz(make_v2_conventions_fixture("CF-1.8",
                                                       key = "conventions")))
})

test_that("inq_nz_source ndims is the number of unique dims", {
  skip_if_not_installed("pizzarr")

  z <- make_v2_dimcount_fixture()

  src <- inq_nz_source(z)
  expect_equal(src$ndims, 4L)
  expect_equal(src$nvars, 2L)
})

test_that("scalar arrays round-trip through the inquiry/read API", {
  skip_if_not_installed("pizzarr")

  z <- make_v2_scalar_fixture()

  # Scalar must not contribute to the dimension count: only `v(x, y)`
  # defines named dimensions, so the group has exactly two unique dims.
  src <- inq_nz_source(z)
  expect_equal(src$ndims, 2L)
  expect_equal(src$nvars, 2L)

  # Scalar variable: rank 0, no dimids, but otherwise a normal NUG var.
  iv <- inq_var(z, "s")
  expect_equal(iv$ndims, 0L)
  expect_length(iv$dimids, 0L)

  # get_var on a scalar returns the bare value, no dim attribute.
  out <- get_var(z, "s")
  expect_equal(out, 42)
  expect_null(dim(out))

  # nzdump must render the scalar with empty dimension parens and not
  # error trying to look up a non-existent dim id.
  dump <- capture.output(nzdump(z))
  expect_true(any(grepl("s\\(\\)", dump)))
})
