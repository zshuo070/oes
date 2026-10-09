# Manual error-bar Study 4B data example for oes 1.0.0.
# From the oes project directory, after installing oes:
# source("development/example-error-bar-study4b.R")
# Data DOI: https://doi.org/10.17605/OSF.IO/DTYBF
# File: https://osf.io/dtybf/files/ebsh5
# Shuo Zang and Denis Cousineau; data CC BY 4.0; see ERROR_BAR_DATA_SOURCE.md.
# This illustrates a computational extension, not empirical OES validation.
# The automated tests do not require this data or any network connection.

study_path <- file.path("development", "Study4_long.csv")
if (!file.exists(study_path)) {
  stop("Run from the oes project directory with development/Study4_long.csv present.")
}
Study4_long <- utils::read.csv(study_path, check.names = FALSE)
required_columns <- c("id", "EB", "distortion", "average_rating")
stopifnot(all(required_columns %in% names(Study4_long)))
Study4_long$EB <- factor(Study4_long$EB, levels = paste0("EB", 1:4))
Study4_long$distortion <- factor(Study4_long$distortion)
stopifnot(!anyNA(Study4_long[required_columns]))

# EB and distortion are repeated within each participant. format has only
# one level in this file, so it is not included as an experimental factor.
profile <- with(Study4_long, table(id, EB, distortion))
stopifnot(all(profile == 1L))

p_study <- ggplot2::ggplot(
  Study4_long, ggplot2::aes(EB, average_rating, colour = distortion)
) + ggplot2::geom_boxplot() + ggplot2::theme_bw() +
  ggplot2::labs(x = "Error-bar condition", y = "Average rating")

study_graph_summary <- oes::optimal_graph(
  p_study, data = Study4_long, DV = average_rating,
  within = c(EB, distortion), id = id,
  error_bar = "ci95_corr", measurement_range = c(1, 7),
  layout = "summary", detail = TRUE
)
# Numerical results come from the public function's detailed return object.
study_oes <- study_graph_summary$oes
study_graph_original <- oes::optimal_graph(
  p_study, data = Study4_long, DV = average_rating,
  within = c(EB, distortion), id = id,
  error_bar = "ci95_corr", measurement_range = c(1, 7),
  layout = "original", detail = TRUE
)
study_text <- oes::optimal_graph(
  data = Study4_long, DV = average_rating,
  within = c(EB, distortion), id = id,
  error_bar = "ci95_corr", measurement_range = c(1, 7),
  output = "y_axis_limit"
)

print(study_oes$range)
print(study_graph_summary$plot)
print(study_graph_original$plot)
cat(study_text, "\n")
