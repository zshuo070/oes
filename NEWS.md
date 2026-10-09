# oes 1.0.0

Initial public-version numbering, based on development version V1.8.

- Rechecked release-plan Steps 1–6. Plot-only fallbacks now honor and validate
  a supplied measurement range. Explicit original-layout limit overrides
  clear previous y-scale limits before plotting, restoring censored observations
  while retaining the scale configuration and leaving the input plot unchanged.
- Added regressions for those plot edge cases and independent numerical
  checks of multilevel conditional-effect selection and three-condition
  Cousineau–Morey intervals. Corrected the exploratory Hedges' g warning
  to describe the studied calibration setting accurately.
- Added package metadata, namespace declarations, MIT licensing, and the
  software citation with Shuo Zang's ORCID.
- Moved the V1.8 functions into the package's `R/` directory and declared
  runtime dependencies instead of attaching them with `library()`.
- Made `optimal_graph()` the sole exported function. Kept `oes()` as an
  internal calculation engine, with numerical results available through
  `optimal_graph(..., detail = TRUE)$oes`. Updated examples and tests to
  follow this API.
- Retained the V1.8 summary grouping and colour correction, including
  fill-only, shape, and linetype mappings.
- Retained the V1.7 numerical corrections for Hedges' g, Cousineau-Morey
  degrees of freedom, and forwarded column/factor arguments.
- Integrated the standalone numerical and plotting regressions into
  installed-package tests using self-contained data.
- Added a methods guide and clarified the evidence limits:
  *Visualizing Standardized Effect Sizes Using the Framework of Graph Perception and Data Visualization* (Shuo Zang and Denis Cousineau, 2026, unpublished
  manuscript) studied single-factor, two-level comparisons using Cohen's d; broader designs,
  other effect estimators, and generalized ER recommendations remain
  empirically unvalidated extensions.
- Documented that the current a constants come directly from the
  effect-size study and may
  change after further research. A separate package-methods paper is planned.
- Identified the effect-size study's associated OSF resource
  (Zang and Cousineau, 2025; CC BY 4.0):
  <https://doi.org/10.17605/OSF.IO/DRCTA>. This is a resource DOI,
  separate from the unpublished manuscript and software citation.
- Recorded the supplied error-bar study-data provenance (OSF DOI
  10.17605/OSF.IO/DTYBF), the exact CSV reference, and its CC BY 4.0 license.
  Mandatory tests remain independent of external data and network access.
- Added a corrected manual error-bar Study 4B example for the project ZIP
  (`development/example-error-bar-study4b.R`) and included error-bar
  data-source attribution in `inst/doc/error-bar-data-source.md`.
- Identified Cousineau (2017), *Varieties of confidence intervals*
  <https://doi.org/10.5709/acp-0214-z>, as the primary reference for CI
  difference adjustment and combined repeated-measures adjustment. Retained
  Cousineau (2005) and Morey (2008) for normalization and bias correction.
  Clarified that `ci95_corr` omits sqrt(2), while `ci95_dif_corr` applies
  both adjustments; the article supports CI construction, not OES calibration.
- Added recommended graphing workflows: `oes` for y-axis ranges with
  `superb::superb()` for adjustable error bars, custom ggplot2 graphs with
  `oes`, or graphs generated directly by `optimal_graph()`. Cited Cousineau,
  Goulet, and Harding (2021), <https://doi.org/10.1177/25152459211035109>.
- Prepared automated checks for Linux, Windows, and macOS. Release validation
  is in progress; publication follows completed checks.
