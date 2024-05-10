#' @title Inquire Zarr Attribute
#'
#' @inheritParams inq_store
#' @param var integer zero-based index id of variable of interest. If missing
#' or -1 for global.
#' @param att integer zero-based index id of attribute of interest
#' @return list similar to that returned by \link[RNetCDF]{att.inq.nc}
#' @export
#' @examples
#'
#' z <- open_zarr(system.file("extdata", "bcsd_obs_1999.zarr", package = "rnz"))
#'
#' inq_att(z, att = 0)
#'
#' inq_att(z, -1, 0)
#'
#' inq_att(z, 0, 0)
#'
#' # equivalent data in NetCDF
#' requireNamespace("RNetCDF", quietly = TRUE) {
#'   nc <- system.file("extdata", "bcsd_obs_1999.nc", package = "rnz")
#'
#'   (RNetCDF::att.inq.nc(RNetCDF::open.nc(nc), 0, 0))
#' }
#'
inq_att <- function(z, var, att) {

  is_zarr(z)

  if(missing(var)) var <- -1

  stopifnot(is.numeric(var), length(var) == 1, as.integer(var) == var)

  atts <- get_attributes(z, var, noarray = TRUE)

  list(id = att,
       name = )

}
