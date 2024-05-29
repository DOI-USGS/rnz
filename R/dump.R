#' Dump zarr like ncdump
#' @description
#' Prints an ncdump-like output to the console.
#'
#' @param store path to store, open zarr store, or open zarr group
#' @return a list of lines printed to the console invisibly
#' @export
#' @examples
#' store <- rnz::z_demo()
#'
#' zdump(store)
#'
zdump <- function(store) {

  store <- if(inherits(store, "ZarrGroup")) {
    store
  } else if(is.character(store)) {
    open_zarr(store)
  } else {
    try(open_zarr(store))
  }

  if(is.null(store)) return(NULL)

  if(inherits(store, "try-error")) {
    warning("could't interpret store input as a zarr store")
    return(invisible(NULL))
  }

  istore <- inq_store(store)

  dims <- vapply(z_seq(istore$ndims), \(i) {
    d <- inq_dim(store, i)
    paste0(d$name, " = ", d$length, " ;")
  }, "")

  vars <- lapply(z_seq(istore$nvars), \(i) {
    v <- inq_var(store, i)

    dim_names <- vapply(v$dimids, \(d) inq_dim(store, d)$name, "")

    v$atts <- lapply(z_seq(v$natts), \(i) get_att(store, v$id, i))

    names(v$atts) <- vapply(z_seq(v$natts), \(i) inq_att(store, v$id, i)$name, "")

    c(paste0("\t", v$type, " ", v$name, "(", paste(dim_names, collapse = ", "), ") ;"),
      vapply(z_seq(v$natts), \(i) {
        aname <- inq_att(store, v$id, i)$name
        aval <- get_att(store, v$id, i)
        paste0("\t\t", v$name, ":", aname, " = ", aval, " ;")
      }, ""))

    })

  vars <- unlist(vars)

  gatts <- vapply(z_seq(istore$ngatts), \(i) {
    aname <- inq_att(store, -1, i)$name
    aval <- get_att(store, -1, i)
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




