#' @title open zarr
#' @param store a pizzarr store or path to a zarr store
#' @return ZarrGroup
#' @importFrom pizzarr zarr_open
#' @export
#' @examples
#' z <- z_demo()
#'
#' bcsd <- open_zarr(z)
#'
#' class(bcsd)
#'
#' zarr <- pizzarr::DirectoryStore$new(z)
#'
#' class(zarr)
#'
#' bcsd <- open_zarr(zarr)
#'
#' class(bcsd)
#'
#' # equivalent data in NetCDF
#' if(requireNamespace("RNetCDF", quietly = TRUE)) {
#'   nc <- system.file("extdata", "bcsd_obs_1999.nc", package = "rnz")
#'
#'   (RNetCDF::open.nc(nc))
#' }
#'
open_zarr <- function(store) {
  invisible(pizzarr::zarr_open(store, mode = 'r'))
}
