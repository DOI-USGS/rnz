#' @title Inquire Zarr Dimension
#' @description
#' NOTE: assumes the `_ARRAY_DIMENSION` convention from `xarray`
#'
#' @inheritParams inq_store
#' @param dim integer zero-based index id of dimension of interest
#' @return list similar to that returned by \link[RNetCDF]{dim.inq.nc}
#' @export
#' @examples
#'
#' z <- open_zarr(system.file("extdata", "bcsd_obs_1999.zarr", package = "rnz"))
#'
#' inq_dim(z, 0)
#'
#' # equivalent data in NetCDF
#' requireNamespace("RNetCDF", quietly = TRUE) {
#'   nc <- system.file("extdata", "bcsd_obs_1999.nc", package = "rnz")
#'
#'   (RNetCDF::dim.inq.nc(RNetCDF::open.nc(nc), 0))
#' }
#'
inq_dim <- function(z, dim) {

  is_zarr(z)

  stopifnot(is.numeric(dim), length(dim) == 1, as.integer(dim) == dim)

  array_dims <- get_unique_dims(z)

  dim_name <- array_dims[(dim + 1)]

  rep_var_len <- get_array_dims(z$get_item(get_rep_var(z, dim_name)))$length

  list(id = dim,
       name = dim_name,
       length = rep_var_len)

}
