#' @title Inquire Zarr Variable
#'
#' @inheritParams inq_store
#' @param var integer zero-based index id of variable of interest
#' @return list similar to that returned by \link[RNetCDF]{var.inq.nc}
#' @export
#' @examples
#'
#' z <- open_zarr(system.file("extdata", "bcsd_obs_1999.zarr", package = "rnz"))
#'
#' inq_var(z, 0)
#'
#' # equivalent data in NetCDF
#' requireNamespace("RNetCDF", quietly = TRUE) {
#'   nc <- system.file("extdata", "bcsd_obs_1999.nc", package = "rnz")
#'
#'   (RNetCDF::var.inq.nc(RNetCDF::open.nc(nc), 0))
#' }
#'
inq_var <- function(z, var) {

  is_zarr(z)

  stopifnot(is.numeric(var), length(var) == 1, as.integer(var) == var)

  var_name <- get_vars(z)[(var + 1)]

  num_dim <- z$get_item(var_name)$get_ndim()

  type <- z$get_item(var_name)$get_dtype()$dtype

  all_dims <- get_unique_dims(z)

  dim_ids <- which(get_all_dims(z, var_name)[[1]]$name == all_dims) - 1

  num_atts <- length(get_attributes(z, var_name))

  list(id = var,
       name = var_name,
       type = type,
       ndims = num_dim,
       dimids = dim_ids,
       natts = num_atts)

}
