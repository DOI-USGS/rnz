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
get_array_dims <- function(x, include_size = TRUE) {
  stopifnot(inherits(x, "ZarrArray"))

  out <- list(name = as.character(x$get_attrs()$to_list()$`_ARRAY_DIMENSIONS`))

  if(include_size) {

    out$length <- sapply(seq_along(out$name), \(i) x$get_shape()[i])

  }

  out
}

# gets the unique array dimensions.
# this is used as a proxy for the order in which
# the dimensions are declared.
get_unique_dims <- function(z, vars = get_vars(z)) {
  is_zarr(z)

  unique(unlist(get_all_dims(z, vars)))
}

# gets all array dimensions for provided vars
get_all_dims <- function(z, vars = get_vars(z)) {
  is_zarr(z)

  out <- lapply(vars, \(x) get_array_dims(z$get_item(x), include_size = FALSE))

  names(out) <- vars

  out
}

get_dim_size <- function(z, vars = get_vars(z)) {

  is_zarr(z)

  out <- lapply(vars, \(x) get_array_dims(z$get_item(x), include_size = TRUE))

  names(out) <- vars

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

# gets a representative variable for a given dimension name
# will return the coordinate variable if it exists
get_rep_var <- function(z, dim_name) {
  is_zarr(z)

  stopifnot(is.character(dim_name), dim_name %in% get_unique_dims(z))

  all_var_dims <- get_all_dims(z)

  # if there is a coordinate variable, return it
  if(any(names(all_var_dims) == dim_name))
    return(all_var_dims[names(all_var_dims) == dim_name][[1]]$name)

  # otherwise return the first variable on that dimension
  all_var_dims[sapply(all_var_dims, \(x) any(grepl(dim_name, x)))][1][[1]]$name
}
