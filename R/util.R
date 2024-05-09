nodots <- function(x) {
  x[!grepl("\\.zattrs|\\.zgroup|\\.zmetadata", x)]
}
