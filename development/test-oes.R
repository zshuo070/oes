###############################################################################
# OES v1.8: self-contained examples and regression checks
###############################################################################
# Updates from the v1.7 test file:
# - Added assertions for fill-only plots: separate lines, visible colours,
#   correct cell means, aligned error bars, and distinct dodged positions.
# - Added shape-only, combined colour/shape, linetype, and explicit-group checks.
# - Checked that the original raincloud layout preserves its data and layers.
# - Retained all effect-size, CI, pooling, argument, and range checks below.
#
# Updates from the v1.6 test file:
# - Replaced the unsupported "difci95" name with "ci95_dif".
# - Removed Study4_long.csv, readr, superb, forcats, and project-specific data.
# - Replaced examples that imply participants belong to multiple independent
#   groups with a mixed design in which every participant belongs to one group.
# - Replaced unverified example calls with deterministic data and assertions.
# - Added checks for the v1.7 Hedges' g fix and Cousineau-Morey CI df fix.
# - Retained the approved sqrt(2) multiplier for difference-adjusted CIs.
# - Checks do not require testthat or write any files.
#
# Usage: save beside OES_v1.8.R, then run source("test-oes.R") or
#        Rscript /path/to/test-oes.R.
# If OES_v1.8.R is absent beside this script, oes() and optimal_graph() must
# already be loaded (for example, from the future installed package).
###############################################################################

required_packages <- c("ggplot2", "dplyr", "rlang", "rstatix")
missing_packages <- required_packages[!vapply(
  required_packages, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1)
)]
if (length(missing_packages)) {
  stop("Install required packages first: ", paste(missing_packages, collapse = ", "))
}
if (utils::packageVersion("ggplot2") < "4.0.0") {
  stop("The graph checks require ggplot2 >= 4.0.0; update ggplot2 first.")
}

# Locate the script without changing the working directory.
script_dir <- local({
  ofiles <- vapply(sys.frames(), function(frame) {
    if (is.null(frame$ofile)) "" else as.character(frame$ofile)[1L]
  }, character(1))
  ofiles <- ofiles[nzchar(ofiles)]
  file_arg <- grep("^--file=", commandArgs(), value = TRUE)
  script_path <- if (length(ofiles)) {
    tail(ofiles, 1L)
  } else if (length(file_arg)) {
    sub("^--file=", "", file_arg[1L])
  } else {
    NULL
  }
  if (is.null(script_path)) getwd() else dirname(normalizePath(
    script_path, winslash = "/", mustWork = FALSE
  ))
})
source_path <- file.path(script_dir, "OES_v1.8.R")
if (file.exists(source_path)) {
  source(source_path)
} else if (!exists("oes", mode = "function") ||
           !exists("optimal_graph", mode = "function")) {
  stop("Save OES_v1.8.R beside test-oes.R or load the OES functions first.")
}

check <- function(condition, label) {
  if (!isTRUE(condition)) stop("FAILED: ", label, call. = FALSE)
  invisible(TRUE)
}
equal_num <- function(actual, expected, label, tolerance = 1e-8) {
  check(isTRUE(all.equal(as.numeric(actual), as.numeric(expected),
                         tolerance = tolerance)), label)
}
expect_error <- function(expr, pattern, label) {
  err <- tryCatch({ force(expr); NULL }, error = identity)
  check(inherits(err, "error") && grepl(pattern, conditionMessage(err)), label)
}
capture_warnings <- function(expr) {
  messages <- character()
  value <- withCallingHandlers(expr, warning = function(w) {
    messages <<- c(messages, conditionMessage(w))
    invokeRestart("muffleWarning")
  })
  list(value = value, warnings = messages)
}
finite_result <- function(result, label) {
  check(inherits(result, "oes_result"), paste(label, "result class"))
  check(all(is.finite(unlist(result$range))) &&
          result$range$lower < result$range$upper, paste(label, "valid range"))
  check(all(is.finite(result$res$eb_half)), paste(label, "finite error bars"))
}
build_ok <- function(p, label) {
  check(inherits(p, "ggplot"), paste(label, "ggplot result"))
  built <- ggplot2::ggplot_build(p)
  check(length(built$data) > 0L, paste(label, "builds"))
  invisible(built)
}

# 1. Independent groups: manually calculable Cohen's d and corrected g.
independent <- data.frame(
  group = factor(rep(c("A", "B"), each = 5L)),
  score = c(1:5, 3:7)
)
d_result <- oes(independent, DV = score, between = group,
                detail = TRUE, verbose = FALSE)
d_expected <- abs(mean(1:5) - mean(3:7)) / stats::sd(1:5)
equal_num(d_result$dp, d_expected, "independent Cohen's d")
check(identical(d_result$effect_info$effect_type, "d"), "d metadata")
finite_result(d_result, "independent d")
unequal_groups <- data.frame(
  group = factor(c(rep("A", 4L), rep("B", 6L))),
  score = c(1, 2, 3, 4, 2, 4, 6, 8, 10, 12)
)
unequal_result <- oes(unequal_groups, DV = score, between = group,
                      detail = TRUE, verbose = FALSE)
unequal_expected <- abs(mean(1:4) - mean(seq(2, 12, 2))) /
  sqrt((stats::var(1:4) + stats::var(seq(2, 12, 2))) / 2)
equal_num(unequal_result$dp, unequal_expected,
          "v1.6 between-subject standardization retained for unequal groups")
forwarded <- oes_chr(independent, DV = "score", between = "group",
                     detail = TRUE, verbose = FALSE)
equal_num(forwarded$dp, d_result$dp, "forwarded NULL within/id defaults")
for (dv_name in c("mean", "n", "score value")) {
  renamed <- independent
  names(renamed) <- c("group type", dv_name)
  renamed_result <- oes(renamed, DV = dv_name, between = "group type",
                        detail = TRUE, verbose = FALSE)
  equal_num(renamed_result$dp, d_result$dp, paste(dv_name, "effect unchanged"))
  equal_num(renamed_result$res$sd, d_result$res$sd, paste(dv_name, "SD unchanged"))
  equal_num(unlist(renamed_result$range), unlist(d_result$range),
            paste(dv_name, "range unchanged"))
}

g_result <- oes(independent, DV = score, between = group,
                effect = "g", detail = TRUE, verbose = FALSE)
g_expected <- rstatix::cohens_d(
  independent, score ~ group, hedges.correction = TRUE
)$effsize[1L]
equal_num(g_result$dp, abs(g_expected), "Hedges' g uses supported correction")
check(identical(g_result$effect_info$effect_type, "g"), "g metadata")
check(g_result$dp < d_result$dp, "small-sample g is smaller than d")
finite_result(g_result, "independent g")

# 2. Paired observations: shuffled rows must still match by participant id.
a <- c(2, 3, 4, 5, 6)
b <- c(3, 5, 5, 8, 9)
paired <- data.frame(
  id = rep(1:5, 2L),
  condition = factor(rep(c("A", "B"), each = 5L)),
  score = c(a, b)
)
paired <- paired[c(10, 2, 8, 4, 6, 1, 9, 3, 7, 5), ]
dz_expected <- abs(mean(a - b)) / stats::sd(a - b)
paired_bare <- oes(paired, DV = score, within = condition, id = id,
                   error_bar = "ci95_corr", detail = TRUE, verbose = FALSE)
paired_quoted <- oes(paired, DV = "score", within = "condition", id = "id",
                     error_bar = "ci95_corr", detail = TRUE, verbose = FALSE)
equal_num(paired_bare$dp, dz_expected, "paired Cohen's dz with shuffled rows")
equal_num(paired_bare$range$lower, paired_quoted$range$lower, "bare/quoted lower")
equal_num(paired_bare$range$upper, paired_quoted$range$upper, "bare/quoted upper")
check(identical(paired_bare$effect_info$effect_type, "dz"), "dz metadata")

# With J = 2 conditions, corrected SD = SD(a - b) / sqrt(2).
# Pooling the two transformed SDs does not turn 5 participants into 10.
cm_sd_expected <- stats::sd(a - b) / sqrt(2)
cm_half_expected <- stats::qt(0.975, df = 4) * cm_sd_expected / sqrt(5)
equal_num(paired_bare$res$df, rep(4, 2L), "CM pooled df is n - 1")
equal_num(paired_bare$res$se_cm, rep(cm_sd_expected / sqrt(5), 2L), "CM SE")
equal_num(paired_bare$res$eb_half, rep(cm_half_expected, 2L), "CM CI half-width")
check(all(paired_bare$res$eb_half >
            stats::qt(0.975, df = 8) * paired_bare$res$se_cm),
      "CM CI does not use old overcounted df = 8")

paired_g <- oes(paired, DV = score, within = condition, id = id,
                effect = "g", detail = TRUE, verbose = FALSE)
equal_num(paired_g$dp, dz_expected, "effect g keeps within-subject dz")

# 3. Valid mixed 2 x 3 design: participants occupy exactly one group.
mixed <- expand.grid(id = 1:12, condition = paste0("C", 1:3))
mixed$group <- factor(ifelse(mixed$id <= 6, "G1", "G2"))
mixed$condition <- factor(mixed$condition, levels = paste0("C", 1:3))
condition_index <- as.integer(mixed$condition)
mixed$score <- 5 + mixed$id / 5 + (mixed$group == "G2") / 2 +
  condition_index + sin(mixed$id * 1.1 + condition_index) * 0.7

# Every supported method must produce finite bars/ranges. Pooling may change
# bars and the final range; the single variability estimate used by ER stays
# unchanged when only pooled is toggled within the SAME error-bar method.
methods <- c("ci95", "ci95_dif", "ci95_corr", "ci95_dif_corr", "se", "sd")
results <- list()
for (method in methods) {
  pooled_result <- oes(mixed, DV = score, within = condition, between = group,
                       id = id, error_bar = method, pooled = TRUE,
                       detail = TRUE, verbose = FALSE)
  unpooled_result <- oes(mixed, DV = score, within = condition, between = group,
                         id = id, error_bar = method, pooled = FALSE,
                         detail = TRUE, verbose = FALSE)
  finite_result(pooled_result, paste(method, "pooled"))
  finite_result(unpooled_result, paste(method, "unpooled"))
  equal_num(pooled_result$dp, unpooled_result$dp, paste(method, "same X"))
  equal_num(pooled_result$pooled_sd, unpooled_result$pooled_sd,
            paste(method, "same ER variability"))
  equal_num(pooled_result$ER, unpooled_result$ER, paste(method, "same ER"))
  if (method %in% c("ci95_corr", "ci95_dif_corr")) {
    equal_num(pooled_result$res$df, rep(5, 6L), paste(method, "mixed CM df"))
  }
  results[[method]] <- pooled_result
}
equal_num(results$ci95_dif$res$eb_half, results$ci95$res$eb_half * sqrt(2),
          "ordinary difference-adjusted CI multiplier")
equal_num(results$ci95_dif_corr$res$eb_half,
          results$ci95_corr$res$eb_half * sqrt(2), "CM difference multiplier")
equal_num(results$ci95_dif_corr$ER, results$ci95_corr$ER,
          "CM difference adjustment does not affect ER")
check(all(c("d", "dz") %in% results$ci95$effect_table$effect_type),
      "mixed conditional search includes d and dz")

# 4. Required inputs: errors are intentional and caught by the checks.
for (method in c("ci95_corr", "ci95_dif_corr")) {
  expect_error(oes(paired, DV = score, within = condition, error_bar = method),
               "valid participant", paste(method, "rejects missing id"))
  expect_error(oes(independent, DV = score, between = group,
                   error_bar = method), "within-subject factor",
               paste(method, "rejects a between-only design"))
}
expect_error(oes(independent, DV = score, between = group,
                 error_bar = "difci95"), "arg", "obsolete name is rejected")
expect_error(oes(independent, DV = score, between = group,
                 measurement_range = c(7, 1)), "must be <", "reversed range")
expect_error(oes(independent, DV = "absent", between = group),
             "not present", "missing DV has clear error")
no_id <- capture_warnings(oes(paired, DV = score, within = condition,
                              measurement_range = c(0, 10), detail = TRUE))
check(any(grepl("no valid participant", no_id$warnings)), "missing-id warning")
check(is.na(no_id$value$dp), "paired effect unavailable without id")
equal_num(unlist(no_id$value$range), c(0, 10), "missing-id fallback range")
incomplete <- paired[!(paired$id == 5 & paired$condition == "B"), ]
expect_error(oes(incomplete, DV = score, within = condition, id = id,
                 error_bar = "ci95_corr", verbose = FALSE),
             "complete|missing|incomplete", "CM rejects incomplete profiles")
ordinary_incomplete <- oes(incomplete, DV = score, within = condition, id = id,
                           error_bar = "ci95", detail = TRUE, verbose = FALSE)
finite_result(ordinary_incomplete, "ordinary CI with incomplete data")
zero_effect <- independent
zero_effect$score <- rep(1:5, 2L)
zero_result <- oes(zero_effect, DV = score, between = group,
                   measurement_range = c(0, 10), detail = TRUE, verbose = FALSE)
equal_num(zero_result$dp, 0, "zero effect estimated")
equal_num(unlist(zero_result$range), c(0, 10), "effect below .20 falls back")

# 5. Summary data provide error bars but do not identify participant effects.
full_summary <- data.frame(group = factor(c("A", "B")),
                           score = c(3, 5), n = c(5, 5),
                           sd = rep(stats::sd(1:5), 2L))
summary_result <- oes(full_summary, DV = score, between = group,
                      measurement_range = c(0, 10), detail = TRUE, verbose = FALSE)
check(identical(summary_result$args$summary_type, "summary_full"),
      "n/sd summary is recognized")
check(is.na(summary_result$dp), "summary effect size not fabricated")
equal_num(unlist(summary_result$range), c(0, 10), "summary uses supplied fallback")
check(all(is.finite(summary_result$res$eb_half)), "full summary bars finite")
means_only <- full_summary[c("group", "score")]
means_result <- capture_warnings(oes(means_only, DV = score, between = group,
                                    measurement_range = c(0, 10), detail = TRUE))
check(any(grepl("means-only summary", means_result$warnings)),
      "means-only summary warning explains missing variability")
equal_num(unlist(means_result$value$range), c(0, 10), "means-only fallback")

# 6. Self-contained plotting examples: x, colour, shape, facets, and layers.
p_box <- ggplot2::ggplot(independent, ggplot2::aes(group, score)) +
  ggplot2::geom_hline(yintercept = 4, colour = "red") + ggplot2::geom_boxplot()
p_mixed <- ggplot2::ggplot(mixed, ggplot2::aes(condition, score, colour = group)) +
  ggplot2::geom_boxplot() + ggplot2::facet_wrap(~ group)
p_shape <- ggplot2::ggplot(mixed, ggplot2::aes(condition, score, shape = group)) +
  ggplot2::geom_point()
p_violin <- ggplot2::ggplot(mixed, ggplot2::aes(condition, score, fill = group)) +
  ggplot2::geom_violin(position = "dodge") +
  ggplot2::geom_boxplot(width = 0.15, position = ggplot2::position_dodge(0.9))
p_line <- ggplot2::ggplot(mixed, ggplot2::aes(condition, score, colour = group)) +
  ggplot2::stat_summary(fun = mean, geom = "line", ggplot2::aes(group = group)) +
  ggplot2::stat_summary(fun = mean, geom = "point")
p_layer <- ggplot2::ggplot() + ggplot2::geom_boxplot(
  data = independent, mapping = ggplot2::aes(group, score)
)
for (p in list(p_box, p_mixed, p_shape, p_violin, p_line, p_layer)) {
  build_ok(optimal_graph(p, verbose = FALSE), "plot-only summary")
  build_ok(optimal_graph(p, layout = "original", verbose = FALSE),
           "plot-only original")
}

# 6a. V1.8 summary grouping regressions. Building without an error alone would
# miss the old bug: it rendered six means as one black zigzag line.
layer_data <- function(p, built, geom_class) {
  index <- which(vapply(p$layers, function(layer) {
    inherits(layer$geom, geom_class)
  }, logical(1)))
  check(length(index) == 1L, paste("exactly one", geom_class, "layer"))
  built$data[[index]]
}
check_series <- function(layer, n_groups, rows_per_group, label) {
  check(length(unique(layer$group)) == n_groups, paste(label, "group count"))
  check(all(as.integer(table(layer$group)) == rows_per_group),
        paste(label, "rows per group"))
}
order_layer <- function(layer) {
  layer[order(layer$group, as.numeric(layer$x), layer$y), , drop = FALSE]
}

# This reproduces the user's seed-456 example exactly. Its id is not supplied
# to OES: the grid repeats each id across both Groups, so it is not a valid
# mixed-design participant identifier. Numerical mixed-design checks above
# use the valid `mixed` data instead.
set.seed(456)
dat_2x3 <- expand.grid(
  Group = factor(c("A", "B")),
  Condition = factor(paste0("C", 1:3)),
  id = 1:40
)
cell_mu <- c(A.C1 = 0, A.C2 = 0.3, A.C3 = 0.6,
             B.C1 = 0.2, B.C2 = 0.7, B.C3 = 1.0)
dat_2x3$mu <- unname(cell_mu[paste(dat_2x3$Group, dat_2x3$Condition, sep = ".")])
dat_2x3$DV <- stats::rnorm(nrow(dat_2x3), mean = dat_2x3$mu, sd = 0.8)
p_rain <- ggplot2::ggplot(dat_2x3,
                          ggplot2::aes(Condition, DV, fill = Group)) +
  ggplot2::geom_violin(width = 0.8, alpha = 0.3,
                      position = ggplot2::position_dodge(width = 0.8)) +
  ggplot2::geom_boxplot(width = 0.15, outlier.shape = NA,
                       position = ggplot2::position_dodge(width = 0.8)) +
  ggplot2::geom_jitter(alpha = 0.4, size = 1,
                      position = ggplot2::position_jitterdodge(
                        jitter.width = 0.1, dodge.width = 0.8))
rain_result <- optimal_graph(p_rain, detail = TRUE, layout = "summary",
                             verbose = FALSE)
rain_built <- build_ok(rain_result$plot, "fill-only raincloud summary")
rain_lines <- order_layer(layer_data(rain_result$plot, rain_built, "GeomLine"))
rain_points <- order_layer(layer_data(rain_result$plot, rain_built, "GeomPoint"))
rain_bars <- order_layer(layer_data(rain_result$plot, rain_built, "GeomErrorbar"))
expected_means <- stats::aggregate(DV ~ Group + Condition,
                                   data = dat_2x3, FUN = mean)$DV
for (layer in list(rain_lines, rain_points, rain_bars)) {
  check_series(layer, 2L, 3L, "fill-only summary")
  check(length(unique(layer$colour)) == 2L,
        "fill supplies two visible summary colours")
  check(all(vapply(split(layer$colour, layer$group), function(x) {
    length(unique(x)) == 1L
  }, logical(1))), "fill series have constant colours")
  equal_num(sort(layer$y), sort(expected_means), "fill-only cell means retained")
  check(all(vapply(split(as.numeric(layer$x), round(as.numeric(layer$x))),
                   function(x) length(x) == 2L && diff(sort(x)) > 0,
                   logical(1))), "fill-only groups have distinct x positions")
}
equal_num(rain_lines$x, rain_points$x, "fill line/point x alignment")
equal_num(rain_points$x, rain_bars$x, "fill point/error-bar x alignment")
check(identical(rain_lines$group, rain_points$group) &&
        identical(rain_points$group, rain_bars$group), "fill layer group alignment")
check(identical(rain_lines$colour, rain_points$colour) &&
        identical(rain_points$colour, rain_bars$colour), "fill layer colour alignment")
equal_num(sort(rain_bars$ymin), sort(rain_result$oes$res$eb_lower),
          "fill error-bar lower bounds")
equal_num(sort(rain_bars$ymax), sort(rain_result$oes$res$eb_upper),
          "fill error-bar upper bounds")
rain_original <- optimal_graph(p_rain, detail = TRUE, layout = "original",
                               verbose = FALSE)
check(identical(rain_original$plot$data, p_rain$data),
      "original raincloud raw data retained")
check(identical(rain_original$plot$mapping, p_rain$mapping),
      "original raincloud mappings retained")
check(identical(vapply(rain_original$plot$layers, function(x) class(x$geom)[1L],
                       character(1)),
                vapply(p_rain$layers, function(x) class(x$geom)[1L], character(1))),
      "original raincloud violin, box, and jitter layers retained")
build_ok(rain_original$plot, "original raincloud still builds")

shape_result <- optimal_graph(p_shape, detail = TRUE, verbose = FALSE)
shape_built <- build_ok(shape_result$plot, "shape-only summary")
check_series(layer_data(shape_result$plot, shape_built, "GeomLine"),
             2L, 3L, "shape-only line")
shape_points <- layer_data(shape_result$plot, shape_built, "GeomPoint")
check_series(shape_points, 2L, 3L, "shape-only point")
check(length(unique(shape_points$shape)) == 2L, "shape-only shapes retained")
check(all(vapply(split(shape_points$shape, shape_points$group), function(x) {
  length(unique(x)) == 1L
}, logical(1))), "shape-only series keep their shapes")

combined <- mixed
combined$shape_group <- factor(ifelse(combined$id %% 2L, "odd", "even"))
p_combined <- ggplot2::ggplot(combined, ggplot2::aes(
  condition, score, colour = group, shape = shape_group
)) + ggplot2::geom_point()
combined_result <- optimal_graph(p_combined, detail = TRUE, verbose = FALSE)
combined_built <- build_ok(combined_result$plot, "combined colour/shape summary")
combined_lines <- layer_data(combined_result$plot, combined_built, "GeomLine")
combined_points <- layer_data(combined_result$plot, combined_built, "GeomPoint")
check_series(combined_lines, 4L, 3L, "combined colour/shape line")
check_series(combined_points, 4L, 3L, "combined colour/shape point")
check(length(unique(combined_points$colour)) == 2L &&
        length(unique(combined_points$shape)) == 2L,
      "combined colour and shape both retained")
check(all(vapply(split(combined_points, combined_points$group), function(x) {
  length(unique(x$colour)) == 1L && length(unique(x$shape)) == 1L
}, logical(1))), "each colour/shape combination forms its own series")
check(nrow(unique(combined_points[c("group", "colour", "shape")])) == 4L,
      "four distinct colour/shape series")

p_linetype <- ggplot2::ggplot(mixed, ggplot2::aes(
  condition, score, linetype = group
)) + ggplot2::stat_summary(fun = mean, geom = "line")
linetype_result <- optimal_graph(p_linetype, detail = TRUE, verbose = FALSE)
linetype_built <- build_ok(linetype_result$plot, "linetype-only summary")
linetype_lines <- layer_data(linetype_result$plot, linetype_built, "GeomLine")
check_series(linetype_lines, 2L, 3L, "linetype-only line")
check(length(unique(linetype_lines$linetype)) == 2L,
      "linetype-only line styles retained")

# Explicit grouping must override the otherwise inferred colour/shape
# interaction. Six cell summaries in each Group are intentional here.
p_explicit <- p_combined + ggplot2::aes(group = group)
explicit_result <- optimal_graph(p_explicit, detail = TRUE, verbose = FALSE)
explicit_built <- build_ok(explicit_result$plot, "explicit group summary")
check_series(layer_data(explicit_result$plot, explicit_built, "GeomLine"),
             2L, 6L, "explicit group overrides colour/shape interaction")

graph_result <- optimal_graph(data = paired, DV = score, within = condition,
                              id = id, error_bar = "ci95_corr", detail = TRUE,
                              verbose = FALSE)
equal_num(graph_result$oes$dp, dz_expected, "optimal_graph forwards bare id")
built <- build_ok(graph_result$plot, "explicit paired-data graph")
equal_num(built$layout$panel_params[[1L]]$y.range,
          unlist(graph_result$oes$range), "exact vertical OES limits")
x_range <- built$layout$panel_params[[1L]]$x.range
check(x_range[1L] < 1 && x_range[2L] > 2, "horizontal category expansion retained")

original <- optimal_graph(p_box, layout = "original", detail = TRUE,
                          verbose = FALSE)
check(length(original$plot$layers) == length(p_box$layers), "original layers retained")
equal_num(ggplot2::ggplot_build(original$plot)$layout$panel_params[[1L]]$y.range,
          unlist(original$oes$range), "original layout exact vertical limits")
limited <- p_box + ggplot2::coord_cartesian(ylim = c(0, 10))
preserved <- optimal_graph(limited, layout = "original", verbose = FALSE)
equal_num(preserved$coordinates$limits$y, c(0, 10), "existing coord limits preserved")
replaced <- suppressMessages(optimal_graph(limited, layout = "original",
                           override_existing_limits = TRUE, verbose = FALSE))
equal_num(replaced$coordinates$limits$y, unlist(d_result$range), "limits override works")

# Means-only plots need raw data for X; supply raw data explicitly to recover it.
p_means <- ggplot2::ggplot(means_only, ggplot2::aes(group, score)) +
  ggplot2::geom_col()
insufficient_text <- optimal_graph(p_means, output = "y_axis_limit", verbose = FALSE)
check(grepl("not estimable", insufficient_text) &&
        grepl("sufficient raw or summary", insufficient_text),
      "means-only plot reports insufficient information")
recovered <- optimal_graph(plot = p_means, data = independent, DV = score,
                           between = group, detail = TRUE, verbose = FALSE)
equal_num(recovered$oes$dp, d_expected, "raw data recover X for summary plot")
build_ok(recovered$plot, "summary plot with explicit raw data")
recommendation <- optimal_graph(data = paired, DV = score, within = condition,
                                id = id, error_bar = "ci95_dif_corr",
                                output = "y_axis_limit", verbose = FALSE)
check(is.character(recommendation) && length(recommendation) == 1L &&
        grepl("Recommended y-axis limits", recommendation),
      "detailed text recommendation")

message("All OES v1.8 self-contained checks passed.")
