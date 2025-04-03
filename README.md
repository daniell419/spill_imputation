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
\alpha_i + \lambda_t + \epsilon_{it} + \tau \cdot Treated_{it} + \gamma \cdot FriendsTreated_i \cdot Post_{t}
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
