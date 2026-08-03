# Cloud (s3:// and gs://) source support, Zarr v2 and v3.
#
# pizzarr's S3Store and GcsStore are dispatch markers: they carry a URL and
# raise on get_item()/contains_item()/listdir(), so the store surface every
# helper in util.R depends on is not there. What is available is
# pizzarr::zarrs_get_key() for a single key and pizzarr::zarrs_get_subset()
# for array reads, both taking the store URL directly.
#
# That is enough, because both Zarr versions can put every array's metadata
# in one document. v2 publishes a `.zmetadata` key holding each array's
# `.zarray` and `.zattrs`. v3 puts the same information inline in the root
# `zarr.json` under `consolidated_metadata`. Either way a single fetch
# supplies shapes, dtypes, fill values, attributes, and dimension labels.
#
# nz_cloud_metadata() normalizes the two into one per-array record, so the
# version difference is confined to this file's top half. The objects below
# present the small slice of the pizzarr ZarrGroup surface that rnz actually
# calls, backed by those records. They are plain environments rather than R6
# so the Zarr backend stays a Suggests-only dependency. The group carries
# class c("NZCloud", "ZarrGroup") so every existing `.ZarrGroup` method
# dispatches to it unchanged.
#
# zarrs also opens plain filesystem paths, so this adapter can be pointed at
# a local store. tests/testthat/test_cloud.R uses that to check the whole
# path offline against pizzarr's own reader.

# URL schemes open_nz() routes here.
nz_cloud_schemes <- "^(s3|gs)://"

# pizzarr's store class for a URL, reported as `format` by inq_nz_source().
# A bare path reports DirectoryStore, matching what pizzarr reports for the
# same store, so the offline parity tests can compare the whole structure.
nz_cloud_store_class <- function(url) {
  if(grepl("^gs://", url)) return("GcsStore")
  if(grepl("^s3://", url)) return("S3Store")

  "DirectoryStore"
}

# ---------------------------------------------------------------------------
# dtype
# ---------------------------------------------------------------------------

# Zarr v3 names its data types (`float32`); v2 uses numpy-style strings
# (`<f4`). pizzarr converts v3 to the v2 form before exposing it, and
# inq_var() reports get_dtype() verbatim, so this route has to convert the
# same way or the cloud and local routes would disagree on `type` for the
# same store. test_cloud.R pins that agreement against pizzarr's own reader
# rather than against a copy of its table.
nz_v3_dtypes <- list(bool = "b1", int8 = "i1", uint8 = "u1",
                     int16 = "i2", uint16 = "u2",
                     int32 = "i4", uint32 = "u4",
                     int64 = "i8", uint64 = "u8",
                     float32 = "f4", float64 = "f8")

# single-byte types carry no byte order
nz_v3_single <- c("bool", "int8", "uint8")

nz_v3_dtype <- function(data_type, endian = "little") {
  base <- nz_v3_dtypes[[data_type]]

  if(is.null(base))
    stop("unsupported v3 data_type: ", data_type, "\n  supported types: ",
         paste(names(nz_v3_dtypes), collapse = ", "))

  prefix <- if(data_type %in% nz_v3_single) {
    "|"
  } else if(identical(endian, "big")) {
    ">"
  } else {
    "<"
  }

  paste0(prefix, base)
}

# Byte order comes from the array-to-bytes codec: "bytes" is the
# zarr-python name, "endian" the zarrita one. v3 defaults to little.
nz_v3_endian <- function(codecs) {
  for(codec in codecs) {
    if(!is.null(codec$name) && codec$name %in% c("bytes", "endian") &&
       !is.null(codec$configuration$endian)) {
      return(codec$configuration$endian)
    }
  }

  "little"
}

# ---------------------------------------------------------------------------
# metadata
# ---------------------------------------------------------------------------

# Zarr v2 writes non-finite fill values as JSON strings, and v3 kept the
# same encoding. pizzarr hands back the numeric, so match it -- get_var()
# compares data against this value.
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

# Fetch and normalize store metadata. Returns:
#   format     2L or 3L
#   arrays     named list of per-array records (shape, dtype, fill_value,
#              attrs, dim_names)
#   root_attrs the root group's attributes
#   raw        the parsed v2 consolidated blob, or NULL on v3 -- see
#              nz_cloud_store() for why that distinction matters
nz_cloud_metadata <- function(url) {
  if(!requireNamespace("pizzarr", quietly = TRUE))
    stop("pizzarr is required to open a cloud store")

  if(!requireNamespace("jsonlite", quietly = TRUE))
    stop("jsonlite is required to read cloud store metadata")

  if(!exists("zarrs_get_key", envir = asNamespace("pizzarr")))
    stop("this pizzarr build has no zarrs_get_key(); pizzarr >= 0.2.1 with ",
         "the zarrs backend is required to open ", url)

  # v3 first: a v3 store always has a root zarr.json, and a v2 store never
  # does, so this also identifies the version.
  root <- pizzarr::zarrs_get_key(url, "zarr.json")

  if(!is.null(root)) return(nz_cloud_meta_v3(url, root))

  raw_meta <- pizzarr::zarrs_get_key(url, ".zmetadata")

  if(is.null(raw_meta))
    stop("no consolidated metadata found at ", url, "\n",
         "  looked for `zarr.json` (v3) and `.zmetadata` (v2). rnz can only\n",
         "  inquire cloud stores that publish consolidated metadata, because\n",
         "  the object store APIs offer no way to list keys.")

  nz_cloud_meta_v2(raw_meta)
}

nz_cloud_meta_v3 <- function(url, root_bytes) {
  root <- jsonlite::fromJSON(rawToChar(root_bytes), simplifyVector = FALSE)

  nodes <- root$consolidated_metadata$metadata

  if(is.null(nodes))
    stop("the v3 store at ", url, " does not consolidate its metadata\n",
         "  its root `zarr.json` has no `consolidated_metadata`. rnz can only\n",
         "  inquire cloud stores that publish consolidated metadata, because\n",
         "  the object store APIs offer no way to list keys.")

  # zarr-python keys the consolidated map by child path. rnz reads the root
  # group only, so nested nodes are dropped rather than flattened, and
  # group nodes are dropped so `arrays` holds only arrays.
  nodes <- nodes[!grepl("/", names(nodes))]
  nodes <- nodes[vapply(nodes, \(x) identical(x$node_type, "array"),
                        logical(1))]

  list(format = 3L,
       arrays = lapply(nodes, nz_cloud_record_v3),
       root_attrs = nz_cloud_or_empty(root$attributes),
       raw = NULL)
}

nz_cloud_record_v3 <- function(x) {
  list(shape = as.integer(unlist(x$shape)),
       dtype = nz_v3_dtype(x$data_type, nz_v3_endian(x$codecs)),
       fill_value = nz_cloud_fill_value(x$fill_value),
       attrs = nz_cloud_or_empty(x$attributes),
       # NZ-1.0 / v3 carries dimension labels as a first-class field
       dim_names = if(is.null(x$dimension_names)) NULL
                   else as.character(unlist(x$dimension_names)))
}

nz_cloud_meta_v2 <- function(raw_meta) {
  meta <- jsonlite::fromJSON(rawToChar(raw_meta), simplifyVector = FALSE)

  nodes <- meta$metadata

  # keys look like `lat/.zarray`; the array name is the first component.
  # Keeping only names that actually carry a `.zarray` drops both the
  # store-level dot keys and any subgroup, matching the v3 filter above.
  vars <- unique(vapply(strsplit(names(nodes), "/"), \(x) x[1], ""))
  vars <- vars[vapply(vars,
                      \(nm) !is.null(nodes[[paste0(nm, "/.zarray")]]),
                      logical(1))]

  arrays <- lapply(vars, \(nm) nz_cloud_record_v2(nodes, nm))
  names(arrays) <- vars

  list(format = 2L,
       arrays = arrays,
       root_attrs = nz_cloud_or_empty(nodes[[".zattrs"]]),
       raw = meta)
}

nz_cloud_record_v2 <- function(nodes, nm) {
  zarray <- nodes[[paste0(nm, "/.zarray")]]

  list(shape = as.integer(unlist(zarray$shape)),
       dtype = zarray$dtype,
       fill_value = nz_cloud_fill_value(zarray$fill_value),
       attrs = nz_cloud_or_empty(nodes[[paste0(nm, "/.zattrs")]]),
       # v2 carries dimension labels in the `_ARRAY_DIMENSIONS` attribute;
       # NULL sends get_array_dims() to that fallback
       dim_names = NULL)
}

nz_cloud_or_empty <- function(x) if(is.null(x)) list() else x

# ---------------------------------------------------------------------------
# ZarrGroup surface
# ---------------------------------------------------------------------------

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
# with no aperm(). This is version-agnostic: zarrs reads v2 and v3 alike.
nz_cloud_read <- function(url, name, ranges) {
  out <- pizzarr::zarrs_get_subset(url, name, ranges, NULL)

  array(out$data, dim = as.integer(out$shape))
}

# Array shim over one normalized record.
nz_cloud_array <- function(url, name, rec) {
  self <- new.env(parent = emptyenv())

  self$get_attrs <- function() nz_cloud_attrs(rec$attrs)
  self$get_shape <- function() rec$shape
  self$get_ndim <- function() length(rec$shape)
  self$get_dtype <- function() list(dtype = rec$dtype)
  self$get_fill_value <- function() rec$fill_value
  self$get_dimension_names <- function() rec$dim_names

  self$as.array <- function() {
    nz_cloud_read(url, name, lapply(rec$shape, \(s) c(0L, s)))
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

  # On v2 hand back the raw consolidated blob, so get_all_dims() keeps its
  # existing fast path of reading `_ARRAY_DIMENSIONS` straight out of the
  # document. On v3 return NULL, so it falls through to the ZarrGroup branch
  # and reads dimension_names off the array shim -- the same route the local
  # v3 path takes. Either way nothing extra is fetched; the records are
  # already in memory.
  self$get_consolidated_metadata <- function() meta$raw
  self$get_store_identifier <- function() url
  self$listdir <- function(path = NA) names(meta$arrays)

  class(self) <- c(nz_cloud_store_class(url), "NZCloudStore")

  self
}

# Group adapter. Returned by open_nz() for an s3:// or gs:// URL.
nz_cloud_group <- function(url) {
  meta <- nz_cloud_metadata(url)

  store <- nz_cloud_store(url, meta)

  self <- new.env(parent = emptyenv())

  self$get_store <- function() store
  self$get_attrs <- function() nz_cloud_attrs(meta$root_attrs)

  self$get_item <- function(name) {
    rec <- meta$arrays[[name]]

    if(is.null(rec)) stop("array metadata not found for ", name)

    nz_cloud_array(url, name, rec)
  }

  # match what pizzarr reports for a root group
  self$get_name <- function() "/"
  self$get_path <- function() ""
  self$get_url <- function() url
  self$get_zarr_format <- function() meta$format

  class(self) <- c("NZCloud", "ZarrGroup")

  self
}
