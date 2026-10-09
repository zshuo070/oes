# oes 1.0.0: cross-platform release checks

These instructions describe Step 7 checks. Completed results and pending
items are recorded in `RELEASE_CHECKS.md`. A workflow file and instructions
are not evidence that remote checks have passed. Record the actual R version,
operating system, archive SHA256, check summary, and result/log URL for each
completed run. Review every ERROR, WARNING, and NOTE before release.

## Check the built archive locally first

From the parent of the `oes/` project directory:

```sh
R CMD build oes
R CMD check --as-cran oes_1.0.0.tar.gz
```

Use the newly built archive, rather than an earlier archive with the same
filename. Run the checks in a clean directory, and preserve `00check.log`
and the test output. This command includes PDF-manual checks, which require
a working LaTeX installation. A check run with `--no-manual` is a partial
check; report that limitation rather than counting it as a completed
PDF-manual check.

Repeat on current released R when possible, and include R-devel checks before
a later CRAN submission. A clean result on one system does not demonstrate
Windows or macOS compatibility. Mandatory examples and tests are synthetic
and offline; they do not download OSF data.

## GitHub Actions workflow

The project contains `.github/workflows/R-CMD-check.yaml`, adapted from the
[official r-lib standard workflow](https://github.com/r-lib/actions/blob/v2-branch/examples/check-standard.yaml).
It runs the following matrix after the package is placed at a GitHub
repository root and the workflow is enabled:

| Operating system | R channel |
|---|---|
| macOS | release |
| Windows | release |
| Linux | devel |
| Linux | release |
| Linux | oldrel-1 |

Pushes to `main` or `master`, pull requests, and manual workflow runs trigger
the checks. A GitHub repository and permission to add the workflow are
required. No repository has been created by these instructions. The workflow
uses GitHub's automatic `GITHUB_TOKEN` with read access to repository contents;
no separate personal access token is required for this check workflow. See
[GitHub's token documentation](https://docs.github.com/en/actions/tutorials/authenticate-with-github_token).

The jobs install declared dependencies and run `R CMD check` using
`--no-manual --as-cran`. They retain successful and failed check results as
workflow artifacts. Errors and warnings fail the jobs; notes still require
manual review. These jobs explicitly disable CRAN incoming checks and do
not build the PDF manual. Full incoming and PDF checks remain separate
release tasks. See the
[check action's documented inputs and implementation](https://github.com/r-lib/actions/blob/v2-branch/check-r-package/action.yaml).

Do not describe an unexecuted workflow as a passing cross-platform check.
The workflow directory is excluded from the installable source archive.

## Windows: official Win-builder

After the local archive passes review, it can be checked using
[Win-builder](https://win-builder.r-project.org/) and its
[upload page](https://win-builder.r-project.org/upload.aspx).
Submit the built source archive to R-release and R-devel; R-oldrelease is
an additional compatibility check. The upload form does not require an
account login. The service uses the maintainer email in the built package's
`DESCRIPTION` and normally sends a results email in approximately 30
minutes. For this package the maintainer is Shuo Zang,
<zshuo070@gmail.com>.

The email contains links to the binary and check logs in a randomly named
directory that the official instructions say is removed after roughly 72
hours. Download and preserve the logs promptly. The website does not
guarantee confidentiality of uploaded source, binaries, or results.

Alternatively, from the project directory, these functions build and upload
the package to the same service:

```r
# These commands upload source and cause the service to email the maintainer.
devtools::check_win_release(pkg = ".", webform = TRUE)
devtools::check_win_devel(pkg = ".", webform = TRUE)
```

See the [official devtools documentation](https://devtools.r-lib.org/reference/check_win.html).
Running these commands performs a remote upload; they are not local checks.

## macOS: official MacBuilder

The [official MacBuilder form](https://mac.r-project.org/macbuilder/submit.html)
accepts an archive prepared using `R CMD build`, with the submitter listed
as maintainer. Its default setup matches the CRAN M1 build machine. The
observed upload form does not require an account login. Check the available
R channels before uploading: on 2026-10-08 the live form exposes only the
development channel, with the release option commented out in its HTML. The
devtools documentation provides both release and development functions,
and the API accepted both channel requests in this session. Both completed
jobs actually used R 4.6.1 Patched; the requested development channel did
not establish actual R-devel coverage. Always read the runtime in the log.
Its service is a best-effort check on a particular
Apple Silicon setup, rather than proof of every macOS configuration.

The documented devtools functions return the result-page URL invisibly:

```r
# These commands build and upload the package to MacBuilder.
# Confirm the actual runtime in the returned logs for either request.
mac_release_url <- devtools::check_mac_release(pkg = ".")
mac_devel_url <- devtools::check_mac_devel(pkg = ".")
print(mac_release_url)
print(mac_devel_url)
```

Preserve those URLs and download the completed logs. Do not assume the
MacBuilder results arrive by email: the documented retrieval method is the
returned results URL. See the
[official devtools documentation](https://devtools.r-lib.org/reference/check_mac_release.html).
MacBuilder does not guarantee confidentiality of uploaded files or data.

## Archive contents and results record

Upload only `oes_1.0.0.tar.gz`, not the full development ZIP. The source build
excludes `development/`, including the manual study CSV and historical
scripts; mandatory tests remain in `tests/testthat/`. Remote check uploads
are not a CRAN submission, but they transfer the source to the selected
service. GitHub publication and CRAN submission are later actions.

| Check | Archive SHA256 | OS / R version | Status | Logs / result URL |
|---|---|---|---|---|
| Local Linux | record at execution | record at execution | record actual result | preserve local logs |
| Windows release | same reviewed archive | record from logs | pending | pending |
| Windows devel | same reviewed archive | record from logs | pending | pending |
| macOS release | same reviewed archive | record from logs | pending service availability or GitHub CI | pending |
| macOS devel | same reviewed archive | record from logs | pending | pending |
| GitHub matrix | record commit / built archive | record per job | pending | pending repository |

These instructions were checked against the linked official documentation
on 2026-10-08. Record channel versions from each completed check rather than
assuming that a channel's exact R version stays fixed.
