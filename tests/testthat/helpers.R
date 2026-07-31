z_path <- z_demo()

if(requireNamespace("pizzarr", quietly = TRUE)) {
  # The consolidated-metadata fixture is a remote http store. Only reach for
  # it under the same conditions its tests run under: pizzarr's HttpStore
  # needs crul, and CRAN checks must not touch the network. Tests that use
  # `zarr_consolidated` guard with skip_if_not_installed("crul") and
  # skip_on_cran(), so it is fine for this to stay unset.
  if(requireNamespace("crul", quietly = TRUE) &&
     identical(Sys.getenv("NOT_CRAN"), "true")) {
    zarr_consolidated <- open_nz("https://raw.githubusercontent.com/DOI-USGS/rnz/main/inst/extdata/bcsd.zarr")
  }

  zarr_test <- open_nz(z_path)
}

nc_file <- z_demo(format = "netcdf")

nc <- open_nz(nc_file, backend = "RNetCDF")

# ---------------------------------------------------------------------------
# Fixture builders for the NZ-1.0 / v3 TDD scaffold (test_nz_v3.R).
# All builders return a ZarrGroup backed by an in-memory MemoryStore.
# All require pizzarr (>= 0.1.3) for the v3 dimension_names API.
# ---------------------------------------------------------------------------

# v3 in-memory fixture: a 3D `data` array plus three 1D coordinate arrays,
# each with populated `dimension_names`. Used to pin v3 dimension discovery
# and zarr.json filtering behavior.
make_v3_dim_fixture <- function(arrays = NULL, group_attrs = list()) {
  if (is.null(arrays)) {
    arrays <- list(
      data = list(data = array(as.double(1:30), dim = c(2, 3, 5)),
                  dim_names = c("x", "y", "t")),
      x    = list(data = array(as.double(1:2),  dim = c(2)),
                  dim_names = c("x")),
      y    = list(data = array(as.double(1:3),  dim = c(3)),
                  dim_names = c("y")),
      t    = list(data = array(as.double(1:5),  dim = c(5)),
                  dim_names = c("t"))
    )
  }

  s <- pizzarr::MemoryStore$new()
  r <- pizzarr::zarr_create_group(store = s, zarr_format = 3L)

  # NB: do NOT pass `zarr_format = 3L` to create_dataset -- the parent group
  # already supplies it and a duplicate arg errors out.
  for (nm in names(arrays)) {
    spec <- arrays[[nm]]
    r$create_dataset(nm, data = spec$data, shape = dim(spec$data),
                     dimension_names = spec$dim_names)
  }

  for (k in names(group_attrs)) {
    r$get_attrs()$set_item(k, group_attrs[[k]])
  }

  r
}

# v2 in-memory fixture: a 2x3 array whose storage `fill_value` (-1) and
# attribute `_FillValue` (-999) point at distinct cells. Used to pin
# attribute-precedence masking in get_var().
make_v2_fillvalue_fixture <- function() {
  s <- pizzarr::MemoryStore$new()
  r <- pizzarr::zarr_create_group(store = s)

  a <- array(NA_real_, dim = c(2, 3))
  a[1, 1] <-    1
  a[2, 1] <-    2
  a[1, 2] <- -999    # _FillValue (attribute) sentinel
  a[2, 2] <-   -1    # storage fill_value sentinel
  a[1, 3] <-    3
  a[2, 3] <-    4

  r$create_dataset("v", data = a, shape = dim(a), fill_value = -1)
  r$get_item("v")$get_attrs()$set_item("_ARRAY_DIMENSIONS", list("x", "y"))
  r$get_item("v")$get_attrs()$set_item("_FillValue", -999)

  r
}

# v2 in-memory fixture: an array with packing attributes plus an
# `_nczarr_attr` annotation block carrying their precise types. Used to
# pin both `_nczarr_attr` suppression and inq_att type recovery.
make_v2_nczarr_attr_fixture <- function() {
  s <- pizzarr::MemoryStore$new()
  r <- pizzarr::zarr_create_group(store = s)

  a <- array(as.double(1:6), dim = c(2, 3))
  r$create_dataset("v", data = a, shape = dim(a))

  atts <- r$get_item("v")$get_attrs()
  atts$set_item("_ARRAY_DIMENSIONS", list("x", "y"))
  atts$set_item("scale_factor", 0.1)
  atts$set_item("add_offset", 100)
  atts$set_item("_nczarr_attr",
                list(types = list(scale_factor = "<f4",
                                  add_offset   = "<f8")))

  r
}

# v2 in-memory fixture: a minimal store whose root group has a
# `conventions` (or `Conventions`) attribute. Used to pin convention
# detection by is_nz().
make_v2_conventions_fixture <- function(conv_string, key = "conventions") {
  stopifnot(is.character(conv_string), length(conv_string) == 1)
  if (!key %in% c("conventions", "Conventions"))
    stop("key must be 'conventions' or 'Conventions'")

  s <- pizzarr::MemoryStore$new()
  r <- pizzarr::zarr_create_group(store = s)

  r$create_dataset("placeholder",
                   data = array(as.double(1:2), dim = c(2)),
                   shape = c(2))
  r$get_item("placeholder")$get_attrs()$set_item("_ARRAY_DIMENSIONS",
                                                 list("x"))

  r$get_attrs()$set_item(key, conv_string)

  r
}

# v2 in-memory fixture: builds a store from a name -> dimension-labels map,
# e.g. `list(a = "latitude", b = "lat")`. Used to pin exact (non-regex)
# dimension-label matching in get_rep_var.
make_v2_dim_named_fixture <- function(spec) {
  s <- pizzarr::MemoryStore$new()
  r <- pizzarr::zarr_create_group(store = s)

  for (nm in names(spec)) {
    shp <- rep(2L, length(spec[[nm]]))
    r$create_dataset(nm, data = array(as.double(1:prod(shp)), dim = shp),
                     shape = shp)
    r$get_item(nm)$get_attrs()$set_item("_ARRAY_DIMENSIONS",
                                        as.list(spec[[nm]]))
  }

  r
}

# v2 on-disk fixture: a packed array carrying `scale_factor` / `add_offset`.
# Returns the store path so the `character` method of get_var can be
# exercised, which is where `unpack` was being dropped.
make_v2_packed_path_fixture <- function(dir) {
  s <- pizzarr::DirectoryStore$new(dir)
  r <- pizzarr::zarr_create_group(store = s)

  a <- array(as.double(1:6), dim = c(2, 3))
  r$create_dataset("v", data = a, shape = dim(a))

  atts <- r$get_item("v")$get_attrs()
  atts$set_item("_ARRAY_DIMENSIONS", list("x", "y"))
  atts$set_item("scale_factor", 10)
  atts$set_item("add_offset", 100)

  dir
}

# v2 in-memory fixture: two 2D arrays on disjoint dims (x,y) and (z,t).
# Four unique dims, no array of rank > 2. Used to pin the unique-count
# fix in inq_nz_source$ndims.
make_v2_dimcount_fixture <- function() {
  s <- pizzarr::MemoryStore$new()
  r <- pizzarr::zarr_create_group(store = s)

  a1 <- array(as.double(1:6),  dim = c(2, 3))
  a2 <- array(as.double(1:20), dim = c(4, 5))

  r$create_dataset("a1", data = a1, shape = dim(a1))
  r$create_dataset("a2", data = a2, shape = dim(a2))

  r$get_item("a1")$get_attrs()$set_item("_ARRAY_DIMENSIONS", list("x", "y"))
  r$get_item("a2")$get_attrs()$set_item("_ARRAY_DIMENSIONS", list("z", "t"))

  r
}

# v2 in-memory fixture: a 2x3 dimensioned array `v(x, y)` plus a scalar
# array `s` (`shape: integer(0)`, `_ARRAY_DIMENSIONS: list()`). Pins
# NZ-1.0 scalar-array support: a 0-rank array must round-trip through
# inq_nz_source / inq_var / get_var / nzdump without erroring and must
# not contribute spurious entries to the dimension count.
make_v2_scalar_fixture <- function() {
  s <- pizzarr::MemoryStore$new()
  r <- pizzarr::zarr_create_group(store = s)

  v <- array(as.double(1:6), dim = c(2, 3))
  r$create_dataset("v", data = v, shape = dim(v))
  r$get_item("v")$get_attrs()$set_item("_ARRAY_DIMENSIONS", list("x", "y"))

  r$create_dataset("s", data = 42, shape = integer(0))
  r$get_item("s")$get_attrs()$set_item("_ARRAY_DIMENSIONS", list())

  r
}
