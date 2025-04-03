<h1><code>spill_imputation</code>: Imputation-Based Spillover Estimator</h1>

<p>
This function implements an imputation-based estimator to assess treatment effects in a difference-in-differences (DiD) setting with potential spillovers. 
It imputes counterfactual untreated outcomes using observations not yet treated and never exposed to spillovers.
</p>

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

<p>
Only a subset of never-exposed units is required for estimation. This method does not require knowledge of the true spillover exposure function.
</p>

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
