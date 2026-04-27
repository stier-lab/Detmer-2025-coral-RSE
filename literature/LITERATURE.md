# RSE Fundemar — Literature Database

170 papers. Searchable index in `DATABASE.csv`. All PDFs in this folder.

---

## How to use this

- **DATABASE.csv** — open in Excel/Sheets. Columns: filename, author, year, title, journal, DOI, domain tags, whether it's in Zotero, whether it's a hero paper. Sort/filter by domain to find papers for a specific section.
- **Hero papers** — the 6 papers we're modeling the manuscript after. Read these first.
- **Sections below** — papers organized by where they appear in the manuscript. A paper can appear in multiple sections.

---

## Hero Papers

These are the papers we want this manuscript to read like. Each is grounded in a specific system but presents a generalizable framework.

| # | Paper | Journal | File | Role |
|---|-------|---------|------|------|
| 1 | Canessa et al. 2025 | Conservation Letters | `Canessa_2025_SimulatingDemographyMonitoringManagement.pdf` | Our structural template — MSE for hihi bird |
| 2 | Mullin et al. 2023 | J Wildlife Management | `Mullin_2023_HeadstartingDiminishingReturns.pdf` | Grow-out with diminishing returns (turtles) |
| 3 | Lorenzen 2000 | Can J Fish Aquat Sci | `Lorenzen_2000_OptimalReleaseSize.pdf` | Size-at-release theory |
| 4 | Moore et al. 2018 | Ecological Applications | `Moore_2018_OysterRestorationDensityDependence.pdf` | Marine restoration + density dependence (oysters) |
| 5 | Chamberland et al. 2015 | Global Ecol Conserv | `Chamberland_Rest_Restoration_critically_endangered_elkhorn.pdf` | Empirical A. palmata sexual propagation |
| 6 | Weijerman et al. 2016 | PLOS ONE | `Weijerman_2016_MSE_CoralReefs.pdf` | Only prior coral reef MSE |

### What to take from each

**Canessa 2025** — Follow their three-tier arc (Frame → Simulate → Compare). Build a strategy comparison table like their Table 1. Their Figure 2 (jittered dots by strategy × objective) is cleaner than petal plots.

**Mullin 2023** — Our grow-out punchline in another taxon. Bigger is better but diminishing returns. When facility capacity is fixed, 1-yr and 2-yr headstarts converge. Directly parallels our SC1 vs SC2 × lab capacity question.

**Lorenzen 2000** — Mortality ∝ length^(−1) across stocked fish. General allometric law. Grounds our size-class survival differences in theory that spans taxa.

**Moore 2018** — Stocking with larger oysters is 3× more efficient than spat. Also compares stock enhancement vs habitat enhancement — maps onto our outplanting vs orchard comparison. Density dependence creates restoration thresholds.

**Chamberland 2015** — The empirical counterargument. Early outplanting of *A. palmata* yielded 6.8× higher survival at 1/25th the cost ($13 vs $325). If our model recommends grow-out, we must show when and why despite this evidence.

**Weijerman 2016** — Only prior coral MSE. Used Atlantis (ecosystem model) for Hawaiian reefs. We bring MSE to population-level with species-specific practitioner decisions. Position against in Introduction.

---

## Papers by Manuscript Section

### Introduction — Why RSE exists

*The problem:* coral restoration lacks structured decision tools.

| Paper | Why cite |
|-------|---------|
| Edmunds & Riegl 2020 (`Edmunds_Urge_Urgent_need_coral_demography.pdf`) | Calls for demographic models to evaluate restoration — our paper delivers this |
| Bunnefeld et al. 2011 (`Bunnefeld_2011_MSE_Conservation.pdf`) | MSE should move from fisheries to conservation — our paper answers this call |
| Bostrom-Einarsson et al. 2020 (`Bostrom-Einarsson_2020_CoralRestorationReview.pdf`) | 362 case studies, establishes field context, documents lack of modeling |
| Bayraktarov et al. 2019 (`Bayraktarov_Moti_Motivations_success_cost_coral.pdf`) | Global restoration costs ($12K–$2.9M/ha), most projects short-duration |
| Suggett et al. 2024 (`Suggett_2024_RestorationMeaningfulAid.pdf`) | Restoration meaningfully aids recovery — counters scaling critics |
| Hughes et al. 2017 (need to download) | "Coral reefs in the Anthropocene" — why management under decline, not return to baseline |
| Anthony et al. 2017 (need to download) | "New interventions needed" — portfolio of interventions, our model evaluates components |

*The framework:* MSE lineage.

| Paper | Why cite |
|-------|---------|
| Punt et al. 2014 (`Punt_2014_MSE_BestPractices.pdf`) | MSE best practices — the canonical reference (608 citations) |
| Weijerman et al. 2016 (`Weijerman_2016_MSE_CoralReefs.pdf`) | Only prior coral reef MSE |
| Canessa et al. 2025 (`Canessa_2025_SimulatingDemographyMonitoringManagement.pdf`) | Conservation MSE template |
| Lorenzen 2005 (`Lorenzen_2005_StockEnhancement.pdf`) | Fisheries stock enhancement — the theoretical bridge to restoration |

### Methods — Model structure and parameterization

*Model framework:*

| Paper | Why cite |
|-------|---------|
| Hughes 1984 (`Hughes_1984_PopulationDynamicsSize.pdf`) | Bedrock paper for size-based coral matrix models |
| Vardi et al. 2012 (`Vardi_Popu_Population_dynamics_threatened_elkhorn.pdf`) | Stage-structured model for *A. palmata* — we extend this directly |
| Lirman 2003 (`Lirman_2003_SimulationAcropora.pdf`) | Earlier *A. palmata* simulation model — compare projections |
| Babcock 1991 (`Babcock_Comp_Comparative_Demography_Three_Species.pdf`) | Comparative coral demography using age/size |

*Vital rates — survival, growth, fragmentation:*

| Paper | Why cite |
|-------|---------|
| Forrester et al. 2014 (`Forrester_Long_Longterm_survival_colony_growth.pdf`) | 7-yr transplant tracking: survival is size-dependent, growth is not |
| Lirman 2000 (`Lirman_Frag_Fragmentation_branching_coral_Acropora.pdf`) | Fragment survivorship by size and substrate (58% loss on sand) |
| Highsmith 1982 (`Highsmith_1982_ReproductionFragmentation.pdf`) | Foundational fragmentation biology |
| Chamberland et al. 2015 (`Chamberland_Rest_Restoration_critically_endangered_elkhorn.pdf`) | Sexual recruit survival rates (86% mortality in 6 months) |
| Mercado-Molina et al. 2015 (`Mercado-Molina_2015_DemographyCervicornis.pdf`) | *A. cervicornis* demography — sister species comparison |
| Schopmeyer et al. 2017 (`Schopmeyer_2017_RestorationBenchmarks.pdf`) | Regional benchmarks: >80% nursery, >70% outplant survival |

*Density dependence:*

| Paper | Why cite |
|-------|---------|
| Griffin et al. (`Griffin_Dens_Densitydependent_effects_initial_growth.pdf`) | DD in branching coral restoration |
| Ladd et al. (`Ladd_Dens_Density_Dependence_Drives_Habitat.pdf`) | DD drives habitat production in *A. cervicornis* |
| Vermeij et al. (`Vermeij_Dens_DensityDependent_Settlement_Mortality_Structure.pdf`) | DD settlement and mortality |

*Disturbance:*

| Paper | Why cite |
|-------|---------|
| Rogers (`Rogers_Effe_Effects_Hurricanes_David_Frederic.pdf`) | Hurricane effects on *A. palmata* — empirical baseline |
| Speare et al. 2022 (`Speare_Size_Sizedependent_mortality_corals.pdf`) | Size-dependent mortality during marine heatwaves — our disturbance × size interaction |

*Cost model:*

| Paper | Why cite |
|-------|---------|
| Bayraktarov et al. 2019 | Global cost benchmarks |
| Chamberland et al. 2015 | $13 vs $325 per coral (early vs nursery grow-out) |
| Scott et al. 2024 (`Scott_2024_CostEffectivenessCoralPlanting.pdf`) | Per-colony cost data from scaled program ($12–$248) |
| Suggett et al. 2019 (`Suggett_Opti_Optimizing_returnoneffort_coral_nursery.pdf`) | Return-on-effort framework |

### Results — Scenario comparisons

*Scenario 1 — Orchard allocation:*

| Paper | Why cite |
|-------|---------|
| Nedimyer et al. 2011 (`Nedimyer_2011_CoralTreeNursery.pdf`) | The in-water nursery concept our orchard models |
| Lirman & Schopmeyer 2016 (`Lirman_2016_EcologicalSolutionsReefDegradation.pdf`) | Caribbean *Acropora* nursery optimization |
| Moore et al. 2018 | Stock enhancement vs habitat enhancement — same tradeoff |

*Scenario 2 — Lab grow-out:*

| Paper | Why cite |
|-------|---------|
| Lorenzen 2000 | Size-at-release theory (allometric mortality) |
| Mullin et al. 2023 | Diminishing returns on grow-out duration (turtles) |
| Chamberland et al. 2015 | Early outplanting wins empirically — the counterargument |
| dela Cruz & Harrison 2017 (`delaCruz_2017_LarvalSupplyRecruitment.pdf`) | Mass larval settlement works at scale, $13/surviving juvenile |
| Heppell et al. 1996 (`Heppell_1996_HeadstartingTurtles.pdf`) | Headstarting evaluation with demographic models — precedent |

### Discussion — Generalizability and context

*Cross-system precedent (size-at-release is general):*

| Paper | Why cite |
|-------|---------|
| Lorenzen 2000 + 2005 | Fish: allometric mortality law |
| Mullin et al. 2023 | Turtles: diminishing returns |
| Moore et al. 2018 | Oysters: larger stocking more efficient |
| Canessa et al. 2023 (`Canessa_2023_OptimalReintroductionPlan.pdf`) | Newts: optimal life-stage for release |

*MSE in conservation:*

| Paper | Why cite |
|-------|---------|
| Canessa et al. 2016 (`Canessa_2016_AdaptiveManagement.pdf`) | AM across captive-wild spectrum |
| Canessa et al. 2019 (`Canessa_2019_AdaptiveMgmtSalamander.pdf`) | Real-world AM with Bayesian updating |
| Runge 2013 (`Runge_2013_AdaptiveManagementReintroduction.pdf`) | Active adaptive management theory |
| Converse et al. 2013 (`Converse_2013_DemographicsReintroduced.pdf`) | Demographics of reintroduced populations |

*Coral restoration context:*

| Paper | Why cite |
|-------|---------|
| van Woesik et al. 2021 (`vanWoesik_2021_DifferentialSurvivalOutplants.pdf`) | Spatial variation in outplant outcomes |
| Guest et al. 2014 (`Guest_2014_ClosingTheCircle.pdf`) | Sexual propagation feasibility ("closing the circle") |
| Drury et al. 2017 (`Drury_2017_GenotypeEnvironmentSurvivorship.pdf`) | Genotype × environment — the dimension we omit |
| Baums 2019 (`Baums_2019_AdaptiveVariationResilience.pdf`) | Adaptive variation for resilience |
| Banaszak et al. 2023 (`Banaszak_2023_LongtermSurvivalPalmata.pdf`) | 9-yr survival data for sexual *A. palmata* recruits |
| Banaszak et al. 2024 (`Banaszak_2024_ThermalToleranceSexualRecruits.pdf`) | Sexual recruits had higher thermal tolerance in 2023 bleaching |
| Nixon et al. 2025 (`Nixon_2025_RearingTechniquesSexualCorals.pdf`) | Multi-year rearing technique comparison |
| Vardi et al. 2021 (`Vardi_2021_SixPrioritiesRestoration.pdf`) | Six priorities for restoration science |
| Miller 2016 (`Miller_2016_ReefScaleTrendsAcropora.pdf`) | Reef-scale *Acropora* trends in Florida |

*Demographic modeling for marine restoration:*

| Paper | Why cite |
|-------|---------|
| Edmunds 2015 (need to download) | 25-yr size-transition matrix for Caribbean coral |
| Hall et al. 2021 (`Hall_2021_CoralSensitivityDisturbed.pdf`) | Elasticity analysis shifts under disturbance |
| Baskett et al. 2010 (`Baskett_2010_ConservationManagementCoralsClimateChange.pdf`) | Theoretical comparison of coral climate adaptation approaches |
| Melbourne-Thomas et al. 2011 (`Melbourne-Thomas_2011_CoralReefScenarioModeling.pdf`) | Coral reef scenario modeling as decision support |
| Carturan/Bozec et al. 2020 (`Carturan_2020_CombiningModelingApproaches.pdf`) | Agent-based + demographic modeling for Caribbean reefs |
| Matz et al. 2024 (`Matz_2024_SelectiveBreedingHeatTolerance.pdf`) | Selective breeding enhances thermal tolerance |

---

## Still need to download

| Paper | DOI | Why |
|-------|-----|-----|
| Edmunds 2015 — 25-yr demographic analysis, *Orbicella* | 10.1002/lno.10075 | Closest methodological parallel (size-transition matrix, Caribbean) |
| Mulla 2024 — Recovery despite negative lambda | 10.1002/ecy.4368 | Challenges simple lambda-based success metrics |
| Mumby et al. 2007 — Caribbean reef thresholds | 10.1038/nature06252 | Benchmark Caribbean reef simulation model |
| Anthony et al. 2017 — New interventions needed | 10.1038/s41559-017-0313-5 | Portfolio of coral interventions framework |

---

## Domain Summary

| Domain | Count | Coverage |
|--------|-------|----------|
| Restoration methods & practice | 55 | Strong |
| Vital rates (growth, survival, fragmentation) | 44 | Strong |
| Reef ecology (predation, herbivory, fish) | 34 | Strong — some tangential |
| Disturbance (bleaching, hurricanes, resilience) | 26 | Strong |
| Reproduction & recruitment | 25 | Good |
| *A. palmata* biology | 17 | Good |
| MSE & decision analysis | 14 | Good |
| Demographic models | 10 | Adequate |
| Costs & economics | 9 | Adequate |
| Density dependence | 7 | Adequate |
| *A. cervicornis* (sister species) | 4 | Sufficient |
| Genetics & assisted evolution | 3 | Thin (not our focus) |
| Size-at-release theory | 2 | Sufficient (Lorenzen covers theory) |

---

## NotebookLM

24 key sources loaded for AI querying:
https://notebooklm.google.com/notebook/0ad000ef-e1ec-481e-9250-553de0cf384b
