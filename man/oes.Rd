\name{oes}
\alias{oes}
\title{Internal Calculation Helper for Effect-Size-Based Y-Axis Ranges}
\description{
Internal, unexported calculation helper used by \code{\link{optimal_graph}}.
Users should call \code{optimal_graph(detail = TRUE)} and inspect the
returned \code{oes} component for numerical limits and metadata.
Compute an Optimal Effect Size (OES) y-axis recommendation from a factorial
design, with optional calculation details. The implementation uses constants
from a single-factor, two-level empirical calibration; broader factorial
and repeated-measures applications are computational generalizations.
}
\usage{
oes(
  data, DV, within = NULL, between = NULL, pooled = TRUE,
  error_bar = c("ci95", "ci95_dif", "ci95_corr", "ci95_dif_corr", "se", "sd"),
  range_type = c("dp", "quantile", "data"), id = NULL,
  effect = c("d", "g"), measurement_range = NULL,
  verbose = TRUE, detail = FALSE
)
}
\arguments{
  \item{data}{A data frame of raw responses, or one row per design cell.
  For summary input, \code{DV} identifies the cell mean; optional
  \code{n}, \code{sd}, and \code{se} columns describe cell variability.
  Raw data are required to estimate the maximum effect in this version.}
  \item{DV}{Response column, supplied as a bare name or character string.}
  \item{within}{Within-subject factor names, as bare names or a character
  vector. Use \code{c(...)} for multiple factors. Default \code{NULL}.}
  \item{between}{Between-subject factor names, with the same syntax as
  \code{within}. At least one factor must be supplied.}
  \item{pooled}{Whether error bars use pooled rather than cell-specific
  variability. The OES expansion always uses a single pooled variability
  estimate, regardless of this argument.}
  \item{error_bar}{Error-bar method. \code{"ci95"} uses ordinary 95 percent
  confidence intervals; \code{"ci95_dif"} multiplies their half-widths by
  \eqn{\sqrt{2}}. \code{"ci95_corr"} uses Cousineau--Morey
  correlation-adjusted base intervals without \eqn{\sqrt{2}};
  \code{"ci95_dif_corr"} also applies the
  \eqn{\sqrt{2}} multiplier. \code{"se"} and \code{"sd"} use one standard
  error and one standard deviation, respectively.}
  \item{range_type}{Base range before expansion: \code{"dp"} uses the
  outer error-bar endpoints; \code{"quantile"} uses the 2nd and 98th
  response percentiles; \code{"data"} uses the measurement or observed
  response range. The latter two choices are exploratory.}
  \item{id}{Participant ID column, as a bare name or character string.
  Required for paired within-subject effects and correlation-adjusted CIs.}
  \item{effect}{\code{"d"} uses Cohen's d for between-subject contrasts
  and paired Cohen's dz for within-subject contrasts. \code{"g"} applies
  Hedges' correction to between-subject contrasts only; within-subject
  contrasts still use dz. Recommendations using g or paired dz have not
  been empirically validated; see the evidence and limitations section.}
  \item{measurement_range}{Optional numeric vector \code{c(min, max)}
  giving a finite, strictly increasing theoretical response range.
  Otherwise the observed range is used. This supplies the \code{"data"}
  base range and the fallback range. It does not clamp OES recommendations.}
  \item{verbose}{Whether to emit optional methodological and fallback
  warnings. Errors are not suppressed.}
  \item{detail}{If \code{FALSE}, return limits only. If \code{TRUE}, return
  calculation details in an object of class \code{oes_result}.}
}
\details{
The effect search compares levels of each factor while conditioning on the
other factors. Within-subject comparisons match observations by participant
ID. Specify the experimental design explicitly; grouping variables alone
do not identify repeated measurements.

Between-subject contrasts use \code{rstatix::cohens_d(var.equal = FALSE)}.
Their standardized mean difference divides by
\eqn{\sqrt{(s_1^2 + s_2^2)/2}}, even when group sample sizes differ; it
does not use an n-weighted two-group SD. Hedges' g uses the correction
implemented by rstatix. This contrast denominator is separate from the
degrees-of-freedom-weighted pooled cell SD used for ER variability.

For maximum absolute effect \eqn{X \geq 0.20}, the expansion on each side
is \eqn{ER = s_p/(X + a)}, where \eqn{s_p} is pooled within-cell SD for
ordinary error bars or pooled transformed SD for Cousineau--Morey intervals.
The parameter \eqn{a} uses the inherited calibration constants described
below: 5.723 for \eqn{X \geq 0.8}, 1.575 for
\eqn{0.5 \leq X < 0.8}, and 0.254 for \eqn{0.2 \leq X < 0.5}.
These values are retained in this version and may change in later versions
as further evidence becomes available.
If \eqn{X} is unavailable or smaller than 0.20, the measurement or observed
range is returned directly. The default \code{range_type = "dp"} and
\code{effect = "d"} retain the calibration's method choices; selecting
them does not establish empirical validity for every supported design.
The output phrase ``calibrated OES expansion'' refers to use of the inherited
formula and constants, not to empirical validation of all supported designs
or effect estimators.

Correlation-adjusted intervals require raw data, valid participant IDs, at
least one within-subject factor, at least two repeated-measures conditions
per between-subject stratum, complete within-participant condition profiles,
and at least two participants per stratum.
Duplicate participant-condition responses are averaged first. Their t
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
}
\section{Evidence and limitations}{
\emph{Visualizing Standardized Effect Sizes Using the Framework of Graph Perception and Data Visualization}
(Shuo Zang and Denis Cousineau, 2026, unpublished manuscript) studied
single-factor, two-level
comparisons across different populations and sample sizes, focusing on
Cohen's d. The package's support for broader independent, repeated-measures,
and mixed factorial designs is a computational generalization of that work,
not empirical validation of those generalized y-axis recommendations.

Recommendations using Hedges' g, paired Cohen's dz, multi-factor
maximum-effect selection, or the generalized ER rule beyond the studied
comparisons remain unvalidated extensions. Alternative base ranges
\code{"quantile"} and \code{"data"} are also exploratory.
Software tests verify implemented calculations and behavior; they do not
validate perceptual outcomes for these extensions.

A separate methods paper is planned to explain the package's derivation
from the effect-size study. The planned methods paper is not yet published,
and no bibliographic citation for it is included here.
}
\value{
With \code{detail = FALSE}, a one-row data frame with \code{lower} and
\code{upper}. With \code{detail = TRUE}, a list of class \code{oes_result}
containing \code{range} (that data frame), \code{res} (cell summaries and
error bars), \code{dp} (maximum absolute effect), \code{effect_info},
\code{effect_table} (conditional comparisons), \code{pooled_sd},
\code{ER}, \code{sd_info}, \code{error_bar_info}, \code{range_info},
\code{L}, \code{U}, and \code{args}. On fallback, \code{ER} is \code{NA}
and \code{L}/\code{U} are the final fallback bounds; otherwise they are
the base bounds before expansion.
The \code{range_info$calibrated} flag is \code{TRUE} exactly when
\code{range_type = "dp"}, including on fallback. It identifies the
original base-range choice, not empirical validation of a generalized
design, effect estimator, or recommendation.
}
\seealso{\code{\link{optimal_graph}}}
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
\keyword{internal}
