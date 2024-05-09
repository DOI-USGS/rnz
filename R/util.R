# useful for getting only the data arrays
nodots <- function(x) {
  x[!grepl("\\.zattrs|\\.zgroup|\\.zmetadata", x)]
}

# using this to validate all over the place
is_zarr <- function(z) {
  if(!inherits(z, "ZarrGroup")) stop("z must be a zarr group")
  invisible(TRUE)
}

# pull out the `_ARRAY_DIMENSIONS` xarray convention
get_array_dims <- function(x) {
  stopifnot(inherits(x, "ZarrArray"))

  as.character(x$get_attrs()$to_list()$`_ARRAY_DIMENSIONS`)
}

# gets the unique array dimensions.
# this is used as a proxy for the order in which
# the dimensions are declared.
get_unique_dims <- function(z, vars = get_vars(z)) {
  is_zarr(z)

  unique(unlist(lapply(vars, \(x) get_array_dims(z$get_item(x)))))
}

# just pull out all the variables from the root group.
get_vars <- function(z) {
  is_zarr(z)

  nodots(z$get_store()$listdir())
}

# only return variables that are not the same name as a dimension
get_coord_vars <- function(z, vars = get_vars(z)) {
  is_zarr(z)

  dims <- get_dims(z)

  vars[vars %in% dims]
}
