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

  if(var == "global") var <- -1

  if(is.character(var)) var <- var_char_to_id(z, var)
  if(is.character(att)) att <- att_char_to_id(z, var, att)

  stopifnot(is.numeric(var), length(var) == 1, as.integer(var) == var)

  atts <- get_attributes(z, var, noarray = TRUE)

  if(att + 1 > length(atts)) stop("Index is greater than number of attributes. Zero index issue?")

  list(id = att,
       name = names(atts)[att + 1],
       type = class(unlist(atts[att + 1])),
       length = length(atts[[att + 1]]))

}

att_char_to_id <- function(z, var, char_att) {
  out <- which(names(get_attributes(z, var, noarray = TRUE)) == char_att) - 1 # 0 indexed

  if(length(out) == 0) stop("attribute not found")

  out
}
