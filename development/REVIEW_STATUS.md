# Author review checkpoint: oes 1.0.0

Shuo Zang has approved Steps 1–6 of the release plan as of 2026-10-08.
Step 7 (release checks) is in progress. GitHub publication and CRAN
submission are later actions and have not been performed.

Steps 1–6 were rechecked on 2026-10-09: package identity, structure, V1.8
adaptation, supplied-test adaptation, regression coverage, and documentation.
Two reproduced plot-interface defects were fixed and documentation clarified.
Fresh tests passed 465 assertions across 30 cases with zero failures, errors,
warnings or skips. Runnable help, guide and manual Study 4B examples passed.
The exact current source archive passed Linux `--as-cran` with zero errors,
zero warnings and three reviewed notes. See `RELEASE_CHECKS.md` for the
step-by-step acceptance table, fixes, evidence, archive identity and note details.

Components 1-3 were initially approved by Shuo Zang on 2026-10-08. The author
subsequently requested `optimal_graph()` as the sole exported function and
`oes()` as an internal calculation engine. Documentation, examples, and
package tests now follow that API. The effect-size, CI and ER mathematics
are retained; the subsequent scoped plot-interface corrections are in `NEWS.md`.

## Step 4: supplied-test adaptation and study example

- Original installed-package regression suite: 384 assertions across 25 tests,
  all passed on the earlier Linux/R 4.3.3 environment. The current recheck
  expands this suite to 465 assertions across 30 cases.
- Coverage and example corrections: `tests/testthat/README.md`.
- Test source: `tests/testthat/test-*.R` and `helper-fixtures.R`.
- Public API checks confirm that only `optimal_graph()` is exported;
  internal numerical regressions access `oes()` explicitly from its namespace.
- Corrected actual-data example: `development/example-error-bar-study4b.R`.
- Unmodified OSF CSV and source/license: `development/Study4_long.csv` and
  `development/ERROR_BAR_DATA_SOURCE.md`.
- The manual CSV example passed with the complete 30-participant profiles.
  Automated tests do not need that file or network access.

## Step 5: regression coverage

Review `tests/testthat/README.md` and the installed-package tests. The current
suite includes independent numerical oracles for multilevel conditional-effect
selection and three-condition Cousineau–Morey intervals, plus the reproduced
plot-fallback and limit-override edge cases. Coverage verifies software
behavior, not empirical transfer of the effect-size study.

## Step 6: documentation and tutorials

Review `README.md`, `NEWS.md`, `inst/doc/methods-guide.md` and the updated `man/`
help pages for installation, citation, provenance, evidence limits and the effect-size study's
scope, generalized designs, estimator definitions, ER constants, pooling,
error bars, layouts, fallbacks, and limitations. The guide's runnable examples
passed. A separate package-methods paper is planned; this guide is not that
manuscript and does not assign it publication details.

Build and local installation passed. These checks verify implementation and
documentation, not empirical transfer of the effect-size study. See `CROSS_PLATFORM_CHECKS.md`
and the release-check report for the subsequent validation results.

## Step 7: release checks

The earlier platform-submitted source archive, built with R 4.6.1, passed full `--as-cran` checking:
0 errors, 0 warnings, one expected new-submission note, and all 384 assertions
passed. The final archive also installs and passes public API smoke checks
on R 4.3.3. Earlier macOS jobs passed on byte-identical sources, while final
archive requests returned service errors without result URLs. The Windows release and actual R-devel logs for that archive have now
been reviewed: each has zero errors and warnings and one incoming-check
note. The current corrected archive is newer and has a fresh Linux check;
the earlier remote platform checks are historical evidence, not checks of its
exact bytes or corrected code. New Windows/macOS checking remains Step 7 work.
See `RELEASE_CHECKS.md` for precise
archive hashes, runtime scope, submission timestamps, and outstanding work.

## Research names and sources: 2026-10-09

The effect-size manuscript is *Visualizing Standardized Effect Sizes Using
the Framework of Graph Perception and Data Visualization*, by Shuo Zang
and Denis Cousineau. Its OSF research resource is
<https://doi.org/10.17605/OSF.IO/DRCTA>. The resource DOI does not identify
the software or a published journal article.

The manual error-bar Study 4B example retains the separate DTYBF resource
and the original `Study4_long.csv` filename. Its wrapper and provenance
files now explicitly identify the error-bar study. Documentation and
links have been updated; calculations and original input files are unchanged.
The rebuilt archive and its new checks are recorded in `RELEASE_CHECKS.md`.

## Confidence-interval reference correction: 2026-10-09

Cousineau (2017), *Varieties of confidence intervals*,
<https://doi.org/10.5709/acp-0214-z>, is the main reference for the interval
adjustment framework. Cousineau (2005) and Morey (2008) remain the
normalization and bias-correction references. The documentation distinguishes
`ci95_corr` (the normalized and corrected base interval) from
`ci95_dif_corr` (also multiplied by sqrt(2)), the combined comparative
construction described in the 2017 paper. No calculations or options changed.

## Recommended graphing workflows: 2026-10-09

README and the methods guide now recommend three alternatives: `oes` for
y-axis ranges plus `superb::superb()` for graphs with adjustable error bars,
custom ggplot2 graphs with `oes`, or `optimal_graph()` on its own. The optional
superb workflow cites Cousineau, Goulet, and Harding (2021),
<https://doi.org/10.1177/25152459211035109>. No package dependency, code,
function export or numerical method was changed by this documentation edit.
