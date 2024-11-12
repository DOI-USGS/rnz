#' @title close netcdf or zarr
#' Closes handle. Doesn't currently do anything for zarr stores.
#' @inheritParams inq_att
#' @examples
#' if(requireNamespace("pizzarr", quietly = TRUE)) {
#'
#' z <- z_demo()
#'
#' bcsd <- open_nz(z)
#'
#' close_nz(bcsd)
#'
#' }
#'
#' # equivalent data in NetCDF
#' if(requireNamespace("RNetCDF", quietly = TRUE)) {
#'   nc <- z_demo(format = "netcdf")
#'
#'   bcsd <- open_nz(nc)
#'
#'   close_nz(bcsd)
#' }
#' @name close_nz
#' @export
close_nz <- function(nz) {
  UseMethod("close_nz")
}

#' @name close_nz
#' @export
close_nz.NetCDF <- function(z) {

  RNetCDF::close.nc(z)

}


#' @name close_nz
#' @export
close_nz.ZarrGroup <- function(z) {

  z

}

#' @name close_nz
#' @export
close_nz.NULL <- function(z) {

  NULL

}
