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
    mutate(not_exposed = ifelse((!!sym(never_name) == 1 & !!sym(treated) == 0) | !!sym(tname) < treatment_time, 1, 0))
  
  # Estimate model on not-exposed observations
  first_stage_est <- fixest::feols(
    fml = formula,
    se = "standard",
    data = df %>% filter(not_exposed == 1),
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
  
  # Treated group summary
  df_treated <- df %>%
    filter(!!sym(treated) == 1) %>%
    summarize_tau(!!sym(tname))
  
  # Exposed but untreated summary
  df_untreated <- df %>%
    filter(!!sym(treated) == 0 & !!sym(never_name) == 0) %>%
    summarize_tau(!!sym(tname))
  
  
  return(list(
    ATOTT = df_treated,
    ASEU = df_untreated,
    tau_pred = df[[tau_name]]
  ))
}