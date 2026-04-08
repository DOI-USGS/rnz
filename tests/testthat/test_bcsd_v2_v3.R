# Smoke tests: pizzarr ships paired Zarr v2 and v3 copies of the same
# bcsd dataset (`bcsd_v2.zarr`, `bcsd_v3.zarr`). The whole point of the
# NZ-1.0 abstraction is that the inquiry/read API behaves identically
# regardless of the underlying Zarr storage version. Lock that in by
# walking the public surface against both stores and asserting equality.

skip_if_no_bcsd <- function() {
  skip_if_not_installed("pizzarr")
  if (!exists("pizzarr_sample", where = asNamespace("pizzarr"),
              inherits = FALSE)) {
    skip("pizzarr::pizzarr_sample() not available")
  }
}

open_bcsd_pair <- function() {
  v2 <- pizzarr::pizzarr_sample("bcsd_v2")
  v3 <- pizzarr::pizzarr_sample("bcsd_v3")
  list(v2 = open_nz(v2), v3 = open_nz(v3))
}

test_that("inq_nz_source matches between bcsd_v2 and bcsd_v3", {
  skip_if_no_bcsd()
  z <- open_bcsd_pair()

  expect_equal(inq_nz_source(z$v2), inq_nz_source(z$v3))
})

test_that("inq_grp matches between bcsd_v2 and bcsd_v3", {
  skip_if_no_bcsd()
  z <- open_bcsd_pair()

  expect_equal(inq_grp(z$v2), inq_grp(z$v3))
})

test_that("inq_dim matches between bcsd_v2 and bcsd_v3", {
  skip_if_no_bcsd()
  z <- open_bcsd_pair()

  ndims <- inq_nz_source(z$v2)$ndims
  for (i in z_seq(ndims)) {
    expect_equal(inq_dim(z$v2, i), inq_dim(z$v3, i))
  }
})

test_that("inq_var matches between bcsd_v2 and bcsd_v3", {
  skip_if_no_bcsd()
  z <- open_bcsd_pair()

  nvars <- inq_nz_source(z$v2)$nvars
  for (i in z_seq(nvars)) {
    expect_equal(inq_var(z$v2, i), inq_var(z$v3, i))
  }
})

test_that("inq_att matches between bcsd_v2 and bcsd_v3", {
  skip_if_no_bcsd()
  z <- open_bcsd_pair()

  src <- inq_nz_source(z$v2)
  for (vid in c(-1L, z_seq(src$nvars))) {
    n <- if (vid == -1L) src$ngatts else inq_var(z$v2, vid)$natts
    for (aid in z_seq(n)) {
      expect_equal(inq_att(z$v2, vid, aid),
                   inq_att(z$v3, vid, aid))
    }
  }
})

test_that("get_att matches between bcsd_v2 and bcsd_v3", {
  skip_if_no_bcsd()
  z <- open_bcsd_pair()

  expect_equal(get_att(z$v2, "global", "Conventions"),
               get_att(z$v3, "global", "Conventions"))

  expect_equal(get_att(z$v2, "latitude", "long_name"),
               get_att(z$v3, "latitude", "long_name"))

  expect_equal(get_att(z$v2, "pr", "units"),
               get_att(z$v3, "pr", "units"))
})

test_that("get_var matches between bcsd_v2 and bcsd_v3", {
  skip_if_no_bcsd()
  z <- open_bcsd_pair()

  for (nm in c("latitude", "longitude", "time", "pr", "tas")) {
    expect_equal(get_var(z$v2, nm), get_var(z$v3, nm))
  }
})

test_that("get_var with start/count matches between bcsd_v2 and bcsd_v3", {
  skip_if_no_bcsd()
  z <- open_bcsd_pair()

  # `pr` dim order in zarr is (time, latitude, longitude); take a small
  # interior slab so we exercise the start/count code path on both
  # storage versions.
  expect_equal(
    get_var(z$v2, "pr", start = c(2, 3, 4), count = c(3, 5, 6)),
    get_var(z$v3, "pr", start = c(2, 3, 4), count = c(3, 5, 6))
  )
})

test_that("nzdump matches between bcsd_v2 and bcsd_v3", {
  skip_if_no_bcsd()
  z <- open_bcsd_pair()

  capture.output(out2 <- nzdump(z$v2))
  capture.output(out3 <- nzdump(z$v3))
  expect_equal(out2, out3)
})
