# Cloud (s3:// and gs://) source support.
#
# pizzarr's S3Store and GcsStore are dispatch markers: they carry a URL and
# raise on get_item()/contains_item()/listdir(), so the store surface every
# helper in util.R depends on is not there. What is available is
# pizzarr::zarrs_get_key() for a single key and pizzarr::zarrs_get_subset()
# for array reads, both taking the cloud URL directly.
#
# That is enough. A consolidated store publishes `.zmetadata`, which holds
# every array's `.zarray` and `.zattrs` in one document -- shapes, dtypes,
# `_ARRAY_DIMENSIONS`, and attributes. Fetching that single key supplies
# everything the inquiry API needs.
#
# The objects below present the small slice of the pizzarr ZarrGroup surface
# that rnz actually calls, backed by that document. They are plain
# environments rather than R6 so the Zarr backend stays a Suggests-only
# dependency. The group carries class c("NZCloud", "ZarrGroup") so every
# existing `.ZarrGroup` method dispatches to it unchanged.

# URL schemes rnz reads through the zarrs backend.
nz_cloud_schemes <- "^(s3|gs)://"

# pizzarr's store class for a scheme, reported as `format` by
# inq_nz_source().
nz_cloud_store_class <- function(url) {
  if(grepl("^gs://", url)) "GcsStore" else "S3Store"
}

# Fetch and parse `.zmetadata` for a cloud store.
nz_cloud_metadata <- function(url) {
  if(!requireNamespace("pizzarr", quietly = TRUE))
    stop("pizzarr is required to open a cloud store")

  if(!requireNamespace("jsonlite", quietly = TRUE))
    stop("jsonlite is required to read cloud store metadata")

  if(!exists("zarrs_get_key", envir = asNamespace("pizzarr")))
    stop("this pizzarr build has no zarrs_get_key(); pizzarr >= 0.2.1 with ",
         "the zarrs backend is required to open ", url)

  raw_meta <- pizzarr::zarrs_get_key(url, ".zmetadata")

  if(is.null(raw_meta))
    stop("no consolidated metadata (.zmetadata) found at ", url, "\n",
         "  rnz can only inquire cloud stores that publish consolidated ",
         "metadata,\n  because the object store APIs offer no way to list ",
         "keys.")

  jsonlite::fromJSON(rawToChar(raw_meta), simplifyVector = FALSE)
}

# Zarr v2 writes non-finite fill values as JSON strings. pizzarr hands back
# the numeric, so match it -- `get_var()` compares data against this value.
nz_cloud_fill_value <- function(x) {
  if(is.null(x)) return(NULL)

  if(is.character(x)) {
    return(switch(x,
                  "NaN" = NaN,
                  "Infinity" = Inf,
                  "-Infinity" = -Inf,
                  x))
  }

  unlist(x)
}

# Attribute bag: `to_list()` and `get_item()` are the only methods used.
nz_cloud_attrs <- function(atts) {
  self <- new.env(parent = emptyenv())

  self$to_list <- function() atts
  self$get_item <- function(key) atts[[key]]

  self
}

# Read an array subset. `ranges` are zero-based, stop-exclusive, one per
# dimension -- the form zarrs_get_subset() takes. zarrs returns C-order data
# but pizzarr transposes to F-order on the Rust side, so array() is correct
# with no aperm().
nz_cloud_read <- function(url, name, ranges) {
  out <- pizzarr::zarrs_get_subset(url, name, ranges, NULL)

  array(out$data, dim = as.integer(out$shape))
}

# Array shim over one entry of the consolidated metadata.
nz_cloud_array <- function(url, name, meta) {
  zarray <- meta[[paste0(name, "/.zarray")]]

  if(is.null(zarray)) stop("array metadata not found for ", name)

  zattrs <- meta[[paste0(name, "/.zattrs")]]
  if(is.null(zattrs)) zattrs <- list()

  shape <- as.integer(unlist(zarray$shape))

  self <- new.env(parent = emptyenv())

  self$get_attrs <- function() nz_cloud_attrs(zattrs)
  self$get_shape <- function() shape
  self$get_ndim <- function() length(shape)
  self$get_dtype <- function() list(dtype = zarray$dtype)
  self$get_fill_value <- function() nz_cloud_fill_value(zarray$fill_value)

  # v2 carries dimension labels in `_ARRAY_DIMENSIONS`; NULL sends
  # get_array_dims() to that fallback.
  self$get_dimension_names <- function() NULL

  self$as.array <- function() {
    nz_cloud_read(url, name, lapply(shape, \(s) c(0L, s)))
  }

  # `sel` is a list of pizzarr Slice objects. Their start/stop are already
  # zero-based and stop-exclusive.
  self$get_item <- function(sel) {
    ranges <- lapply(sel, \(s) c(as.integer(s$start), as.integer(s$stop)))

    out <- nz_cloud_read(url, name, ranges)

    sliced <- new.env(parent = emptyenv())
    sliced$as.array <- function() out
    sliced
  }

  self
}

# Store shim. `format` in inq_nz_source() reads class(...)[1].
nz_cloud_store <- function(url, meta) {
  self <- new.env(parent = emptyenv())

  self$get_consolidated_metadata <- function() meta
  self$get_store_identifier <- function() url

  # Mirror HttpStore$listdir(): first path component of every metadata key,
  # deduplicated, with dot-keys dropped. Matching it keeps variable ids
  # identical between the cloud and HTTPS routes.
  self$listdir <- function(path = NA) {
    keys <- names(meta$metadata)
    out <- unique(vapply(strsplit(keys, "/"), \(x) x[1], ""))
    out[!grepl("^\\.", out)]
  }

  class(self) <- c(nz_cloud_store_class(url), "NZCloudStore")

  self
}

# Group adapter. Returned by open_nz() for an s3:// or gs:// URL.
nz_cloud_group <- function(url) {
  meta <- nz_cloud_metadata(url)

  store <- nz_cloud_store(url, meta)

  root_attrs <- meta$metadata[[".zattrs"]]
  if(is.null(root_attrs)) root_attrs <- list()

  self <- new.env(parent = emptyenv())

  self$get_store <- function() store
  self$get_attrs <- function() nz_cloud_attrs(root_attrs)
  self$get_item <- function(name) nz_cloud_array(url, name, meta$metadata)

  # match what pizzarr reports for a root group
  self$get_name <- function() "/"
  self$get_path <- function() ""
  self$get_url <- function() url

  class(self) <- c("NZCloud", "ZarrGroup")

  self
}
