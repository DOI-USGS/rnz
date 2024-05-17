#' @title Inquire Zarr Store
#' @param z an open ZarrGroup as returned by \link{open_zarr}
#' @return list similar to that returned by \link[RNetCDF]{file.inq.nc}
#' @export
#' @examples
#'
#' z <- open_zarr(z_demo())
#'
#' inq_store(z)
#'
#' # equivalent data in NetCDF
#' if(requireNamespace("RNetCDF", quietly = TRUE)) {
#'   nc <- system.file("extdata", "bcsd_obs_1999.nc", package = "rnz")
#'
#'   (RNetCDF::file.inq.nc(RNetCDF::open.nc(nc)))
#' }
#'
inq_store <- function(z) {

  is_zarr(z)

  vars <- nodots(z$get_store()$listdir())

  list(ndims = max(sapply(vars, \(x) z$get_item(x)$get_ndim())),
       nvars = length(vars),
       ngatts = length(z$get_attrs()$to_list()),
       format = class(z$get_store())[1])

}
