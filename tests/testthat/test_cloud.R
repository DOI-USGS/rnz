# Cloud (s3:// and gs://) store tests.
#
# These need the r-universe pizzarr build -- the zarrs backend with the `s3`
# or `gcs` feature -- and network access. See helpers.R for `have_s3()`,
# `have_gcs()`, and the fixture addresses.
#
# Each store is reachable at both a cloud URL and an HTTPS URL serving the
# same bytes, so the HTTPS route is the reference: anything the cloud path
# returns must match it. That is what pins the zero-based, stop-exclusive
# range translation and the C-to-F axis order in R/cloud_source.R.
#
# The HTTPS reference builds a pizzarr ZarrArray, and both fixtures are
# Blosc-compressed, so it needs the blosc R package. The cloud paths decode
# in Rust and do not.

skip_unless_s3 <- function() {
  skip_if_not_installed("pizzarr")
  skip_if(!have_s3(), "pizzarr zarrs backend with s3 feature not available")
  skip_on_cran()
  skip_on_ci()
}

skip_unless_gcs <- function() {
  skip_if_not_installed("pizzarr")
  skip_if(!have_gcs(), "pizzarr zarrs backend with gcs feature not available")
  skip_on_cran()
  skip_on_ci()
}

# ---------------------------------------------------------------------------
# s3://
# ---------------------------------------------------------------------------

test_that("open_nz opens an s3:// store", {
  skip_unless_s3()

  withr::local_envvar(c(AWS_ENDPOINT = gridmet_endpoint))

  z <- open_nz(gridmet_s3)
  withr::defer(close_nz(z))

  expect_s3_class(z, "NZCloud")
  expect_s3_class(z, "ZarrGroup")

  src <- inq_nz_source(z)
  expect_equal(src$format, "S3Store")
  expect_equal(src$ndims, 3)
  expect_true(src$nvars > 0)
})

test_that("a store without consolidated metadata errors clearly", {
  skip_unless_s3()

  withr::local_envvar(c(AWS_ENDPOINT = gridmet_endpoint))

  z <- open_nz("s3://mdmf/gdp/not-a-real-store.zarr")

  expect_s3_class(z, "try-error")
  expect_match(conditionMessage(attr(z, "condition")),
               "consolidated metadata")
})

test_that("an explicit RNetCDF backend is rejected for a cloud store", {
  skip_if_not_installed("pizzarr")

  expect_error(open_nz(gridmet_s3, backend = "RNetCDF"), "pizzarr")
  expect_error(open_nz(ecco_gs, backend = "RNetCDF"), "pizzarr")
})

test_that("inquiry over s3:// matches the same store over HTTPS", {
  skip_unless_s3()
  skip_if_not_installed("crul")
  skip_if_not_installed("blosc")

  withr::local_envvar(c(AWS_ENDPOINT = gridmet_endpoint))

  s3 <- open_nz(gridmet_s3)
  withr::defer(close_nz(s3))

  http <- open_nz(gridmet_https)
  skip_if(inherits(http, "try-error"), "HTTPS reference store unreachable")

  expect_equal(inq_nz_source(s3)$ndims, inq_nz_source(http)$ndims)
  expect_equal(inq_nz_source(s3)$nvars, inq_nz_source(http)$nvars)
  expect_equal(inq_nz_source(s3)$ngatts, inq_nz_source(http)$ngatts)

  expect_equal(inq_grp(s3), inq_grp(http))

  # variable and dimension ids have to line up, or every id-based call
  # below would be comparing different things
  expect_equal(get_vars(s3), get_vars(http))
  expect_equal(get_unique_dims(s3), get_unique_dims(http))
  expect_equal(get_all_dims(s3), get_all_dims(http))
  expect_equal(get_dim_size(s3), get_dim_size(http))

  for (i in z_seq(3)) expect_equal(inq_dim(s3, i), inq_dim(http, i))

  for (v in c("lat", "lon", "time", "precipitation_amount")) {
    expect_equal(inq_var(s3, v), inq_var(http, v))
  }

  expect_equal(inq_att(s3, "lat", "units"), inq_att(http, "lat", "units"))
  expect_equal(get_att(s3, "lat", "units"), get_att(http, "lat", "units"))
  expect_equal(get_att(s3, "lat", 0), get_att(http, "lat", 0))
})

test_that("reads over s3:// match the same store over HTTPS", {
  skip_unless_s3()
  skip_if_not_installed("crul")
  skip_if_not_installed("blosc")

  withr::local_envvar(c(AWS_ENDPOINT = gridmet_endpoint))

  s3 <- open_nz(gridmet_s3)
  withr::defer(close_nz(s3))

  http <- open_nz(gridmet_https)
  skip_if(inherits(http, "try-error"), "HTTPS reference store unreachable")

  # 1D, whole array and offset slices
  expect_equal(get_var(s3, "lat"), get_var(http, "lat"))
  expect_equal(get_var(s3, "lat", 1, 5), get_var(http, "lat", 1, 5))
  expect_equal(get_var(s3, "lat", 3, 4), get_var(http, "lat", 3, 4))

  # 3D: a 1D array cannot expose a transposed axis order, and an offset
  # start cannot be confused with a zero start
  expect_equal(get_var(s3, "precipitation_amount", c(1, 1, 1), c(2, 3, 4)),
               get_var(http, "precipitation_amount", c(1, 1, 1), c(2, 3, 4)))

  expect_equal(get_var(s3, "precipitation_amount", c(5, 10, 20), c(2, 3, 4)),
               get_var(http, "precipitation_amount", c(5, 10, 20), c(2, 3, 4)))

  # packed int16 with scale_factor / add_offset
  expect_equal(
    get_var(s3, "precipitation_amount", c(5, 10, 20), c(2, 3, 4),
            unpack = TRUE),
    get_var(http, "precipitation_amount", c(5, 10, 20), c(2, 3, 4),
            unpack = TRUE))
})

test_that("nzdump works over s3://", {
  skip_unless_s3()

  withr::local_envvar(c(AWS_ENDPOINT = gridmet_endpoint))

  z <- open_nz(gridmet_s3)
  withr::defer(close_nz(z))

  out <- capture.output(nzdump(z))

  expect_equal(out[1], "zarr {")
  expect_true(any(grepl("^lat = 585 ;$", out)))
})

test_that("close_nz drops the cached zarrs handle", {
  skip_unless_s3()

  withr::local_envvar(c(AWS_ENDPOINT = gridmet_endpoint))

  z <- open_nz(gridmet_s3)

  # handles are cached by URL on the Rust side; TRUE means one was removed
  expect_true(pizzarr::zarrs_close_store(gridmet_s3))

  expect_invisible(close_nz(z))
})

# ---------------------------------------------------------------------------
# gs://
# ---------------------------------------------------------------------------

test_that("open_nz opens a gs:// store", {
  skip_unless_gcs()

  # GCS has no anonymous mode by default -- object_store always attempts
  # authentication unless told not to.
  withr::local_envvar(c(GOOGLE_SKIP_SIGNATURE = "true"))

  z <- open_nz(ecco_gs)
  withr::defer(close_nz(z))

  expect_s3_class(z, "NZCloud")

  src <- inq_nz_source(z)
  expect_equal(src$format, "GcsStore")
  expect_equal(src$ndims, 3)
  expect_equal(sort(get_vars(z)), c("basin_mask", "face", "i", "j"))
})

test_that("inquiry over gs:// matches the same store over HTTPS", {
  skip_unless_gcs()
  skip_if_not_installed("crul")
  skip_if_not_installed("blosc")

  withr::local_envvar(c(GOOGLE_SKIP_SIGNATURE = "true"))

  gs <- open_nz(ecco_gs)
  withr::defer(close_nz(gs))

  http <- open_nz(ecco_https)
  skip_if(inherits(http, "try-error"), "HTTPS reference store unreachable")

  expect_equal(inq_grp(gs), inq_grp(http))
  expect_equal(get_vars(gs), get_vars(http))
  expect_equal(get_unique_dims(gs), get_unique_dims(http))
  expect_equal(get_all_dims(gs), get_all_dims(http))
  expect_equal(get_dim_size(gs), get_dim_size(http))

  for (i in z_seq(3)) expect_equal(inq_dim(gs, i), inq_dim(http, i))

  for (v in c("face", "i", "j", "basin_mask")) {
    expect_equal(inq_var(gs, v), inq_var(http, v))
    expect_equal(get_attributes(gs, v), get_attributes(http, v))
  }

  expect_equal(inq_att(gs, "i", "axis"), inq_att(http, "i", "axis"))
  expect_equal(get_att(gs, "i", "axis"), get_att(http, "i", "axis"))
})

test_that("reads over gs:// match the same store over HTTPS", {
  skip_unless_gcs()
  skip_if_not_installed("crul")
  skip_if_not_installed("blosc")

  withr::local_envvar(c(GOOGLE_SKIP_SIGNATURE = "true"))

  gs <- open_nz(ecco_gs)
  withr::defer(close_nz(gs))

  http <- open_nz(ecco_https)
  skip_if(inherits(http, "try-error"), "HTTPS reference store unreachable")

  expect_equal(get_var(gs, "face"), get_var(http, "face"))
  expect_equal(get_var(gs, "i", 1, 5), get_var(http, "i", 1, 5))

  # basin_mask is big-endian `>f4`, which the gridMET fixture does not cover
  expect_equal(get_var(gs, "basin_mask", c(1, 1, 1), c(2, 3, 4)),
               get_var(http, "basin_mask", c(1, 1, 1), c(2, 3, 4)))

  expect_equal(get_var(gs, "basin_mask", c(3, 10, 20), c(2, 3, 4)),
               get_var(http, "basin_mask", c(3, 10, 20), c(2, 3, 4)))
})
