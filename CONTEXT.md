# rnz

R package providing an `RNetCDF`-like inquiry/read API over both NetCDF
files (via `RNetCDF`) and Zarr stores (via `pizzarr`). The Zarr backend
is the focus of active development; the `RNetCDF` backend is a
compatibility shim so the same code paths can be exercised against
equivalent NetCDF data.

## References

The two normative references for this package are:

- **NUG** — [NetCDF Users Guide](https://docs.unidata.ucar.edu/nug/current/).
  The structural reference for the netCDF data model: dimensions,
  variables, attributes, coordinate variables, `_FillValue`, and the
  `Conventions` attribute. This is what `RNetCDF` exposes.
- **NZ-1.0** — [NetCDF–Zarr convention](https://github.com/zarr-conventions/nz/).
  The structural interoperability layer that puts NUG-equivalent
  semantics on top of Zarr v3. This is what the Zarr backend should
  target. NZ is to Zarr v3 what the NUG is to netCDF-4: it defines
  shared dimensions, dimension coordinates, `_FillValue` semantics, and
  the `conventions` attribute, without entering domain-convention
  territory (CF, GeoZarr, etc.).

The mental model: every `inq_*` / `get_*` function in this package
should behave the same way against a NetCDF file (NUG-defined) and
against an NZ-compliant Zarr store. The `RNetCDF` and `pizzarr` S3
methods are two implementations of one API.

Key NZ structural rules to keep in mind when working on the Zarr
backend:

- Every array MUST have a fully populated `dimension_names`
  (NZ-1.0 §Array). Dimension labels carry co-extent within a group
  (shared dimension constraint).
- A *dimension coordinate* is structurally identified: 1D array whose
  single `dimension_names` entry equals its own name and whose values
  are strictly monotonic. No attribute is required.
- `_FillValue` (an attribute) is the **semantic** missing-data
  indicator. It is decoupled from Zarr's storage-level `fill_value`.
- The root-group `conventions` attribute declares NZ compliance;
  `Conventions` (capital C, NUG style) MUST be treated as equivalent on
  read.
- For Zarr v2 datasets, the equivalent of `dimension_names` is the
  `_ARRAY_DIMENSIONS` attribute under the xarray convention. The
  current code base reads v2 stores via this attribute (see
  [`R/util.R`](R/util.R), `get_array_dims`).

When the NUG and NZ disagree on a detail (e.g. `Conventions` vs
`conventions`, unlimited dimensions, user-defined types), prefer the
NZ behavior on the Zarr code path and the NUG behavior on the
`RNetCDF` code path. NZ Appendix B documents the differences.

## Companion package: pizzarr

`pizzarr` is the Zarr v2/v3 implementation that this package delegates
to. It is on CRAN and is listed in `Suggests` in
[`DESCRIPTION`](DESCRIPTION). When debugging Zarr-side issues, consult
the pizzarr documentation — its R6 store / group / array classes are
what the `ZarrGroup` S3 methods here are calling.

Conventions inherited from pizzarr that apply here:

- **Style**: snake_case for functions, methods, and variables.
  2-space indent.
- **Errors**: prefer `stop("Message")` from base R. No `rlang`, no
  assertion library — use direct `if (...) stop(...)` /
  `stopifnot(...)`.
- **Warnings/info**: base R `warning()` and `message()`.
- **Tests**: testthat 3e (`Config/testthat/edition: 3`), parallel on
  non-Windows (`Config/testthat/parallel: true`). Test fixtures and
  shared open handles live in [`tests/testthat/helpers.R`](tests/testthat/helpers.R).
- **Roxygen**: one S3 generic per file with each method documented
  under the same `@name` and re-exported. See [`R/inq_var.R`](R/inq_var.R)
  for the canonical pattern.

## Commands

- `Rscript -e "devtools::test()"` — run tests
- `Rscript -e "devtools::check()"` — R CMD check
- `Rscript -e "devtools::document()"` — rebuild roxygen docs
- Rscript on this machine: `/c/Users/dblodgett/AppData/Local/Programs/R/R-4.5.2/bin/Rscript.exe`
- Multiline R commands must be run from a script file, not pasted into
  the bash tool, to avoid terminal segfaults on Windows.

## Code organization

One file per inquiry concept, mirroring `RNetCDF`:

- [`R/open.R`](R/open.R) — `open_nz()` S3 generic. Tries `pizzarr`
  first, falls back to `RNetCDF`. Methods: `Store`, `character`,
  `NULL`.
- [`R/inq_store.R`](R/inq_store.R) — `inq_nz_source()` (parallels
  `RNetCDF::file.inq.nc`).
- [`R/inq_grp.R`](R/inq_grp.R) — group inquiry. Only the root group is
  currently supported.
- [`R/inq_dim.R`](R/inq_dim.R) — dimension inquiry. The Zarr method
  uses `_ARRAY_DIMENSIONS` (xarray / NZ-equivalent on v2) — see the
  NOTE in the roxygen header.
- [`R/inq_var.R`](R/inq_var.R) — variable inquiry. Includes the
  `var_char_to_id` zero-indexing helper.
- [`R/inq_att.R`](R/inq_att.R) — attribute inquiry, with the global
  attribute alias (`-1`, `"global"`, `"NC_GLOBAL"`).
- [`R/get_var.R`](R/get_var.R), [`R/get_att.R`](R/get_att.R) — value
  retrieval.
- [`R/dump.R`](R/dump.R) — `nzdump()` (CDL-ish text dump, parallels
  `ncdump`).
- [`R/util.R`](R/util.R) — internal helpers: `get_vars`,
  `get_array_dims`, `get_unique_dims`, `get_rep_var`, `var_prep`,
  `att_prep`, `z_seq`, `nodots`, `z_demo`. **Read this first** when
  touching the Zarr backend; nearly every method depends on it.
- [`R/close.R`](R/close.R) — close handles.

## API conventions (RNetCDF parity)

- Variable, dimension, and attribute IDs are **zero-indexed integers**
  to match `RNetCDF` / NUG. `z_seq()` exists in [`R/util.R`](R/util.R)
  for this. When converting `which()` results to IDs, subtract 1.
- The global-attribute id is `-1`. The strings `"global"` and
  `"NC_GLOBAL"` are accepted as aliases (see `att_prep` in
  [`R/util.R`](R/util.R)).
- Each public function is an S3 generic with at least:
  `.character` (path → opens then re-dispatches),
  `.ZarrGroup` (pizzarr backend),
  `.NetCDF` (RNetCDF backend, usually a one-liner pass-through),
  `.NULL` (returns `NULL`, used so pipelines stay safe when `open_nz`
  returned `NULL`).
- Return values must match the field names that `RNetCDF` returns
  (`id`, `name`, `length`, `type`, `ndims`, `dimids`, `natts`,
  `ngatts`, `format`, ...). Tests in
  [`tests/testthat/test_inq.R`](tests/testthat/test_inq.R) lock these
  in.

## Gotchas

- `pizzarr::zarr_open()` is wrapped in `try()` inside `open_nz()` —
  failures should produce a `try-error` that the caller can detect, not
  an abort. Don't strip the `try()`.
- The current Zarr inquiry path assumes the root group only. Nested
  groups are out of scope until consciously added — many helpers in
  [`R/util.R`](R/util.R) call `z$get_store()$listdir()` against the
  root.
- `get_unique_dims()` is used as a proxy for "the order in which
  dimensions are declared" for the purpose of assigning zero-based
  dimension IDs. The order is whatever pizzarr returns from
  `listdir()` — be careful when reasoning about `dimids` stability.
- `nodots()` filters `.zattrs`, `.zgroup`, and `.zmetadata` from a
  store listing. This is Zarr v2-specific. If/when v3 is wired up,
  the equivalent filter is needed for `zarr.json`.
- `_ARRAY_DIMENSIONS` is **v2 only**. NZ-1.0 / Zarr v3 carries the
  same information in the `dimension_names` field of `zarr.json`. The
  helpers in `util.R` will need a v3 branch when v3 support lands.
- Consolidated metadata: `get_all_dims()` already special-cases
  `zarr_consolidated_format == 1`. Preserve this — pulling metadata
  from the consolidated blob avoids one HTTP request per array on
  remote stores.
- Tests open a remote Zarr store from the GitHub raw URL (see
  [`tests/testthat/helpers.R`](tests/testthat/helpers.R)). Tests will
  fail without network. There is no VCR mocking here.
- Demo data lives in [`inst/extdata/`](inst/extdata/): `bcsd_obs_1999.nc`
  for NetCDF and `bcsd_obs_1999.zip` (unzipped on demand by `z_demo()`)
  for Zarr.

## When extending the Zarr backend

1. Read NZ-1.0 first, especially the Data Model and Properties
   sections, to confirm the structural concept you are exposing.
2. Confirm the `RNetCDF` equivalent in the NUG so the return shape
   matches what the existing tests expect.
3. Add the S3 method on `ZarrGroup`, share helpers via
   [`R/util.R`](R/util.R), and add the `.NULL` and `.character`
   methods so the dispatch table is complete.
4. Update [`tests/testthat/test_inq.R`](tests/testthat/test_inq.R) (or
   the relevant test file) with both a `zarr_test` assertion and an
   `nc` cross-check using `expect_equal`.
5. If you touch anything that depends on Zarr v3, branch on the format
   rather than retrofitting v2 helpers. NZ-1.0 §Appendix A enumerates
   the v3 vs v2 differences relevant here.
