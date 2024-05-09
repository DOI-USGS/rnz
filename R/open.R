#' @title open zarr
#' @param store a pizzarr store or path to a zarr store
#' @return ZarrGroup
#' @importFrom pizzarr zarr_open
#' @export
#' @examples
#' z <- system.file("extdata", "bcsd_obs_1999.zarr", package = "rnz")
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
#' requireNamespace("RNetCDF", quietly = TRUE) {
#'   nc <- system.file("extdata", "bcsd_obs_1999.nc", package = "rnz")
#'
#'   (RNetCDF::open.nc(nc))
#' }
#'
open_zarr <- function(con) {
  invisible(pizzarr::zarr_open(con, mode = 'r'))
}
