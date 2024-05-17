
<!-- README.md is generated from README.Rmd. Please edit that file -->

# `rnz` R NetCDF Zarr

This is a work in progress package aiming to provide an RNetCDF-like set
of functions that wrap the
[`pizzarr`](https://github.com/keller-mark/pizzarr) package.

``` r

z <- rnz::z_demo()

bcsd <- rnz::open_zarr(z)

class(bcsd)
#> [1] "ZarrGroup" "R6"

# TODO: implement a nc_dump print-like method to print CDL for a zarr object

rnz::inq_store(bcsd) |> str()
#> List of 4
#>  $ ndims : int 3
#>  $ nvars : int 5
#>  $ ngatts: int 30
#>  $ format: chr "DirectoryStore"

rnz::inq_grp(bcsd) |> str() # only the root group supported
#> List of 6
#>  $ grps    : list()
#>  $ name    : chr "/"
#>  $ fullname: chr "/"
#>  $ dimids  : num [1:3] 0 1 2
#>  $ varids  : num [1:5] 0 1 2 3 4
#>  $ ngatts  : int 30

rnz::inq_dim(bcsd, 0) |> str()
#> List of 3
#>  $ id    : num 0
#>  $ name  : chr "latitude"
#>  $ length: int 33
rnz::inq_dim(bcsd, "latitude") |> str()
#> List of 3
#>  $ id    : num 0
#>  $ name  : chr "latitude"
#>  $ length: int 33

rnz::inq_var(bcsd, 0) |> str()
#> List of 6
#>  $ id    : num 0
#>  $ name  : chr "latitude"
#>  $ type  : chr "<f4"
#>  $ ndims : int 1
#>  $ dimids: num 0
#>  $ natts : int 7
rnz::inq_var(bcsd, "latitude") |> str()
#> List of 6
#>  $ id    : num 0
#>  $ name  : chr "latitude"
#>  $ type  : chr "<f4"
#>  $ ndims : int 1
#>  $ dimids: num 0
#>  $ natts : int 7

rnz::inq_att(bcsd, 0, 5) |> str()
#> List of 4
#>  $ id    : num 5
#>  $ name  : chr "units"
#>  $ type  : chr "character"
#>  $ length: int 1
rnz::inq_att(bcsd, "latitude", "units") |> str()
#> List of 4
#>  $ id    : num 5
#>  $ name  : chr "units"
#>  $ type  : chr "character"
#>  $ length: int 1

rnz::get_var(bcsd, 0) |> str()
#>  num [1:33(1d)] 33.1 33.2 33.3 33.4 33.6 ...
rnz::get_var(bcsd, "latitude") |> str()
#>  num [1:33(1d)] 33.1 33.2 33.3 33.4 33.6 ...

rnz::get_att(bcsd, 0, 5)
#> [1] "degrees_north"
rnz::get_att(bcsd, "time", "units")
#> [1] "days since 1950-01-01"
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
