#' @title Inquire Zarr Variable
#'
#' @inheritParams inq_store
#' @param var integer or character zero-based index id of variable of interest
#' or name of variable of interest.
#' @return list similar to that returned by \link[RNetCDF]{var.inq.nc}
#' @export
#' @examples
#'
#' z <- open_zarr(z_demo())
#'
#' inq_var(z, 0)
#'
#' inq_var(z, "pr")
#'
#' # equivalent data in NetCDF
#' if(requireNamespace("RNetCDF", quietly = TRUE)) {
#'   nc <- system.file("extdata", "bcsd_obs_1999.nc", package = "rnz")
#'
#'   (RNetCDF::var.inq.nc(RNetCDF::open.nc(nc), 0))
#' }
#'
inq_var <- function(z, var) {

  v <- var_prep(z, var)

  num_dim <- z$get_item(v$var_name)$get_ndim()

  type <- z$get_item(v$var_name)$get_dtype()$dtype

  all_dims <- get_unique_dims(z)

  dim_ids <- which(get_all_dims(z, v$var_name)[[1]]$name == all_dims) - 1

  num_atts <- length(get_attributes(z, v$var_name))

  list(id = v$var,
       name = v$var_name,
       type = type,
       ndims = num_dim,
       dimids = dim_ids,
       natts = num_atts)

}


var_char_to_id <- function(z, char_var) {
  out <- which(get_vars(z) == char_var) - 1 # 0 indexed

  if(length(out) == 0) stop("variable not found")

  out
}
