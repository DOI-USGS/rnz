z_path <- z_demo()

if(requireNamespace("pizzarr", quietly = TRUE)) {
  z <- open_nz(z_path)
}

nc_file <- z_demo(format = "netcdf")

nc <- open_nz(nc_file, backend = "RNetCDF")
