test_that("optimal_graph is the sole export and the numerical engine is internal", {
  exports <- getNamespaceExports("oes")
  expect_identical(exports, "optimal_graph")
  expect_type(oes::optimal_graph, "closure")
  expect_true(exists("oes", envir = asNamespace("oes"), inherits = FALSE))
  expect_type(oes_internal_for_test, "closure")
  expect_error(getExportedValue("oes", "oes"), "not an exported object")
})

test_that("public detailed independent and paired graphs retain manual effects", {
  independent <- make_independent()
  result <- oes::optimal_graph(data = independent, DV = score, between = group,
                               detail = TRUE, verbose = FALSE)
  expect_finite_result(result$oes)
  expect_equal(result$oes$dp, 2 / stats::sd(1:5), tolerance = 1e-8)
  expect_identical(result$oes$effect_info$effect_type, "d")
  expect_buildable(result$plot)

  paired <- make_paired()
  difference <- c(2, 3, 4, 5, 6) - c(3, 5, 5, 8, 9)
  result <- oes::optimal_graph(data = paired, DV = score, within = condition,
                               id = id, error_bar = "ci95_corr",
                               detail = TRUE, verbose = FALSE)
  expect_finite_result(result$oes)
  expect_equal(result$oes$dp, abs(mean(difference)) / stats::sd(difference),
               tolerance = 1e-8)
  expect_identical(result$oes$effect_info$effect_type, "dz")
  expect_equal(result$oes$res$df, rep(4, 2L))
  expect_buildable(result$plot)
})

test_that("public detailed mixed graphs retain the internal numerical result", {
  mixed <- make_mixed()
  result <- oes::optimal_graph(data = mixed, DV = score, within = condition,
                               between = group, id = id, error_bar = "ci95_corr",
                               detail = TRUE, verbose = FALSE)
  reference <- oes_internal_for_test(mixed, DV = score, within = condition,
                                     between = group, id = id,
                                     error_bar = "ci95_corr",
                                     detail = TRUE, verbose = FALSE)
  expect_finite_result(result$oes)
  expect_equal(result$oes$dp, reference$dp)
  expect_equal(result$oes$range, reference$range)
  expect_equal(result$oes$res$eb_half, reference$res$eb_half)
  expect_equal(result$oes$pooled_sd, reference$pooled_sd)
  expect_equal(result$oes$ER, reference$ER)
  expect_true(all(c("d", "dz") %in% result$oes$effect_table$effect_type))
  expect_equal(result$oes$res$df, rep(5, 6L))
  expect_buildable(result$plot)
})
