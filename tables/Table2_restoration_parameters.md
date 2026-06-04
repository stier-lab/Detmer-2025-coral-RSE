**Table 2. Restoration parameters.**

| Symbol | Parameter | Value | Source |
| --- | --- | --- | --- |
| reef_prop | Proportion of outplants to reef (default strategy) | 0.50 | Strategy variable (varied 0-1) |
| y_collect | Embryo yield, reef & orchard collection | 0.72 | Fundemar 2025; calibrated |
| sett | Settlement rate (settlers per embryo on tiles) | 0.15 | Fundemar 2025 spawning data |
| s_l | Recruit lab survival, immediate outplants | 0.95 | Calibrated to Fundemar 2025 outplant data |
| s_l(1yr) | Recruit lab survival, 1-year retention | 0.70 | Calibrated |
| m_l | Density-dependent lab mortality | 0.02 | Calibrated |
| lab_max | Lab settlement-tile capacity (tiles) | 4,000 | Fundemar facility constraint |
| lab_retain | Tiles retained 1 year (default) | 0 | Scenario choice |
| orchard_size | Orchard capacity (tiles) | 15,000 (500 stars x 30 tiles) | Fundemar facility (500 reef stars) |
| e_T | Target orchard embryos per year | 2e+06 | ~2x 2025 reference-reef collection |
| tank_min/max | Tank embryo min / max | 14,600 / 33,333 | Fundemar 2025 spawning data |
| A_reef | Restoration reef area (m^2) | 7,837 | Mean of 3 Fundemar restoration sites |
| transplant | Transplant from orchard to reef (default) | 0 (none) | Scenario choice |
| dist_sev | Disturbance severity (severe / extreme) | x0.2 (80%) / x0.1 (90%) | Working estimate (needs calibration) |
| dist_freq | Disturbance return interval (yr) | 3 | Scenario choice |
| ext_thresh | Quasi-extinction threshold (m^2) | 100 | Model choice |
| n_sets | Demographic parameter sets (drawn from bootstrap) | 100 (of 2,000) | Hierarchical bootstrap |
| T_sim | Simulation horizon (yr) | 50 | Scenario choice |
