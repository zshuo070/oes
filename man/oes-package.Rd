\name{oes-package}
\alias{oes-package}
\docType{package}
\title{oes: Optimal Effect-Size-Based Y-Axis Ranges}
\description{
Compute effect-size-informed y-axis recommendations and display them
with mean/error-bar plots or existing ggplot objects. Calibration constants
come from single-factor, two-level comparisons. The implementation supports
broader between-subject, within-subject, and mixed factorial designs as
computational generalizations.
}
\details{
\code{\link{optimal_graph}} is the package's sole exported function.
Use it for graphical and text output, or request \code{detail = TRUE}
with graph output and inspect the returned \code{oes} component for
numeric limits and calculation metadata. Calculation helpers are internal.
Recommendations depend on the specified design and effect-size method;
explicitly identify repeated measurements and participant IDs.

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

\emph{Visualizing Standardized Effect Sizes Using the Framework of Graph Perception and Data Visualization}
(Shuo Zang and Denis Cousineau, 2026, unpublished manuscript) studied
single-factor, two-level
comparisons across different populations and sample sizes, focusing on
Cohen's d. Broader independent, repeated-measures, and mixed factorial
support does not constitute empirical validation of the generalized
y-axis recommendations. Hedges' g, paired dz, multi-factor maximum-effect
selection, and generalized ER use beyond the studied comparisons are
unvalidated extensions. Alternative base ranges are exploratory.

The parameter \eqn{a} is taken directly from the effect-size study: 5.723 for
\eqn{X \geq 0.8}, 1.575 for \eqn{0.5 \leq X < 0.8}, and 0.254 for
\eqn{0.2 \leq X < 0.5}. These values may change in later versions as
further evidence becomes available. See \code{\link{optimal_graph}} for the exact
implemented expansion, pooling, and fallback rules.

A separate methods paper is planned to explain the package's derivation
from the effect-size study. It is not yet published; the package does not supply
a citation to that planned paper.

Version 1.0.0 is the first public package version, based on the V1.8
development implementation. The code is available under the MIT license.
Run \code{citation("oes")} for the software citation.
}
\section{Public data resources}{
The effect-size manuscript is associated with Shuo Zang and Denis
Cousineau's 2025 OSF resource, \emph{Visualizing Standardized Effect Sizes Using the Framework of Graph Perception and Data Visualization},
licensed under CC BY 4.0: \doi{10.17605/OSF.IO/DRCTA}. This DOI identifies
the OSF resource, not a published-paper or software DOI.

The supplied \code{Study4_long.csv} example data come from Shuo Zang and
Denis Cousineau's 2025 OSF project, ``When Error Bars Fail to Correct
Misleading Charts: Judgments of Lower y-axis Truncation across Layouts and
Audiences'', under CC BY 4.0. The project and source-file links are
\doi{10.17605/OSF.IO/DTYBF} and
\url{https://osf.io/dtybf/files/ebsh5}.
This is the error-bar project, not the effect-size calibration dataset.
The package's self-contained examples and tests do not download these
resources or require their files.
}
\references{
Zang, S., and Cousineau, D. (2026).
\emph{Visualizing Standardized Effect Sizes Using the Framework of Graph Perception and Data Visualization}. Unpublished manuscript.

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
\author{
Shuo Zang and Denis Cousineau, School of Psychology, University of Ottawa.
Maintainer: Shuo Zang \email{zshuo070@gmail.com}.
Shuo Zang's ORCID: \url{https://orcid.org/0009-0000-4387-8145}.
}
\keyword{package}
