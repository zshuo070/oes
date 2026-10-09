test_that("invalid inputs give specific errors", {
  independent <- make_independent()
  paired <- make_paired()
  for (method in c("ci95_corr", "ci95_dif_corr")) {
    expect_error(oes_internal_for_test(paired, DV = score, within = condition, error_bar = method),
                 "valid participant")
    expect_error(oes_internal_for_test(independent, DV = score, between = group, error_bar = method),
                 "within-subject factor")
  }
  expect_error(oes_internal_for_test(independent, DV = score, between = group, error_bar = "difci95"),
               "arg")
  expect_error(oes_internal_for_test(independent, DV = score, between = group,
                       measurement_range = c(7, 1)), "must be <")
  expect_error(oes_internal_for_test(independent, DV = score, between = group,
                       measurement_range = c(0, Inf)), "finite")
  expect_error(oes_internal_for_test(independent, DV = score, between = group,
                       measurement_range = 1), "numeric length 2")
  expect_error(oes_internal_for_test(independent, DV = "absent", between = group), "not present")
  expect_error(oes_internal_for_test(independent, DV = score), "at least one factor")
})

test_that("missing IDs and small effects use the supplied fallback range", {
  paired <- make_paired()
  caught <- capture_test_warnings(oes_internal_for_test(
    paired, DV = score, within = condition,
    measurement_range = c(0, 10), detail = TRUE
  ))
  expect_length(caught$warnings, 2L)
  expect_match(caught$warnings[1L], "no valid participant")
  expect_match(caught$warnings[2L], "X could not be estimated")
  result <- caught$value
  expect_true(is.na(result$dp))
  expect_equal(unlist(result$range, use.names = FALSE), c(0, 10))
  expect_true(result$range_info$fallback)

  independent <- make_independent()
  independent$score <- rep(1:5, 2L)
  zero <- oes_internal_for_test(independent, DV = score, between = group,
                   measurement_range = c(0, 10), detail = TRUE, verbose = FALSE)
  expect_equal(zero$dp, 0)
  expect_equal(unlist(zero$range, use.names = FALSE), c(0, 10))
  expect_true(zero$range_info$fallback)
})

test_that("CM requires complete repeated profiles and multiple participants", {
  paired <- make_paired()
  incomplete <- paired[!(paired$id == 5 & paired$condition == "B"), ]
  expect_error(oes_internal_for_test(incomplete, DV = score, within = condition, id = id,
                       error_bar = "ci95_corr", verbose = FALSE),
               "complete|missing|incomplete")
  ordinary <- oes_internal_for_test(incomplete, DV = score, within = condition, id = id,
                       error_bar = "ci95", detail = TRUE, verbose = FALSE)
  expect_finite_result(ordinary)
  single <- paired[paired$id == 1, ]
  # Duplicate rows preserve the raw-data classification while retaining one ID.
  single <- rbind(single, single)
  expect_error(oes_internal_for_test(single, DV = score, within = condition, id = id,
                       error_bar = "ci95_corr", verbose = FALSE), "two participants")
})

test_that("summary data supply intervals without fabricating participant effects", {
  full <- data.frame(group = factor(c("A", "B")), score = c(3, 5),
                     n = c(5, 5), sd = rep(stats::sd(1:5), 2L))
  result <- oes_internal_for_test(full, DV = score, between = group,
                     measurement_range = c(0, 10), detail = TRUE, verbose = FALSE)
  expect_identical(result$args$summary_type, "summary_full")
  expect_true(is.na(result$dp))
  expect_equal(unlist(result$range, use.names = FALSE), c(0, 10))
  expect_true(all(is.finite(result$res$eb_half)))
  expect_equal(result$res$eb_half,
               rep(stats::qt(0.975, 8) * stats::sd(1:5) / sqrt(5), 2L))

  from_se <- full
  from_se$se <- from_se$sd / sqrt(from_se$n)
  from_se$sd <- NULL
  se_result <- oes_internal_for_test(from_se, DV = score, between = group,
                        measurement_range = c(0, 10), detail = TRUE, verbose = FALSE)
  expect_equal(se_result$res$eb_half, result$res$eb_half)
  expect_true(is.na(se_result$dp))

  means <- full[c("group", "score")]
  caught <- capture_test_warnings(oes_internal_for_test(
    means, DV = score, between = group,
    measurement_range = c(0, 10), detail = TRUE
  ))
  expect_length(caught$warnings, 2L)
  expect_match(caught$warnings[1L], "means-only summary")
  expect_match(caught$warnings[2L], "X could not be estimated")
  means_result <- caught$value
  expect_true(is.na(means_result$dp))
  expect_equal(unlist(means_result$range, use.names = FALSE), c(0, 10))
  expect_true(all(is.na(means_result$res$eb_half)))
  expect_error(oes_internal_for_test(full, DV = score, within = group, id = "group",
                       error_bar = "ci95_corr", verbose = FALSE),
               "raw participant-level data")
})

test_that("alternative base ranges and calibrated ER give expected limits", {
  dat <- make_independent()
  reference <- oes_internal_for_test(dat, DV = score, between = group, detail = TRUE, verbose = FALSE)
  expect_equal(reference$ER, reference$pooled_sd / (reference$dp + 5.723))
  expect_equal(reference$range$lower, min(reference$res$eb_lower) - reference$ER)
  expect_equal(reference$range$upper, max(reference$res$eb_upper) + reference$ER)
  for (type in c("data", "quantile")) {
    result <- oes_internal_for_test(dat, DV = score, between = group, range_type = type,
                       measurement_range = c(0, 10), detail = TRUE, verbose = FALSE)
    base <- if (type == "data") c(0, 10) else
      stats::quantile(dat$score, c(0.02, 0.98), names = FALSE)
    expect_equal(unlist(result$range, use.names = FALSE), base + c(-result$ER, result$ER))
  }
})

test_that("prescribed contrasts exercise fallback and all three ER constants", {
  # Identical SD profiles are shifted to independently prescribed d values.
  # The explicit case table avoids floating-point threshold-boundary tests.
  targets <- c(0.1, 0.3, 0.6, 0.9)
  constants <- c(NA_real_, 0.254, 1.575, 5.723)
  known_sd <- stats::sd(1:5)
  for (i in seq_along(targets)) {
    shifted <- make_independent()
    shifted$score <- c(1:5, 1:5 + targets[i] * known_sd)
    result <- oes_internal_for_test(shifted, DV = score, between = group,
                       measurement_range = c(0, 10),
                       detail = TRUE, verbose = FALSE)
    expect_equal(result$dp, targets[i], tolerance = 1e-8)
    expect_equal(result$pooled_sd, known_sd, tolerance = 1e-8)
    if (i == 1L) {
      expect_true(result$range_info$fallback)
      expect_match(result$range_info$fallback_reason, "below 0.20")
      expect_true(is.na(result$ER))
      expect_equal(unlist(result$range, use.names = FALSE), c(0, 10))
    } else {
      expect_false(result$range_info$fallback)
      expect_equal(result$ER, known_sd / (result$dp + constants[i]),
                   tolerance = 1e-8)
    }
  }
})
