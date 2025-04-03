<h1><code>spill_imputation</code>: Imputation-Based Differences-in-differences Estimator</h1>

This package implements a difference-in-differences estimator that accounts for **spillover effects**. It extends the imputation method from Borusyak, Jaravel, and Spiess (2021) by identifying a subset of **not-exposed** and **not-treated** units to estimate counterfactual untreated and unexposed outcomes. The estimator does not requiere to a-priori know the structure of the spillvoers propagation. 



## 🚀 Installation

You can install the development version of `spillimputation` from GitHub using:

```r
devtools::install_github("daniell419/spillimputation")
library(spillimputation)
```
## 🔢 Example

### 1) 📄 Simulate a Dataset with spillovers
```r
# Simulate the spillover data
df_sim <- simulate_spillover_data()
```
The dataset produced by `simulate_panel_data()` is a **balanced panel** of `n_units × n_periods` observations. Each row represents a unit (`id`) observed at a particular time period (`time`). The data is designed to simulate a difference-in-differences (DiD) setup with spillover effects and fixed effects.

#### **Columns**

| Column        | Type     | Description |
|---------------|----------|-------------|
| `y`           | `double` | Simulated outcome variable. It is constructed as a function of unit and time fixed effects, a treatment effect (applied only post-treatment for treated units), spillover effects from treated friends, and random noise. |
| `not_exposed` | `integer`| Indicator variable equal to 1 if a unit has **zero treated friends** throughout all time periods (i.e., is not exposed to any spillover effects). |
| `id`          | `integer`| Unique identifier for each unit (e.g., individual, firm, region). |
| `time`        | `integer`| Time period identifier ranging from 1 to `n_periods`. |
| `treat_group` | `integer`| Indicator equal to 1 if the unit belongs to the treated group (by default, the first half of units), and 0 otherwise. Treatment starts at the specified `treatment_period`. |

<h2>Function Application</h2>

```r
SpilL_results <- spill_imputation(
  data = df,
  yname = "y",
  treated = "treat_group",
  never_name = "not_exposed_group",
  tname = "time",
  idname = "id",
  treatment_time = 4
)

SpilL_results$ATOTT     # Treated group effects by time
SpilL_results$ASEU      # Spillover effects on untreated by time
SpilL_results$tau_pred  # Difference between predicted and observed outcome
```





<h2>Description</h2>
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

<h2>Usage Example</h2>
<pre><code>
result <- spill_imputation(
  data = df,
  yname = "y",
  treated = "treat_group",
  never_name = "not_exposed_group",
  tname = "time",
  idname = "id",
  treatment_time = 4
)

result$ATOTT     # Treated group effects by time
result$ASEU      # Spillover effects on untreated
result$tau_pred  # Residualized outcome
</code></pre>

<h2>References</h2>
<ul>
  <li>Borusyak, Jaravel, and Spiess (2021). “Revisiting Event Study Designs: Robust and Efficient Estimation.”</li>
</ul>

<h2>Notes</h2>
<p>
This method avoids bias from incorrect spillover mapping assumptions. However, statistical inference may be affected by potential correlation in residuals induced by spillovers.
</p>

</body>
</html>

# Simulation: Difference-in-Differences with Spillovers

This project simulates a panel dataset for evaluating treatment effects in a difference-in-differences (DiD) setup with **spillovers from treated neighbors (friends)**. The goal is to allow testing of imputation-based DiD estimators when there are potential violations of the stable unit treatment value assumption (SUTVA), such as spillover effects.

---

## 🔢 Simulation Overview

We simulate panel data for `N = 500` units over `T = 6` time periods. Half of the units are treated starting in period 4, and each unit has a random number of "friends" who are also treated. The outcome variable is generated with:

- **Individual fixed effects**
- **Time fixed effects**
- **Treatment effects**
- **Spillover effects** from friends (activated only post-treatment)

---

## 📐 Model Equation

For unit \\( i \\) in time \\( t \\), the outcome is:

$$
y_{it} = \alpha_i + \lambda_t + \epsilon_{it} + \tau \cdot Treated_{it} + \gamma \cdot FriendsTreated_i \cdot Post_{t}
$$

Where:

- \\( \\alpha_i \\): individual fixed effect (drawn from \\( \\mathcal{N}(0, 2^2) \\))  
- \\( \\lambda_t \\): time fixed effect (drawn from \\( \\mathcal{N}(0, 1^2) \\))  
- \\( \\epsilon_{it} \\): idiosyncratic error \\( \\sim \\mathcal{N}(0, 1) \\)  
- \\( \\tau = 5 \\): treatment effect  
- \\( \\gamma = 1 \\): spillover effect per friend treated  
- \\( \\text{Treated}_{it} = 1 \\) if unit is in treated group and \\( t \\geq 4 \\)  
- \\( \\text{FriendsTreated}_i \\in \\{0, 1, ..., 4\\} \\): number of friends treated (random)  
- \\( \\text{Post}_t = 1 \\) if \\( t \\geq 4 \\)

---
