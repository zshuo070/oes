The only public function is `optimal_graph()`. Public-API tests verify the
namespace exports only that function and that `detail = TRUE` retains the
numerical OES results for independent, repeated-measures, and mixed designs.

Numerical regression tests use the clearly named `oes_internal_for_test`
helper obtained with `getFromNamespace("oes", "oes")` to exercise the internal
engine. This is a testing technique, not a user-facing API. The suite tests
the installed package without sourcing development scripts or downloading data.

Coverage includes manual independent d/g and paired dz calculations, ordinary
and Cousineau-Morey interval widths, participant degrees of freedom, all six
error-bar methods, pooling/ER invariance, argument resolution, invalid inputs,
missing-ID and low-effect fallbacks, all three ER constants, summary-data
limitations, inferred plot
factors, fill/shape/linetype grouping, explicit groups, original layouts,
existing limits, exact vertical ranges, and text output. Applicable built-in
mpg, ToothGrowth, and PlantGrowth examples from `test-oes(1).R` are included.
The mpg two-level driving example filters to the two requested levels rather
than retaining a third `other` level. The outcome-derived weight-bin facet is
excluded as a design example. Synthetic repeated-measures fixtures assign
each participant to exactly one independent group.

Numerical regressions establish software implementation behavior. They do
not establish empirical calibration for broader designs, Hedges' g, paired
dz, multifactor graphs, or alternative geometries beyond the two-level,
single-factor Cohen's d conditions evaluated in *Visualizing Standardized Effect Sizes Using the Framework of Graph Perception and Data Visualization*
(Shuo Zang and Denis Cousineau, 2026, unpublished manuscript).
The associated OSF resource (Zang and Cousineau, 2025; CC BY 4.0) is
<https://doi.org/10.17605/OSF.IO/DRCTA>. This DOI identifies the
effect-size project resource, not a published-paper or software DOI.

The supplied error-bar Study 4B example refers to user-provided source data at
https://doi.org/10.17605/OSF.IO/DTYBF and https://osf.io/dtybf/files/ebsh5.
Those data belong to *When Error Bars Fail to Correct Misleading Charts:
Judgments of Lower y-axis Truncation across Layouts and Audiences*, by
Shuo Zang and Denis Cousineau. Real-data and optional `superb`
demonstrations belong in manual examples
with their provenance and design assumptions stated. They are not required
by this offline test suite and are not identified here as effect-size study data.

The Steps 1–6 recheck adds independent numerical checks of a three-level,
two-factor conditional-effect table and its winning standardized contrast,
and three-condition Cousineau–Morey normalization/correction for both pooling
settings. Plot regressions cover supplied measurement ranges and validation
in both plot-only fallback branches, plus restoration of observations when
original-layout overrides clear old y-scale limits. The original input graph
and other scale settings are checked for preservation.
