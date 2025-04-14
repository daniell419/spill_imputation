<h1><code>spill_imputation</code>: Imputation Differences-in-differences Estimator for Spillovers</h1>

This package implements a difference-in-differences estimator that accounts for **spillover effects**. It extends the imputation method from Borusyak, Jaravel, and Spiess (2021) by identifying a subset of **not-exposed** and **not-treated** units to estimate counterfactual untreated and unexposed outcomes. The estimator does not requiere to a-priori know the structure of the spillvoers propagation. 



## 🚀 Installation

You can install the development version of `spillimputation` from GitHub using:

```r
devtools::install_github("daniell419/spill_imputation")
library(spillimputation)
```
## 🔢 Example

### 1) 📄 Simulate a Dataset with spillovers
```r
# Simulate the spillover data
df_sim <- simulate_spillover_data()
```
The dataset produced by `simulate_panel_data()` is a **balanced panel** of `n_units × n_periods` observations. Each row represents a unit (`id`) observed at a particular time period (`time`). The data is designed to simulate a difference-in-differences (DiD) setup with spillover effects and fixed effects. Below, step 3 explains in detail the spillover simulation procedure. The estimator expects the following data formatting:

#### **Columns**

| Column        | Type     | Description |
|---------------|----------|-------------|
| `y`           | `double` | Simulated outcome variable. It is constructed as a function of unit and time fixed effects, a treatment effect (applied only post-treatment for treated units), spillover effects from treated friends, and random noise. |
| `not_exposed` | `integer`| Indicator variable equal to 1 if a unit is unexposed and untreated throughout **all** time periods (i.e., is not exposed to any spillover effects). For units in this group the variable should be 1 for every time  |
| `id`          | `integer`| Unique identifier for each unit (e.g., individual, firm, region). |
| `time`        | `integer`| Time period identifier. |
| `treat_group` | `integer`| Indicator equal to 1 if the unit belongs to the treated group, and 0 otherwise. Treatment starts at the specified `treatment_period` (default is 4). |


### 2) Spill-imputation Function Application
The function requeieres the names of the outcome variable, the binary definition of the treated group, a label for the not-exposed cohort, time and id indicators and the value of the treatment time. It returns a dataframe of the estimates of the ATOTT and ASEUT by year. Also, a vector with the individual treatment effects to explore heterogeneity. 
```r
Spill_results <- spill_imputation(
  data = df_sim,
  yname = "y",
  treated = "treat_group",
  never_name = "not_exposed",
  tname = "time",
  idname = "id",
  treatment_time = 4
)

Spill_results$ATOTT     # Treated group effects by time
Spill_results$ASEU      # Spillover effects on untreated by time
Spill_results$tau_pred  # Difference between predicted and observed outcome
```
### 3) Plotting 
The package also provides a function to plot the dynamic effects of both the ATOTT and the ASEU. The function `simulate_panel_data()` returns a ggplot object that can be modified. 
```r
plot_spill_estimates(Spill_results, treatment_time=4, title = "Spillover Imputation Estimates")
```

![image](https://github.com/user-attachments/assets/e0f561f5-799b-4455-b8e5-2d2dcce0b587)


<h1>Technical Overview</h1>
<p>
Rather than assuming a specific functional form for spillover exposure, this method estimates the untreated potential outcome 
<span style="font-family:monospace;">Y<sub>it</sub>(0)</span> using a two-way fixed effects regression on never-exposed and not-yet-treated units. 
These predicted values are subtracted from observed outcomes to recover treatment and spillover effects.
</p>

<h2>Assumptions</h2>
<ul>
  <li><b>Unit Parallel Trends:</b> Untreated outcomes follow a linear additive model with unit and time fixed effects:</li>
</ul>
<pre>
E[Y<sub>it</sub>(0, 0)] = α<sub>i</sub> + λ<sub>t</sub>
</pre>

<ul>
  <li><b>No anticipation:</b> future treatment assignments and exposures do not affect potential outcomesprior to treatment:</li>
</ul>
<pre>
Y<sub>it</sub>(d, h) = Y<sub>it</sub>(0, 0) &forall;h &isin; H, &forall;d(j,k) &isin; {0, 1}, &forall;t &lt; t0

</pre>

<ul>
  <li><b>Identification of a not-treated and not-exposed cohort:</b> The researcher knows a group that is not-exposed and not-treated. 
</ul>


<h2>Estimation Procedure</h2>
<ol>
  <li>Subset the data to never-exposed and pre-treatment observations.</li>
  <li>Estimate:
  <pre>Y<sub>it</sub> = α<sub>i</sub> + λ<sub>t</sub> + ε<sub>it</sub></pre>
  </li>
  <li>Predict counterfactual <span style="font-family:monospace;">Ŷ<sub>it</sub>(0)</span> for all units.</li>
  <li>Compute residuals: <span style="font-family:monospace;">τ̂<sub>it</sub> = Y<sub>it</sub> − Ŷ<sub>it</sub>(0)</span></li>
  <li>Aggregate average effects:
    <ul>
      <li><b>ATOTT:</b> Average treatment effect on treated</li>
      <li><b>ASEU:</b> Average spillover effect on untreated but exposed</li>
    </ul>
  </li>
</ol>

<h2>Estimator Equations</h2>
<p>Average Treatment Effect on the Treated (ATOTT):</p>
<pre>
ATOTT = mean(Y<sub>it</sub>(1, S<sub>it</sub>) − Ŷ<sub>it</sub>(0, 0)) for treated units
</pre>

<p>Average Spillover Effect on the Untreated (ASEU):</p>
<pre>
ASEU = mean(Y<sub>it</sub>(0, S<sub>it</sub>) − Ŷ<sub>it</sub>(0, 0)) for untreated but exposed units
</pre>


<h2>References</h2>
<ul>
  <li>Borusyak, Jaravel, and Spiess (2024). “Revisiting Event Study Designs: Robust and Efficient Estimation.”</li>
    <li>Lasso, D. (2025). “Spillover Gridlock: Adressing Spillovers in Differences-in-differences.”</li>
</ul>

</body>
</html>
---

## 🔢 Simulation Overview

We simulate panel data for `N = 500` units over `T = 6` time periods. Half of the units are treated starting in period 4, and each unit has a random number of "friends" who are also treated. The outcome variable is generated with:

- **Individual fixed effects**
- **Time fixed effects**
- **Treatment effects**
- **Spillover effects** from friends (activated only post-treatment)

---

<h2>📐 Model Equation</h2>
  <p>For unit \( i \) in time \( t \), the outcome is:</p>
  <p>
    $$ 
      y_{it} = \alpha_i + \lambda_t + \epsilon_{it} + \tau \cdot \text{Treated}_{it} + \gamma \cdot \text{FriendsTreated}_i \cdot \text{Post}_{t}
    $$ 
  </p>
  <p>Where:</p>
<ul>
    <li>
      \( \alpha_i \): individual fixed effect 
      (drawn from \( \mathcal{N}(0, 2^2) \))
    </li>
    <li>
      \( \lambda_t \): time fixed effect 
      (drawn from \( \mathcal{N}(0, 1^2) \))
    </li>
    <li>
      \( \epsilon_{it} \): idiosyncratic error 
      \( \sim \mathcal{N}(0, 1) \)
    </li>
    <li>
      \( \tau = 5 \): treatment effect
    </li>
    <li>
      \( \gamma = 1 \): spillover effect per friend treated
    </li>
    <li>
      \( \text{Treated}_{it} = 1 \) if unit is in the treated group 
      and \( t \geq 4 \)
    </li>
    <li>
      \( \text{FriendsTreated}_i \in \{0, 1, ..., 4\} \):
      number of friends treated (random)
    </li>
    <li>
      \( \text{Post}_t = 1 \) if \( t \geq 4 \)
    </li>
  </ul>
---
