#' Simulate Panel Data with Treatment and Spillover Effects
#'
#' This function generates a panel dataset for a difference-in-differences (DiD) setup
#' with treatment assignment, fixed effects, and spillover effects from treated "friends."
#'
#' @param n_units Integer. Number of units (individuals, regions, etc.). Default is 500.
#' @param n_periods Integer. Number of time periods. Default is 6.
#' @param treatment_period Integer. Period in which treatment begins. Default is 4.
#' @param treatment_effect Numeric. Effect size of the treatment on treated units. Default is 5.
#' @param spillover_effect Numeric. Effect size per treated friend in post-treatment periods. Default is 1.
#' @param seed Integer. Random seed for reproducibility. Default is 123.
#'
#' @return A `data.frame` with the following columns:
#' \describe{
#'   \item{y}{Outcome variable including fixed effects, treatment, spillover, and noise.}
#'   \item{not_exposed}{Binary indicator equal to 1 if the unit has 0 treated friends.}
#'   \item{id}{Unit identifier.}
#'   \item{time}{Time period.}
#'   \item{treat_group}{Binary indicator equal to 1 if the unit is in the treated group.}
#' }
#'
#' @examples
#' df <- simulate_panel_data()
#' head(df)
#'
#' @export
simulate_spillover_data <- function(n_units = 500,
                                n_periods = 6,
                                treatment_period = 4,
                                treatment_effect = 5,
                                spillover_effect = 1,
                                seed = 123) {
  set.seed(seed)

  library(dplyr)

  # Create panel structure
  df <- expand.grid(id = 1:n_units, time = 1:n_periods)
  df <- df[order(df$id, df$time), ]

  # Assign treatment to first half of units
  df$treat_group <- as.integer(df$id <= n_units / 2)

  # Simulate number of treated friends (0–4) for each unit
  friends_df <- data.frame(id = 1:n_units,
                           friends_treated = sample(0:4, n_units, replace = TRUE))
  df <- merge(df, friends_df, by = "id")

  # Indicator for post-treatment time periods
  df$post_treatment <- as.integer(df$time >= treatment_period)

  # DiD interaction term
  df$did <- df$treat_group * df$post_treatment

  # Unit and time fixed effects
  unit_fe <- rnorm(n_units, mean = 0, sd = 2)
  df$unit_fe <- unit_fe[df$id]

  time_fe <- rnorm(n_periods, mean = 0, sd = 1)
  df$time_fe <- time_fe[df$time]

  # Random error
  df$epsilon <- rnorm(nrow(df), mean = 0, sd = 1)

  # Spillover effect (only after treatment starts)
  df$spillover <- df$post_treatment * df$friends_treated * spillover_effect

  # Outcome variable: fixed effects + treatment + spillovers + noise
  df$y <- df$unit_fe + df$time_fe + df$epsilon +
    treatment_effect * df$did + df$spillover

  # Identify units not exposed to spillovers (all friends treated == 0)
  df <- df %>%
    group_by(id) %>%
    mutate(not_exposed = as.integer(all(friends_treated == 0))) %>%
    ungroup() %>%
    select(y, not_exposed, id, time, treat_group)

  return(df)
}

