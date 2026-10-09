test_that("multilevel effects select the largest conditional contrast", {
  # Each entry is one independent design cell. The high-context C cell has
  # twice the SD. Its A-C mean gap is largest, but the low-context A-C
  # standardized contrast is larger, distinguishing effect-size selection
  # from mean-gap selection.
  profile <- c(-2, -1, 0, 1, 2)
  cells <- list(
    low_A = profile,
    low_B = profile + 1,
    low_C = profile + 6,
    high_A = profile + 0.5,
    high_B = profile + 1.5,
    high_C = 2 * profile + 8
  )
  dat <- data.frame(
    condition = factor(rep(rep(c("A", "B", "C"), each = 5L), 2L),
                       levels = c("A", "B", "C")),
    context = factor(rep(c("low", "high"), each = 15L),
                     levels = c("low", "high")),
    score = unlist(cells, use.names = FALSE)
  )
  # The denominator is the package's documented unweighted two-cell SD.
  manual_d <- function(x, y) {
    abs(mean(x) - mean(y)) / sqrt((stats::var(x) + stats::var(y)) / 2)
  }
  expected <- data.frame(
    focal_factor = c(rep("condition", 6L), rep("context", 3L)),
    level1 = c("A", "A", "B", "A", "A", "B", rep("low", 3L)),
    level2 = c("B", "C", "C", "B", "C", "C", rep("high", 3L)),
    conditioning = c(rep("context = low", 3L), rep("context = high", 3L),
                     paste0("condition = ", c("A", "B", "C"))),
    abs_effect = c(
      manual_d(cells$low_A, cells$low_B),
      manual_d(cells$low_A, cells$low_C),
      manual_d(cells$low_B, cells$low_C),
      manual_d(cells$high_A, cells$high_B),
      manual_d(cells$high_A, cells$high_C),
      manual_d(cells$high_B, cells$high_C),
      manual_d(cells$low_A, cells$high_A),
      manual_d(cells$low_B, cells$high_B),
      manual_d(cells$low_C, cells$high_C)
    )
  )
  result <- oes_internal_for_test(
    dat, DV = score, between = c("condition", "context"),
    detail = TRUE, verbose = FALSE
  )
  actual <- as.data.frame(result$effect_table[names(expected)])
  rownames(actual) <- NULL
  expect_equal(actual, expected, tolerance = 1e-8)
  # The independently specified winning contrast is C versus A in low
  # context: 6 / sqrt(2.5), exceeding high context's 7.5 / 2.5 = 3.
  expected_max <- 6 / stats::sd(profile)
  expect_equal(result$dp, expected_max, tolerance = 1e-8)
  expect_equal(result$effect_info$max_effect, expected_max, tolerance = 1e-8)
  expect_identical(result$effect_info$focal_factor, "condition")
  expect_identical(result$effect_info$level1, "A")
  expect_identical(result$effect_info$level2, "C")
  expect_identical(result$effect_info$conditioning, "context = low")
  expect_identical(result$effect_info$effect_type, "d")
})

test_that("three-condition CM widths agree with matrix normalization", {
  # Rows are participants; columns are repeated conditions. The three
  # columns have unequal transformed variances, exercising both pooling
  # choices. The oracle uses the Appendix A transformation in Cousineau
  # (2017), followed by the separate optional sqrt(2) difference adjustment.
  scores <- cbind(
    A = c(1, 3, 5, 7),
    B = c(2, 5, 5, 9),
    C = c(5, 7, 10, 10)
  )
  n <- nrow(scores)
  J <- ncol(scores)
  normalized <- sweep(scores, 1L, rowMeans(scores), "-") + mean(scores)
  condition_means <- colMeans(normalized)
  corrected <- sweep(normalized, 2L, condition_means, "-") * sqrt(J / (J - 1))
  corrected <- sweep(corrected, 2L, condition_means, "+")
  corrected_sd <- apply(corrected, 2L, stats::sd)
  # Each condition has n independent participants, so equal df weights
  # reduce the pooled transformed variance to this arithmetic mean.
  pooled_corrected_sd <- sqrt(mean(corrected_sd^2))
  critical <- stats::qt(0.975, n - 1)
  dat <- data.frame(
    id = rep(seq_len(n), J),
    condition = factor(rep(colnames(scores), each = n), levels = colnames(scores)),
    score = as.vector(scores)
  )
  dat <- dat[c(12, 3, 8, 1, 10, 5, 7, 4, 2, 11, 6, 9), ]
  for (pooled in c(TRUE, FALSE)) {
    expected_sd <- if (pooled) rep(pooled_corrected_sd, J) else unname(corrected_sd)
    expected_se <- expected_sd / sqrt(n)
    for (method in c("ci95_corr", "ci95_dif_corr")) {
      multiplier <- if (method == "ci95_dif_corr") sqrt(2) else 1
      expected_half <- critical * expected_se * multiplier
      result <- oes_internal_for_test(
        dat, DV = score, within = condition, id = id,
        error_bar = method, pooled = pooled, detail = TRUE, verbose = FALSE
      )
      actual <- result$res[match(colnames(scores), as.character(result$res$condition)), ]
      expect_equal(actual$n, rep(n, J))
      expect_equal(actual$J, rep(J, J))
      expect_equal(actual$df, rep(n - 1, J))
      expect_equal(actual$mean, unname(colMeans(scores)), tolerance = 1e-8)
      expect_equal(actual$sd_z, unname(corrected_sd), tolerance = 1e-8)
      expect_equal(actual$se_cm, expected_se, tolerance = 1e-8)
      expect_equal(actual$eb_half, expected_half, tolerance = 1e-8)
      expect_equal(actual$eb_lower, unname(colMeans(scores)) - expected_half,
                   tolerance = 1e-8)
      expect_equal(actual$eb_upper, unname(colMeans(scores)) + expected_half,
                   tolerance = 1e-8)
      expect_equal(result$pooled_sd, pooled_corrected_sd, tolerance = 1e-8)
    }
  }
})
