###############################################################################
# oes 1.0.0: based on development version V1.8
###############################################################################
#
# PACKAGE RECHECK CORRECTIONS
#   Plot-only fallbacks honor supplied measurement ranges. Explicit original
#   limit overrides clear censoring y-scale limits without changing the input
#   graph. The exploratory Hedges' g warning states the studied setting.
#
# UPDATES FROM v1.7 TO v1.8
#
# 1. Fixed fill-only summary plots: fill now supplies visible line, point,
#    and error-bar colours when the source plot has no colour mapping.
#
# 2. Fixed summary grouping: an explicit group mapping has priority;
#    otherwise colour, fill, shape, and linetype jointly define separate
#    series. X and facet variables are excluded from inferred series groups.
#    Multiple series are dodged consistently across summary layers.
#
# 3. Summary plots now preserve mapped linetypes. Original-layout plots
#    retain their supplied layers and aesthetics.
#
# 4. Added regression checks for fill-only raincloud summaries, shape-only
#    and combined-aesthetic grouping, and explicit group precedence.
#    All v1.7 effect-size, error-bar, and y-axis calculations are retained.
#
# HISTORICAL UPDATES FROM v1.6 TO v1.7
#
# 1. Fixed `effect = 'g'` for between-subject contrasts. Hedges' correction
#    now uses rstatix::cohens_d(hedges.correction = TRUE), rather than the
#    nonexistent rstatix::hedges_g(). `var.equal = FALSE` explicitly retains
#    the v1.6 standardization; within-subject contrasts still use paired dz.
#
# 2. Corrected Cousineau-Morey CI degrees of freedom to n - 1 per condition
#    for BOTH pooled settings. Pooling transformed SDs does not create more
#    independent participants. This applies to ci95_corr and ci95_dif_corr.
#
# 3. Added clear errors for incomplete repeated-measures profiles and strata
#    with fewer than two participants when correlation-adjusted CIs are
#    requested. Duplicate observations are still averaged first. Ordinary
#    error-bar methods retain their existing handling of missing responses.
#
# 4. Fixed forwarded NULL column/factor arguments, including oes_chr()
#    defaults. NULL remains NULL (or no factors), rather than being mistaken
#    for the name of the forwarding variable.
#
# 5. Fixed raw responses named `mean` or `n`: cell summaries now read from
#    a fresh temporary response column, avoiding dplyr summary-name shadowing.
#
# 6. Between-subject effect calculations now use a temporary two-column data
#    frame, so quoted response/factor names containing spaces also work.
#
# 7. Updated test-oes.R with self-contained examples and numeric assertions.
#    Removed Study4_long.csv/readr/superb dependencies, replaced difci95 with
#    ci95_dif, and added regression checks for the corrections above.
#
# 8. Graph requests now report a clear dependency error if ggplot2 < 4.0.0
#    is installed, rather than failing later during directional expansion.
#
# RETAINED FROM v1.6
#   - Six error-bar methods: ci95, ci95_dif, ci95_corr, ci95_dif_corr, se, sd.
#   - The approved sqrt(2) multiplier for both difference-adjusted CI methods.
#   - OES expansion always uses one pooled SD in ER = pooled_sd / (X + a),
#     regardless of the `pooled` error-bar setting.
#   - Conditional maximum-effect search, paired dz, bare/quoted column names,
#     graph/text outputs, existing-limit policy, and exact vertical limits.
#
# RUNTIME REQUIREMENT
#   Graph output uses the directional `coord_cartesian(expand = ...)` API
#   introduced in ggplot2 4.0.0; use ggplot2 >= 4.0.0. The internal numerical
#   engine does not depend on this newer coordinate feature.
#
###############################################################################
#
# MAIN FUNCTION
#   optimal_graph(...)
#
# PURPOSE
#   Estimate an effect-size-informed y-axis range and either:
#   1. return a graph using that range (`output = 'graph'`, default), or
#   2. return a detailed text recommendation
#      (`output = 'y_axis_limit'`).
#
# BASIC USE
#
#   optimal_graph(
#     data = my_data,
#     DV = score,
#     between = group
#   )
#
#   optimal_graph(
#     data = my_data,
#     DV = score,
#     between = group,
#     output = 'y_axis_limit'
#   )
#
#   optimal_graph(
#     plot = my_plot,
#     data = my_data,
#     DV = score,
#     within = condition,
#     id = participant,
#     error_bar = 'ci95_corr',
#     layout = 'original'
#   )
#
# ARGUMENTS FOR optimal_graph()
#
#   plot
#     Optional ggplot object. When `data` and `DV` are also supplied, the
#     supplied data drive OES calculations while the plot supplies layout.
#
#   data
#     Raw or summary data frame.
#
#   DV
#     Dependent-variable column, supplied as a bare name or character string.
#
#   layout
#     'summary'  = rebuild a mean/error-bar graph.
#     'original' = retain supplied plot layers and apply the OES y-axis range.
#
#   pooled
#     Controls ERROR-BAR variability only:
#       TRUE  = pooled variability for error-bar construction.
#       FALSE = condition-specific variability for error-bar construction.
#     Regardless of this setting, OES expansion ER always uses one pooled
#     variability estimate.
#
#   error_bar
#     'ci95'          = 95% CIs of the means: t * SE.
#     'ci95_dif'      = difference-adjusted 95% CIs of the means:
#                       t * SE * sqrt(2).
#     'ci95_corr'     = correlation-adjusted 95% CIs of the means
#                       (Cousineau-Morey): t * SE_CM.
#     'ci95_dif_corr' = correlation- and difference-adjusted 95% CIs of the
#                       means (Cousineau-Morey):
#                       t * SE_CM * sqrt(2).
#     'se'            = SE error bars: mean +/- 1 SE.
#     'sd'            = SD error bars: mean +/- 1 SD.
#     The two correlation-adjusted CI options require raw participant-level
#     data, at least one within-subject factor, and participant `id`.
#
#   range_type
#     'dp'       = calibrated OES method.
#     'quantile' = 2nd to 98th percentile base range (exploratory).
#     'data'     = measurement/observed data base range (exploratory).
#
#   id
#     Participant identifier. May be supplied as either:
#       id = participant
#       id = 'participant'
#     Required for paired Cohen's dz and for both correlation-adjusted
#     CI options (`ci95_corr` and `ci95_dif_corr`).
#
#   within
#     Within-subject factor(s), e.g.:
#       within = condition
#       within = c(time, condition)
#       within = c('time', 'condition')
#
#   between
#     Between-subject factor(s), e.g.:
#       between = group
#       between = c(group, treatment)
#
#   effect
#     'd' = calibrated/default Cohen-family option:
#             between factors -> Cohen's d
#             within factors  -> paired Cohen's dz
#     'g' = Hedges' g for between-subject contrasts only.
#           Within-subject contrasts remain paired dz.
#           This option is exploratory and produces a warning.
#
#   measurement_range
#     Optional theoretical DV range, c(min, max).
#     Used as:
#       - base range when `range_type = 'data'`;
#       - fallback range when X < .20 or X cannot be estimated.
#
#   output
#     'graph'        = return graph (default).
#     'y_axis_limit' = return detailed text recommendation.
#
#   override_existing_limits
#     FALSE = preserve explicit y limits already present in a supplied plot.
#     TRUE  = replace them with OES limits.
#
#   verbose
#     TRUE  = show informative OES messages/warnings.
#     FALSE = suppress optional OES messages/warnings.
#
#   detail
#     FALSE = graph only.
#     TRUE  = return list(plot = ..., oes = ...), including metadata and the
#             full conditional effect-size table.
#
# LOWER-LEVEL FUNCTION
#   optimal_graph() is the sole exported function. oes() computes numerical
#   recommendations internally; detail = TRUE exposes its results under $oes.
###############################################################################

#########################
# Dependencies (dev only)
#########################
# In an R package, list these in DESCRIPTION Imports and use pkg::fun.

#########################
# General helpers
#########################

`%||%` <- function(x, y) if (is.null(x)) y else x

.aes_var <- function(x) {
  if (is.null(x) || rlang::quo_is_null(x))
    return(NULL)

  tryCatch(rlang::as_name(x), error = function(e) NULL)
}

# Resolve a column argument without forcing a bare symbol.
# Supports:
#   DV = score
#   DV = 'score'
#   DV = dv_name_object   where dv_name_object == 'score'
.resolve_quo_name <- function(quo) {
  if (rlang::quo_is_null(quo))
    return(NULL)

  resolved <- TRUE
  value <- tryCatch(rlang::eval_tidy(quo), error = function(e) {
    resolved <<- FALSE
    NULL
  })

  if (resolved && is.null(value))
    return(NULL)

  if (is.character(value) && length(value) > 0L) {
    return(value[1L])
  }

  expr <- rlang::get_expr(quo)

  if (rlang::is_symbol(expr)) {
    return(rlang::as_name(expr))
  }

  if (is.character(expr) && length(expr) > 0L) {
    return(expr[1L])
  }

  rlang::as_label(quo)
}

# Parse a factor specification from a captured quosure:
#   NULL
#   within = Condition
#   within = 'Condition'
#   within = c(Time, Condition)
#   within = c('Time', 'Condition')
#   within = character_vector
.parse_factor_quo <- function(quo) {
  if (rlang::quo_is_null(quo))
    return(character(0L))

  resolved <- TRUE
  value <- tryCatch(rlang::eval_tidy(quo), error = function(e) {
    resolved <<- FALSE
    NULL
  })

  if (resolved && is.null(value))
    return(character(0L))

  if (is.character(value)) {
    return(value)
  }

  expr <- rlang::get_expr(quo)

  if (rlang::is_call(expr, "c")) {
    args <- as.list(expr)[-1L]
    env <- rlang::get_env(quo)

    return(vapply(args, function(a) {
      q <- rlang::new_quosure(a, env)

      val <- tryCatch(rlang::eval_tidy(q), error = function(e) NULL)

      if (is.character(val) && length(val) > 0L) {
        val[1L]
      } else if (rlang::is_symbol(a)) {
        rlang::as_name(a)
      } else {
        rlang::as_label(q)
      }
    }, character(1L)))
  }

  if (rlang::is_symbol(expr)) {
    return(rlang::as_name(expr))
  }

  rlang::as_label(quo)
}

.safe_levels <- function(x) {
  unique(x[!is.na(x)])
}

.stratum_label <- function(row, vars) {
  if (length(vars) == 0L)
    return("")

  paste(paste0(vars, " = ", vapply(vars, function(v) as.character(row[[v]][1L]), character(1L))),
    collapse = ", ")
}

.subset_to_stratum <- function(data, row, vars) {
  out <- data
  if (length(vars) == 0L)
    return(out)

  for (v in vars) {
    val <- row[[v]][1L]

    if (is.na(val)) {
      out <- out[is.na(out[[v]]), , drop = FALSE]
    } else {
      out <- out[out[[v]] == val, , drop = FALSE]
    }
  }

  out
}

.pooled_sd_from_cells <- function(sd, n) {
  ok <- is.finite(sd) & is.finite(n) & n > 1

  if (!any(ok))
    return(NA_real_)

  dfs <- n[ok] - 1
  denom <- sum(dfs)
  num <- sum(dfs * sd[ok]^2)

  if (!is.finite(denom) || denom <= 0 || !is.finite(num)) {
    return(NA_real_)
  }

  sqrt(num/denom)
}

#########################
# Effect-size helpers
#########################

# Paired Cohen's dz for one pair of levels of a within-subject focal factor,
# conditional on the current levels of all other design factors.
.paired_dz_two_levels <- function(data, dv_name, focal, id_name, level1, level2) {
  if (is.null(id_name) || !id_name %in% names(data)) {
    return(NA_real_)
  }

  dat <- data[data[[focal]] %in% c(level1, level2), unique(c(id_name, focal, dv_name)),
    drop = FALSE]

  dat <- dat[stats::complete.cases(dat), , drop = FALSE]

  if (nrow(dat) == 0L)
    return(NA_real_)

  # If duplicate observations remain within ID x focal-level, average them.
  dat <- dat |>
    dplyr::group_by(dplyr::across(dplyr::all_of(c(id_name, focal)))) |>
    dplyr::summarise(.dv = mean(.data[[dv_name]], na.rm = TRUE), .groups = "drop")

  wide <- tryCatch(stats::reshape(as.data.frame(dat), idvar = id_name, timevar = focal,
    direction = "wide"), error = function(e) NULL)

  if (is.null(wide))
    return(NA_real_)

  candidates1 <- unique(c(paste0(".dv.", as.character(level1)), paste0(".dv.", make.names(as.character(level1)))))

  candidates2 <- unique(c(paste0(".dv.", as.character(level2)), paste0(".dv.", make.names(as.character(level2)))))

  match1 <- candidates1[candidates1 %in% names(wide)]
  match2 <- candidates2[candidates2 %in% names(wide)]

  if (length(match1) == 0L || length(match2) == 0L) {
    return(NA_real_)
  }

  col1 <- match1[1L]
  col2 <- match2[1L]

  diff <- wide[[col2]] - wide[[col1]]
  diff <- diff[is.finite(diff)]

  if (length(diff) < 2L)
    return(NA_real_)

  sd_diff <- stats::sd(diff)

  if (!is.finite(sd_diff) || sd_diff == 0) {
    return(NA_real_)
  }

  mean(diff)/sd_diff
}

# Cohen's d or Hedges' g for one pair of levels of a between-subject factor.
.between_effect_two_levels <- function(data, dv_name, focal, level1, level2, effect = "d") {
  sub <- data[data[[focal]] %in% c(level1, level2), , drop = FALSE]

  sub <- sub[stats::complete.cases(sub[, c(focal, dv_name), drop = FALSE]), , drop = FALSE]

  if (nrow(sub) < 2L || dplyr::n_distinct(sub[[focal]]) < 2L) {
    return(NA_real_)
  }

  sub[[focal]] <- factor(sub[[focal]], levels = c(level1, level2))

  # Temporary names keep valid non-syntactic user column names out of formulas.
  es_data <- data.frame(.oes_dv = sub[[dv_name]], .oes_group = sub[[focal]])

  ans <- tryCatch(rstatix::cohens_d(data = es_data, formula = .oes_dv ~ .oes_group, var.equal = FALSE,
    hedges.correction = identical(effect, "g")), error = function(e) NULL)

  if (is.null(ans) || nrow(ans) == 0L) {
    return(NA_real_)
  }

  ans$effsize[1L]
}

# Enumerate all pairwise effects for every focal factor, conditional on every
# combination of all other factors. The maximum absolute effect becomes X.
.compute_effect_table <- function(data, dv_name, within_names, between_names, id_name = NULL,
  effect = "d") {
  all_factors <- unique(c(within_names, between_names))

  if (length(all_factors) == 0L) {
    return(data.frame())
  }

  out <- list()
  idx <- 1L

  for (focal in all_factors) {
    is_within <- focal %in% within_names
    others <- setdiff(all_factors, focal)

    strata <- if (length(others) == 0L) {
      data.frame(.dummy = 1L)
    } else {
      dplyr::distinct(data, dplyr::across(dplyr::all_of(others)))
    }

    for (i in seq_len(nrow(strata))) {
      stratum_row <- strata[i, , drop = FALSE]

      sub <- if (length(others) == 0L) {
        data
      } else {
        .subset_to_stratum(data, stratum_row, others)
      }

      lv <- .safe_levels(sub[[focal]])

      if (length(lv) < 2L)
        next

      pairs <- utils::combn(lv, 2L, simplify = FALSE)

      for (pair in pairs) {
        level1 <- pair[[1L]]
        level2 <- pair[[2L]]

        eff <- if (is_within) {
          .paired_dz_two_levels(data = sub, dv_name = dv_name, focal = focal, id_name = id_name,
          level1 = level1, level2 = level2)
        } else {
          .between_effect_two_levels(data = sub, dv_name = dv_name, focal = focal,
          level1 = level1, level2 = level2, effect = effect)
        }

        row <- data.frame(focal_factor = focal, level1 = as.character(level1), level2 = as.character(level2),
          effect_type = if (is_within) {
          "dz"
          } else if (effect == "g") {
          "g"
          } else {
          "d"
          }, effect = eff, abs_effect = if (is.finite(eff)) {
          abs(eff)
          } else {
          NA_real_
          }, conditioning = if (length(others) == 0L) {
          ""
          } else {
          .stratum_label(stratum_row, others)
          }, stringsAsFactors = FALSE)

        if (length(others) > 0L) {
          for (v in others) {
          row[[v]] <- as.character(stratum_row[[v]][1L])
          }
        }

        out[[idx]] <- row
        idx <- idx + 1L
      }
    }
  }

  if (length(out) == 0L) {
    return(data.frame())
  }

  all_cols <- unique(unlist(lapply(out, names)))

  out <- lapply(out, function(x) {
    missing <- setdiff(all_cols, names(x))

    for (m in missing) {
      x[[m]] <- NA_character_
    }

    x[, all_cols, drop = FALSE]
  })

  dplyr::bind_rows(out)
}

.max_effect_info <- function(effect_table) {
  empty <- list(max_effect = NA_real_, signed_effect = NA_real_, effect_type = NA_character_,
    focal_factor = NA_character_, level1 = NA_character_, level2 = NA_character_, conditioning = "")

  if (is.null(effect_table) || nrow(effect_table) == 0L) {
    return(empty)
  }

  finite_rows <- which(is.finite(effect_table$abs_effect))

  if (length(finite_rows) == 0L) {
    return(empty)
  }

  j <- finite_rows[which.max(effect_table$abs_effect[finite_rows])]

  row <- effect_table[j, , drop = FALSE]

  list(max_effect = row$abs_effect[1L], signed_effect = row$effect[1L], effect_type = row$effect_type[1L],
    focal_factor = row$focal_factor[1L], level1 = row$level1[1L], level2 = row$level2[1L],
    conditioning = row$conditioning[1L], row = row)
}

#########################
# Cousineau-Morey CI helper
#########################

# Implements the Cousineau normalization followed by the Morey correction.
# In mixed designs, normalization is performed separately within each
# between-subject stratum.
.cousineau_morey_ci <- function(data, dv_name, id_name, within_names, between_names, pooled = TRUE,
  difference_adjusted = FALSE) {
  method_code <- if (isTRUE(difference_adjusted)) {
    "ci95_dif_corr"
  } else {
    "ci95_corr"
  }

  if (length(within_names) == 0L) {
    stop("`error_bar = \"", method_code, "\"` requires at least one within-subject factor.")
  }

  if (is.null(id_name) || !id_name %in% names(data)) {
    stop("`error_bar = \"", method_code, "\"` requires a valid participant `id`.")
  }

  required <- unique(c(id_name, within_names, between_names, dv_name))

  missing_cols <- setdiff(required, names(data))

  if (length(missing_cols) > 0L) {
    stop("Missing required columns for `", method_code, "`: ", paste(missing_cols, collapse = ", "))
  }

  dat <- data[, required, drop = FALSE]

  dat <- dat[stats::complete.cases(dat), , drop = FALSE]

  if (nrow(dat) == 0L) {
    stop("No complete raw observations are available for `", method_code, "`.")
  }

  full_cell_vars <- unique(c(between_names, within_names))

  # Average duplicate observations within participant x complete condition.
  dat <- dat |>
    dplyr::group_by(dplyr::across(dplyr::all_of(c(id_name, full_cell_vars)))) |>
    dplyr::summarise(.x = mean(.data[[dv_name]], na.rm = TRUE), .groups = "drop")

  between_strata <- if (length(between_names) == 0L) {
    data.frame(.dummy = 1L)
  } else {
    dplyr::distinct(dat, dplyr::across(dplyr::all_of(between_names)))
  }

  transformed_parts <- list()
  part_idx <- 1L

  for (i in seq_len(nrow(between_strata))) {
    stratum_row <- between_strata[i, , drop = FALSE]

    sub <- if (length(between_names) == 0L) {
      dat
    } else {
      .subset_to_stratum(dat, stratum_row, between_names)
    }

    if (nrow(sub) == 0L)
      next

    within_cells <- dplyr::distinct(sub, dplyr::across(dplyr::all_of(within_names)))

    J <- nrow(within_cells)

    if (J < 2L) {
      stop("`error_bar = \"", method_code, "\"` requires at least two repeated-measures conditions ",
        "within each between-subject stratum.")
    }

    # The usual Cousineau-Morey correction assumes the same repeated
    # conditions for every participant in this between-subject stratum.
    profile_sizes <- table(sub[[id_name]])
    profile_sizes <- profile_sizes[profile_sizes > 0L]
    if (length(profile_sizes) < 2L) {
      stop("`error_bar = \"", method_code, "\"` requires at least two participants within each ",
        "between-subject stratum.")
    }
    if (any(profile_sizes != J)) {
      stop("`error_bar = \"", method_code, "\"` requires complete repeated-measures profiles: each participant ",
        "must have a non-missing observation in every within-subject ", "condition of their between-subject stratum. Resolve missing ",
        "conditions explicitly or choose an ordinary error-bar method.")
    }

    morey_factor <- sqrt(J/(J - 1))

    grand_mean <- mean(sub$.x, na.rm = TRUE)

    # Cousineau normalization:
    # Y_sj = X_sj - Xbar_s. + Xbar_..
    sub <- sub |>
      dplyr::group_by(.data[[id_name]]) |>
      dplyr::mutate(.subject_mean = mean(.x, na.rm = TRUE), .Y = .x - .subject_mean +
        grand_mean) |>
      dplyr::ungroup()

    # Morey correction:
    # Z_sj = sqrt(J/(J-1)) * (Y_sj - Ybar_.j) + Ybar_.j
    sub <- sub |>
      dplyr::group_by(dplyr::across(dplyr::all_of(within_names))) |>
      dplyr::mutate(.Y_condition_mean = mean(.Y, na.rm = TRUE), .Z = morey_factor *
        (.Y - .Y_condition_mean) + .Y_condition_mean, .J = J) |>
      dplyr::ungroup()

    transformed_parts[[part_idx]] <- sub
    part_idx <- part_idx + 1L
  }

  zdat <- dplyr::bind_rows(transformed_parts)

  if (nrow(zdat) == 0L) {
    stop("Cousineau-Morey transformation could not be computed.")
  }

  cell_vars <- unique(c(between_names, within_names))

  zsumm <- zdat |>
    dplyr::group_by(dplyr::across(dplyr::all_of(cell_vars))) |>
    dplyr::summarise(n = sum(is.finite(.Z)), mean = mean(.x, na.rm = TRUE), sd_z = stats::sd(.Z,
      na.rm = TRUE), J = dplyr::first(.J), .groups = "drop")

  difference_multiplier <- if (isTRUE(difference_adjusted)) {
    sqrt(2)
  } else {
    1
  }

  if (pooled) {
    # For mixed designs, error-bar pooling remains separate within each
    # between-subject stratum.
    if (length(between_names) == 0L) {
      zsumm <- zsumm |>
        dplyr::mutate(.between_key = "all")

      pool_groups <- ".between_key"
    } else {
      pool_groups <- between_names
    }

    pooled_tbl <- zsumm |>
      dplyr::group_by(dplyr::across(dplyr::all_of(pool_groups))) |>
      dplyr::summarise(pooled_sd_z = .pooled_sd_from_cells(sd_z, n), .groups = "drop")

    zsumm <- dplyr::left_join(zsumm, pooled_tbl, by = pool_groups)

    zsumm <- zsumm |>
      dplyr::mutate(se_cm = pooled_sd_z/sqrt(n), se = se_cm, df = n - 1, eb_half = stats::qt(0.975,
        pmax(df, 1)) * se_cm * difference_multiplier)

    if (".between_key" %in% names(zsumm)) {
      zsumm$.between_key <- NULL
    }
  } else {
    zsumm <- zsumm |>
      dplyr::mutate(se_cm = sd_z/sqrt(n), se = se_cm, df = n - 1, eb_half = stats::qt(0.975,
        pmax(df, 1)) * se_cm * difference_multiplier)
  }

  zsumm |>
    dplyr::mutate(difference_multiplier = difference_multiplier, eb_lower = mean - eb_half,
      eb_upper = mean + eb_half)
}

#########################
# Metadata helpers
#########################

.make_error_bar_info <- function(error_bar, pooled, res = NULL) {
  correlation_adjusted <- error_bar %in% c("ci95_corr", "ci95_dif_corr")

  difference_adjusted <- error_bar %in% c("ci95_dif", "ci95_dif_corr")

  label <- switch(error_bar, ci95 = "95% CIs of the means", ci95_dif = "difference-adjusted 95% CIs of the means",
    ci95_corr = paste0("correlation-adjusted 95% CIs of the means ", "(Cousineau-Morey)"),
    ci95_dif_corr = paste0("correlation- and difference-adjusted 95% CIs of the means ",
      "(Cousineau-Morey)"), se = "SE error bars (mean +/- 1 SE)", sd = "SD error bars (mean +/- 1 SD)")

  variability <- if (correlation_adjusted) {
    if (pooled) {
      "pooled Cousineau-Morey transformed SD"
    } else {
      "condition-specific Cousineau-Morey transformed SDs"
    }
  } else {
    if (pooled) {
      "pooled raw within-cell SD"
    } else {
      "condition-specific raw within-cell SDs"
    }
  }

  J <- integer(0L)

  if (!is.null(res) && "J" %in% names(res)) {
    J <- sort(unique(res$J[is.finite(res$J)]))
  }

  list(code = error_bar, label = label, pooled = pooled, variability = variability, J = J,
    correlation_adjusted = correlation_adjusted, difference_adjusted = difference_adjusted,
    correction = if (correlation_adjusted) {
      "Cousineau-Morey"
    } else {
      NULL
    }, difference_multiplier = if (difference_adjusted) {
      sqrt(2)
    } else {
      1
    }, se_type = switch(error_bar, sd = "not applicable", ci95_corr = "SE_CM", ci95_dif_corr = "SE_CM",
      "SE"))
}

.make_sd_info <- function(pooled_sd, error_bar) {
  correlation_adjusted <- error_bar %in% c("ci95_corr", "ci95_dif_corr")

  label <- if (correlation_adjusted) {
    "pooled Cousineau-Morey transformed SD"
  } else {
    "pooled raw within-cell SD"
  }

  list(type = if (correlation_adjusted) {
    "pooled_cousineau_morey"
  } else {
    "pooled_raw_within_cell"
  }, label = label, value = pooled_sd, role = "OES expansion", rule = paste0("OES expansion always uses one pooled variability estimate, ",
    "regardless of `pooled`."))
}

.make_range_info <- function(range_type, measurement_range, base_L, base_U, fallback = FALSE,
  fallback_reason = NULL, final_lower = NA_real_, final_upper = NA_real_) {
  base_source <- switch(range_type, dp = "outer limits of the selected error bars", quantile = "2nd and 98th percentiles of the DV",
    data = if (!is.null(measurement_range)) {
      "supplied measurement range"
    } else {
      "observed DV minimum and maximum"
    })

  final_source <- if (fallback) {
    if (!is.null(measurement_range)) {
      "supplied measurement range"
    } else {
      "observed DV minimum and maximum"
    }
  } else {
    "base range plus calibrated OES expansion"
  }

  list(method = range_type, calibrated = identical(range_type, "dp"), base_source = base_source,
    base_L = base_L, base_U = base_U, fallback = fallback, fallback_reason = fallback_reason,
    final_source = final_source, final_lower = final_lower, final_upper = final_upper)
}

#########################
# Text output helper
#########################

.format_number <- function(x, digits = 3L) {
  if (length(x) == 0L || !is.finite(x[1L])) {
    return("not estimable")
  }

  formatC(x[1L], format = "f", digits = digits)
}

.format_limit_recommendation <- function(oes_res, digits = 3L) {
  if (is.null(oes_res) || is.null(oes_res$range)) {
    return(paste("A y-axis recommendation could not be computed from the supplied plot or data.",
      "Supply sufficient data, DV, and design information."))
  }

  lower <- oes_res$range$lower[1L]
  upper <- oes_res$range$upper[1L]

  x <- oes_res$dp
  info <- oes_res$effect_info
  eb_info <- oes_res$error_bar_info
  sd_info <- oes_res$sd_info
  range_info <- oes_res$range_info
  ER <- oes_res$ER

  x_text <- .format_number(x, digits)

  effect_type_text <- NULL

  if (!is.null(info) && !is.na(info$effect_type) && nzchar(info$effect_type)) {
    effect_type_text <- switch(info$effect_type, d = "Cohen's d", dz = "paired Cohen's dz",
      g = "Hedges' g", info$effect_type)
  }

  line1 <- if (!is.null(effect_type_text) && is.finite(info$max_effect)) {
    paste0("Maximum effect size X = ", x_text, " (", effect_type_text, ").")
  } else {
    paste0("Maximum effect size X = ", x_text, ".")
  }

  lines <- line1

  if (!is.null(info) && is.finite(info$max_effect) && !is.na(info$focal_factor) && nzchar(info$focal_factor)) {

    contrast <- paste0("Maximum contrast: ", info$focal_factor, ": ", info$level1, " vs ",
      info$level2)

    if (!is.null(info$conditioning) && !is.na(info$conditioning) && nzchar(info$conditioning)) {
      contrast <- paste0(contrast, ", conditional on ", info$conditioning)
    }

    lines <- c(lines, paste0(contrast, "."))
  }

  if (!is.null(eb_info)) {
    lines <- c(lines, "", paste0("Error bars: ", eb_info$label, "."), paste0("Error-bar variability: ",
      eb_info$variability, " (`pooled = ", if (isTRUE(eb_info$pooled)) {
        "TRUE"
      } else {
        "FALSE"
      }, "`)."))

    if (isTRUE(eb_info$correlation_adjusted) && length(eb_info$J) > 0L) {
      J_text <- if (length(eb_info$J) == 1L) {
        as.character(eb_info$J)
      } else {
        paste(eb_info$J, collapse = ", ")
      }

      lines <- c(lines, paste0("Repeated-measures conditions J = ", J_text, if (length(eb_info$J) >
        1L) {
        " across strata."
      } else {
        "."
      }))
    }
  }

  if (!is.null(eb_info) && isTRUE(eb_info$difference_adjusted)) {
    lines <- c(lines, "Difference adjustment: CI half-width multiplied by sqrt(2).")
  }

  if (!is.null(sd_info)) {
    lines <- c(lines, paste0("SD used for OES expansion: ", sd_info$label, " = ", .format_number(sd_info$value,
      digits), "."))

    if (!is.null(eb_info) && !isTRUE(eb_info$pooled)) {
      lines <- c(lines, "OES expansion uses this single pooled SD even though the error bars use condition-specific variability.")
    }
  }

  if (!is.null(range_info)) {
    lines <- c(lines, paste0("Base range (", range_info$base_source, "): L = ", .format_number(range_info$base_L,
      digits), ", U = ", .format_number(range_info$base_U, digits), "."))
  }

  if (!is.null(range_info) && isTRUE(range_info$fallback)) {
    reason <- range_info$fallback_reason %||% "X was below 0.20 or could not be estimated"

    lines <- c(lines, paste0("OES expansion: not applied because ", reason, "."))
  } else {
    lines <- c(lines, paste0("OES expansion: ER = ", .format_number(ER, digits), "."))
  }

  lines <- c(lines, "", paste0("Recommended y-axis limits: lower = ", .format_number(lower,
    digits), ", upper = ", .format_number(upper, digits), "."))

  if (!is.null(range_info)) {
    method_line <- if (range_info$method == "dp") {
      "Range method: calibrated OES (`range_type = \"dp\"`)."
    } else {
      paste0("Range method: `range_type = \"", range_info$method, "\"` (exploratory; OES was calibrated for `range_type = \"dp\"`).")
    }

    lines <- c(lines, method_line)

    if (isTRUE(range_info$fallback)) {
      lines <- c(lines, paste0("Final range source: ", range_info$final_source, "."))
    }
  }

  paste(lines, collapse = "\n")
}

#########################
# Plot helpers
#########################

# Extract original/source data from a ggplot object.
# Do NOT use built/transformed layer data for OES calculations.
.extract_plot_source_data <- function(p) {
  if (!is.null(p$data) && is.data.frame(p$data) && nrow(p$data) > 0L) {
    return(list(data = p$data, source = "plot$data"))
  }

  if (length(p$layers) > 0L) {
    candidates <- lapply(p$layers, function(layer) {
      d <- layer$data

      if (is.data.frame(d) && nrow(d) > 0L) {
        d
      } else {
        NULL
      }
    })

    keep <- which(vapply(candidates, function(x) !is.null(x), logical(1L)))

    if (length(keep) > 0L) {
      sizes <- vapply(candidates[keep], nrow, integer(1L))

      best <- keep[which.max(sizes)]

      return(list(data = candidates[[best]], source = paste0("plot layer ", best, " data")))
    }
  }

  NULL
}

.get_existing_y_limits <- function(p, pg = NULL) {
  if (is.null(pg)) {
    pg <- ggplot2::ggplot_build(p)
  }

  coord_limits <- pg$layout$coord$limits$y

  if (!is.null(coord_limits)) {
    return(coord_limits)
  }

  yscale <- pg$plot$scales$get_scales("y")

  if (!is.null(yscale) && !is.null(yscale$limits)) {
    return(yscale$limits)
  }

  NULL
}

.clear_y_scale_limits <- function(p) {
  yscale <- p$scales$get_scales("y")

  if (!is.null(yscale) && !is.null(yscale$limits)) {
    # Clone before replacement so the caller's scale remains unchanged.
    yscale <- yscale$clone()
    yscale$limits <- NULL
    p <- suppressMessages(p + yscale)
  }

  p
}

.fallback_y_range <- function(values, measurement_range = NULL) {
  if (!is.null(measurement_range)) {
    if (!is.numeric(measurement_range) || length(measurement_range) != 2L) {
      stop("`measurement_range` must be numeric length 2: c(min, max).")
    }
    if (!all(is.finite(measurement_range))) {
      stop("`measurement_range` must contain finite values.")
    }
    if (!(measurement_range[1L] < measurement_range[2L])) {
      stop("`measurement_range[1]` must be < `measurement_range[2]`.")
    }
    return(unname(measurement_range))
  }

  limits <- suppressWarnings(range(values, na.rm = TRUE))
  if (!all(is.finite(limits))) {
    stop("The DV does not contain a finite range.")
  }
  limits
}

.plot_data_is_means_only <- function(data, dv_name, iv_names) {
  if (length(iv_names) == 0L || !dv_name %in% names(data)) {
    return(FALSE)
  }

  has_summary_variability <- any(c("n", "sd", "se") %in% names(data))

  if (has_summary_variability) {
    return(FALSE)
  }

  cells <- data |>
    dplyr::distinct(dplyr::across(dplyr::all_of(iv_names)))

  nrow(data) == nrow(cells)
}

extract_design_from_pg <- function(pg) {
  mapping_global <- pg$plot$mapping

  layer_mapping <- if (length(pg$plot$layers) > 0L) {
    pg$plot$layers[[1L]]$mapping
  } else {
    list()
  }

  full_map <- utils::modifyList(as.list(mapping_global), as.list(layer_mapping))

  DV <- .aes_var(full_map$y)
  xIV <- .aes_var(full_map$x)

  colorIV <- .aes_var(full_map$colour)
  shapeIV <- .aes_var(full_map$shape)
  fillIV <- .aes_var(full_map$fill)
  ltypeIV <- .aes_var(full_map$linetype)
  groupIV <- .aes_var(full_map$group)

  facet_params <- pg$layout$facet$params

  facet_vars <- unique(c(names(facet_params$facets %||% NULL), names(facet_params$rows %||%
    NULL), names(facet_params$cols %||% NULL)))

  IVs <- c(xIV, colorIV, shapeIV, fillIV, ltypeIV, groupIV, facet_vars)

  IVs <- unique(IVs[!is.na(IVs) & nzchar(IVs)])

  IVs <- setdiff(IVs, DV)

  list(DV = DV, IVs = IVs, n_factors = length(IVs), iv_roles = list(x = xIV, colour = colorIV,
    shape = shapeIV, fill = fillIV, linetype = ltypeIV, group = groupIV, facet = facet_vars))
}

#########################
# Core OES engine
#########################

#' Optimal effect-size-based y-axis range
#'
#' Computes the OES recommendation and detailed calculation metadata.
oes <- function(data, DV, within = NULL, between = NULL, pooled = TRUE, error_bar = c("ci95",
  "ci95_dif", "ci95_corr", "ci95_dif_corr", "se", "sd"), range_type = c("dp", "quantile",
  "data"), id = NULL, effect = c("d", "g"), measurement_range = NULL, verbose = TRUE, detail = FALSE) {
  error_bar <- match.arg(error_bar)

  range_type <- match.arg(range_type)

  effect <- match.arg(effect)

  correlation_ci_methods <- c("ci95_corr", "ci95_dif_corr")

  if (range_type != "dp" && verbose) {
    warning("The OES method was calibrated for `range_type = \"dp\"`; ", "other range types should be considered exploratory.")
  }

  if (effect == "g" && verbose) {
    warning("The OES method was calibrated using Cohen's d in single-factor, ",
      "two-level independent comparisons; `effect = \"g\"` should be considered exploratory.")
  }

  dv_name <- .resolve_quo_name(rlang::enquo(DV))

  id_name <- .resolve_quo_name(rlang::enquo(id))

  within_names <- .parse_factor_quo(rlang::enquo(within))

  between_names <- .parse_factor_quo(rlang::enquo(between))

  iv_names <- unique(c(within_names, between_names))

  if (length(iv_names) == 0L) {
    stop("You must supply at least one factor in `within` or `between`.")
  }

  if (!dv_name %in% names(data)) {
    stop("DV column '", dv_name, "' is not present in the data.")
  }

  missing_iv <- setdiff(iv_names, names(data))

  if (length(missing_iv) > 0L) {
    stop("These factors in `within`/`between` are not in the data: ", paste(missing_iv,
      collapse = ", "))
  }

  design_type <- if (length(within_names) > 0L && length(between_names) > 0L) {
    "mixed"
  } else if (length(within_names) > 0L) {
    "within"
  } else {
    "between"
  }

  missing_valid_id <- length(within_names) > 0L && (is.null(id_name) || !id_name %in% names(data))

  # Correlation-adjusted CIs have the stronger requirement because the
  # interval calculation itself requires participant matching.
  if (error_bar %in% correlation_ci_methods) {
    if (length(within_names) == 0L) {
      stop("`error_bar = \"", error_bar, "\"` requires at least one within-subject factor.")
    }

    if (missing_valid_id) {
      stop("`error_bar = \"", error_bar, "\"` requires a valid participant `id`.")
    }
  } else if (missing_valid_id && verbose) {
    if (length(between_names) > 0L) {
      warning("Within-subject factor(s) were specified but no valid participant `id` ",
        "was supplied. Error bars and between-subject effect sizes can still ", "be calculated, but paired Cohen's dz for within-subject contrasts ",
        "cannot be estimated. Maximum effect size X will therefore be selected ",
        "only from estimable between-subject contrasts.")
    } else {
      warning("Within-subject factor(s) were specified but no valid participant `id` ",
        "was supplied. Error bars can still be calculated, but paired Cohen's ",
        "dz for within-subject contrasts cannot be estimated. Therefore, ", "maximum effect size X may not be estimable.")
    }
  }

  # Measurement/data range used by range_type = 'data' and as fallback.
  measurement_limits <- .fallback_y_range(data[[dv_name]], measurement_range)
  meas_L <- measurement_limits[1L]
  meas_U <- measurement_limits[2L]

  # Detect raw vs summary data.
  has_n <- "n" %in% names(data)
  has_sd <- "sd" %in% names(data)
  has_se <- "se" %in% names(data)

  distinct_cells <- data |>
    dplyr::distinct(dplyr::across(dplyr::all_of(iv_names)))

  is_one_row_per_cell <- nrow(data) == nrow(distinct_cells)

  summary_type <- if (is_one_row_per_cell) {
    if (has_n || has_sd || has_se) {
      "summary_full"
    } else {
      "summary_means"
    }
  } else {
    "raw"
  }

  if (summary_type == "summary_means" && verbose) {
    warning("One row per cell but no n/sd/se columns; treating the input as ", "means-only summary data. Effect size X cannot be estimated from ",
      "these summary means.")
  }

  if (error_bar %in% correlation_ci_methods && summary_type != "raw") {
    stop("`error_bar = \"", error_bar, "\"` requires raw participant-level data; ", "Cousineau-Morey intervals cannot be reconstructed from summary data.")
  }

  # Ordinary cell summaries.
  if (summary_type == "raw") {
    # A fresh response column avoids shadowing when DV is named n or mean.
    raw_value_name <- ".oes_value"
    while (raw_value_name %in% names(data)) {
      raw_value_name <- paste0(raw_value_name, "_")
    }
    raw_data <- data
    raw_data[[raw_value_name]] <- data[[dv_name]]
    summ <- raw_data |>
      dplyr::group_by(dplyr::across(dplyr::all_of(iv_names))) |>
      dplyr::summarise(n = sum(!is.na(.data[[raw_value_name]])), mean = mean(.data[[raw_value_name]],
        na.rm = TRUE), sd = stats::sd(.data[[raw_value_name]], na.rm = TRUE), .groups = "drop")
  } else if (summary_type == "summary_full") {
    summary_input <- data

    summary_input$.oes_n <- if (has_n) {
      summary_input[["n"]]
    } else {
      1
    }

    summary_input$.oes_sd <- if (has_sd) {
      summary_input[["sd"]]
    } else if (has_se && has_n) {
      summary_input[["se"]] * sqrt(summary_input[["n"]])
    } else {
      NA_real_
    }

    summ <- summary_input |>
      dplyr::group_by(dplyr::across(dplyr::all_of(iv_names))) |>
      dplyr::summarise(n = dplyr::first(.data[[".oes_n"]]), mean = dplyr::first(.data[[dv_name]]),
        sd = dplyr::first(.data[[".oes_sd"]]), .groups = "drop")
  } else {
    summ <- data |>
      dplyr::group_by(dplyr::across(dplyr::all_of(iv_names))) |>
      dplyr::summarise(n = 1L, mean = dplyr::first(.data[[dv_name]]), sd = NA_real_,
        .groups = "drop")
  }

  J_cells <- nrow(summ)
  N <- sum(summ$n, na.rm = TRUE)

  # One pooled raw within-cell SD, computed regardless of `pooled`.
  pooled_sd_raw <- .pooled_sd_from_cells(summ$sd, summ$n)

  if (!is.finite(pooled_sd_raw)) {
    pooled_sd_raw <- if (summary_type == "raw") {
      stats::sd(data[[dv_name]], na.rm = TRUE)
    } else {
      NA_real_
    }
  }

  # ------------------------------------------------------------
  # Error-bar construction
  # ------------------------------------------------------------
  if (error_bar %in% correlation_ci_methods) {
    res <- .cousineau_morey_ci(data = data, dv_name = dv_name, id_name = id_name, within_names = within_names,
      between_names = between_names, pooled = pooled, difference_adjusted = identical(error_bar,
        "ci95_dif_corr"))

    # OES always uses ONE pooled transformed SD, regardless of `pooled`.
    # The sqrt(2) difference adjustment affects only the CI half-width,
    # not the pooled variability scale used by ER.
    pooled_sd <- .pooled_sd_from_cells(res$sd_z, res$n)

  } else {
    if (pooled) {
      se <- pooled_sd_raw/sqrt(summ$n)

      df <- N - J_cells

      eb_half <- switch(error_bar, sd = rep(pooled_sd_raw, nrow(summ)), se = se, ci95 = stats::qt(0.975,
        ifelse(is.na(df) || df <= 0, 1, df)) * se, ci95_dif = stats::qt(0.975, ifelse(is.na(df) ||
        df <= 0, 1, df)) * se * sqrt(2))
    } else {
      se <- summ$sd/sqrt(summ$n)

      df <- summ$n - 1

      df_safe <- ifelse(is.na(df) | df <= 0, 1, df)

      eb_half <- switch(error_bar, sd = summ$sd, se = se, ci95 = stats::qt(0.975, df_safe) *
        se, ci95_dif = stats::qt(0.975, df_safe) * se * sqrt(2))
    }

    res <- summ |>
      dplyr::mutate(se = se, eb_half = eb_half, eb_lower = mean - eb_half, eb_upper = mean +
        eb_half)

    # OES always uses one pooled raw within-cell SD.
    pooled_sd <- pooled_sd_raw
  }

  if (!is.finite(pooled_sd)) {
    pooled_sd <- if (summary_type == "raw") {
      stats::sd(data[[dv_name]], na.rm = TRUE)
    } else {
      NA_real_
    }
  }

  # ------------------------------------------------------------
  # Base range L/U
  # ------------------------------------------------------------
  if (range_type == "data") {
    base_L <- meas_L
    base_U <- meas_U
  } else if (range_type == "quantile") {
    qs <- stats::quantile(data[[dv_name]], probs = c(0.02, 0.98), na.rm = TRUE, names = FALSE)

    base_L <- qs[1L]
    base_U <- qs[2L]
  } else {
    base_L <- suppressWarnings(min(res$eb_lower, na.rm = TRUE))

    base_U <- suppressWarnings(max(res$eb_upper, na.rm = TRUE))

    if (!is.finite(base_L) || !is.finite(base_U)) {
      base_L <- meas_L
      base_U <- meas_U
    }
  }

  res <- res |>
    dplyr::mutate(L = base_L, U = base_U)

  # ------------------------------------------------------------
  # Full-design conditional pairwise effect-size search
  # ------------------------------------------------------------
  effect_table <- data.frame()
  effect_info <- .max_effect_info(effect_table)
  dp <- NA_real_

  if (summary_type == "raw") {
    effect_table <- .compute_effect_table(data = data, dv_name = dv_name, within_names = within_names,
      between_names = between_names, id_name = id_name, effect = effect)

    effect_info <- .max_effect_info(effect_table)

    dp <- effect_info$max_effect
  }

  res <- res |>
    dplyr::mutate(d = dp)

  error_bar_info <- .make_error_bar_info(error_bar = error_bar, pooled = pooled, res = res)

  sd_info <- .make_sd_info(pooled_sd = pooled_sd, error_bar = error_bar)

  # ------------------------------------------------------------
  # Fallback if X is not estimable or below .20
  # ------------------------------------------------------------
  fallback <- !is.finite(dp) || is.na(dp) || dp < 0.2

  if (fallback) {
    fallback_reason <- if (!is.finite(dp) || is.na(dp)) {
      "X could not be estimated"
    } else {
      "X was below 0.20"
    }

    if (verbose) {
      warning(fallback_reason, "; falling back to the measurement/data range.")
    }

    range_df <- data.frame(lower = meas_L, upper = meas_U)

    range_info <- .make_range_info(range_type = range_type, measurement_range = measurement_range,
      base_L = base_L, base_U = base_U, fallback = TRUE, fallback_reason = fallback_reason,
      final_lower = meas_L, final_upper = meas_U)

    ER <- NA_real_

    if (!detail) {
      return(range_df)
    }

    return(structure(list(range = range_df, res = res, dp = dp, effect_info = effect_info,
      effect_table = effect_table, pooled_sd = pooled_sd, ER = ER, sd_info = sd_info,
      error_bar_info = error_bar_info, range_info = range_info, L = meas_L, U = meas_U,
      args = list(pooled = pooled, error_bar = error_bar, range_type = range_type,
        id = id_name, within = within_names, between = between_names, design = design_type,
        effect = effect, summary_type = summary_type, measurement_range = measurement_range)),
      class = "oes_result"))
  }

  # ------------------------------------------------------------
  # Calibrated OES expansion
  # ------------------------------------------------------------
  a <- if (dp >= 0.8) {
    5.723
  } else if (dp >= 0.5) {
    1.575
  } else {
    0.254
  }

  ER <- pooled_sd/(dp + a)

  lower <- base_L - ER
  upper <- base_U + ER

  res <- res |>
    dplyr::mutate(ER = ER, lower = lower, upper = upper, pooled_sd = pooled_sd)

  range_df <- data.frame(lower = lower, upper = upper)

  range_info <- .make_range_info(range_type = range_type, measurement_range = measurement_range,
    base_L = base_L, base_U = base_U, fallback = FALSE, fallback_reason = NULL, final_lower = lower,
    final_upper = upper)

  if (!detail) {
    return(range_df)
  }

  structure(list(range = range_df, res = res, dp = dp, effect_info = effect_info, effect_table = effect_table,
    pooled_sd = pooled_sd, ER = ER, sd_info = sd_info, error_bar_info = error_bar_info,
    range_info = range_info, L = base_L, U = base_U, args = list(pooled = pooled, error_bar = error_bar,
      range_type = range_type, id = id_name, within = within_names, between = between_names,
      design = design_type, effect = effect, summary_type = summary_type, measurement_range = measurement_range)),
    class = "oes_result")
}

# Character-interface wrapper.
oes_chr <- function(data, DV, within = NULL, between = NULL, ...) {
  oes(data = data, DV = DV, within = within, between = between, ...)
}

#########################
# Summary plot builder
#########################

.build_summary_plot <- function(res_tbl, design_info, dv_name) {
  x_var <- design_info$iv_roles$x %||% design_info$IVs[1L]

  fillVar <- design_info$iv_roles$fill
  # Lines, ordinary points, and error-bar outlines use colour, not fill.
  # Preserve an explicit colour mapping; otherwise display the fill groups.
  colourVar <- design_info$iv_roles$colour %||% fillVar
  shapeVar <- design_info$iv_roles$shape
  linetypeVar <- design_info$iv_roles$linetype
  facetVars <- design_info$iv_roles$facet %||% character(0L)

  # Respect explicit grouping. Otherwise separate every aesthetic series,
  # while allowing each series to connect across x within its facet panel.
  groupVars <- if (!is.null(design_info$iv_roles$group)) {
    design_info$iv_roles$group
  } else {
    setdiff(unique(c(colourVar, fillVar, shapeVar, linetypeVar)),
      c(x_var, facetVars))
  }

  aes_list <- list(x = rlang::sym(x_var), y = rlang::sym("mean"))

  if (!is.null(colourVar)) {
    aes_list$colour <- rlang::sym(colourVar)
  }

  if (!is.null(shapeVar)) {
    aes_list$shape <- rlang::sym(shapeVar)
  }

  if (!is.null(fillVar)) {
    aes_list$fill <- rlang::sym(fillVar)
  }

  if (!is.null(linetypeVar)) {
    aes_list$linetype <- rlang::sym(linetypeVar)
  }

  if (length(groupVars) == 1L) {
    aes_list$group <- rlang::sym(groupVars)
  } else if (length(groupVars) > 1L) {
    aes_list$group <- rlang::expr(base::interaction(
      !!!rlang::syms(groupVars), drop = TRUE, lex.order = TRUE))
  } else {
    aes_list$group <- 1
  }

  pos <- if (length(setdiff(groupVars, c(x_var, facetVars))) > 0L) {
    ggplot2::position_dodge(width = 0.3)
  } else {
    ggplot2::position_identity()
  }

  p <- ggplot2::ggplot(res_tbl, do.call(ggplot2::aes, aes_list)) + ggplot2::geom_line(position = pos) +
    ggplot2::geom_point(position = pos) + ggplot2::geom_errorbar(ggplot2::aes(ymin = eb_lower,
    ymax = eb_upper), position = pos, width = 0.15)

  if (length(facetVars) > 0L) {
    fml <- stats::as.formula(paste("~", paste(facetVars, collapse = "+")))

    p <- p + ggplot2::facet_wrap(fml)
  }

  if (!is.null(colourVar) && requireNamespace("ggsci", quietly = TRUE)) {
    p <- p + ggsci::scale_color_npg()
  }

  if (!is.null(fillVar) && requireNamespace("ggsci", quietly = TRUE)) {
    p <- p + ggsci::scale_fill_npg()
  }

  p + ggplot2::labs(y = dv_name)
}

#########################
# High-level wrapper
#########################

#' Create an optimal-range graph or report recommended y-axis limits
#'
#' @param plot Optional ggplot object.
#' @param data Raw or summary data frame.
#' @param DV Dependent-variable column as a bare name or character string.
#' @param layout Either `'summary'` or `'original'`.
#' @param pooled Controls error-bar pooling. OES expansion always uses one
#'   pooled variability estimate regardless of this setting.
#' @param error_bar One of `'ci95'`, `'ci95_dif'`, `'ci95_corr'`,
#'   `'ci95_dif_corr'`, `'se'`, or `'sd'`.
#' @param range_type One of `'dp'`, `'quantile'`, or `'data'`.
#' @param id Participant identifier for repeated-measures data.
#' @param within Within-subject factor or factors.
#' @param between Between-subject factor or factors.
#' @param effect `'d'` or exploratory `'g'`.
#' @param measurement_range Optional theoretical DV limits, `c(min, max)`.
#' @param output `'graph'` or `'y_axis_limit'`.
#' @param override_existing_limits Whether to replace existing plot y limits.
#' @param verbose Whether to print OES messages and warnings.
#' @param detail Whether graph output should also include the OES result.
#'
#' @return A ggplot, a list containing plot and OES details, or a character
#'   recommendation when `output = 'y_axis_limit'`.
#' @export
optimal_graph <- function(plot = NULL, data = NULL, DV = NULL, layout = c("summary", "original"),
  pooled = TRUE, error_bar = c("ci95", "ci95_dif", "ci95_corr", "ci95_dif_corr", "se",
    "sd"), range_type = c("dp", "quantile", "data"), id = NULL, within = NULL, between = NULL,
  effect = c("d", "g"), measurement_range = NULL, output = c("graph", "y_axis_limit"),
  override_existing_limits = FALSE, verbose = TRUE, detail = FALSE) {
  layout <- match.arg(layout)

  error_bar <- match.arg(error_bar)

  range_type <- match.arg(range_type)

  effect <- match.arg(effect)

  output <- match.arg(output)

  if (output == "graph" && utils::packageVersion("ggplot2") < "4.0.0") {
    stop("Graph output in oes requires ggplot2 >= 4.0.0. ", "Update ggplot2, or use output = \"y_axis_limit\" ",
      "for numerical recommendations.")
  }

  # Resolve high-level column arguments once.
  within_names <- .parse_factor_quo(rlang::enquo(within))

  between_names <- .parse_factor_quo(rlang::enquo(between))

  DV_user <- .resolve_quo_name(rlang::enquo(DV))

  id_user <- .resolve_quo_name(rlang::enquo(id))

  infer_between_from_data <- function(data_obj, dv_name) {
    candidate_IVs <- setdiff(names(data_obj), c(dv_name, "n", "sd", "se"))

    candidate_IVs[vapply(candidate_IVs, function(v) {
      col <- data_obj[[v]]

      is.factor(col) || is.character(col) || is.logical(col)
    }, logical(1L))]
  }

  is_group_like <- function(d, v) {
    if (!v %in% names(d)) {
      return(FALSE)
    }

    col <- d[[v]]

    is.factor(col) || is.character(col) || is.logical(col) || dplyr::n_distinct(col) <=
      10L
  }

  # ============================================================
  # 1) PRIMARY: explicit data + DV
  # ============================================================
  if (!is.null(data) && !is.null(DV_user)) {
    data_obj <- data
    dv_name <- DV_user

    if (!dv_name %in% names(data_obj)) {
      stop("DV column '", dv_name, "' is not present in `data`.")
    }

    # If no design was supplied, infer categorical columns as between factors.
    if (length(within_names) == 0L && length(between_names) == 0L) {
      between_names <- infer_between_from_data(data_obj, dv_name)

      if (verbose && length(between_names) > 0L) {
        message("No `within`/`between` specified; treating as between-subject IVs: ",
          paste(between_names, collapse = ", "))
      }
    }

    iv_for_oes <- unique(c(within_names, between_names))

    if (length(iv_for_oes) == 0L) {
      stop("Could not identify any IVs from `within`, `between`, or the data.")
    }

    oes_res <- oes_chr(data = data_obj, DV = dv_name, within = within_names, between = between_names,
      pooled = pooled, error_bar = error_bar, range_type = range_type, id = id_user,
      effect = effect, measurement_range = measurement_range, verbose = verbose, detail = TRUE)

    lower <- oes_res$range$lower
    upper <- oes_res$range$upper

    if (output == "y_axis_limit") {
      return(.format_limit_recommendation(oes_res))
    }

    # If a plot is also supplied, use it for graphical layout only.
    if (!is.null(plot)) {
      p <- plot
      if (override_existing_limits) {
        p <- .clear_y_scale_limits(p)
      }
      pg <- ggplot2::ggplot_build(p)

      design_info <- extract_design_from_pg(pg)

      dv_from_plot <- design_info$DV

      if (!is.null(dv_from_plot) && nzchar(dv_from_plot) && !is.null(pg$plot$data) &&
        is.data.frame(pg$plot$data) && dv_from_plot %in% names(pg$plot$data) && !identical(dv_from_plot,
        dv_name)) {
        warning("DV from plot y aesthetic (", dv_from_plot, ") does not match DV provided (",
          dv_name, ").")
      }

      current_limits <- .get_existing_y_limits(p, pg)

      if (!is.null(current_limits) && !override_existing_limits) {
        if (!detail) {
          return(p)
        }

        return(list(plot = p, oes = oes_res))
      }

      if (layout == "original") {
        plot_out <- p + ggplot2::coord_cartesian(ylim = c(lower, upper), expand = c(top = FALSE,
          right = TRUE, bottom = FALSE, left = TRUE))
      } else {
        plot_out <- .build_summary_plot(oes_res$res, design_info, dv_name) + ggplot2::coord_cartesian(ylim = c(lower,
          upper), expand = c(top = FALSE, right = TRUE, bottom = FALSE, left = TRUE))
      }

      if (!detail) {
        return(plot_out)
      }

      return(list(plot = plot_out, oes = oes_res))
    }

    # No plot supplied: create a summary plot from the specified design.
    design_info_data <- list(DV = dv_name, IVs = iv_for_oes, iv_roles = list(x = iv_for_oes[1L],
      colour = if (length(iv_for_oes) >= 2L) {
        iv_for_oes[2L]
      } else {
        NULL
      }, shape = NULL, fill = NULL, linetype = NULL, group = if (length(iv_for_oes) >=
        2L) {
        iv_for_oes[2L]
      } else {
        NULL
      }, facet = if (length(iv_for_oes) > 2L) {
        iv_for_oes[3:length(iv_for_oes)]
      } else {
        character(0L)
      }))

    plot_out <- .build_summary_plot(oes_res$res, design_info_data, dv_name) + ggplot2::coord_cartesian(ylim = c(lower,
      upper), expand = c(top = FALSE, right = TRUE, bottom = FALSE, left = TRUE))

    if (!detail) {
      return(plot_out)
    }

    return(list(plot = plot_out, oes = oes_res))
  }

  # ============================================================
  # 2) SECONDARY: plot-only interface
  # ============================================================
  if (!is.null(plot)) {
    p <- plot
    if (override_existing_limits) {
      p <- .clear_y_scale_limits(p)
    }

    pg <- ggplot2::ggplot_build(p)

    design_info <- extract_design_from_pg(pg)

    dv_from_plot <- design_info$DV

    plot_data_info <- .extract_plot_source_data(p)

    if (is.null(plot_data_info)) {
      if (verbose) {
        warning("The supplied plot does not contain accessible source data for OES. ",
          "Supply `data`, `DV`, and the relevant `within`/`between` arguments.")
      }

      if (output == "y_axis_limit") {
        return(paste("A y-axis recommendation could not be computed from the plot alone.",
          "The plot does not contain accessible source data for OES.", "Supply `data`, `DV`, and the relevant `within`/`between` arguments."))
      }

      if (!detail) {
        return(plot)
      }

      return(list(plot = plot, oes = NULL))
    }

    d <- plot_data_info$data

    if (is.null(dv_from_plot) || !dv_from_plot %in% names(d)) {
      if (verbose) {
        warning("No valid raw DV mapping could be resolved from the supplied plot. ",
          "Supply `data` and `DV` explicitly for OES calculations.")
      }

      if (output == "y_axis_limit") {
        return(paste("A y-axis recommendation could not be computed from the plot alone.",
          "No valid raw DV mapping could be resolved.", "Supply `data` and `DV` explicitly."))
      }

      if (!detail) {
        return(plot)
      }

      return(list(plot = plot, oes = NULL))
    }

    if (!is.null(DV_user) && !identical(DV_user, dv_from_plot)) {
      stop("DV specified in `DV` (", DV_user, ") does not match plot y aesthetic (",
        dv_from_plot, ").")
    }

    dv_name <- dv_from_plot

    IVs_detected <- if (length(design_info$IVs) > 0L) {
      design_info$IVs[vapply(design_info$IVs, function(v) {
        is_group_like(d, v)
      }, logical(1L))]
    } else {
      character(0L)
    }

    if (length(within_names) == 0L && length(between_names) == 0L) {
      between_names <- IVs_detected
    } else {
      missing_in_plot <- setdiff(c(within_names, between_names), IVs_detected)

      if (length(missing_in_plot) > 0L && verbose) {
        warning("Factors in `within`/`between` not present in plot aesthetics/facets: ",
          paste(missing_in_plot, collapse = ", "), ". OES will still use the supplied source data if those columns exist.")
      }
    }

    iv_for_oes <- unique(c(within_names, between_names))

    if (length(iv_for_oes) == 0L) {
      yrange <- .fallback_y_range(d[[dv_name]], measurement_range)
      range_source <- if (is.null(measurement_range)) {
        "observed DV minimum and maximum"
      } else {
        "supplied measurement range"
      }

      if (verbose) {
        warning("No design factors could be identified from the plot. ",
          "Effect size X cannot be estimated; using the ", range_source, ".")
      }

      if (output == "y_axis_limit") {
        return(paste0("Maximum effect size X = not estimable.\n", "No design factors could be identified from the plot.\n\n",
          "Recommended y-axis limits: lower = ", .format_number(yrange[1L]), ", upper = ",
          .format_number(yrange[2L]), ".\n", "Final range source: ", range_source, "."))
      }

      current_limits <- .get_existing_y_limits(p, pg)

      plot_out <- if (!is.null(current_limits) && !override_existing_limits) {
        p
      } else {
        p + ggplot2::coord_cartesian(ylim = yrange, expand = c(top = FALSE, right = TRUE,
          bottom = FALSE, left = TRUE))
      }

      if (!detail) {
        return(plot_out)
      }

      return(list(plot = plot_out, oes = NULL))
    }

    # If the plot source contains one row per design cell and no n/sd/se,
    # the plot alone cannot supply effect-size information.
    if (.plot_data_is_means_only(data = d, dv_name = dv_name, iv_names = iv_for_oes)) {
      yrange <- .fallback_y_range(d[[dv_name]], measurement_range)
      range_source <- if (is.null(measurement_range)) {
        "observed DV minimum and maximum"
      } else {
        "supplied measurement range"
      }

      if (verbose) {
        warning("The plot source data contain one row per design cell but no n/sd/se ",
          "information. The plot alone does not contain sufficient raw data to ",
          "estimate effect size X. Supply `data`, `DV`, and the relevant ", "`within`/`between` arguments.")
      }

      if (output == "y_axis_limit") {
        return(paste0("Maximum effect size X = not estimable.\n", "The plot source data do not contain sufficient raw or summary ",
          "information to estimate X.\n\n", "Recommended y-axis limits: lower = ",
          .format_number(yrange[1L]), ", upper = ", .format_number(yrange[2L]), ".\n",
          "Final range source: ", range_source, "."))
      }

      current_limits <- .get_existing_y_limits(p, pg)

      plot_out <- if (!is.null(current_limits) && !override_existing_limits) {
        p
      } else {
        p + ggplot2::coord_cartesian(ylim = yrange, expand = c(top = FALSE, right = TRUE,
          bottom = FALSE, left = TRUE))
      }

      if (!detail) {
        return(plot_out)
      }

      return(list(plot = plot_out, oes = NULL))
    }

    current_limits <- .get_existing_y_limits(p, pg)

    compute_oes <- function() {
      oes_chr(data = d, DV = dv_name, within = within_names, between = between_names,
        pooled = pooled, error_bar = error_bar, range_type = range_type, id = id_user,
        effect = effect, measurement_range = measurement_range, verbose = verbose,
        detail = TRUE)
    }

    if (!is.null(current_limits) && !override_existing_limits) {
      oes_res <- if (detail || output == "y_axis_limit") {
        compute_oes()
      } else {
        NULL
      }

      if (output == "y_axis_limit") {
        return(.format_limit_recommendation(oes_res))
      }

      if (!detail) {
        return(p)
      }

      return(list(plot = p, oes = oes_res))
    }

    oes_res <- compute_oes()

    lower <- oes_res$range$lower
    upper <- oes_res$range$upper

    if (output == "y_axis_limit") {
      return(.format_limit_recommendation(oes_res))
    }

    if (layout == "original") {
      plot_out <- p + ggplot2::coord_cartesian(ylim = c(lower, upper), expand = c(top = FALSE,
        right = TRUE, bottom = FALSE, left = TRUE))
    } else {
      plot_out <- .build_summary_plot(oes_res$res, design_info, dv_name) + ggplot2::coord_cartesian(ylim = c(lower,
        upper), expand = c(top = FALSE, right = TRUE, bottom = FALSE, left = TRUE))
    }

    if (!detail) {
      return(plot_out)
    }

    return(list(plot = plot_out, oes = oes_res))
  }

  # ============================================================
  # 3) Neither explicit data+DV nor plot supplied
  # ============================================================
  stop("You must supply either (`data` + `DV`) or `plot`.")
}

