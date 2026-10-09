# The numerical engine is internal; regression tests reach it explicitly.
# User-facing behavior is exercised through exported optimal_graph().
oes_internal_for_test <- utils::getFromNamespace("oes", "oes")

# Synthetic fixtures test implementation behavior; they do not establish the
# empirical validity of the calibrated recommendation outside the effect-size study.
make_independent <- function() {
  data.frame(group = factor(rep(c("A", "B"), each = 5L)), score = c(1:5, 3:7))
}

make_paired <- function(shuffle = TRUE) {
  dat <- data.frame(
    id = rep(1:5, 2L), condition = factor(rep(c("A", "B"), each = 5L)),
    score = c(2, 3, 4, 5, 6, 3, 5, 5, 8, 9)
  )
  if (shuffle) dat <- dat[c(10, 2, 8, 4, 6, 1, 9, 3, 7, 5), ]
  dat
}

make_mixed <- function() {
  dat <- expand.grid(id = 1:12, condition = paste0("C", 1:3))
  dat$group <- factor(ifelse(dat$id <= 6, "G1", "G2"))
  dat$condition <- factor(dat$condition, levels = paste0("C", 1:3))
  index <- as.integer(dat$condition)
  dat$score <- 5 + dat$id / 5 + (dat$group == "G2") / 2 + index +
    sin(dat$id * 1.1 + index) * 0.7
  dat
}

expect_finite_result <- function(result) {
  expect_s3_class(result, "oes_result")
  expect_true(all(is.finite(unlist(result$range))))
  expect_lt(result$range$lower, result$range$upper)
  expect_true(all(is.finite(result$res$eb_half)))
}

expect_buildable <- function(plot) {
  expect_true(inherits(plot, "ggplot"))
  built <- ggplot2::ggplot_build(plot)
  expect_gt(length(built$data), 0L)
  built
}

get_summary_layer <- function(plot, built, geom_class) {
  index <- which(vapply(plot$layers, function(layer) {
    inherits(layer$geom, geom_class)
  }, logical(1)))
  expect_length(index, 1L)
  layer <- built$data[[index]]
  layer[order(layer$group, as.numeric(layer$x), layer$y), , drop = FALSE]
}

expect_series <- function(layer, groups, rows) {
  expect_length(unique(layer$group), groups)
  expect_true(all(as.integer(table(layer$group)) == rows))
}

capture_test_warnings <- function(expr) {
  warnings <- character()
  value <- withCallingHandlers(expr, warning = function(w) {
    warnings <<- c(warnings, conditionMessage(w))
    invokeRestart("muffleWarning")
  })
  list(value = value, warnings = warnings)
}
