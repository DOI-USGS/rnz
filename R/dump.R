#' Dump zarr like ncdump
#' @description
#' Prints an ncdump-like output to the console.
#'
#' @param nz path to store, open zarr store, or open zarr group
#' @return a list of lines printed to the console invisibly
#' @export
#' @examples
#' store <- rnz::z_demo()
#'
#' nzdump(store)
#'
#' nc <- z_demo(format = "netcdf")
#'
#' nzdump(nz)
#'
#' @name nzdump
#' @export
nzdump <- function(nz) {
  if(is.null(nz)) return(NULL)

  UseMethod("nzdump")
}

#' @name nzdump
#' @export
nzdump.character <- function(nz) {

  nz <- suppressWarnings(open_nz(nz))

  if(inherits(nz, "try-error")) {
    warning("could't interpret nz input as a zarr store or NetCDF resource")
    return(invisible(NULL))
  }

  nzdump(nz)
}

#' @name nzdump
#' @export
nzdump.NetCDF <- function(nz) {
  return(invisible(RNetCDF::print.nc(nz)))
}

#' @name nzdump
#' @export
nzdump.ZarrGroup <- function(nz) {

  inz <- inq_nz_source(nz)

  dims <- vapply(z_seq(inz$ndims), \(i) {
    d <- inq_dim(nz, i)
    paste0(d$name, " = ", d$length, " ;")
  }, "")

  vars <- lapply(z_seq(inz$nvars), \(i) {
    v <- inq_var(nz, i)

    dim_names <- vapply(v$dimids, \(d) inq_dim(nz, d)$name, "")

    v$atts <- lapply(z_seq(v$natts), \(i) get_att(nz, v$id, i))

    names(v$atts) <- vapply(z_seq(v$natts), \(i) inq_att(nz, v$id, i)$name, "")

    c(paste0("\t", v$type, " ", v$name, "(", paste(dim_names, collapse = ", "), ") ;"),
      vapply(z_seq(v$natts), \(i) {
        aname <- inq_att(nz, v$id, i)$name
        aval <- get_att(nz, v$id, i)
        paste0("\t\t", v$name, ":", aname, " = ", aval, " ;")
      }, ""))

    })

  vars <- unlist(vars)

  gatts <- vapply(z_seq(inz$ngatts), \(i) {
    aname <- inq_att(nz, -1, i)$name
    aval <- get_att(nz, -1, i)
    paste0("\t\t", ":", aname, " = ", paste(aval, collapse = ", "), " ;")
  }, "")

  lines <- c("zarr {",
             "dimensions:",
             dims,
             "variables:",
             vars,
             "",
             "// global attributes:",
             gatts,
             "}")

  cat(lines, sep = "\n")

  return(invisible(lines))
}




