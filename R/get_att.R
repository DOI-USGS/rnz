#' @title Get Zarr Attribute
#'
#' @inheritParams inq_att
#' @return vector containing requested attribute \link[RNetCDF]{att.get.nc}
#' @examples
#'
#' z <- open_nz(z_demo())
#'
#' get_att(z, -1, 2)
#'
#' get_att(z, "global", "Conventions")
#'
#' get_att(z, 0, 3)
#'
#' get_att(z, "latitude", "long_name")
#'
#' # equivalent data in NetCDF
#' if(requireNamespace("RNetCDF", quietly = TRUE)) {
#'   nc <- z_demo(format = "netcdf")
#'
#'   (get_att(nc, 0, 0))
#'
#'   (get_att(nc, "global", 1))
#' }
#'
#' @name get_att
#' @export
get_att <- function(z, var, att) {
  UseMethod("get_att")
}

#' @name get_att
#' @export
get_att.character <- function(z, var, att) {
  get_att(open_nz(z, warn = FALSE), var, att)
}

#' @name get_att
#' @export
get_att.NetCDF <- function(z, var, att) {
  if(var == "global" | var == -1) var <- "NC_GLOBAL"

  RNetCDF::att.get.nc(z, var, att)
}


#' @name get_att
#' @export
get_att.ZarrGroup <- function(z, var, att) {

  if(is.null(z)) return(NULL)

  a <- att_prep(z, var, att)

  a$atts[[a$att + 1]]

}
