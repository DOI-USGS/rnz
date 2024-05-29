#' @title open netcdf or zarr
#' @param store a pizzarr store, a path to a zarr store, or a path to a netcdf resource
#' @return ZarrGroup or NetCDF object
#' @export
#' @examples
#' if(requireNamespace("pizzarr", quietly = TRUE)) {
#'
#' z <- z_demo()
#'
#' bcsd <- open_nz(z)
#'
#' class(bcsd)
#'
#' zarr <- pizzarr::DirectoryStore$new(z)
#'
#' class(zarr)
#'
#' bcsd <- open_nz(zarr)
#'
#' class(bcsd)
#'
#' }
#'
#' # equivalent data in NetCDF
#' if(requireNamespace("RNetCDF", quietly = TRUE)) {
#'   nc <- system.file("extdata", "bcsd_obs_1999.nc", package = "rnz")
#'
#'   (RNetCDF::open.nc(nc))
#' }
#'
open_nz <- function(store) {
  if(!check_pizzarr()) return(NULL)

  ret <- try(pizzarr::zarr_open(store, mode = 'r'))

  if(inherits(ret, "try-error")) warning("Failed to open store")

  invisible(ret)
}
