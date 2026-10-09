# oes 1.0.0: methods and usage guide

This guide describes the current implementation, its relationship to
*Visualizing Standardized Effect Sizes Using the Framework of Graph Perception and Data Visualization* (Shuo Zang and Denis Cousineau, 2026,
unpublished manuscript), and its evidence limits. The synthetic examples demonstrate
software usage; they do not empirically validate the generalized settings.

## Relationship to the effect-size study and the planned methods paper

The effect-size study focused on single-factor comparisons
with two levels using Cohen's d. It examined different populations and sample
sizes within that setting. The package extends the calculation to multiple
factors, more than two levels, repeated measurements, and mixed designs.

The effect-size study does not verify these broader recommendations. In particular, the
largest-conditional-effect rule, paired Cohen's dz, Hedges' g, and generalized
ER calculation have not been empirically validated as OES rules beyond the effect-size study setting.
Other choices should not be treated as verified merely because the software
computes them. A separate methods paper is planned to explain the derivation
and generalization from the effect-size study; it is not yet a published reference.

## Specify the design

Use `between` for factors whose levels contain different participants and
`within` for factors measured repeatedly on the same participants. Supply
`id` for repeated measurements. IDs should be unique across between-subject
groups, and each participant must occupy one level of each between factor.

Plots cannot establish the experimental design. If design arguments are
omitted, `optimal_graph()` treats eligible detected factors as between-subject
factors. Specify repeated measurements explicitly. Avoid treating a bin
derived from the response as an experimental factor.

`optimal_graph()` is the only exported function. Its internal `oes()`
engine computes the recommendation. With graph output and `detail = TRUE`,
numerical results are available under the returned list's `$oes` element.

Load the installed package before running these examples:

```r
library(oes)
```

### Independent groups

```r
independent <- data.frame(
  group = factor(rep(c("A", "B"), each = 6)),
  score = c(1:6, 3:8)
)
independent_graph <- optimal_graph(
  data = independent, DV = score, between = group,
  effect = "d", detail = TRUE
)
independent_result <- independent_graph$oes
independent_result$range
independent_result$effect_table
```

For independent contrasts, the implementation calls
`rstatix::cohens_d(var.equal = FALSE)`. Its denominator is
`sqrt((s1^2 + s2^2) / 2)`, including when the two sample sizes differ.
This gives equal weight to the two group variances; it is distinct from
the degrees-of-freedom-weighted cell SD used for ER. Absolute effect magnitude
selects the expansion rule. The exploratory g option applies rstatix's
small-sample correction to this between-subject effect.

### Repeated measurements

```r
paired <- data.frame(
  id = rep(1:6, 2),
  condition = factor(rep(c("A", "B"), each = 6)),
  score = c(2, 3, 4, 3, 5, 6, 3, 5, 5, 6, 6, 8)
)
paired_graph <- optimal_graph(
  data = paired, DV = score, within = condition, id = id,
  error_bar = "ci95_corr", detail = TRUE
)
paired_result <- paired_graph$oes
paired_result$range
paired_result$res
```

Paired comparisons match observations by ID and use Cohen's dz: mean paired
difference divided by SD of paired differences. dz has a different denominator
from independent-group d. Reusing the effect-size study constants with dz is an unvalidated
extension. `effect = "g"` applies no paired Hedges correction in this
implementation; within-subject contrasts still use dz.

### Mixed design

```r
mixed <- expand.grid(id = 1:12, condition = paste0("C", 1:3))
mixed$condition <- factor(mixed$condition)
mixed$group <- factor(ifelse(mixed$id <= 6, "G1", "G2"))
condition_index <- as.integer(mixed$condition)
mixed$score <- 4 + mixed$id / 5 + condition_index +
  (mixed$group == "G2") / 2 +
  sin(mixed$id * 1.1 + condition_index) * 0.7
mixed_graph <- optimal_graph(
  data = mixed, DV = score, within = condition, between = group, id = id,
  error_bar = "ci95_corr", detail = TRUE
)
mixed_result <- mixed_graph$oes
mixed_result$effect_table
mixed_result$range
```

Every ID belongs to one group and is measured in every condition. The effect
search compares levels of each factor while conditioning on the other factors,
then selects the largest absolute estimable conditional effect. It does not
use an omnibus ANOVA effect size. Between-subject contrasts use d or
exploratory g; within-subject contrasts use dz. Their denominators differ.
Selecting the maximum across them and using one ER requires further validation.

## Expansion and thresholds

Let `X` denote the largest absolute estimable conditional effect. For
`X >= 0.2`, the implemented expansion is `ER = pooled_sd / (X + a)`.

| Effect magnitude X | Current a |
|---|---:|
| X >= 0.8 | 5.723 |
| 0.5 <= X < 0.8 | 1.575 |
| 0.2 <= X < 0.5 | 0.254 |

The values of `a` are taken directly from the effect-size study and are not refitted for the
package's broader designs or estimators. They may change after further
research. Report the package version and the options used.

With `range_type = "dp"`, base bounds `L` and `U` are the lowest lower
error-bar endpoint and highest upper error-bar endpoint. Final bounds are
`L - ER` and `U + ER`. The name `dp` selects the base-range method; effect
estimation is controlled separately by `effect` and the design.

Exploratory `range_type = "quantile"` uses the 2nd and 98th response
percentiles; `range_type = "data"` uses the measurement or observed range.
The metadata flag `range_info$calibrated` identifies the `dp` base-range
choice. It does not establish empirical validation of other designs,
estimators, or error-bar choices. Text labels mentioning calibration refer
to the inherited formula and constants, subject to these evidence limits.

## Pooling and variability

`pooled` controls error bars. ER always uses one pooled variability scale,
even with `pooled = FALSE`. Ordinary error bars use pooled raw within-cell
SD for ER; Cousineau-Morey methods use pooled transformed SD.

For cells with finite SD and `n_j > 1`, the pooled scale is
`sqrt(sum((n_j - 1) * s_j^2) / sum(n_j - 1))`. With Cousineau-Morey methods,
`s_j` is the transformed cell SD. This weights cell variances by their
degrees of freedom, unlike the equal-weighted two-group contrast denominator.

For mixed designs, Cousineau-Morey normalization and error-bar pooling occur
separately within each between-subject stratum. ER still uses one pooled
transformed scale across cell summaries. Toggling `pooled` may change the
error bars, base bounds, and final range while retaining ER within the same
error-bar method.

## Error bars

| `error_bar` | Construction |
|---|---|
| `"ci95"` | Ordinary 95% confidence intervals for cell means. |
| `"ci95_dif"` | Ordinary CI half-widths multiplied by sqrt(2), following Cousineau (2017), Equation 3. |
| `"ci95_corr"` | Cousineau-Morey correlation-adjusted 95% base intervals, without sqrt(2). |
| `"ci95_dif_corr"` | Cousineau-Morey CI half-widths multiplied by sqrt(2), combining both adjustments as in Cousineau (2017), Equation 5b. |
| `"se"` | Mean plus/minus one standard error. |
| `"sd"` | Mean plus/minus one standard deviation. |

Cousineau (2017), *Varieties of confidence intervals*, is the primary
reference for the CI adjustment distinctions. Equation 3 multiplies
CI half-widths by sqrt(2) for the difference adjustment. Repeated-measures
base intervals use Cousineau's (2005) normalization and Morey's (2008)
bias correction. The package retains `ci95_corr` as a separate choice
with those adjustments alone; it does not include sqrt(2) and is not the
2017 article's combined comparative construction. `ci95_dif_corr` adds
the sqrt(2) multiplier, combining the adjustments described in Equation 5b.
The `se` and `sd` options remain generic standard-error and standard-deviation
bars. These sources support CI construction; the OES expansion and
calibration come from the effect-size manuscript.

Report the selected method. Availability does not validate every option as
an OES perceptual recommendation in every design. The difference-adjusted
multiplier is not a general inferential test for all factorial comparisons.

For ordinary pooled CIs, the implemented t critical value uses
`sum(cell n) - number_of_cells` degrees of freedom. Unpooled ordinary CIs
use each cell's `n - 1`. Nonpositive or unavailable df are replaced by 1 for
the critical-value calculation. In repeated-measures data, ordinary methods
retain this convention; they do not apply the participant-based CM adjustment.

Cousineau-Morey methods require raw data, a valid ID, a within-subject factor,
at least two repeated-measures conditions per between-subject stratum,
complete repeated-measures profiles, and at least two participants per
stratum. Duplicate participant-condition responses are
averaged first. The t critical value uses `n - 1` degrees of freedom for both
pooling settings, where `n` is the participant count in the cell. Ordinary
CIs remain a separate choice for repeated-measures data.

## Plotting layouts and output

```r
p <- ggplot2::ggplot(
  mixed, ggplot2::aes(condition, score, fill = group)
) + ggplot2::geom_boxplot()
summary_graph <- optimal_graph(
  p, data = mixed, DV = score,
  within = condition, between = group, id = id,
  error_bar = "ci95_corr", layout = "summary", detail = TRUE
)
summary_graph$plot
original_graph <- optimal_graph(
  p, data = mixed, DV = score,
  within = condition, between = group, id = id,
  error_bar = "ci95_corr", layout = "original"
)
original_graph
optimal_graph(
  data = mixed, DV = score,
  within = condition, between = group, id = id,
  error_bar = "ci95_corr", output = "y_axis_limit"
)
```

`summary` rebuilds mean, line, and error-bar layers. Colour, fill, shape,
linetype, and explicit grouping can separate series; not every original
styling choice is retained. `original` retains the supplied layers and applies
the recommendation to the limits. Without a supplied plot, either layout
produces a summary graph.

Existing explicit y limits are retained by default, so the existing plot
may be returned even if summary layout was requested. With
`override_existing_limits = TRUE`, the recommended limits replace existing
limits. For original-layout output, existing y-scale limits are cleared
before the recommended coordinate limits are applied. This restores data
previously censored by those scale limits, preserves the rest of the scale
configuration, and leaves the supplied graph unmodified. The chosen
error-bar method drives the calculation; retained original layers may
display different error bars or none.

`optimal_graph(..., detail = TRUE)` returns `plot` and `oes` for graph output.
The `$oes` element contains numerical limits in `$range` and the calculation
metadata; it is a returned object, not a call to a public `oes()` function.
`output = "y_axis_limit"` always returns text.

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

## Fallbacks and limitations

- If the maximum effect is unavailable or below 0.2, the supplied
  `measurement_range` or observed minimum/maximum is returned directly.
  ER is unavailable on this fallback path; no expansion is added.
- `measurement_range` also sets base bounds for `range_type = "data"`.
  It does not clip expanded recommendations.
- Summary means and variability do not identify the participant-level effect
  required by the current raw-data effect search. Supply raw data explicitly
  for means-only plots.
- Without a valid ID, within-subject contrasts cannot yield paired effects.
  Correlation-adjusted CIs produce an error when their requirements are unmet;
  missing conditions must be resolved explicitly.
- Original plots may place extreme observations outside recommended limits.
  Inspect the result and report the chosen layout and limits.
- Regression tests establish software behavior, not perceptual optimality,
  inferential validity of graphical comparisons, or transfer of the effect-size study constants.

## Data, citation, and future work

The supplied error-bar Study 4B example uses the OSF data for *When Error
Bars Fail to Correct Misleading Charts: Judgments of Lower y-axis Truncation
across Layouts and Audiences*, by Shuo Zang and Denis Cousineau:
<https://doi.org/10.17605/OSF.IO/DTYBF> and
<https://osf.io/dtybf/files/ebsh5>. This is a study-data usage example,
not the effect-size calibration dataset. [Error-bar data provenance](error-bar-data-source.md) is included with
the installed documentation. The project ZIP contains
`development/example-error-bar-study4b.R`, the manual example. Automated tests and the synthetic examples above require
neither that CSV nor network access.

Use `citation("oes")` for the current software citation. Cite the effect-size
manuscript separately:

- Zang, S., & Cousineau, D. (2026). *Visualizing Standardized Effect Sizes Using the Framework of Graph Perception and Data Visualization*. [Unpublished manuscript].

The associated OSF resource is Zang and Cousineau's (2025)
[*Visualizing Standardized Effect Sizes Using the Framework of Graph Perception and Data Visualization*](https://doi.org/10.17605/OSF.IO/DRCTA)
project, licensed under CC BY 4.0. This DOI identifies the OSF resource,
not a published manuscript or the package. The planned package-methods
reference can be added when finalized. Further
research is needed for broader designs, other effect estimators, and
updated ER constants before extending empirical-validation claims.

## References for confidence-interval construction

Cousineau (2017) is the primary reference for difference adjustment and
the combined repeated-measures adjustment. Cousineau (2005) and Morey
(2008) provide the normalization and bias-correction foundations. These
papers support CI construction; they do not supply or validate the ER
formula or its calibration constants.

- Cousineau, D. (2017). *Varieties of confidence intervals*. Advances in
  Cognitive Psychology, 13(2), 140–155. <https://doi.org/10.5709/acp-0214-z>.

- Cousineau, D. (2005). *Confidence intervals in within-subject designs: A
  simpler solution to Loftus and Masson's method*. Tutorials in Quantitative Methods
  for Psychology, 1(1), 42–45. <https://doi.org/10.20982/tqmp.01.1.p042>.
- Morey, R. D. (2008). *Confidence intervals from normalized data: A correction
  to Cousineau (2005)*. Tutorials in Quantitative Methods for Psychology, 4(2), 61–64.
  <https://doi.org/10.20982/tqmp.04.2.p061>.
