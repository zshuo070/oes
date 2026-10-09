\name{optimal_graph}
\alias{optimal_graph}
\title{Plot or Describe an Effect-Size-Based Y-Axis Recommendation}
\description{
Create a mean and error-bar plot, apply recommended y-axis limits to an
existing ggplot, or return a text description of the recommendation.
Broader factorial and repeated-measures uses generalize an empirical
calibration of single-factor, two-level comparisons.
}
\usage{
optimal_graph(
  plot = NULL, data = NULL, DV = NULL,
  layout = c("summary", "original"), pooled = TRUE,
  error_bar = c("ci95", "ci95_dif", "ci95_corr", "ci95_dif_corr", "se", "sd"),
  range_type = c("dp", "quantile", "data"), id = NULL,
  within = NULL, between = NULL, effect = c("d", "g"),
  measurement_range = NULL, output = c("graph", "y_axis_limit"),
  override_existing_limits = FALSE, verbose = TRUE, detail = FALSE
)
}
\arguments{
  \item{plot}{Optional ggplot object. If \code{data} and \code{DV} are also
  supplied, they drive calculations and the plot supplies the graphical
  layout. Otherwise accessible source data and mapped columns are used.}
  \item{data}{Optional data frame of raw responses, or one row per design
  cell. For summary input, \code{DV} identifies the cell mean; optional
  \code{n}, \code{sd}, and \code{se} columns describe cell variability.
  Raw data are required to estimate the maximum effect in this version.}
  \item{DV}{Response column, as a bare name or character string. Required
  with explicit \code{data}; otherwise inferred from the plot y mapping.}
  \item{layout}{\code{"summary"} rebuilds a mean and error-bar plot;
  \code{"original"} retains the supplied plot layers. Without a supplied
  plot, a summary plot is produced for either choice.}
  \item{pooled}{Whether error bars use pooled variability. OES expansion
  always uses a single pooled SD, regardless of this setting.}
  \item{error_bar}{One of ordinary 95 percent CIs (\code{"ci95"}),
  difference-adjusted CIs (\code{"ci95_dif"}), Cousineau--Morey CIs
  without the difference multiplier (\code{"ci95_corr"}), both
  adjustments (\code{"ci95_dif_corr"}),
  one standard error (\code{"se"}), or one standard deviation
  (\code{"sd"}). Difference adjustment multiplies half-widths by
  \eqn{\sqrt{2}}. Correlation-adjusted methods require raw data,
  within-subject factors, and valid participant IDs.}
  \item{range_type}{\code{"dp"} uses error-bar endpoints as the base
  range. Exploratory alternatives \code{"quantile"} and \code{"data"}
  use the 2nd--98th percentile or measurement/observed range.}
  \item{id}{Participant ID column, as a bare name or character string.
  Required for paired effects and correlation-adjusted intervals.}
  \item{within}{Within-subject factor names, as bare names or a character
  vector, with \code{c(...)} for multiple factors. Default \code{NULL}.}
  \item{between}{Between-subject factor names, using the same syntax.
  If neither design argument is supplied, eligible categorical data
  columns or detected plot factors are treated as between-subject factors.}
  \item{effect}{\code{"d"} for between-subject Cohen's d and paired
  within-subject dz. Exploratory \code{"g"} applies Hedges' correction
  to between-subject contrasts only. Neither g-based nor paired dz-based
  recommendations have been empirically validated; see the evidence and limitations section.}
  \item{measurement_range}{Optional numeric \code{c(min, max)} giving
  finite, strictly increasing theoretical bounds. Used for the
  \code{"data"} base range and fallback; otherwise the observed response
  range is used. This is not a clipping restriction.}
  \item{output}{\code{"graph"} returns a plot; \code{"y_axis_limit"}
  returns a character string describing calculations and limits.}
  \item{override_existing_limits}{Whether to replace explicit y-axis
  limits already present in \code{plot}. With the default \code{FALSE},
  a supplied plot with explicit limits is retained, even when a summary
  layout was requested. With \code{TRUE}, the recommended limits replace
  existing limits. For original-layout output, existing y-scale limits
  are cleared before the recommended coordinate limits are applied; the
  rest of the scale configuration is preserved and the supplied graph
  is unmodified. Text output still reports the recommendation.}
  \item{verbose}{Whether to emit optional OES messages and warnings.
  Errors and all underlying ggplot warnings are not suppressed.}
  \item{detail}{For graph output, return a list containing the plot and
  calculation details rather than the plot alone. Does not change the
  character return type of \code{output = "y_axis_limit"}.}
}
\details{
Always specify \code{within}, \code{between}, and \code{id} for repeated
measurements or mixed designs: plot aesthetics cannot establish whether
measurements come from the same participant.

The effect search compares levels of each factor while conditioning on
the other factors. Within-subject comparisons match observations by ID.
Between-subject contrasts use \code{rstatix::cohens_d(var.equal = FALSE)},
with denominator \eqn{\sqrt{(s_1^2 + s_2^2)/2}} even when group sample
sizes differ, rather than an n-weighted two-group SD. Hedges' g uses
rstatix's implemented correction. This contrast denominator is separate
from the degrees-of-freedom-weighted pooled cell SD used for ER variability.

For maximum absolute effect \eqn{X \geq 0.20}, each side of the base range
is expanded by \eqn{ER = s_p/(X + a)}. Here \eqn{s_p} is pooled
within-cell SD for ordinary error bars or pooled transformed SD for
Cousineau--Morey intervals. This variability scale is pooled for both
values of \code{pooled}. If \eqn{X} is unavailable or smaller than 0.20,
the measurement or observed range is returned directly.

Correlation-adjusted intervals require raw data, valid participant IDs,
at least one within-subject factor, at least two repeated-measures
conditions per between-subject stratum, complete within-participant
condition profiles, and at least two participants per stratum.
Duplicate participant-condition responses are averaged first. The t
critical value uses \eqn{n - 1} degrees of freedom for both pooling settings.
Confidence-interval options follow the distinctions in Cousineau (2017).
Difference adjustment multiplies half-widths by \eqn{\sqrt{2}}
(Equation 3). Repeated-measures base intervals use Cousineau's (2005)
normalization and Morey's (2008) bias correction. The separate
\code{"ci95_corr"} option returns these base intervals without
\eqn{\sqrt{2}} and is not the 2017 article's combined comparative
construction. \code{"ci95_dif_corr"} adds \eqn{\sqrt{2}}, combining
the adjustments described in Equation 5b. \code{"se"} and
\code{"sd"} use one standard error or standard deviation.
These sources support CI construction; the OES expansion rule and
calibration constants come from the effect-size manuscript.

Summary output uses mapped colour, fill, shape, and linetype to separate
series, with an explicit group mapping taking priority. Fill supplies
visible colours when colour is absent. Summary output rebuilds layers
and does not preserve every styling choice in the original plot.

Graph output requires ggplot2 version 4.0.0 or later. Missing or
means-only plot source data cannot establish an OES effect size. The
function warns and may return the original plot or an observed-range
fallback. Supply explicit raw data and design arguments in those cases.
}
\section{Evidence and limitations}{
\emph{Visualizing Standardized Effect Sizes Using the Framework of Graph Perception and Data Visualization}
(Shuo Zang and Denis Cousineau, 2026, unpublished manuscript) examined
single-factor, two-level
comparisons across different populations and sample sizes, focusing on
Cohen's d. Support for broader independent, repeated-measures, and mixed
factorial designs is computational; it does not establish the empirical
validity of the generalized recommendations.

Hedges' g, paired dz, multi-factor maximum-effect selection, and generalized
ER use beyond the studied comparisons are unvalidated extensions.
\code{range_type = "quantile"} and \code{range_type = "data"} are
exploratory alternatives. The default settings do not remove these design
limitations.

The parameter \eqn{a} in \eqn{ER = s_p/(X + a)} is taken directly from
the effect-size study: 5.723 for \eqn{X \geq 0.8}, 1.575 for
\eqn{0.5 \leq X < 0.8}, and 0.254 for \eqn{0.2 \leq X < 0.5}.
These constants may change in later versions with further evidence.
Text mentioning ``calibrated OES expansion'' identifies the inherited
formula and constants, not empirical validation of all designs or estimators.
A separate methods paper explaining the derivation from the effect-size study is
planned but is not yet published.
}
\value{
For \code{output = "graph"} and \code{detail = FALSE}, a ggplot object.
With \code{detail = TRUE}, a list with \code{plot} and \code{oes};
\code{oes} is a list of class \code{oes_result}, or \code{NULL} when a
recommendation cannot be calculated from the plot. Its fields are
\code{range} (a one-row data frame with \code{lower} and \code{upper}),
\code{res} (cell summaries and error bars), \code{dp} (maximum absolute
effect), \code{effect_info}, \code{effect_table} (conditional comparisons),
\code{pooled_sd}, \code{ER}, \code{sd_info}, \code{error_bar_info},
\code{range_info}, \code{L}, \code{U}, and \code{args}. On fallback,
\code{ER} is \code{NA} and \code{L}/\code{U} are the final fallback
bounds; otherwise they are the base bounds before expansion.
\code{range_info$calibrated} is \code{TRUE} exactly when
\code{range_type = "dp"}, including on fallback. It identifies the
original base-range choice, not empirical validity of a generalized
design, effect estimator, or recommendation.

For \code{output = "y_axis_limit"}, a character string, regardless
of \code{detail}. Numerical metadata are accessed through the
\code{oes} component of \code{optimal_graph(..., detail = TRUE)} with
graph output; the underlying numerical helper is not exported.
}
\seealso{\code{\link{oes-package}}}
\references{
Zang, S., and Cousineau, D. (2026).
\emph{Visualizing Standardized Effect Sizes Using the Framework of Graph Perception and Data Visualization}. Unpublished manuscript.
The associated OSF resource (Zang and Cousineau, 2025) is licensed under
CC BY 4.0: \doi{10.17605/OSF.IO/DRCTA}. This is the resource DOI,
not a published-paper or software DOI.

Cousineau, D. (2017). Varieties of confidence intervals.
\emph{Advances in Cognitive Psychology}, 13(2), 140--155.
\doi{10.5709/acp-0214-z}

Cousineau, D. (2005). Confidence intervals in within-subject designs:
A simpler solution to Loftus and Masson's method.
\emph{Tutorials in Quantitative Methods for Psychology}, 1(1), 42--45.
\doi{10.20982/tqmp.01.1.p042}

Morey, R. D. (2008). Confidence intervals from normalized data:
A correction to Cousineau (2005).
\emph{Tutorials in Quantitative Methods for Psychology}, 4(2), 61--64.
\doi{10.20982/tqmp.04.2.p061}
}
\examples{
dat <- data.frame(
  group = factor(rep(c("A", "B"), each = 6)),
  score = c(1, 2, 3, 2, 3, 4, 5, 6, 7, 6, 7, 8)
)
optimal_graph(data = dat, DV = score, between = group)
optimal_graph(data = dat, DV = score, between = group,
              output = "y_axis_limit")
result <- optimal_graph(data = dat, DV = score, between = group,
                        detail = TRUE)
result$oes$range
result$oes$effect_table
p <- ggplot2::ggplot(dat, ggplot2::aes(group, score, fill = group)) +
  ggplot2::geom_boxplot()
optimal_graph(p, layout = "original")
}
