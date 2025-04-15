#' Plot Spillover DiD Estimates
#'
#' @description
#' This function takes the output from `spill_imputation()` and generates a
#' DiD-style plot showing point estimates and confidence intervals for
#' the treated and exposed untreated groups.
#'
#' @param result A list output from the `spill_imputation()` function.
#' @param title Optional. Title for the plot.
#'
#' @return A ggplot object.
#' @export
plot_spill_estimates <- function(result, title = "Spillover Imputation Estimates", treatment_time=NULL) {
  library(ggplot2)
  library(dplyr)

  # Add group labels
  df_plot <- bind_rows(
    result$ATOT %>% mutate(Estimate = "ATOT"),
    result$ASEU %>% mutate(Estimate = "ASEUT"),
    result$ATT %>% mutate(Estimate = "ATT(0)")
  )

  # Create ggplot
  p <- ggplot(df_plot, aes(x = period, y = estimate, color = Estimate)) +
    geom_point(position = position_dodge(width = 0.4)) +
    geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
                  width = 0.2, position = position_dodge(width = 0.4)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray30") +
    geom_vline(xintercept = treatment_time, linetype = "dashed", color = "gray30") +
    labs(
      title = title,
      x = "Time",
      y = "Treatment Effect (± 95% CI)",
      color = "Estimate"
    ) +
    theme_minimal(base_size = 14)

  return(p)
}

plot_spill_estimates(Spill_results, treatment_time=4)
