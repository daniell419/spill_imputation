#' Imputation-Based Spillover Estimator
#'
#' @description
#' This function implements an imputation-based estimator to assess treatment effects
#' in a difference-in-differences setting with potential spillovers. It estimates
#' untreated potential outcomes using units not yet treated and never exposed to spillovers,
#' and then computes residualized outcomes for treated and exposed untreated units.
#'
#' @param data A `data.frame` or `tibble` containing panel data.
#' @param yname A string. The name of the outcome variable.
#' @param treated A string. The name of the treatment indicator variable (1 if treated, 0 otherwise).
#' @param never_name A string. The name of the column identifying units never exposed to spillovers (1 if never exposed).
#' @param tname A string. The name of the time period variable.
#' @param idname A string. The name of the unit ID variable.
#' @param treatment_time A numeric scalar indicating the time period when treatment begins.
#'
#' @return A list with the following components:
#' \describe{
#'   \item{ATOTT}{A `data.frame` with summary stats (mean, std. error, 95% confidence interval)
#'     of the residualized outcome by time for the treated group.}
#'   \item{ASEU}{A `data.frame` with the same summary stats for the exposed untreated group.}
#'   \item{tau_pred}{A vector with the residualized outcome `Y(1) - Yhat(0)` for each row in the original dataset.}
#' }
#'
#' @examples
#' \dontrun{
#' result <- spill_imputation(
#'   data = df,
#'   yname = "y",
#'   treated = "treat_group",
#'   never_name = "not_exposed_group",
#'   tname = "time",
#'   idname = "id",
#'   treatment_time = 4
#' )
#'
#' result$ATOTT     # Summary for treated group
#' result$ASEU      # Summary for exposed untreated group
#' result$tau_pred  # Residualized values
#' }
#'
#' @importFrom dplyr mutate group_by summarise filter rename
#' @importFrom rlang sym .data
#' @importFrom fixest feols
#' @export
spill_imputation <- function(data, yname, treated, never_name, tname, idname, treatment_time) {
  library(dplyr)
  library(fixest)
  library(rlang)

  # Create formula for fixed effects
  first_stage <- paste0("0 | ", idname, " + ", tname)
  formula <- stats::as.formula(paste0(yname, " ~ ", first_stage))

  # Copy data to avoid modifying original
  df <- data

  # Create indicator for non-exposed periods
  df <- df %>%
    mutate(ZZZ_group_not_exposed = ifelse((!!sym(never_name) == 1 & !!sym(treated) == 0) | !!sym(tname) < treatment_time, 1, 0))

  # Estimate model on not-exposed observations
  first_stage_est <- fixest::feols(
    fml = formula,
    se = "standard",
    data = df %>% filter(ZZZ_group_not_exposed == 1),
    warn = FALSE, notes = FALSE
  )

  # Compute residualized outcome (tau)
  tau_name <- paste0("tau_", yname)
  df[[tau_name]] <- df[[yname]] - stats::predict(first_stage_est, newdata = df)


  # fucntion to format
  summarize_tau <- function(sub_df, time_var) {
    sub_df %>%
      group_by({{ time_var }}) %>%
      summarise(
        estimate = mean(.data[[tau_name]]),
        std.error = sd(.data[[tau_name]]),
        conf.low = estimate - 1.96 * std.error, # 95% conf interval
        conf.high = estimate + 1.96 * std.error, # 95% conf interval
        .groups = "drop"
      ) %>%
      rename(period = {{ time_var }})
  }

  # ATOT
  df_treated <- df %>%
    filter(!!sym(treated) == 1) %>%
    summarize_tau(!!sym(tname))

  # ASEUT
  df_untreated <- df %>%
    filter(!!sym(treated) == 0 & !!sym(never_name) == 0) %>%
    summarize_tau(!!sym(tname))

  # ATT(0)
  df_ATT <- df %>%
    filter(!!sym(treated) == 1 & !!sym(never_name) == 1) %>%
    summarize_tau(!!sym(tname))


  return(list(
    ATOT = df_treated,
    ASEU = df_untreated,
    ATT = df_ATT,
    tau_pred = df[[tau_name]]
  ))
}
