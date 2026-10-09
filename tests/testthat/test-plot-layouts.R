test_that("plot-only calls extract global, layer, and faceted raw data", {
  independent <- make_independent()
  mixed <- make_mixed()
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
    expect_buildable(oes::optimal_graph(p, verbose = FALSE))
    expect_buildable(oes::optimal_graph(p, layout = "original", verbose = FALSE))
  }
  reference <- oes_internal_for_test(independent, DV = score, between = group,
                        detail = TRUE, verbose = FALSE)
  layer_result <- oes::optimal_graph(p_layer, detail = TRUE, verbose = FALSE)
  expect_equal(layer_result$oes$dp, reference$dp)
  expect_equal(layer_result$oes$res$mean, reference$res$mean)
})

test_that("fill-only summaries retain separate coloured and aligned series", {
  # Reproduce supplied p16 exactly; ID is not passed because its grid repeats
  # each ID across both Groups. This plot-only test assumes independent cells.
  set.seed(456)
  dat <- expand.grid(Group = factor(c("A", "B")),
                     Condition = factor(paste0("C", 1:3)), id = 1:40)
  cell_mu <- c(A.C1 = 0, A.C2 = 0.3, A.C3 = 0.6,
               B.C1 = 0.2, B.C2 = 0.7, B.C3 = 1.0)
  dat$mu <- unname(cell_mu[paste(dat$Group, dat$Condition, sep = ".")])
  dat$DV <- stats::rnorm(nrow(dat), dat$mu, 0.8)
  p <- ggplot2::ggplot(dat, ggplot2::aes(Condition, DV, fill = Group)) +
    ggplot2::geom_violin(width = 0.8, alpha = 0.3,
                        position = ggplot2::position_dodge(width = 0.8)) +
    ggplot2::geom_boxplot(width = 0.15, outlier.shape = NA,
                         position = ggplot2::position_dodge(width = 0.8)) +
    ggplot2::geom_jitter(alpha = 0.4, size = 1,
                        position = ggplot2::position_jitterdodge(
                          jitter.width = 0.1, dodge.width = 0.8))
  result <- oes::optimal_graph(p, detail = TRUE, layout = "summary", verbose = FALSE)
  built <- expect_buildable(result$plot)
  lines <- get_summary_layer(result$plot, built, "GeomLine")
  points <- get_summary_layer(result$plot, built, "GeomPoint")
  bars <- get_summary_layer(result$plot, built, "GeomErrorbar")
  expected_means <- stats::aggregate(DV ~ Group + Condition, dat, mean)$DV
  for (layer in list(lines, points, bars)) {
    expect_series(layer, 2L, 3L)
    expect_length(unique(layer$colour), 2L)
    expect_true(all(vapply(split(layer$colour, layer$group), function(x) {
      length(unique(x)) == 1L
    }, logical(1))))
    expect_equal(sort(layer$y), sort(expected_means), tolerance = 1e-8)
    expect_true(all(vapply(split(as.numeric(layer$x), round(as.numeric(layer$x))),
                          function(x) length(x) == 2L && diff(sort(x)) > 0,
                          logical(1))))
  }
  expect_equal(as.numeric(lines$x), as.numeric(points$x))
  expect_equal(as.numeric(points$x), as.numeric(bars$x))
  expect_identical(lines$group, points$group)
  expect_identical(points$group, bars$group)
  expect_identical(lines$colour, points$colour)
  expect_identical(points$colour, bars$colour)
  expect_equal(sort(bars$ymin), sort(result$oes$res$eb_lower))
  expect_equal(sort(bars$ymax), sort(result$oes$res$eb_upper))

  original <- oes::optimal_graph(p, detail = TRUE, layout = "original", verbose = FALSE)
  expect_identical(original$plot$data, p$data)
  expect_identical(original$plot$mapping, p$mapping)
  expect_identical(vapply(original$plot$layers, function(x) class(x$geom)[1L], character(1)),
                   vapply(p$layers, function(x) class(x$geom)[1L], character(1)))
  expect_buildable(original$plot)
})

test_that("shape, colour-shape, and linetype series are grouped independently", {
  dat <- make_mixed()
  p_shape <- ggplot2::ggplot(dat, ggplot2::aes(condition, score, shape = group)) +
    ggplot2::geom_point()
  shape <- oes::optimal_graph(p_shape, detail = TRUE, verbose = FALSE)
  built <- expect_buildable(shape$plot)
  expect_series(get_summary_layer(shape$plot, built, "GeomLine"), 2L, 3L)
  points <- get_summary_layer(shape$plot, built, "GeomPoint")
  expect_series(points, 2L, 3L)
  expect_length(unique(points$shape), 2L)
  expect_true(all(vapply(split(points$shape, points$group), function(x) {
    length(unique(x)) == 1L
  }, logical(1))))

  dat$shape_group <- factor(ifelse(dat$id %% 2L, "odd", "even"))
  p_combined <- ggplot2::ggplot(dat, ggplot2::aes(
    condition, score, colour = group, shape = shape_group
  )) + ggplot2::geom_point()
  combined <- oes::optimal_graph(p_combined, detail = TRUE, verbose = FALSE)
  built <- expect_buildable(combined$plot)
  expect_series(get_summary_layer(combined$plot, built, "GeomLine"), 4L, 3L)
  points <- get_summary_layer(combined$plot, built, "GeomPoint")
  expect_series(points, 4L, 3L)
  expect_length(unique(points$colour), 2L)
  expect_length(unique(points$shape), 2L)
  expect_true(all(vapply(split(points, points$group), function(x) {
    length(unique(x$colour)) == 1L && length(unique(x$shape)) == 1L
  }, logical(1))))
  expect_equal(nrow(unique(points[c("group", "colour", "shape")])), 4L)

  p_line <- ggplot2::ggplot(dat, ggplot2::aes(condition, score, linetype = group)) +
    ggplot2::stat_summary(fun = mean, geom = "line")
  line <- oes::optimal_graph(p_line, detail = TRUE, verbose = FALSE)
  lines <- get_summary_layer(line$plot, expect_buildable(line$plot), "GeomLine")
  expect_series(lines, 2L, 3L)
  expect_length(unique(lines$linetype), 2L)

  explicit <- oes::optimal_graph(p_combined + ggplot2::aes(group = group),
                                 detail = TRUE, verbose = FALSE)
  expect_series(get_summary_layer(explicit$plot, expect_buildable(explicit$plot),
                                 "GeomLine"), 2L, 6L)
})

test_that("numerical OES limits match both plot layouts without vertical padding", {
  paired <- make_paired()
  result <- oes::optimal_graph(data = paired, DV = score, within = condition,
                               id = id, error_bar = "ci95_corr",
                               detail = TRUE, verbose = FALSE)
  expected <- abs(mean(c(2, 3, 4, 5, 6) - c(3, 5, 5, 8, 9))) /
    stats::sd(c(2, 3, 4, 5, 6) - c(3, 5, 5, 8, 9))
  expect_equal(result$oes$dp, expected, tolerance = 1e-8)
  built <- expect_buildable(result$plot)
  expect_equal(built$layout$panel_params[[1L]]$y.range,
               unlist(result$oes$range, use.names = FALSE))
  x <- built$layout$panel_params[[1L]]$x.range
  expect_lt(x[1L], 1)
  expect_gt(x[2L], 2)

  dat <- make_independent()
  p <- ggplot2::ggplot(dat, ggplot2::aes(group, score)) +
    ggplot2::geom_hline(yintercept = 4, colour = "red") + ggplot2::geom_boxplot()
  original <- oes::optimal_graph(p, layout = "original", detail = TRUE, verbose = FALSE)
  expect_length(original$plot$layers, length(p$layers))
  expect_equal(expect_buildable(original$plot)$layout$panel_params[[1L]]$y.range,
               unlist(original$oes$range, use.names = FALSE))
})

test_that("existing coordinate and scale limits are retained or explicitly replaced", {
  dat <- make_independent()
  reference <- oes_internal_for_test(dat, DV = score, between = group, detail = TRUE, verbose = FALSE)
  p <- ggplot2::ggplot(dat, ggplot2::aes(group, score)) + ggplot2::geom_boxplot()
  limited <- p + ggplot2::coord_cartesian(ylim = c(0, 10))
  preserved <- oes::optimal_graph(limited, layout = "original", verbose = FALSE)
  expect_equal(preserved$coordinates$limits$y, c(0, 10))
  replaced <- suppressMessages(oes::optimal_graph(limited, layout = "original",
    override_existing_limits = TRUE, verbose = FALSE))
  expect_equal(replaced$coordinates$limits$y, unlist(reference$range, use.names = FALSE))

  scaled <- p + ggplot2::scale_y_continuous(limits = c(0, 10))
  kept <- oes::optimal_graph(scaled, layout = "original", verbose = FALSE)
  expect_equal(kept$scales$get_scales("y")$limits, c(0, 10))
  replaced <- suppressMessages(oes::optimal_graph(scaled, layout = "original",
    override_existing_limits = TRUE, verbose = FALSE))
  expect_equal(expect_buildable(replaced)$layout$panel_params[[1L]]$y.range,
               unlist(reference$range, use.names = FALSE))
})

test_that("summary plots require raw data for X and can recover it explicitly", {
  means <- data.frame(group = factor(c("A", "B")), score = c(3, 5))
  p <- ggplot2::ggplot(means, ggplot2::aes(group, score)) + ggplot2::geom_col()
  text <- oes::optimal_graph(p, output = "y_axis_limit", verbose = FALSE)
  expect_match(text, "not estimable")
  expect_match(text, "sufficient raw or summary")
  expect_warning(oes::optimal_graph(p), "sufficient raw data")

  dat <- make_independent()
  recovered <- oes::optimal_graph(plot = p, data = dat, DV = score, between = group,
                                  detail = TRUE, verbose = FALSE)
  expect_equal(recovered$oes$dp, 2 / stats::sd(1:5), tolerance = 1e-8)
  expect_buildable(recovered$plot)
  paired <- make_paired()
  text <- oes::optimal_graph(data = paired, DV = score, within = condition, id = id,
                             error_bar = "ci95_dif_corr", output = "y_axis_limit",
                             verbose = FALSE)
  expect_type(text, "character")
  expect_length(text, 1L)
  expect_match(text, "Recommended y-axis limits")
  expect_match(text, "Cousineau")
})
