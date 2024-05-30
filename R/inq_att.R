#' @title Inquire Zarr Attribute
#'
#' @inheritParams inq_nz_source
#' @param var integer or character zero-based index id of variable of interest
#' or name of variable of interest. -1 or "global" for global attributes
#' @param att integer or character zero-based index id of attribute of interest
#' or name of attribute of interest.
#' @return list similar to that returned by \link[RNetCDF]{att.inq.nc}
#' @export
#' @examples
#'
#' z <- open_nz(z_demo())
#'
#' inq_att(z, -1, 0)
#'
#' inq_att(z, "global", "Conventions")
#'
#' inq_att(z, 0, 3)
#'
#' inq_att(z, "latitude", "long_name")
#'
#' # equivalent data in NetCDF
#' if(requireNamespace("RNetCDF", quietly = TRUE)) {
#'   nc <- z_demo(format = "netcdf")
#'
#'   (RNetCDF::att.inq.nc(RNetCDF::open.nc(nc), 0, 0))
#' }
#' @name inq_att
inq_att <- function(z, var, att) {

  if(is.null(z)) return(NULL)

  a <- att_prep(z, var, att)

  list(id = a$att,
       name = names(a$atts)[a$att + 1],
       type = class(unlist(a$atts[a$att + 1])),
       length = length(a$atts[[a$att + 1]]))

}

att_char_to_id <- function(z, var, char_att) {
  out <- which(names(get_attributes(z, var, noarray = TRUE)) == char_att) - 1 # 0 indexed

  if(length(out) == 0) stop("attribute not found")

  out
}
