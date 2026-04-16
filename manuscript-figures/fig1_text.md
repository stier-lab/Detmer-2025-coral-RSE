# Figure 1 — Methods Text and Legend

## Methods (for the Model Overview section)

We developed a stage-structured demographic model to evaluate restoration strategies for *Acropora palmata* (elkhorn coral). The Restoration Strategy Evaluation (RSE) model tracks coral populations across four compartments — a reference reef (larval source), a laboratory (larval settlement and tile rearing), an ocean-based nursery orchard, and the restoration reef — connected by management-mediated flows of coral propagules (Fig. 1b).

Within each compartment, the population is structured into five size classes based on colony planar area: SC1 (0–10 cm²), SC2 (10–100 cm²), SC3 (100–900 cm²), SC4 (900–4,000 cm²), and SC5 (≥4,000 cm²). Population dynamics follow a pre-breeding census, stage-structured projection:

**N**(*t*) = (**T** + **F**) · (**S** ⊙ **N**(*t* − 1)) + **R**(*t*)

where **N**(*t*) is the population vector at time *t*, **S** is a vector of size-class-specific annual survival probabilities applied element-wise (⊙), **T** is a transition matrix encoding growth and shrinkage between size classes, **F** is a fragmentation matrix (asexual reproduction by SC4–SC5 colonies), and **R**(*t*) represents external recruitment and outplanting inputs.

Survival probabilities include log-normal environmental stochasticity (σ_s). Growth and shrinkage rates govern transitions between adjacent size classes, with colonies able to move up (growth), down (partial mortality), or remain in their current class. Fragmentation allows large colonies (SC4, SC5) to produce smaller fragments that enter lower size classes. Fecundity (sexual reproduction) is size-class-specific with log-normal stochasticity (σ_f); larvae from reproductive colonies (SC4–SC5) in all compartments contribute to the larval pool processed through the laboratory.

Post-settlement survival on laboratory tiles follows a Ricker-type density-dependent function: survival = *n* · exp(−*m*₁ · *d*), where *d* is tile density and *m*₁ = 0.02. This reflects competitive mortality on crowded substrates.

Disturbance events (bleaching, hurricanes) are modeled as discrete annual shocks that override survival and transition parameters in specified years. We evaluated three disturbance regimes: no disturbance (D0), disturbance every 5 years (D5), and every 3 years (D3).

The model incorporates three key management decisions that practitioners control (Fig. 1b, decision points): (1) the allocation of lab-reared settlers between direct reef outplanting and the nursery orchard (*prop*; Fig. 3), (2) the duration of laboratory retention before outplanting, which trades higher post-settlement survival against a delay cost (*retain*; Fig. 4), and (3) the target size class at which colonies are outplanted to the reef (*size*; Fig. 5). Each decision axis is evaluated independently in the subsequent analyses.

All simulations were run for 50 years with 100 stochastic parameter replicates drawn from empirical distributions of *A. palmata* demographic rates.

---

## Figure 1 Legend

**Figure 1. Restoration Strategy Evaluation (RSE) model for *Acropora palmata*.** (a) [Panel A — physical system illustration, to be added]. (b) Demographic flow diagram showing the three managed compartments — laboratory, nursery orchard, and restoration reef — connected by outplanting and transplant flows (solid arrows). Dashed arrows indicate external inputs: larvae collected from a reference reef (λ_R = 1.26 × 10⁶ yr⁻¹) and wild recruitment (λ). Within each compartment, coral colonies progress through five size classes (bottom strip; SC1–SC5, colony area in cm²), with survival, growth, fragmentation (SC4–SC5), and sexual reproduction (SC4–SC5, ♀) operating at each annual time step. The model equation **N**(*t*+1) = **S** · (**T** + **F**) · **N**(*t*) + **R** describes stage-structured population projection, where **S** = survival, **T** = size-class transitions, **F** = fragmentation, and **R** = recruitment. Three management decision points (amber pills) correspond to analyses in subsequent figures: allocation proportion between orchard and direct reef outplanting (*prop*; Fig. 3), laboratory retention duration (*retain*; Fig. 4), and outplanting size class (*size*; Fig. 5). Laboratory parameters include tile capacity (*K*_lab = 3,100), immediate outplanting survival (*s*₀ = 0.95), and 1-year retention survival (*s*₁ = 0.70). Reef population dynamics include density-dependent survival (*S* = exp(−*m*₁ · *N*)) and stochastic disturbance regimes (none, 5-year, or 3-year return intervals). Coral silhouettes illustrate the characteristic palmate branching morphology of *A. palmata* at increasing colony sizes. Coral illustration: Tracey Saxby, Integration and Application Network (ian.umces.edu), CC BY-SA 4.0.
