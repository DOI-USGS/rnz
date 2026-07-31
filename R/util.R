#' nz demo data directory
#'
#' Data derived from: https://gdo-dcp.ucllnl.org/downscaled_cmip_projections/
#'
#' @param format character "netcdf" or "zarr"
#' @return netcdf sample data or unzips and returns a demo Zarr store directory
#' @export
#' @examples
#' list.files(z_demo(format = "zarr"), recursive = TRUE, all.files = TRUE)
#'
#' basename(z_demo(format = "netcdf"))
z_demo <- function(format = "zarr") {
  if(format == "netcdf")
    return(system.file("extdata", "bcsd_obs_1999.nc", package = "rnz"))

  if(format != "zarr") stop("'format' must be \"zarr\" or \"netcdf\"")

  z <- "bcsd_obs_1999.zarr"

  dir <- file.path(tools::R_user_dir(package = "rnz"), z)

  z_zip <- system.file("extdata", "bcsd_obs_1999.zip", package = "rnz")

  suppressWarnings(utils::unzip(z_zip, exdir = dir, overwrite = FALSE))

  normalizePath(dir)
}

# useful for getting only the data arrays
# v2 metadata files (.zattrs/.zgroup/.zmetadata) and the v3 group
# metadata file (zarr.json) are filtered.
nodots <- function(x) {
  x[!grepl("\\.zattrs|\\.zgroup|\\.zmetadata|^zarr\\.json$", x)]
}

# pull out the `_ARRAY_DIMENSIONS` xarray convention
get_array_dims <- function(z, x, include_size = TRUE) {
  out <- NULL

  if(inherits(z, "ZarrGroup")) {

    x <- z$get_item(x)

    # v3 / NZ-1.0: dimension_names live in zarr.json and are exposed by
    # pizzarr (>= 0.1.3) via ZarrArray$get_dimension_names(). Returns
    # NULL for v2 arrays. When a v3 array carries both dimension_names
    # and a stale _ARRAY_DIMENSIONS attribute, NZ-1.0 says
    # dimension_names wins, so we check it first.
    dim_names <- x$get_dimension_names()

    if(is.null(dim_names)) {
      dim_names <- x$get_attrs()$to_list()$`_ARRAY_DIMENSIONS`
    }

    out <- list(name = as.character(dim_names))

    if(include_size) {

      out$length <- sapply(seq_along(out$name), \(i) x$get_shape()[i])

    }
  } else if(inherits(z, "list")) {

    atts <- z[names(z) == paste0(x, "/.zattrs")]

    if(length(atts) != 1) stop("attributes are not a length 1 list in ", x)

    out <- list(name = as.character(atts[[1]]$`_ARRAY_DIMENSIONS`))

    if(include_size) {

      atts <- z[names(z) == paste0(x, "/.zarray")]

      if(length(atts) != 1) stop("array metadata is not a length 1 list in ", x)

      out$length <- unlist(lapply(seq_along(out$name), \(i) atts[[1]]$shape[i]))

    }
  }

    out
}

# gets the unique array dimensions.
# this is used as a proxy for the order in which
# the dimensions are declared.
get_unique_dims <- function(z, vars = get_vars(z)) {

  unique(unlist(get_all_dims(z, vars)))
}

# gets all array dimensions for provided vars
get_all_dims <- function(z, vars = get_vars(z)) {

  # need to force vars to be evaluated
  var_set <- vars

  meta <- z$get_store()$get_consolidated_metadata()

  if(!is.null(meta$zarr_consolidated_format) && meta$zarr_consolidated_format == 1) {
    z <- meta$metadata
  }

  out <- lapply(var_set, \(x) get_array_dims(z, x, include_size = FALSE))

  names(out) <- vars

  out
}

get_dim_size <- function(z, vars = get_vars(z)) {

  out <- lapply(vars, \(x) get_array_dims(z, x, include_size = TRUE))

  names(out) <- vars

  out

}

# just pull out all the variables from the root group.
get_vars <- function(z) {
  nodots(z$get_store()$listdir())
}

# only return variables that are not the same name as a dimension
get_coord_vars <- function(z, vars = get_vars(z)) {
  dims <- get_unique_dims(z)

  vars[vars %in% dims]
}

# gets a representative variable for a given dimension name
# will return the coordinate variable if it exists
get_rep_var <- function(z, dim_name) {
  stopifnot(is.character(dim_name), dim_name %in% get_unique_dims(z))

  all_var_dims <- get_all_dims(z)

  # exact match on the dimension label. `grepl` would treat `dim_name` as a
  # regex and match substrings, so a dimension named "lat" would pick up a
  # variable on "latitude".
  on_dim <- sapply(all_var_dims, \(x) any(x$name == dim_name))

  # if there is a coordinate variable, return it. sharing a name with the
  # dimension is not enough -- the variable must actually be on it,
  # otherwise it is an unrelated variable that happens to share the name.
  if(isTRUE(on_dim[dim_name])) return(dim_name)

  # otherwise return the first variable on that dimension
  names(on_dim[on_dim][1])
}

get_attributes <- function(z, var_name = NULL, noarray = FALSE) {
  if(is.numeric(var_name)) { # expect 0 indexed
    var_name <- get_vars(z)[var_name + 1]
  }

  if(!is.null(var_name) & length(var_name) != 0) {
    out <- z$get_item(var_name)$get_attrs()$to_list()
  } else {
    out <- z$get_attrs()$to_list()
  }

  if(noarray) {
    # Hide structural / annotation attributes from user-visible listings:
    #   `_ARRAY_DIMENSIONS` is the v2/xarray dimension-name carrier (NZ-1.0
    #   moves this into `dimension_names` in zarr.json on v3) and is not a
    #   user attribute under either the NUG or NZ.
    #   `_nczarr_attr` carries NCZarr's per-attribute type annotations and
    #   is consulted by `inq_att()` for precise types but is not itself a
    #   user-visible NUG attribute.
    out <- out[!names(out) %in% c("_ARRAY_DIMENSIONS", "_nczarr_attr")]
  }

  out
}

att_char_to_id <- function(z, var, char_att) {
  out <- which(names(get_attributes(z, var, noarray = TRUE)) == char_att) - 1 # 0 indexed

  if(length(out) == 0) stop("attribute not found")

  out
}

att_prep <- function(z, var, att) {
  if(var == "global" | var == "NC_GLOBAL") var <- -1

  if(is.character(var)) var <- var_char_to_id(z, var)
  if(is.character(att)) att <- att_char_to_id(z, var, att)

  stopifnot(is.numeric(var), length(var) == 1, as.integer(var) == var)

  # `atts` is the user-visible attribute set (NUG semantics: structural
  # `_ARRAY_DIMENSIONS` and the `_nczarr_attr` annotation block are
  # filtered out by `noarray = TRUE`).
  atts <- get_attributes(z, var, noarray = TRUE)
  # `_nczarr_attr$types` is the NCZarr per-attribute dtype annotation
  # (e.g. `scale_factor = "<f4"`). It is fetched here so `inq_att()` can
  # report the precise on-disk type rather than the R runtime class that
  # JSON deserialization collapses to (`numeric` / `integer`).
  nczarr_types <- get_attributes(z, var, noarray = FALSE)$`_nczarr_attr`$types

  if(att + 1 > length(atts)) stop("Index is greater than number of attributes. Zero index issue?")

  list(atts = atts, var = var, att = att, nczarr_types = nczarr_types)
}


var_prep <- function(z, var) {
  if(is.character(var)) var <- var_char_to_id(z, var)

  stopifnot(is.numeric(var), length(var) == 1, as.integer(var) == var)

  var_name <- get_vars(z)[(var + 1)]

  return(list(var = var, var_name = var_name))
}

z_seq <- function(x) seq_len(x) - 1

rm_na <- function(x) x[!is.na(x)]

# Internal: does the root group of a ZarrGroup declare NZ-1.0 compliance?
# NZ-1.0 \S Conventions allows `conventions` (NZ-preferred, lowercase) and
# treats the NUG-style `Conventions` (capital C) as equivalent on read, so
# we check both keys. Used by other Zarr-backend code paths that need to
# branch on convention compliance (e.g. strict NZ semantics for fill-value
# fallback). Not exported and not S3 - callers always hold a ZarrGroup.
is_nz <- function(z) {
  atts <- z$get_attrs()$to_list()
  conv <- atts$conventions
  if(is.null(conv)) conv <- atts$Conventions

  has_nz(conv)
}

# Internal: parse a convention attribute value (a single string of
# space-separated convention tokens, per NUG \S6.1.2 / NZ \S Conventions)
# and report whether `"NZ-1.0"` is one of the tokens. Returns FALSE for
# NULL / empty / non-character input so callers don't have to guard.
has_nz <- function(conv) {
  if(is.null(conv) || length(conv) == 0) return(FALSE)
  if(!is.character(conv)) return(FALSE)

  tokens <- unlist(strsplit(conv, "\\s+"))
  "NZ-1.0" %in% tokens
}
