test_that("plot-only fallbacks honor and validate measurement ranges", {
  means <- data.frame(group = factor(c("A", "B")), score = c(3, 5))
  no_factors <- data.frame(x = seq_len(12), score = seq(2, 8, length.out = 12))
  plots <- list(
    ggplot2::ggplot(means, ggplot2::aes(group, score)) + ggplot2::geom_col(),
    ggplot2::ggplot(no_factors, ggplot2::aes(x, score)) + ggplot2::geom_point()
  )
  for (p in plots) {
    result <- oes::optimal_graph(p, measurement_range = c(0, 10),
                                 detail = TRUE, verbose = FALSE)
    expect_equal(expect_buildable(result$plot)$layout$panel_params[[1L]]$y.range,
                 c(0, 10))
    text <- oes::optimal_graph(p, measurement_range = c(0, 10),
                               output = "y_axis_limit", verbose = FALSE)
    expect_match(text, "lower = 0[.]0+, upper = 10[.]0+")
    expect_match(text, "supplied measurement range")
    expect_error(oes::optimal_graph(p, measurement_range = c(10, 0),
                                   verbose = FALSE), "must be <")
    expect_error(oes::optimal_graph(p, measurement_range = c(0, Inf),
                                   verbose = FALSE), "finite")
    expect_error(oes::optimal_graph(p, measurement_range = 0,
                                   verbose = FALSE), "numeric length 2")
  }
})

test_that("original-layout override restores observations censored by scale limits", {
  dat <- make_independent()
  p <- ggplot2::ggplot(dat, ggplot2::aes(group, score)) + ggplot2::geom_boxplot()
  limited <- p + ggplot2::scale_y_continuous(limits = c(3, 5), name = "Scores")
  full <- ggplot2::ggplot_build(p)$data[[1L]]
  calls <- list(
    list(plot = limited),
    list(plot = limited, data = dat, DV = "score", between = "group")
  )
  for (args in calls) {
    result <- do.call(oes::optimal_graph, c(args, list(layout = "original",
      override_existing_limits = TRUE, detail = TRUE, verbose = FALSE)))
    built <- expect_buildable(result$plot)
    expect_null(result$plot$scales$get_scales("y")$limits)
    expect_identical(result$plot$scales$get_scales("y")$name, "Scores")
    expect_equal(built$data[[1L]][c("ymin", "lower", "middle", "upper", "ymax")],
                 full[c("ymin", "lower", "middle", "upper", "ymax")])
    expect_equal(built$layout$panel_params[[1L]]$y.range,
                 unlist(result$oes$range, use.names = FALSE))
    expect_equal(limited$scales$get_scales("y")$limits, c(3, 5))
  }
})

test_that("unresolved plot-only calls retain the original plot despite override", {
  # Histograms have no raw y mapping, so no recommendation is available.
  p <- ggplot2::ggplot(data.frame(score = 1:12), ggplot2::aes(x = score)) +
    ggplot2::geom_histogram(bins = 4) +
    ggplot2::scale_y_continuous(limits = c(0, 100))
  result <- oes::optimal_graph(p, override_existing_limits = TRUE,
                               detail = TRUE, verbose = FALSE)
  expect_identical(result$plot, p)
  expect_null(result$oes)
  expect_identical(oes::optimal_graph(p, override_existing_limits = TRUE,
                                     verbose = FALSE), p)
})
