#' @title Get Zarr Variable
#'
#' @inheritParams inq_nz_source
#' @param var integer or character zero-based index id of variable of interest
#' or name of variable of interest.
#' @param start integer vector with length equal to the number of dimensions of var.
#' Uses R-style 1 indexing. If NA the entire array is returned.
#' @param count integer vector with length equal to the number of dimensions of var.
#' Specifies the size of the returned array along the dimension in question. Can not
#' be NA if start is not NA. NA count in one or more dimensions can be used to
#' indicate all of a given dimension.
#' @param collapse logical if TRUE degenerated dimensions (length=1) will be omitted.
#' @param ... passed to RNetCDF var.get.nc
#' @return array of data
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
#' pr <- get_var(z, "pr") |>
#'   aperm(c(3,2,1))
#'
#' pr[pr > 1000] <- NA
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
#'   nc <- z_demo(format = "netcdf")
#'
#'   (get_var(nc, 0))
#'
#'   pr <- get_var(nc, "pr")
#'
#'   image(pr[,,1], col = hcl.colors(12, "PuBuGn", rev = TRUE),
#'         useRaster = TRUE, axes = FALSE)
#'
#' }
#'
#' @name get_var
#' @export
get_var <- function(z, var, start = NA, count = NA,
                    collapse = TRUE, unpack = FALSE, ...) {
  UseMethod("get_var")
}

#' @name get_var
#' @export
get_var.character <- function(z, var, start = NA, count = NA,
                              collapse = TRUE, unpack = FALSE, ...) {
  get_var(open_nz(z, warn = FALSE), var, start, count, collapse = collapse, ...)
}

#' @name get_var
#' @export
get_var.NetCDF <- function(z, var, start = NA, count = NA,
                           collapse = TRUE, unpack = FALSE, ...) {
  RNetCDF::var.get.nc(z, var, start, count, collapse = collapse, unpack = unpack, ...)
}

#' @name get_var
#' @export
get_var.ZarrGroup <- function(z, var, start = NA, count = NA,
                              collapse = TRUE, unpack = FALSE, ...) {

  v <- var_prep(z, var)

  if(is.na(start)[1]) {

    out <- z$get_item(v$var_name)$as.array()

  } else {

    if(length(count) == 1 && is.na(count)[1]) stop("must specify count if start is not NA")

    dim_size <- get_dim_size(z, v$var_name)[[1]]$length

    if(length(start) != length(dim_size) |
       length(count) != length(dim_size))
      stop("start and count must have length\n",
           "equal to the number of dimensions of var")

    count <- replace(count, is.na(count), -1)

    slice_list <- lapply(seq_along(dim_size), \(i) {
      if(count[i] == -1) count[i] <- dim_size[i]
      pizzarr::slice(start[i], (start[i] + count[i] - 1))
    })

    out <- z$get_item(v$var_name)$get_item(slice_list)$as.array()
  }

  if((isTRUE(collapse) && !is.null(dim(out)))) out <- drop(out)

  fill_val <- z$get_item(v$var_name)$get_fill_value()

  out <- replace(out, out == fill_val, NaN)

  if(isTRUE(unpack)) {
    scale <- z$get_item(v$var_name)$get_attrs()$get_item("scale_factor")
    offset <- z$get_item(v$var_name)$get_attrs()$get_item("add_offset")

    if(is.null(offset)) offset <- 0

    if(!is.null(scale)) out <- (out * scale) + offset
  }

  out
}

#' @name get_var
#' @export
get_var.NULL <- function(z, var, start = NA, count = NA,
                         collapse = TRUE, unpack = FALSE, ...) {
  NULL
}
