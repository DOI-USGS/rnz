#' @title Get Zarr Variable
#'
#' @inheritParams inq_store
#' @param var integer or character zero-based index id of variable of interest
#' or name of variable of interest.
#' @return array of data
#' @export
#' @examples
#'
#' z <- open_zarr(system.file("extdata", "bcsd_obs_1999.zarr", package = "rnz"))
#'
#' latitude <- get_var(z, 0)
#'
#' class(latitude)
#'
#' dim(latitude)
#'
#' pr <- get_var(z, "pr")
#'
#' dim(pr)
#'
#' # equivalent data in NetCDF
#' requireNamespace("RNetCDF", quietly = TRUE) {
#'   nc <- system.file("extdata", "bcsd_obs_1999.nc", package = "rnz")
#'
#'   (RNetCDF::var.get.nc(RNetCDF::open.nc(nc), 0))
#' }
#'
get_var <- function(z, var) {

  z$get_item(var_prep(z, var)$var_name)$as.array()

}
