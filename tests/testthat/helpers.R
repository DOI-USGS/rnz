z_path <- z_demo()

if(requireNamespace("pizzarr", quietly = TRUE)) {
  zarr_consolidated <- open_nz("https://raw.githubusercontent.com/DOI-USGS/rnz/main/inst/extdata/bcsd.zarr")
  z <- open_nz(z_path)
}

nc_file <- z_demo(format = "netcdf")

nc <- open_nz(nc_file, backend = "RNetCDF")
