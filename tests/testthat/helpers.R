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
# Cloud store fixtures (test_cloud.R).
#
# Both stores are public, consolidated, and reachable at two addresses -- a
# cloud URL and the equivalent HTTPS URL serving the same bytes. That pairing
# is what makes the cloud route checkable: the HTTPS route is the reference.
#
# gridMET: USGS meteorology on an Open Storage Network pod, reached with an
# alternate S3 endpoint. ECCO_basins: a small Pangeo mask on Google Cloud
# Storage, whose `basin_mask` is big-endian `>f4`.
# ---------------------------------------------------------------------------

gridmet_s3 <- "s3://mdmf/gdp/gridMET.zarr"
gridmet_https <- "https://usgs.osn.mghpcc.org/mdmf/gdp/gridMET.zarr"
gridmet_endpoint <- "https://usgs.osn.mghpcc.org"

ecco_gs <- "gs://pangeo-data/ECCO_basins.zarr"
ecco_https <- "https://storage.googleapis.com/pangeo-data/ECCO_basins.zarr"

# The cloud routes need the zarrs backend with the relevant feature compiled
# in and pizzarr >= 0.2.1 for zarrs_get_key(). The CRAN pizzarr build has
# neither, so tests and vignette chunks gate on this.
have_cloud <- function(feature) {
  if(!requireNamespace("pizzarr", quietly = TRUE)) return(FALSE)
  if(!requireNamespace("jsonlite", quietly = TRUE)) return(FALSE)
  if(!exists("zarrs_get_key", envir = asNamespace("pizzarr"))) return(FALSE)

  feats <- tryCatch(pizzarr::pizzarr_compiled_features(),
                    error = function(e) character(0))

  feature %in% feats
}

have_s3 <- function() have_cloud("s3")
have_gcs <- function() have_cloud("gcs")

# The cloud adapter itself only needs the zarrs backend and a store it can
# reach. zarrs opens plain filesystem paths through the same code path as
# s3:// and gs://, so the offline fixtures below need no cloud feature.
have_zarrs <- function() {
  requireNamespace("pizzarr", quietly = TRUE) &&
    requireNamespace("jsonlite", quietly = TRUE) &&
    exists("zarrs_get_key", envir = asNamespace("pizzarr")) &&
    "filesystem" %in% tryCatch(pizzarr::pizzarr_compiled_features(),
                               error = function(e) character(0))
}

# ---------------------------------------------------------------------------
# Offline cloud-adapter fixtures.
#
# Pointing nz_cloud_group() at a local store exercises the whole adapter --
# metadata fetch through zarrs_get_key(), parsing, and reads through
# zarrs_get_subset() -- with no network, and pizzarr reading the same store
# is the oracle. That covers format handling; the gridMET and ECCO tests
# cover transport.
#
# pizzarr cannot write consolidated metadata, so these builders add it. v3
# inlines every child's zarr.json under `consolidated_metadata` in the root
# zarr.json, matching zarr-python's flat layout. v2 writes a `.zmetadata`
# key holding every `.zarray` and `.zattrs`.
# ---------------------------------------------------------------------------

read_json_file <- function(path) {
  jsonlite::fromJSON(paste(readLines(path, warn = FALSE), collapse = "\n"),
                     simplifyVector = FALSE)
}

write_json_file <- function(x, path) {
  writeLines(jsonlite::toJSON(x, auto_unbox = TRUE, digits = NA,
                              null = "null"), path)
}

consolidate_v3 <- function(dir) {
  root <- read_json_file(file.path(dir, "zarr.json"))

  nodes <- list()

  for(nm in list.dirs(dir, full.names = FALSE, recursive = FALSE)) {
    f <- file.path(dir, nm, "zarr.json")
    if(file.exists(f)) nodes[[nm]] <- read_json_file(f)
  }

  root$consolidated_metadata <- list(kind = "inline",
                                     must_understand = FALSE,
                                     metadata = nodes)

  write_json_file(root, file.path(dir, "zarr.json"))

  dir
}

consolidate_v2 <- function(dir) {
  keys <- gsub("\\\\", "/", list.files(dir, recursive = TRUE,
                                       all.files = TRUE))
  keys <- keys[basename(keys) %in% c(".zarray", ".zattrs", ".zgroup")]

  nodes <- list()

  for(k in keys) nodes[[k]] <- read_json_file(file.path(dir, k))

  write_json_file(list(zarr_consolidated_format = 1, metadata = nodes),
                  file.path(dir, ".zmetadata"))

  dir
}

# A consolidated v3 store: a 3D array on (x, y, t) plus a coordinate array
# per dimension, carrying group attributes, variable attributes, a
# `_FillValue`, and packing attributes. Returns the store path.
make_v3_cloud_fixture <- function(dir) {
  s <- pizzarr::DirectoryStore$new(dir)
  r <- pizzarr::zarr_create_group(store = s, zarr_format = 3L)

  d <- array(as.double(1:30), dim = c(2, 3, 5))
  d[1, 1, 1] <- -999

  r$create_dataset("data", data = d, shape = dim(d),
                   dimension_names = c("x", "y", "t"))

  for(nm in c("x", "y", "t")) {
    n <- c(x = 2, y = 3, t = 5)[[nm]]
    r$create_dataset(nm, data = array(as.double(seq_len(n)), dim = n),
                     shape = n, dimension_names = nm)
  }

  atts <- r$get_item("data")$get_attrs()
  atts$set_item("units", "mm")
  atts$set_item("long_name", "test data")
  atts$set_item("_FillValue", -999)
  atts$set_item("scale_factor", 10)
  atts$set_item("add_offset", 100)

  r$get_item("x")$get_attrs()$set_item("units", "degrees_east")
  r$get_item("t")$get_attrs()$set_item("units", "days since 1999-01-01")

  r$get_attrs()$set_item("conventions", "NZ-1.0")
  r$get_attrs()$set_item("title", "v3 cloud fixture")

  consolidate_v3(dir)
}

# A consolidated v3 store covering the dtype and byte-order mapping. v3
# stores a type name plus a `bytes` codec carrying byte order, and the
# adapter has to rebuild the numpy-style string pizzarr itself reports.
# Single-byte types get a `bytes` codec with no configuration at all.
make_v3_dtype_fixture <- function(dir) {
  s <- pizzarr::DirectoryStore$new(dir)
  r <- pizzarr::zarr_create_group(store = s, zarr_format = 3L)

  for(dt in c(">f4", "<f8", ">i4", "<i2", "|i1")) {
    r$create_dataset(gsub("[<>|]", "", dt),
                     data = array(as.double(1:6), dim = c(2, 3)),
                     shape = c(2, 3), dtype = dt,
                     dimension_names = c("a", "b"))
  }

  consolidate_v3(dir)
}

# The same dataset as a consolidated v2 store, so the v2 branch of the
# adapter is regression-covered offline too. Dimension labels go in
# `_ARRAY_DIMENSIONS` rather than `dimension_names`.
make_v2_cloud_fixture <- function(dir) {
  s <- pizzarr::DirectoryStore$new(dir)
  r <- pizzarr::zarr_create_group(store = s)

  d <- array(as.double(1:30), dim = c(2, 3, 5))
  d[1, 1, 1] <- -999

  r$create_dataset("data", data = d, shape = dim(d))
  r$get_item("data")$get_attrs()$set_item("_ARRAY_DIMENSIONS",
                                          list("x", "y", "t"))

  for(nm in c("x", "y", "t")) {
    n <- c(x = 2, y = 3, t = 5)[[nm]]
    r$create_dataset(nm, data = array(as.double(seq_len(n)), dim = n),
                     shape = n)
    r$get_item(nm)$get_attrs()$set_item("_ARRAY_DIMENSIONS", list(nm))
  }

  atts <- r$get_item("data")$get_attrs()
  atts$set_item("units", "mm")
  atts$set_item("long_name", "test data")
  atts$set_item("_FillValue", -999)
  atts$set_item("scale_factor", 10)
  atts$set_item("add_offset", 100)

  r$get_item("x")$get_attrs()$set_item("units", "degrees_east")
  r$get_item("t")$get_attrs()$set_item("units", "days since 1999-01-01")

  r$get_attrs()$set_item("conventions", "NZ-1.0")
  r$get_attrs()$set_item("title", "v2 cloud fixture")

  consolidate_v2(dir)
}

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
