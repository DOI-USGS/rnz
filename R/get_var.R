#' @title Get Zarr Variable
#'
#' @inheritParams inq_store
#' @param var integer or character zero-based index id of variable of interest
#' or name of variable of interest.
#' @param start integer vector with length equal to the number of dimensions of var.
#' Uses R-style 1 indexing. If NA the entire array is returned.
#' @param count integer vector with length equal to the number of dimensions of var.
#' Specifies the size of the returned array along the dimension in question. Can not
#' be NA if start is not NA. -1 can be used to indicate all of a given dimension.
#' @return array of data
#' @export
#' @examples
#'
#' if(requireNamespace("pizzarr", quietly = TRUE)) {
#' z <- open_nz(z_demo())
#'
#' latitude <- get_var(z, 0)
#'
#' class(latitude)
#' dim(latitude)
#'
#' pr <- get_var(z, "pr")
#'
#' image(pr[,,1], col = hcl.colors(12, "PuBuGn", rev = TRUE),
#'       useRaster = TRUE, axes = FALSE)
#'
#' dim(pr)
#'
#' # subsetting
#'
#' pr <- get_var(z, "pr", start = c(1, 1, 1), count = c(5, 5, -1))
#'
#' dim(pr)
#'
#' }
#'
#' # equivalent data in NetCDF
#' if(requireNamespace("RNetCDF", quietly = TRUE)) {
#'   nc <- system.file("extdata", "bcsd_obs_1999.nc", package = "rnz")
#'
#'   (RNetCDF::var.get.nc(RNetCDF::open.nc(nc), 0))
#' }
#'
get_var <- function(z, var, start = NA, count = NA) {

  if(!check_pizzarr()) return(NULL)

  if(is.null(z)) return(NULL)

  v <- var_prep(z, var)

  if(is.na(start)[1])
    return(z$get_item(v$var_name)$as.array())

  if(is.na(count)[1]) stop("must specify count if start is not NA")

  dim_size <- get_dim_size(z, v$var_name)[[1]]$length

  if(length(start) != length(dim_size) |
     length(count) != length(dim_size))
    stop("start and count must have length\n",
         "equal to the number of dimensions of var")

  slice_list <- lapply(seq_along(dim_size), \(i) {
    if(count[i] == -1) count[i] <- dim_size[i]
    pizzarr::slice(start[i], (start[i] + count[i] - 1))
  })

  z$get_item(v$var_name)$get_item(slice_list)$as.array()

}
