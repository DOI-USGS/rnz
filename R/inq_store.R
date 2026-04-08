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
#'   (inq_nz_source(nc))
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
inq_nz_source.NULL <- function(z) {
  NULL
}

#' @name inq_nz_source
#' @export
inq_nz_source.ZarrGroup <- function(z) {

  vars <- nodots(z$get_store()$listdir())

  # NUG / NZ-1.0: `ndims` is the number of distinct named dimensions in
  # the group (the count of unique `dimension_names` entries across all
  # arrays, equivalently the size of the shared-dimension label set), not
  # the rank of the highest-rank single array. Two disjoint 2D arrays on
  # `(x,y)` and `(z,t)` define four dimensions, even though no single
  # array has rank > 2.
  list(ndims = length(get_unique_dims(z)),
       nvars = length(vars),
       ngatts = length(z$get_attrs()$to_list()),
       format = class(z$get_store())[1])

}

