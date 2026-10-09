# Applicable p1-p16 patterns from test-oes(1).R are recreated offline.
# These are behavior checks, not evidence of empirical calibration for
# multifactor graphs, continuous/derived factors, or alternative geometries.

test_that("built-in mpg examples use genuinely two-level driving factors", {
  example_data <- new.env()
  utils::data("mpg", package = "ggplot2", envir = example_data)
  dat <- as.data.frame(example_data$mpg)
  # fct_other(..., keep = c("4", "f")) would retain a third "other" level.
  dat <- dat[dat$drv %in% c("4", "f"), ]
  dat$drv2 <- factor(dat$drv, levels = c("4", "f"))
  dat$year_f <- factor(dat$year)
  dat$class_small <- factor(ifelse(dat$class %in% c("subcompact", "compact"),
                                  "small", "other"))
  expect_equal(nlevels(dat$drv2), 2L)
  p <- ggplot2::ggplot(dat, ggplot2::aes(drv2, hwy)) + ggplot2::geom_boxplot()
  inferred <- oes::optimal_graph(p, detail = TRUE, verbose = FALSE)
  explicit <- oes_internal_for_test(dat, DV = hwy, between = drv2, detail = TRUE, verbose = FALSE)
  expect_equal(inferred$oes$dp, explicit$dp)
  expect_equal(inferred$oes$res$mean, explicit$res$mean)
  expect_buildable(inferred$plot)

  p <- ggplot2::ggplot(dat, ggplot2::aes(drv2, hwy, colour = class_small)) +
    ggplot2::geom_boxplot() + ggplot2::facet_wrap(~ year_f)
  inferred <- oes::optimal_graph(p, detail = TRUE, verbose = FALSE)
  expect_true(all(c("drv2", "class_small", "year_f") %in%
                  inferred$oes$args$between))
  expect_equal(nrow(inferred$oes$res), nrow(unique(dat[c("drv2", "class_small", "year_f")])))
  built <- expect_buildable(inferred$plot)
  expect_equal(nrow(built$layout$layout), 2L)
})

test_that("ToothGrowth and PlantGrowth examples preserve explicit data choices", {
  tg <- datasets::ToothGrowth
  tg <- tg[tg$dose %in% c(0.5, 2), ]
  tg$supp <- droplevels(tg$supp)
  p <- ggplot2::ggplot(tg, ggplot2::aes(supp, len)) + ggplot2::geom_boxplot()
  inferred <- oes::optimal_graph(p, detail = TRUE, verbose = FALSE)
  explicit <- oes_internal_for_test(tg, DV = len, between = supp, detail = TRUE, verbose = FALSE)
  expect_equal(inferred$oes$dp, explicit$dp)
  expect_equal(inferred$oes$res$n, c(20L, 20L))

  tg <- datasets::ToothGrowth
  tg$dose2 <- factor(ifelse(tg$dose <= 0.7, "low", "high"))
  p <- ggplot2::ggplot(tg, ggplot2::aes(supp, len, colour = dose2)) +
    ggplot2::geom_boxplot()
  result <- oes::optimal_graph(p, detail = TRUE, verbose = FALSE)
  expect_equal(nrow(result$oes$res), 4L)
  expect_buildable(result$plot)

  pg <- datasets::PlantGrowth
  pg$group2 <- factor(ifelse(pg$group == "ctrl", "ctrl", "trt"))
  p <- ggplot2::ggplot(pg, ggplot2::aes(group2, weight)) + ggplot2::geom_boxplot()
  result <- oes::optimal_graph(p, measurement_range = c(1, 7),
                               detail = TRUE, verbose = FALSE)
  expect_lt(result$oes$dp, 0.2)
  expect_equal(unlist(result$oes$range, use.names = FALSE), c(1, 7))
  expect_true(result$oes$range_info$fallback)
})
