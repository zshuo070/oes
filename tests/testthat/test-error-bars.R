test_that("ordinary error bars agree with manually calculated widths", {
  dat <- make_independent()
  sd <- stats::sd(1:5)
  for (pooled in c(TRUE, FALSE)) {
    expected_df <- if (pooled) 8 else 4
    expected <- c(sd = sd, se = sd / sqrt(5),
                  ci95 = stats::qt(0.975, expected_df) * sd / sqrt(5))
    expected <- c(expected, ci95_dif = unname(expected["ci95"]) * sqrt(2))
    for (method in names(expected)) {
      result <- oes_internal_for_test(dat, DV = score, between = group,
                         pooled = pooled, error_bar = method,
                         detail = TRUE, verbose = FALSE)
      expect_equal(result$res$eb_half, rep(unname(expected[method]), 2L),
                   tolerance = 1e-8, info = paste(method, pooled))
      expect_equal(result$res$eb_lower, result$res$mean - result$res$eb_half)
      expect_equal(result$res$eb_upper, result$res$mean + result$res$eb_half)
    }
  }
})

test_that("Cousineau-Morey intervals use participant df under either pooling choice", {
  dat <- make_paired()
  differences <- c(2, 3, 4, 5, 6) - c(3, 5, 5, 8, 9)
  corrected_sd <- stats::sd(differences) / sqrt(2)
  expected_se <- corrected_sd / sqrt(5)
  expected_half <- stats::qt(0.975, 4) * expected_se
  for (pooled in c(TRUE, FALSE)) {
    result <- oes_internal_for_test(dat, DV = score, within = condition, id = id,
                       error_bar = "ci95_corr", pooled = pooled,
                       detail = TRUE, verbose = FALSE)
    expect_equal(result$res$n, rep(5, 2L))
    expect_equal(result$res$df, rep(4, 2L))
    expect_equal(result$res$se_cm, rep(expected_se, 2L), tolerance = 1e-8)
    expect_equal(result$res$eb_half, rep(expected_half, 2L), tolerance = 1e-8)
    expect_true(all(result$res$eb_half > stats::qt(0.975, 8) * result$res$se_cm))
  }
})

test_that("all six methods retain the single ER variability scale when pooling changes", {
  dat <- make_mixed()
  methods <- c("ci95", "ci95_dif", "ci95_corr", "ci95_dif_corr", "se", "sd")
  results <- list()
  for (method in methods) {
    pooled <- oes_internal_for_test(dat, DV = score, within = condition, between = group,
                       id = id, error_bar = method, pooled = TRUE,
                       detail = TRUE, verbose = FALSE)
    unpooled <- oes_internal_for_test(dat, DV = score, within = condition, between = group,
                         id = id, error_bar = method, pooled = FALSE,
                         detail = TRUE, verbose = FALSE)
    expect_finite_result(pooled)
    expect_finite_result(unpooled)
    expect_equal(pooled$dp, unpooled$dp, info = method)
    expect_equal(pooled$pooled_sd, unpooled$pooled_sd, info = method)
    expect_equal(pooled$ER, unpooled$ER, info = method)
    if (method %in% c("ci95_corr", "ci95_dif_corr")) {
      expect_equal(pooled$res$df, rep(5, 6L), info = method)
      expect_equal(unpooled$res$df, rep(5, 6L), info = method)
    }
    results[[method]] <- pooled
  }
  expect_equal(results$ci95_dif$res$eb_half, results$ci95$res$eb_half * sqrt(2))
  expect_equal(results$ci95_dif_corr$res$eb_half,
               results$ci95_corr$res$eb_half * sqrt(2))
  expect_equal(results$ci95_dif_corr$ER, results$ci95_corr$ER)
  expect_true(all(c("d", "dz") %in% results$ci95$effect_table$effect_type))
  # With distinct cell variances, unpooling has a real effect on the bars.
  ordinary_unpooled <- oes_internal_for_test(dat, DV = score, within = condition, between = group,
                                id = id, error_bar = "ci95", pooled = FALSE,
                                detail = TRUE, verbose = FALSE)
  expect_false(isTRUE(all.equal(results$ci95$res$eb_half,
                               ordinary_unpooled$res$eb_half)))
})

test_that("duplicate participant-cell rows are averaged for CM intervals", {
  dat <- make_paired()
  baseline <- oes_internal_for_test(dat, DV = score, within = condition, id = id,
                       error_bar = "ci95_corr", detail = TRUE, verbose = FALSE)
  duplicated <- rbind(dat, dat)
  result <- oes_internal_for_test(duplicated, DV = score, within = condition, id = id,
                     error_bar = "ci95_corr", detail = TRUE, verbose = FALSE)
  expect_equal(result$dp, baseline$dp)
  expect_equal(result$res$n, baseline$res$n)
  expect_equal(result$res$df, baseline$res$df)
  expect_equal(result$res$eb_half, baseline$res$eb_half)
})
