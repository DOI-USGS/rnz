
<!-- README.md is generated from README.Rmd. Please edit that file -->

# `rnz` R NetCDF Zarr

# rnz <img src="man/figures/logo.png" align="right" height="139" alt="" />

[![codecov](https://codecov.io/github/dblodgett-usgs/rnz/graph/badge.svg?token=8DZJ7RYIOJ)](https://codecov.io/github/dblodgett-usgs/rnz)

This is a work in progress package aiming to provide an RNetCDF-like set
of functions that wrap the
[`pizzarr`](https://github.com/keller-mark/pizzarr) package.

``` r

z <- rnz::z_demo() # to use a directory store

# to use an http store
z <- "https://raw.githubusercontent.com/DOI-USGS/rnz/main/inst/extdata/bcsd.zarr/"

bcsd <- rnz::open_nz(z)

class(bcsd)
#> [1] "ZarrGroup" "R6"
```

``` r

if(!is.null(bcsd)) {

rnz::inq_nz_source(bcsd) |> str()

rnz::inq_grp(bcsd) |> str() # only the root group supported

rnz::inq_dim(bcsd, 0) |> str()
rnz::inq_dim(bcsd, "latitude") |> str()

rnz::inq_var(bcsd, 0) |> str()
rnz::inq_var(bcsd, "latitude") |> str()

rnz::inq_att(bcsd, 0, 5) |> str()
rnz::inq_att(bcsd, "latitude", "units") |> str()

rnz::get_var(bcsd, 0) |> str()
rnz::get_var(bcsd, "latitude") |> str()

rnz::get_att(bcsd, 0, 5)
rnz::get_att(bcsd, "time", "units")

rnz::nzdump(bcsd)

}
#> List of 4
#>  $ ndims : int 3
#>  $ nvars : int 5
#>  $ ngatts: int 30
#>  $ format: chr "HttpStore"
#> List of 6
#>  $ grps    : list()
#>  $ name    : chr "/"
#>  $ fullname: chr "/"
#>  $ dimids  : num [1:3] 0 1 2
#>  $ varids  : num [1:5] 0 1 2 3 4
#>  $ ngatts  : int 30
#> List of 3
#>  $ id    : num 0
#>  $ name  : chr "latitude"
#>  $ length: int 33
#> List of 3
#>  $ id    : num 0
#>  $ name  : chr "latitude"
#>  $ length: int 33
#> List of 6
#>  $ id    : num 0
#>  $ name  : chr "latitude"
#>  $ type  : chr "<f4"
#>  $ ndims : int 1
#>  $ dimids: num 0
#>  $ natts : int 6
#> List of 6
#>  $ id    : num 0
#>  $ name  : chr "latitude"
#>  $ type  : chr "<f4"
#>  $ ndims : int 1
#>  $ dimids: num 0
#>  $ natts : int 6
#> List of 4
#>  $ id    : num 5
#>  $ name  : chr "units"
#>  $ type  : chr "character"
#>  $ length: int 1
#> List of 4
#>  $ id    : num 5
#>  $ name  : chr "units"
#>  $ type  : chr "character"
#>  $ length: int 1
#>  num [1:33(1d)] 33.1 33.2 33.3 33.4 33.6 ...
#>  num [1:33(1d)] 33.1 33.2 33.3 33.4 33.6 ...
#> zarr {
#> dimensions:
#> latitude = 33 ;
#> longitude = 81 ;
#> time = 12 ;
#> variables:
#>  <f4 latitude(latitude) ;
#>      latitude:_CoordinateAxisType = Lat ;
#>      latitude:axis = Y ;
#>      latitude:bounds = latitude_bnds ;
#>      latitude:long_name = Latitude ;
#>      latitude:standard_name = latitude ;
#>      latitude:units = degrees_north ;
#>  <f4 longitude(longitude) ;
#>      longitude:_CoordinateAxisType = Lon ;
#>      longitude:axis = X ;
#>      longitude:bounds = longitude_bnds ;
#>      longitude:long_name = Longitude ;
#>      longitude:standard_name = longitude ;
#>      longitude:units = degrees_east ;
#>  <f4 pr(time, latitude, longitude) ;
#>      pr:coordinates = time latitude longitude  ;
#>      pr:long_name = monthly_sum_pr ;
#>      pr:name = pr ;
#>      pr:units = mm/m ;
#>  <f4 tas(time, latitude, longitude) ;
#>      tas:coordinates = time latitude longitude  ;
#>      tas:long_name = monthly_avg_tas ;
#>      tas:missing_value = 1.00000002004088e+20 ;
#>      tas:name = tas ;
#>      tas:units = C ;
#>  <f8 time(time) ;
#>      time:_CoordinateAxisType = Time ;
#>      time:calendar = standard ;
#>      time:standard_name = time ;
#>      time:units = days since 1950-01-01 ;
#> 
#> // global attributes:
#>      :CDI = Climate Data Interface version 1.5.6 (http://code.zmaw.de/projects/cdi) ;
#>      :CDO = Climate Data Operators version 1.5.6.1 (http://code.zmaw.de/projects/cdo) ;
#>      :Conventions = CF-1.0 ;
#>      :History = Translated to CF-1.0 Conventions by Netcdf-Java CDM (CFGridWriter2)
#> Original Dataset = bcsd_obs; Translation Date = 2019-01-03T20:03:59.756Z ;
#>      :Metadata_Conventions = Unidata Dataset Discovery v1.0 ;
#>      :NCO = netCDF Operators version 4.7.6 (Homepage = http://nco.sf.net, Code = http://github.com/nco/nco) ;
#>      :acknowledgment = Maurer, E.P., A.W. Wood, J.C. Adam, D.P. Lettenmaier, and B. Nijssen, 2002, A Long-Term Hydrologically-Based Data Set of Land Surface Fluxes and States for the Conterminous United States, J. Climate 15(22), 3237-3251 ;
#>      :cdm_data_type = Grid ;
#>      :date_created = 2014 ;
#>      :date_issued = 2015-11-01 ;
#>      :geospatial_lat_max = 37.0625 ;
#>      :geospatial_lat_min = 33.0625 ;
#>      :geospatial_lon_max = -74.9375 ;
#>      :geospatial_lon_min = -84.9375 ;
#>      :history = Mon Jan  7 18:59:08 2019: ncks -4 -L3 bcsd_obs_1999_two_var.nc bcsd_obs_1999_two_var.nc.comp
#> Thu May 08 12:07:18 2014: cdo monsum gridded_obs/daily/gridded_obs.daily.Prcp.1950.nc gridded_obs/monthly/gridded_obs.monthly.pr.1950.nc ;
#>      :id = cida.usgs.gov/bcsd_obs ;
#>      :institution = Varies, see http://gdo-dcp.ucllnl.org/downscaled_cmip_projections/ ;
#>      :keywords = Atmospheric Temperature, Air Temperature Atmosphere, Precipitation, Rain, Maximum Daily Temperature, Minimum  Daily Temperature ;
#>      :keywords_vocabulary = GCMD Science Keywords ;
#>      :license = Freely available ;
#>      :naming_authority = cida.usgs.gov ;
#>      :processing_level = Gridded meteorological observations ;
#>      :publisher_email = dblodgett@usgs.gov ;
#>      :publisher_name = Center for Integrated Data Analytics ;
#>      :publisher_url = https://www.cida.usgs.gov/ ;
#>      :summary = These are the monthly observational data used for BCSD downscaling. See: http://gdo-dcp.ucllnl.org/downscaled_cmip_projections/dcpInterface.html#About for more information. ;
#>      :time_coverage_end = 1999-12-15T00:00 ;
#>      :time_coverage_resolution = P1M ;
#>      :time_coverage_start = 1950-01-15T00:00 ;
#>      :title = Monthly Gridded Meteorological Observations ;
#> }
```

# Disclaimer

This software is preliminary or provisional and is subject to revision.
It is being provided to meet the need for timely best science. The
software has not received final approval by the U.S. Geological Survey
(USGS). No warranty, expressed or implied, is made by the USGS or the
U.S. Government as to the functionality of the software and related
material nor shall the fact of release constitute any such warranty. The
software is provided on the condition that neither the USGS nor the U.S.
Government shall be held liable for any damages resulting from the
authorized or unauthorized use of the software.

[![CC0](https://i.creativecommons.org/p/zero/1.0/88x31.png)](https://creativecommons.org/publicdomain/zero/1.0/)
