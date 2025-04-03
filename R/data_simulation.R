set.seed(123)

library(dplyr)

# Parameters
n_units <- 500
n_periods <- 6
treatment_period <- 4
treatment_effect <- 5
spillover_effect <- 1

# Create panel data
df <- expand.grid(id = 1:n_units, time = 1:n_periods)
df <- df[order(df$id, df$time), ]

# Assign treatment group
df$treat_group <- as.integer(df$id <= n_units / 2)

# Add random number of friends treated (0–4) per unit
friends_df <- data.frame(id = 1:n_units,
                         friends_treated = sample(0:4, n_units, replace = TRUE))
df <- merge(df, friends_df, by = "id")

# Indicator for post-treatment period
df$post_treatment <- as.integer(df$time >= treatment_period)

# DiD interaction
df$did <- df$treat_group * df$post_treatment

# Fixed effects
unit_fe <- rnorm(n_units, mean = 0, sd = 2)
df$unit_fe <- unit_fe[df$id]

time_fe <- rnorm(n_periods, mean = 0, sd = 1)
df$time_fe <- time_fe[df$time]

# Random error
df$epsilon <- rnorm(nrow(df), mean = 0, sd = 1)

# Spillover effect only post-treatment
df$spillover <- df$post_treatment * df$friends_treated * spillover_effect

# Final outcome
df$y <- df$unit_fe + df$time_fe + df$epsilon +
  treatment_effect * df$did + df$spillover


df <- df %>%
  group_by(id) %>%
  mutate(not_exposed = as.integer(all(friends_treated == 0))) %>%
  ungroup()
