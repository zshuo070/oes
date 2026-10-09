test_that("independent d and g agree with manual standardized contrasts", {
  dat <- make_independent()
  d <- oes_internal_for_test(dat, DV = score, between = group, detail = TRUE, verbose = FALSE)
  expected_d <- 2 / stats::sd(1:5)
  expect_equal(d$dp, expected_d, tolerance = 1e-8)
  expect_identical(d$effect_info$effect_type, "d")
  expect_finite_result(d)

  g <- oes_internal_for_test(dat, DV = score, between = group, effect = "g",
                detail = TRUE, verbose = FALSE)
  # rstatix uses the small-sample factor (N - 3) / (N - 2.25).
  expected_g <- expected_d * (10 - 3) / (10 - 2.25)
  expect_equal(g$dp, expected_g, tolerance = 1e-8)
  expect_identical(g$effect_info$effect_type, "g")
  expect_lt(g$dp, d$dp)
  expect_finite_result(g)
})

test_that("unequal groups retain the unweighted two-variance denominator", {
  dat <- data.frame(
    group = factor(c(rep("A", 4L), rep("B", 6L))),
    score = c(1:4, seq(2, 12, 2))
  )
  result <- oes_internal_for_test(dat, DV = score, between = group, detail = TRUE, verbose = FALSE)
  expected <- abs(mean(1:4) - mean(seq(2, 12, 2))) /
    sqrt((stats::var(1:4) + stats::var(seq(2, 12, 2))) / 2)
  expect_equal(result$dp, expected, tolerance = 1e-8)
})

test_that("paired contrasts match participants by ID rather than row order", {
  dat <- make_paired()
  a <- c(2, 3, 4, 5, 6)
  b <- c(3, 5, 5, 8, 9)
  expected_dz <- abs(mean(a - b)) / stats::sd(a - b)
  bare <- oes_internal_for_test(dat, DV = score, within = condition, id = id,
                   error_bar = "ci95_corr", detail = TRUE, verbose = FALSE)
  quoted <- oes_internal_for_test(dat, DV = "score", within = "condition", id = "id",
                     error_bar = "ci95_corr", detail = TRUE, verbose = FALSE)
  expect_equal(bare$dp, expected_dz, tolerance = 1e-8)
  expect_identical(bare$effect_info$effect_type, "dz")
  expect_equal(bare$range, quoted$range)
  expect_equal(bare$dp, quoted$dp)
  expect_finite_result(bare)
  g <- oes_internal_for_test(dat, DV = score, within = condition, id = id,
                effect = "g", detail = TRUE, verbose = FALSE)
  expect_equal(g$dp, expected_dz, tolerance = 1e-8)
  expect_identical(g$effect_info$effect_type, "dz")
})

test_that("NULL forwarding and unusual variable names retain numerical results", {
  dat <- make_independent()
  baseline <- oes_internal_for_test(dat, DV = score, between = group, detail = TRUE, verbose = FALSE)
  wrapper <- function(data, DV, within = NULL, between = NULL, ...) {
    oes_internal_for_test(data = data, DV = DV, within = within, between = between, ...)
  }
  forwarded <- wrapper(dat, DV = "score", between = "group",
                       detail = TRUE, verbose = FALSE)
  expect_equal(forwarded$dp, baseline$dp)
  expect_equal(forwarded$range, baseline$range)
  for (dv in c("mean", "n", "score value")) {
    renamed <- dat
    names(renamed) <- c("group type", dv)
    result <- oes_internal_for_test(renamed, DV = dv, between = "group type",
                       detail = TRUE, verbose = FALSE)
    expect_equal(result$dp, baseline$dp, info = dv)
    expect_equal(result$res$sd, baseline$res$sd, info = dv)
    expect_equal(result$range, baseline$range, info = dv)
  }
})
