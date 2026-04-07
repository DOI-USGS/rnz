# Failing-test scaffold for the queued NZ-1.0 / v3 functional changes.
# Each block is gated with tdd_guard() until the matching change lands.
# See TODO.md "rnz TDD pre-work PR" for the scoreboard.

tdd_guard <- function() {
  if (!nzchar(Sys.getenv("RNZ_TDD_RUN"))) {
    skip("TDD pre-work tests - set RNZ_TDD_RUN=1 to run")
  }
}

test_that("v3 dimension discovery and zarr.json filtering", {
  tdd_guard()
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
  tdd_guard()
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
  tdd_guard()
  skip_if_not_installed("pizzarr")

  z <- make_v2_nczarr_attr_fixture()

  expect_equal(inq_var(z, "v")$natts, 2L)

  out <- nzdump(z)
  expect_false(any(grepl("_nczarr_attr", out)))
})

test_that("inq_att consults _nczarr_attr.types for attribute type", {
  tdd_guard()
  skip_if_not_installed("pizzarr")

  z <- make_v2_nczarr_attr_fixture()

  expect_equal(inq_att(z, "v", "scale_factor")$type, "<f4")
  expect_equal(inq_att(z, "v", "add_offset")$type,   "<f8")
})

test_that("is_nz() detects NZ-1.0 convention declarations", {
  tdd_guard()
  skip_if_not_installed("pizzarr")

  expect_true(is_nz(make_v2_conventions_fixture("NZ-1.0",
                                                key = "conventions")))
  expect_true(is_nz(make_v2_conventions_fixture("CF-1.8 NZ-1.0",
                                                key = "Conventions")))
  expect_false(is_nz(make_v2_conventions_fixture("CF-1.8",
                                                 key = "conventions")))

  expect_false(isTRUE(is_nz(NULL)))
  expect_false(is_nz(nc))
})

test_that("inq_nz_source ndims is the number of unique dims", {
  tdd_guard()
  skip_if_not_installed("pizzarr")

  z <- make_v2_dimcount_fixture()

  src <- inq_nz_source(z)
  expect_equal(src$ndims, 4L)
  expect_equal(src$nvars, 2L)
})

test_that("scalar arrays", {
  skip("scalar arrays - low priority, unscheduled")
})
