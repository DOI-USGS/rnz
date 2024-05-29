#' @title Inquire Zarr Group
#' @description
#' NOTE: only functions on a root group thus far
#'
#' @param z an open ZarrGroup as returned by \link{open_nz}
#' @param group NOTUSED
#' @return list similar to that returned by \link[RNetCDF]{grp.inq.nc}
#' @export
#' @examples
#'
#' z <- open_nz(z_demo())
#'
#' inq_grp(z)
#'
#' # equivalent data in NetCDF
#' if(requireNamespace("RNetCDF", quietly = TRUE)) {
#'   nc <- system.file("extdata", "bcsd_obs_1999.nc", package = "rnz")
#'
#'   (RNetCDF::grp.inq.nc(RNetCDF::open.nc(nc)))
#' }
#' @name inq_grp
inq_grp <- function(z, group = "/") {

  if(is.null(z)) return(NULL)

  is_zarr(z)

  array_dims <- get_unique_dims(z)
  vars <- get_vars(z)

  list(grps = list(),
       name = z$get_name(),
       fullname = paste0(z$get_path(), z$get_name()),
       dimids = seq(0, by = 1, length.out = length(array_dims)),
       varids = seq(0, by = 1, length.out = length(vars)),
       ngatts = length(z$get_attrs()$to_list()))

}
