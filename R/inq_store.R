#' @title Inquire Zarr Store
#' @param z an open ZarrGroup as returned by \link{open_nz}
#' @return list similar to that returned by \link[RNetCDF]{file.inq.nc}
#' @examples
#'
#' z <- open_nz(z_demo())
#'
#' inq_nz_source(z)
#'
#' # equivalent data in NetCDF
#' if(requireNamespace("RNetCDF", quietly = TRUE)) {
#'   nc <- z_demo(format = "netcdf")
#'
#'   (inq_nz_source(RNetCDF::open.nc(nc)))
#' }
#' @name inq_nz_source
#' @export
inq_nz_source <- function(z) {
 UseMethod("inq_nz_source")
}

#' @name inq_nz_source
#' @export
inq_nz_source.character <- function(z) {
  inq_nz_source(open_nz(z, warn = FALSE))
}

#' @name inq_nz_source
#' @export
inq_nz_source.NetCDF <- function(z) {
  RNetCDF::file.inq.nc(z)
}

#' @name inq_nz_source
#' @export
inq_nz_source.ZarrGroup <- function(z) {

  if(is.null(z)) return(NULL)

  is_zarr(z)

  vars <- nodots(z$get_store()$listdir())

  list(ndims = max(sapply(vars, \(x) z$get_item(x)$get_ndim())),
       nvars = length(vars),
       ngatts = length(z$get_attrs()$to_list()),
       format = class(z$get_store())[1])

}

