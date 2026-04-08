rnz v0.3.0
==============

v0.3.0 of `rnz` adds support for Zarr v3 stores following the
[NetCDF–Zarr (NZ-1.0)](https://github.com/zarr-conventions/nz/) convention,
alongside the existing Zarr v2 (xarray `_ARRAY_DIMENSIONS`) support. The
inquiry and read API now dispatches against both v2 and v3 stores through the
same `ZarrGroup` methods, with helpers in [`R/util.R`](R/util.R) branching on
store format. New tests in
[`tests/testthat/test_nz_v3.R`](tests/testthat/test_nz_v3.R) and
[`tests/testthat/test_bcsd_v2_v3.R`](tests/testthat/test_bcsd_v2_v3.R) lock in
parity between the v2, v3, and NetCDF code paths. The package now depends on a
remote build of `pizzarr` for v3 features, and the pkgdown site has been
migrated to a GitHub Actions workflow.

rnz v0.2.0
==============

v0.2.0 of `rnz` introduces S3 methods to the package and brings in RNetCDF as an alternate dispatch pathway.

rnz v0.1.0
==============

The initial release of `rnz` includes a read-only set of zarr utilities that mimid the RNetCDF function signatures.
