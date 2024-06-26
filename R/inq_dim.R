#' @title Inquire Zarr Dimension
#' @description
#' NOTE: assumes the `_ARRAY_DIMENSION` convention from `xarray`
#'
#' @inheritParams inq_nz_source
#' @param dim integer zero-based index id of dimension of interest
#' @return list similar to that returned by \link[RNetCDF]{dim.inq.nc}
#' @examples
#'
#' z <- open_nz(z_demo())
#'
#' inq_dim(z, 0)
#'
#' inq_dim(z, "latitude")
#'
#' # equivalent data in NetCDF
#' if(requireNamespace("RNetCDF", quietly = TRUE)) {
#'   nc <- z_demo(format = "netcdf")
#'
#'   (inq_dim(nc, 0))
#' }
#' @name inq_dim
#' @export
inq_dim <- function(z, dim) {
  UseMethod("inq_dim")
}

#' @name inq_dim
#' @export
inq_dim.character <- function(z, dim) {
  inq_dim(open_nz(z, warn = FALSE), dim)
}

#' @name inq_dim
#' @export
inq_dim.NetCDF <- function(z, dim) {
  RNetCDF::dim.inq.nc(z, dim)
}

#' @name inq_dim
#' @export
inq_dim.ZarrGroup <- function(z, dim) {

  if(is.character(dim)) dim <- dim_char_to_id(z, dim)

  stopifnot(is.numeric(dim), length(dim) == 1, as.integer(dim) == dim)

  array_dims <- get_unique_dims(z)

  dim_name <- array_dims[(dim + 1)]

  rep_var <- get_rep_var(z, dim_name)

  rep_var_len <- get_array_dims(z$get_item(rep_var))

  rep_var_len <- rep_var_len$length[which(rep_var_len$name == dim_name)]

  list(id = dim,
       name = dim_name,
       length = rep_var_len)

}

dim_char_to_id <- function(z, char_dim) {
  out <- which(get_unique_dims(z) == char_dim) - 1 # 0 indexed

  if(length(out) == 0) stop("dimension not found")

  out
}

#' @name inq_dim
#' @export
inq_dim.NULL <- function(z, dim) {
  NULL
}
