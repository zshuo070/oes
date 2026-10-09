# oes 1.0.0 release checks

Updated: 2026-10-09. Implementation: development V1.8 with the scoped
plot-interface corrections recorded below. Only
`optimal_graph()` is exported. Steps 1–6 have author approval; Step 7 is
in progress. GitHub publication and CRAN submission have not occurred.

Steps 1–6 have now been rechecked against the current package. The corrected
archive passed fresh Linux tests and local `--as-cran` checking. Earlier
Windows and macOS results apply to the specific historical archives below;
the corrected current archive has not undergone new remote platform checks.
Passing tests establishes
implementation behavior, not empirical validation beyond the effect-size study.

## Current Steps 1–6 recheck

| Step | Acceptance check | Result |
|---|---|---|
| 1. Package identity | `oes` 1.0.0; authors, maintainer, ORCID, MIT license and software citation agree; only `optimal_graph()` is exported | Passed |
| 2. Package structure | Metadata, namespace, R sources, help, tests, documentation and project files are complete; source build and default staged installation succeed | Passed |
| 3. V1.8 adaptation | Dependencies are declared rather than attached; the numerical estimators, CI adjustments, pooled ER rule and constants are retained; scoped plot-interface defects are fixed | Passed |
| 4. Supplied-test adaptation | Automated examples use self-contained data and the installed API; repeated/mixed fixtures have valid IDs; Study 4B and optional superb demonstrations remain manual | Passed |
| 5. Regression coverage | Independent numerical oracles cover effects, intervals, conditional maximum selection, pooling, fallbacks, grouping, layouts and limits | Passed: 465 assertions across 30 cases |
| 6. Documentation/tutorials | Designs, estimator definitions, ER, pooling, error bars, layouts, fallbacks and limitations agree with the code; names, DOI attribution, workflows and runnable examples are current | Passed |

Two pre-recheck plot defects were reproduced using the preserved original
implementation, then corrected:

- Means-only and unidentified-factor plot-only fallbacks now honor and validate
  `measurement_range`, and identify that range correctly in text output.
- `override_existing_limits = TRUE` clears old explicit y-scale limits before
  building an original-layout graph. This restores observations previously
  censored by the scale while preserving other scale settings and leaving the
  caller's graph unchanged. Calls that cannot determine a recommendation still
  return the original graph.

The Hedges' g warning now identifies the independent, single-factor,
two-level Cohen's d calibration setting. Documentation also clarifies the
minimum of two repeated conditions per stratum and that `LICENSE.md` is
included in the project ZIP. Package version, export, dependency requirements,
effect/CI mathematics, ER constants and original development inputs are unchanged.

Fresh installed-package tests: 465 passed assertions, 30 cases, zero failures,
errors, warnings or skips. Two added independent numerical oracles cover the
full nine-contrast table of a three-level/two-factor design and its winning
standardized contrast, plus three-condition Cousineau–Morey normalization,
correction, degrees of freedom, pooling and difference adjustment.

All three Rd files parsed and rendered as HTML/text. All runnable help and
methods-guide examples passed; the manual Study 4B example passed using
240 observations from 30 participants. Relative documentation links resolve,
and the original CSV SHA256 remains
`77d0afb17d980a8370cb3f62c222848a5b773d7c10663977523925554c08d454`.
The PDF manual compiled; revised pages were visually inspected.

Current source archive: `oes_1.0.0.tar.gz`, built with R 4.6.1 on 2026-10-09.
Size: 42,648 bytes. SHA256:

```text
2249ccbe63a60a6af05ad5cb80b622bf4fd4a66f72367624fe6eb9ba2f7c8983
```

Fresh Linux `R CMD check --as-cran` of that exact archive completed with
**0 errors, 0 warnings and 3 reviewed notes**:

1. Expected first-submission incoming NOTE: maintainer details and “New submission”.
2. HTML validation was skipped because the local `tidy` command is absent.
   HTML help rendered successfully; independent HTML validation is not claimed.
3. A residual local `00LOCK-oes` directory remained after successful default
   staged installation. This is a check-environment artifact, not an archive
   member; package installation, examples, tests and PDF checking passed.

Current evidence is preserved as `steps1-6-*` files in
`development/validation/`. Runtime and dependency records identify the isolated
R 4.6.1 installation, current compiled dependencies, and compatible Ubuntu
packages used to restore the missing test environment. No remote platform
submission, GitHub publication or CRAN submission was performed for this recheck.

## Earlier recommended-workflows documentation rebuild

README and the methods guide now describe three workflows: `oes` for y-axis
ranges plus `superb::superb()` for graphs with adjustable error bars,
custom ggplot2 graphs with `oes`, or `optimal_graph()` alone. The optional
superb workflow cites Cousineau, Goulet, and Harding (2021),
<https://doi.org/10.1177/25152459211035109>. The public API remains
`optimal_graph()`; numerical limits come from its detailed return object.

Archive at that stage: `oes_1.0.0.tar.gz`, built with R 4.6.1 on 2026-10-09.
Size: 39,705 bytes. SHA256:

```text
dea77277e197f77fb72a8ed2df54d12c32091d1bcdf8a9a0b0ed511be0f1ee0b
```

Source build and DESCRIPTION metadata checks passed. Static checks confirm
all three workflows and the citation are present in the built archive;
relative documentation links resolve. Official superb documentation was
reviewed for its current `superb()` entry point and ggplot2 output.
No new executable integration examples were added. All R files, tests, Rd
help pages, DESCRIPTION, namespace, dependencies and software citation
are unchanged from the previous saved project. The previously compiled
manual therefore remains current. Full tests and platform checks were not
rerun for this documentation-only edit; earlier results retain their
recorded archive identities.

## Earlier confidence-interval reference rebuild

Cousineau (2017), *Varieties of confidence intervals*,
<https://doi.org/10.5709/acp-0214-z>, is now the main interval-adjustment
reference. Cousineau (2005) and Morey (2008) remain the normalization and
bias-correction references. README, guide, help pages, NEWS, and DESCRIPTION
now distinguish the normalized/corrected `ci95_corr` base intervals from
`ci95_dif_corr`, which additionally applies sqrt(2), as in the 2017 paper's
combined comparative construction. The article does not provide OES
calibration constants.

Archive at that stage: `oes_1.0.0.tar.gz`, built with R 4.6.1 on 2026-10-09.
Size: 38,829 bytes. SHA256:

```text
50b28971ad1c94a103a6f9445c89237ed9aca912cc7094db06e7e8af442a4a9b
```

Scoped checks passed: source build and DESCRIPTION metadata; all three Rd
files parsed, passed `tools::checkRd`, and rendered as HTML/text; PDF manual
compiled and the revised explanation/reference pages were visually inspected;
relative Markdown links resolved. Archive contents contain the corrected
2017 references with the normalization/correction references retained.

All R files, namespace, test assertions, data, version, API and dependency
fields are unchanged from the previous saved project. Only DESCRIPTION's
Description field changed. The full regression suite and `--as-cran` were
not rerun for this documentation/reference change. Platform results below
remain evidence for their recorded earlier archives.

## Earlier title/resource documentation rebuild

Research references now use *Visualizing Standardized Effect Sizes Using
the Framework of Graph Perception and Data Visualization*, by Shuo Zang
and Denis Cousineau, and the associated OSF resource
<https://doi.org/10.17605/OSF.IO/DRCTA>. The separate error-bar Study 4B
example retains DTYBF and the unchanged `Study4_long.csv`.
The example wrapper and provenance files now explicitly name that study.

Archive at that stage: `oes_1.0.0.tar.gz`, built with R 4.6.1 on 2026-10-09.
Size: 37,875 bytes. SHA256:

```text
5e23cf8010e945395f6add3edcabdf9b42368ccce6e57cbd705afb70c4383f09
```

Scoped verification completed for this edit:

- R source build succeeded; DESCRIPTION metadata check passed.
- All three Rd files parsed and passed `tools::checkRd`; HTML/text help
  rendered. The PDF manual compiled and the updated reference page was
  visually inspected.
- Relative Markdown links resolved and archive contents include the new
  error-bar provenance filename and DRCTA references.
- Function code, namespace, dependencies, software citation, test assertions,
  and CSV bytes are unchanged from the previous saved project.

The full test suite and `--as-cran` were not rerun for this documentation-only
change. The current session lacks the external dependency library reused
by the previous checks, including rstatix. Prior passing results below
refer to earlier archive hashes, not this rebuild's exact bytes.

## Previously platform-checked source archive

File: `oes_1.0.0.tar.gz` (37,080 bytes), built with R 4.6.1.

SHA256:

```text
0580abe12189764a36028b7adfe8d4d065d921cbb2327e1f220e3a08b5b3b483
```

Remote submissions at that stage used this archive. Earlier check jobs used a
source-equivalent build, identified below. The source archive
excludes `development/` and `.github/`; the project ZIP includes historical
inputs, the attributed study-data example, workflow, and check evidence.
The numerical implementation was not changed during release checks.

## Historical platform checks

| Environment | Check | Result |
|---|---|---|
| Ubuntu 24.04, R 4.3.3 | Full `R CMD check --as-cran` of the earlier source-equivalent build; installation and public smoke of final archive | Full prior-build check: 0 errors, 0 warnings, 3 reviewed notes, 384 assertions passed; final archive installs and smoke passes |
| Ubuntu 24.04, R 4.6.1 | Full `R CMD check --as-cran` of the final archive, PDF and HTML manuals | 0 errors, 0 warnings, 1 expected “New submission” note; all 384 assertions passed |
| macOS Tahoe 26.6, Apple Silicon, R 4.6.1 Patched (2026-07-27 r90311) | MacBuilder ordinary `R CMD check` of the earlier source-equivalent build, PDF manual | Two jobs passed: 0 errors, warnings, or notes; 384 assertions per job |
| macOS, final archive | MacBuilder release request | Initial request and one reviewed retry returned HTTP 502 without a result URL; outcomes unknown; no passing final-archive check is claimed |
| Windows, R-release | Official Win-builder, previous archive | Reviewed: 0 errors, 0 warnings, 1 incoming-check NOTE; R 4.6.1 (2026-06-24 ucrt) |
| Windows, R-devel | Official Win-builder, previous archive | Reviewed: 0 errors, 0 warnings, 1 incoming-check NOTE; R-devel (2026-10-05 r90641 ucrt) |
| Actual R-devel | Windows development log | Verified by the reviewed Win-builder log; the earlier MacBuilder development request used a release-family runtime |
| GitHub Actions matrix | macOS/Windows release; Linux release/devel/oldrel-1 | Workflow prepared and parsed; not run because no repository has been created |

The rebuilt archive corrected the generated Author/Authors@R formatting
note found by the first R 4.6.1 check. Final current-R checking has only the
expected new-submission note. The earlier build has SHA256
`343d77eab4b6899b62b54e14e0cf45cea493744d8a18065703ecc0e8d3a90e88`.
All 21 source, documentation, and test files are byte-identical between
these builds; differences are limited to generated DESCRIPTION metadata,
timestamps, and the build cache.

The regression suite has 25 cases and 384 assertions, with zero failures,
errors, warnings, or skips in completed test runs. A separate clean default
staged installation also succeeded.

The R 4.3.3 notes are:

1. Incoming feasibility: maintainer details and “New submission”. This is
   expected for a first CRAN submission.
2. Future timestamps: “unable to verify current time”. This is an
   environment clock-verification limitation.
3. A residual `00LOCK-oes` directory under the check directory. Installation
   completed successfully and all tests/manuals passed. A fresh default
   staged-install probe removed its lock normally, and the checked function
   bodies match the final source. This is a reviewed local check artifact;
   it is not present in the source archive.

The current-R Linux environment uses an isolated R build and rebuilds of
dependencies that require the current R binary interface. It also reuses
compatible older installed packages; its runtime/dependency records are
included with the check evidence. It is not a substitute for the CI matrix
that installs dependencies on each platform.

## Earlier source-equivalent macOS result pages

- [Release request](https://mac.R-project.org/macbuilder/results/1791493026-e66e341c054b8c9f/).
- [Development request](https://mac.R-project.org/macbuilder/results/1791493024-a968568427698647/).

Both requests were accepted with their requested `rflavor`, but both actual
logs show **R 4.6.1 Patched**, a release-family runtime. Their recorded check
arguments do not include `--as-cran`. They establish macOS compatibility
under that runtime; they do not establish R-devel or CRAN incoming-check
coverage. The live form and documented API did not expose a supported
alternative that demonstrably selected a development runtime.

## Reviewed Windows result links

- R-release: <https://win-builder.r-project.org/s19sYA4sUHD8/00check.log>.
- R-devel: <https://win-builder.r-project.org/cSbo8Qh12EG8/00check.log>.

Both logs show installation, examples, tests, PDF and HTML manual checks
passed. Their single incoming-check NOTE includes “New submission” and
possible spelling flags for Cousineau and Morey; these are correctly spelled
surnames. Preserved logs are in `development/validation/`.
The earlier conversation recorded 384 assertions for each Windows run;
this update retrieved the main logs, which confirm the tests passed but do
not independently list the assertion count.

## Remaining work

The earlier macOS source-equivalent build passed. Successful verification of
the exact platform-submitted final archive was not obtained because of
service errors. The corrected current archive has not been sent
for new Windows or macOS checks. The prepared GitHub workflow remains unrun.

The current intended source archive now has a fresh Linux `--as-cran` result.
Before CRAN submission, complete current-platform validation and resolve the
local HTML-validator and installation-lock environment notes. Because this
recheck includes plot-interface fixes, historical remote results are not
reported as checks of the current code. Keep each historical result associated
with the archive actually checked. No publication or CRAN submission has occurred.

Check evidence is in `development/validation/` in the project ZIP. Official
service guidance is linked in `development/CROSS_PLATFORM_CHECKS.md`.
