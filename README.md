<h1><code>spill_imputation</code>: Imputation Differences-in-differences Estimator for Spillovers</h1>

This package implements a difference-in-differences estimator that accounts for **spillover effects**. It extends the imputation method from Borusyak, Jaravel, and Spiess (2021) by identifying a subset of **not-exposed** and **not-treated** units to estimate counterfactual untreated and unexposed outcomes. The estimator does not requiere to a-priori know the structure of the spillovers propagation. 



## 🚀 Installation

You can install the development version of `spillimputation` from GitHub using:

```r
devtools::install_github("daniell419/spill_imputation")
library(spillimputation)
```
## 🔢 Usage Example

### 1) 📄 Simulate a Dataset with spillovers
```r
# Simulate the spillover data
df_sim <- simulate_spillover_data()
```
The dataset produced by `simulate_panel_data()` is a **balanced panel** of `n_units × n_periods` observations. Each row represents a unit (`id`) observed at a particular time period (`time`). The data is designed to simulate a difference-in-differences (DiD) setup with spillover effects, that occur at time t=4. There is a group of untreated and unexposed units denoted by `not_exposed`. Below, the simulation overview explains in detail the spillover simulation procedure. The estimator expects the following data formatting:

#### **Columns**

| Column        | Type     | Description |
|---------------|----------|-------------|
| `y`           | `double` | Simulated outcome variable. It is constructed as a function of unit and time fixed effects, a treatment effect (applied only post-treatment for treated units), spillover effects from treated friends, and random noise. |
| `not_exposed` | `integer`| Indicator variable equal to 1 if a unit is unexposed and untreated throughout **all** time periods (i.e., is not exposed to any spillover effects). For units in this group the variable should be 1 for every time  |
| `id`          | `integer`| Unique identifier for each unit (e.g., individual, firm, region). |
| `time`        | `integer`| Time period identifier. |
| `treat_group` | `integer`| Indicator equal to 1 if the unit belongs to the treated group, and 0 otherwise (time invariant). |


### 2) Spill-imputation Function Application
The function requieres the names of the outcome variable, the binary definition of the treated group, a label for the not-exposed cohort, time and id indicators and the value of the `treatment_period` when treatment starts (default is 4). It returns a dataframe of the estimates of the ATOTT and ASEUT by year, if there are treated and not exposed units, it also presents the ATT(0). Also, a vector with the individual treatment effects to explore heterogeneity. 
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
The package also provides a function to plot the dynamic effects of the computed targeted parameters. The function `plot_spill_estimates()` returns a ggplot object that can be modified using the <code>ggplot2</code> structure.
```r
plot_spill_estimates(Spill_results, treatment_time=4, title = "Spillover Imputation Estimates")
```

![Simulation](https://github.com/user-attachments/assets/8a82b416-cb37-4dc7-be49-d9233d604b8b)


<h1>Technical Overview</h1>
<p>
Rather than assuming a specific functional form for spillover exposure, this method estimates the untreated potential outcome 
<span style="font-family:monospace;">Ŷ<sub>it</sub>(0)</span> for each unit by imputating the time and unit fix effect estimated in 
a two-way fixed effects regression using only the subset of never-exposed and not-yet-treated units. 
These predicted values are subtracted from observed outcomes to recover treatment and spillover effects.
</p>

<h2>Assumptions</h2>
Identification of Treatment and Spillover effects requiere the three following assumptions:
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
Y<sub>it</sub>(d, s) = Y<sub>it</sub>(0, 0) &forall;s &isin; S<sub>i</sub>, &forall;d &isin; {0, 1}, &forall;t &lt; t0

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
  <li>Predict counterfactual <span style="font-family:monospace;">Ŷ<sub>it</sub>(0,0)</span> for all units.</li>
  <li>Compute Individual Treatment Effects: <span style="font-family:monospace;">τ̂<sub>it</sub>(d,s) = Y<sub>it</sub>(d,s) − Ŷ<sub>it</sub>(0,0)</span></li>
  <li>Aggregate average effects:
    <ul>
      <li><b>ATOTT:</b> Average Total effect on the Treated</li>
      <li><b>ASEU:</b> Average Spillover Effect on Untreated</li>
    </ul>
        <ul> <b>Optional<b>
      <li><b>ATT(0):</b> Average Treatment Effect on Treated at Exposure 0</li>
    </ul>
  </li>
</ol>

<h2>Estimators for the Target Estimands</h2>
<p>Average Treatment Effect on the Treated (ATOTT):</p>

```math
    \hat{ATOT}_t = \frac{\sum_{i=1} d_i\cdot{\hat{\tau}_{t, \text{Total}}^{(i)}(1, s)}}{\sum_{i=1} d_i}
```

<p>Average Spillover Effect on the Untreated (ASEU):</p>
It excludes the researchers proposed not exposed cohort.

```math
    \hat{ASEU}_t = \frac{\sum_{i=1} (1-d_i)\cdot{\hat{\tau}_{t, \text{Spill}}^{(i)}(0, s)}}{\sum_{i=1} (1-d_i)}
```
<p>Average Treatment Effect on the Treated at exposure 0 (ATT(0)):</p>
Optional: if the researcher specifies beforehand a group of treated and not exposed to treatment units, then:

```math
    \hat{ATT}(\vec{0})_t = \frac{\sum_{i=1} d_i \cdot {1}[S_i={0}]\cdot{\hat{\tau}_{t, \text{Direct}}^{i}(1, {0})}}{\sum_{i=1} d_{i}\cdot {1}[S_{i}={0}]}
```

<h2>References</h2>
<ul>
      <li>Lasso, D. (2025). “Spillover Gridlock: Adressing Spillovers in Differences-in-differences.”</li>
  <li>Borusyak, Jaravel, and Spiess (2024). “Revisiting Event Study Designs: Robust and Efficient Estimation.”</li>
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
  <p> For unit  i in time  t, the simulated outcome is: <p>
    
  <p>
    $$ 
      y_{it} = \alpha_i + \lambda_t + \epsilon_{it} + \tau \cdot \text{Treated}_{it} + \gamma \cdot \text{FriendsTreated}_i \cdot \text{Post}_{t}
    $$ 
  </p>
  <p>Where:</p>
  - **&alpha;<sub>i</sub> (Individual Fixed Effect):**  
  Captures all time-invariant characteristics of unit *i*. These effects are drawn from a normal distribution:  
  &alpha;<sub>i</sub> &sim; 𝒩(0, 2²).

- **&lambda;<sub>t</sub> (Time Fixed Effect):**  
  Represents factors that vary over time but are constant across units. These effects are drawn from a normal distribution:  
  &lambda;<sub>t</sub> &sim; 𝒩(0, 1²).

- **&epsilon;<sub>it</sub> (Idiosyncratic Error):**  
  The random error term that captures unit- and time-specific shocks or measurement errors. It is assumed to follow:  
  &epsilon;<sub>it</sub> &sim; 𝒩(0, 1).

- **&tau; (Treatment Effect):**  
  The coefficient for the direct effect of treatment. In this model, &tau; is set to 5, meaning that the treatment increases the outcome by 5 units for treated units.

- **&gamma; (Spillover Effect per Friend Treated):**  
  The coefficient that captures the spillover (or indirect) effect, representing the impact of each additional treated friend. Here, &gamma; is set to 1.

- **Treated<sub>it</sub> (Treatment Indicator):**  
  A binary indicator that is 1 if the unit is in the treated group and the time period is in the post-treatment phase (i.e., *t* &ge; 4), and 0 otherwise.

- **FriendsTreated<sub>i</sub> (Number of Friends Treated):**  
  A random variable taking values in {0, 1, …, 4} that represents the number of friends treated. This variable captures the network or peer exposure effect.

- **Post<sub>t</sub> (Post-Treatment Indicator):**  
  A binary variable that is 1 if the current time period is in the post-treatment phase (*t* &ge; 4) and 0 otherwise.

  ---
