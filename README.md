# oes 1.0.0

Optimal Effect-Size-Based Y-Axis Ranges

Authors: Shuo Zang and Denis Cousineau, School of Psychology, University of
Ottawa. Maintainer: Shuo Zang <zshuo070@gmail.com>.

This package uses the V1.8 implementation with official version number 1.0.0.
It computes numerical y-axis recommendations and applies them to ggplot2
visualizations. The package is undergoing release checks before publication.

## Evidence and scope

*Visualizing Standardized Effect Sizes Using the Framework of Graph Perception and Data Visualization*, by Shuo Zang and Denis Cousineau (2026, unpublished
manuscript), studied single-factor, two-level comparisons across different
populations and sample sizes. The effect-size study focused on Cohen's d. Those studies do not establish empirical validity for
every design and option supported by this package.

The package generalizes the calculation to independent, repeated-measures,
and mixed designs, including multiple factors and more than two levels.
These are computational extensions. The generalized ER calculation,
selection of the largest conditional effect, paired Cohen's dz, and
alternative Hedges' g option have not been empirically validated as OES
recommendation rules beyond the effect-size study setting. Alternative base ranges are
also exploratory. Passing software tests verifies implementation behavior;
it does not establish the intended perceptual judgments in these additional
settings.

The current expansion is `ER = pooled_sd / (X + a)`, with `a` taken directly
from the effect-size study: 5.723 when `X >= 0.8`, 1.575 when `0.5 <= X < 0.8`, and 0.254 when
`0.2 <= X < 0.5`. The constants are reused in the generalized calculation and
may be updated after further research. For unavailable effects or `X < 0.2`,
the implementation uses the measurement or observed range.

A separate methods paper is planned to explain how the package was derived
and generalized from the effect-size study. It is not yet a published reference. The current
[methods guide](inst/doc/methods-guide.md) documents the implementation,
examples, and limitations for review.

Confidence-interval options follow the distinctions in Cousineau (2017),
*Varieties of confidence intervals*. The difference adjustment
(`ci95_dif`) multiplies ordinary CI half-widths by √2 (Equation 3).
Repeated-measures base intervals use Cousineau's (2005) normalization
and Morey's (2008) correction. The separate `ci95_corr` option returns
those base intervals without the √2 multiplier; it is not the combined
comparative construction in the 2017 article. The `ci95_dif_corr` option
adds √2, combining the two adjustments described in Equation 5b.
The `se` and `sd` options use one standard error or standard deviation.
These references support CI construction; the OES expansion rule and
calibration constants come from the effect-size manuscript:

- Cousineau, D. (2017). *Varieties of confidence intervals*. Advances in
  Cognitive Psychology, 13(2), 140–155. <https://doi.org/10.5709/acp-0214-z>.

- Cousineau, D. (2005). *Confidence intervals in within-subject designs: A
  simpler solution to Loftus and Masson's method*. Tutorials in Quantitative Methods
  for Psychology, 1(1), 42–45. <https://doi.org/10.20982/tqmp.01.1.p042>.
- Morey, R. D. (2008). *Confidence intervals from normalized data: A correction
  to Cousineau (2005)*. Tutorials in Quantitative Methods for Psychology, 4(2), 61–64.
  <https://doi.org/10.20982/tqmp.04.2.p061>.

## Open the project

Extract the project ZIP and open `oes/oes.Rproj` in RStudio.

## Install locally

Use R >= 4.1.0. Install the runtime dependencies first:

```r
install.packages(c("dplyr", "ggplot2", "rlang", "rstatix"))
```

The package requires ggplot2 >= 4.0.0. Optional `ggsci` supplies summary-plot
palettes. `testthat` is needed to run package tests.

From the parent directory of the extracted `oes/` folder:

```r
install.packages("oes", repos = NULL, type = "source")
library(oes)
```

Alternatively, install the supplied source archive using its actual path:

```r
install.packages("oes_1.0.0.tar.gz", repos = NULL, type = "source")
```

## Use optimal_graph

```r
d <- data.frame(
  group = factor(rep(c("A", "B"), each = 5)),
  score = c(1:5, 3:7)
)
result <- optimal_graph(data = d, DV = score, between = group, detail = TRUE)
result$plot
result$oes$range
optimal_graph(data = d, DV = score, between = group, output = "y_axis_limit")
```

`optimal_graph()` is the only exported function. It returns a graph or a
text recommendation; `detail = TRUE` also supplies numerical results under
`result$oes`. The calculation engine `oes()` and other helpers are internal.
See `?optimal_graph` and the methods guide for design requirements.

## Recommended graphing workflows

Use `oes` to obtain recommended y-axis ranges and choose the graphing
workflow that suits your needs:

| Workflow | Recommendation |
|---|---|
| **oes + superb** | Use `optimal_graph()` to obtain the y-axis ranges, then use `superb::superb()` to generate graphs with different error-bar settings appropriate to the design and comparison purpose. Apply the recommended lower and upper limits to the resulting graph. |
| **ggplot2 + oes** | Build a custom graph with `ggplot2`, then use `optimal_graph()` with `layout = "original"` to apply the recommended y-axis range while retaining its layers and error bars. Supply the raw data and design arguments explicitly. |
| **oes alone** | Use `optimal_graph()` directly to generate a mean and error-bar graph with a recommended y-axis range, choosing from the package's supported `error_bar` options. |

With `detail = TRUE`, numerical limits are available in
`result$oes$range$lower` and `result$oes$range$upper`.
For an existing superb or ggplot2 graph, `layout = "original"` retains its
plotted layers; the default `layout = "summary"` rebuilds the summary graph.
Existing explicit y-axis limits are retained by default. With
`override_existing_limits = TRUE`, the recommended limits replace existing
limits. For original-layout output, OES clears existing y-scale limits before
applying its coordinate limits, preserving the rest of the scale configuration
and leaving the supplied graph unmodified.

Use the same raw data and experimental design for the range calculation and
the graph. For error-bar methods supported by `oes`, align the error-bar
and pooling settings with those used in the graph. The default
`range_type = "dp"` uses error-bar endpoints for its base bounds, so changing
those settings requires a corresponding range calculation.

`superb` is a separate package for the optional first workflow. Install it
separately with `install.packages("superb")`. See its
[function documentation](https://dcousin3.github.io/superb/reference/superb.html)
and the framework paper:

Cousineau, D., Goulet, M.-A., & Harding, B. (2021).
*Summary plots with adjusted error bars: The superb framework with an
implementation in R*. Advances in Methods and Practices in Psychological
Science, 4(3). <https://doi.org/10.1177/25152459211035109>.

## Citation and license

```r
citation("oes")
toBibtex(citation("oes"))
```

Shuo Zang's ORCID: <https://orcid.org/0009-0000-4387-8145>.

Package code is licensed under MIT. `LICENSE` accompanies the source archive;
the project ZIP also includes the full license text in `LICENSE.md`.
The software citation is separate from the effect-size manuscript and its
associated OSF resource:

- Zang, S., & Cousineau, D. (2026). *Visualizing Standardized Effect Sizes Using the Framework of Graph Perception and Data Visualization*. [Unpublished manuscript].
- Associated OSF resource: Zang and Cousineau (2025),
  [*Visualizing Standardized Effect Sizes Using the Framework of Graph Perception and Data Visualization*](https://doi.org/10.17605/OSF.IO/DRCTA).
  License: CC BY 4.0.

The DRCTA DOI identifies the effect-size OSF resource, not a published-paper
or package DOI. The separate package-methods paper is planned; its citation
can be added when its bibliographic details are finalized.

## Error-bar study example data

The supplied error-bar study example uses `Study4_long.csv` from a separate
public OSF resource:

- Resource DOI: <https://doi.org/10.17605/OSF.IO/DTYBF>.
- File page: <https://osf.io/dtybf/files/ebsh5>.
- Direct file download: <https://osf.io/download/ebsh5/>.

The resource is *When Error Bars Fail to Correct Misleading Charts:
Judgments of Lower y-axis Truncation across Layouts and Audiences*, by Shuo
Zang and Denis Cousineau, hosted on OSF. The data are licensed under CC BY
4.0, separately from the MIT license for package code. See
[error-bar data provenance](inst/doc/error-bar-data-source.md) in the project ZIP.
The ZIP includes an unmodified copy for the manual study example; the
installable source archive excludes these development inputs.

This dataset demonstrates study-data usage. It does not validate the
package's extensions beyond the effect-size study setting. Automated tests use self-contained data
and do not access OSF or require the CSV.

## Development inputs and tests

The ZIP includes a `development/` folder with the original V1.8 script,
standalone regression script, original supplied examples, and a corrected
manual error-bar Study 4B example, `development/example-error-bar-study4b.R`.
Historical scripts are retained as inputs; the
installed-package tests in `tests/testthat/` are the automated suite.

The automated tests cover effect sizes, error bars, pooling, input handling,
fallbacks, plot grouping, layout preservation, and y-axis limits. Applicable
examples have been adapted to self-contained data; misleading design
examples and internal debugging calls are excluded from public tutorials.
Optional `superb` examples are outside the mandatory package tests.

After installing `testthat`, run the tests from the project directory:

```r
testthat::test_dir("tests/testthat", stop_on_failure = TRUE)
```

Release checks across operating systems and CRAN-specific checks must be
completed before publication.
