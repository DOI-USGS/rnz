#' @title open netcdf or zarr
#' @param nz a pizzarr store, a path to a zarr store, or a path to a netcdf resource
#' @param backend character "pizzarr" or "RNetCDF"
#'  if NULL (the default) will try pizzar first and fall back to RNetCDF
#' @return ZarrGroup or NetCDF object
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
#'   nc <- z_demo(format = "netcdf")
#'
#'   bcsd <- open_nz(nc)
#'
#'   class(bcsd)
#' }
#' @name open_nz
#' @export
open_nz <- function(nz, backend = NULL, warn = TRUE) {
  UseMethod("open_nz")
}

try_zarr <- function(nz, warn) {
  if(!check_pizzarr()) return(NULL)

  ret <- try(pizzarr::zarr_open(nz, mode = 'r'), silent = TRUE)

  if(warn & inherits(ret, "try-error")) warning("Failed to open as zarr", immediate. = TRUE)

  ret
}

#' @name open_nz
#' @export
open_nz.Store <- function(nz, backend = NULL, warn = TRUE) {

  ret <- try_zarr(nz, warn)

  invisible(ret)
}

#' @name open_nz
#' @export
open_nz.character <- function(nz, backend = NULL, warn = TRUE) {

  if(!is.null(backend) && !backend %in% c("pizzarr", "RNetCDF")) stop("'backend' must be NULL, \"pizzarr\", or \"RNetCDF\"")

  ret <- NULL

  if(is.null(backend) || backend == "pizzarr") {
    ret <- try_zarr(nz, warn)
  }

  if(!is.null(backend) && backend == "RNetCDF" | inherits(ret, "try-error")) {
    ret <- try(RNetCDF::open.nc(nz))

    if(!inherits(ret, "try-error") & is.null(backend)) message("Opened as NetCDF")
  }

  invisible(ret)
}
