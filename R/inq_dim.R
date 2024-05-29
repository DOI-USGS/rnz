#' @title Inquire Zarr Dimension
#' @description
#' NOTE: assumes the `_ARRAY_DIMENSION` convention from `xarray`
#'
#' @inheritParams inq_nz_source
#' @param dim integer zero-based index id of dimension of interest
#' @return list similar to that returned by \link[RNetCDF]{dim.inq.nc}
#' @export
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
#'   nc <- system.file("extdata", "bcsd_obs_1999.nc", package = "rnz")
#'
#'   (RNetCDF::dim.inq.nc(RNetCDF::open.nc(nc), 0))
#' }
#' @name inq_dim
inq_dim <- function(z, dim) {

  if(is.null(z)) return(NULL)

  is_zarr(z)

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

