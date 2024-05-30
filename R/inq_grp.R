#' @title Inquire Zarr Group
#' @description
#' NOTE: only functions on a root group thus far
#'
#' @param z an open ZarrGroup as returned by \link{open_nz}
#' @param group NOTUSED
#' @return list similar to that returned by \link[RNetCDF]{grp.inq.nc}
#' @examples
#'
#' z <- open_nz(z_demo())
#'
#' inq_grp(z)
#'
#' # equivalent data in NetCDF
#' if(requireNamespace("RNetCDF", quietly = TRUE)) {#'
#'   inq_grp(z_demo(format = "netcdf"))
#' }
#' @name inq_grp
#' @export
inq_grp <- function(z, group = "/") {
  UseMethod("inq_grp")
}

#' @name inq_grp
#' @export
inq_grp.character <- function(z, group = "/") {
  inq_grp(open_nz(z, warn = FALSE), group)
}

#' @name inq_grp
#' @export
inq_grp.NetCDF <- function(z, group = "/") {
  RNetCDF::grp.inq.nc(z)
}


#' @name inq_grp
#' @export
inq_grp.ZarrGroup <- function(z, group = "/") {

  if(is.null(z)) return(NULL)

  array_dims <- get_unique_dims(z)
  vars <- get_vars(z)

  list(grps = list(),
       name = z$get_name(),
       fullname = paste0(z$get_path(), z$get_name()),
       dimids = seq(0, by = 1, length.out = length(array_dims)),
       varids = seq(0, by = 1, length.out = length(vars)),
       ngatts = length(z$get_attrs()$to_list()))

}
