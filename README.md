
<!-- README.md is generated from README.Rmd. Please edit that file -->

# `rnz` R NetCDF Zarr

This is a work in progress package aiming to provide an RNetCDF-like set
of functions that wrap the
[`pizzarr`](https://github.com/keller-mark/pizzarr) package.

``` r

z <- system.file("extdata", "bcsd_obs_1999.zarr", package = "rnz")

bcsd <- rnz::open_zarr(z)

class(bcsd)
#> [1] "ZarrGroup" "R6"

bcsd
#> <ZarrGroup>
#>   Public:
#>     clone: function (deep = FALSE) 
#>     contains_item: function (item) 
#>     create_dataset: function (name, data = NA, ...) 
#>     create_group: function (name, overwrite = FALSE) 
#>     get_attrs: function () 
#>     get_chunk_store: function () 
#>     get_item: function (item) 
#>     get_meta: function () 
#>     get_name: function () 
#>     get_path: function () 
#>     get_read_only: function () 
#>     get_store: function () 
#>     get_synchronizer: function () 
#>     initialize: function (store, path = NA, read_only = FALSE, chunk_store = NA, 
#>   Private:
#>     attrs: Attributes, R6
#>     cache_attrs: NULL
#>     chunk_store: NA
#>     create_dataset_nosync: function (name, data = NA, ...) 
#>     create_group_nosync: function (name, overwrite = FALSE) 
#>     item_path: function (item) 
#>     key_prefix: 
#>     meta: list
#>     path: 
#>     read_only: TRUE
#>     store: DirectoryStore, Store, R6
#>     synchronizer: NULL
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
