#' @title Get Zarr Attribute
#'
#' @inheritParams inq_att
#' @return vector containing requested attribute \link[RNetCDF]{att.get.nc}
#' @export
#' @examples
#'
#' z <- open_zarr(z_dir())
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
#'   nc <- system.file("extdata", "bcsd_obs_1999.nc", package = "rnz")
#'
#'   (RNetCDF::att.get.nc(RNetCDF::open.nc(nc), 0, 0))
#' }
#'
get_att <- function(z, var, att) {

  a <- att_prep(z, var, att)

  a$atts[[a$att + 1]]

}

att_char_to_id <- function(z, var, char_att) {
  out <- which(names(get_attributes(z, var, noarray = TRUE)) == char_att) - 1 # 0 indexed

  if(length(out) == 0) stop("attribute not found")

  out
}
