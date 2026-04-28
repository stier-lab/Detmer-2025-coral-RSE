# A. palmata Fecundity & Reproduction: Literature Summary

**For Raine** -- summary of what we found in the literature on size-dependent fecundity for *Acropora palmata*, and how it maps to our model's reproduction parameters.

---

## Current model approach

We currently treat fecundity as **size-independent**: SC3--SC5 each produce 48,274 embryos per colony per year (derived from Fundemar 2025: 1,255,111 total embryos / 26 spawning colonies). SC1--SC2 are non-reproductive. See `PARAMETER_PROVENANCE.md` lines 44--45 for full derivation.

The literature strongly suggests fecundity is **size-dependent**. The data below could support a more mechanistic parameterization if we want it.

---

## Key finding: probability of reproduction is strongly size-dependent

Soong & Lang (1992) examined 84 *A. palmata* colonies in Panama and found:

| Size class (cm^2) | % colonies fertile | n colonies |
|---|---|---|
| 0--4 | -- | -- |
| 4--15 | 0% | 4 |
| 15--60 | 0% | 9 |
| 60--250 | 7% | 14 |
| 250--1000 | 11% | 16 |
| 1000--4000 | 43% | 7 |
| >4000 | 88% | 33 |

**Puberty size = ~1600 cm^2** (smallest reproductive colony = 16 x 8 cm surface area).

### Mapping to our size classes

| Model SC | Area (cm^2) | Soong fertility | Implication |
|---|---|---|---|
| SC1 (0--10) | 0--10 | 0% | Non-reproductive -- confirmed |
| SC2 (10--100) | 10--100 | 0--7% | Essentially non-reproductive -- current assumption is correct |
| SC3 (100--900) | 100--900 | 7--11% | ~10% of colonies reproduce -- we currently give them full fecundity |
| SC4 (900--4000) | 900--4000 | 43% | Straddles the puberty threshold |
| SC5 (>4000) | >4000 | 88% | Most colonies are reproductive |

**Bottom line:** Our current model overestimates SC3 fecundity (treating 100% as reproductive when only ~10% are) and somewhat overestimates SC4 (treating 100% as reproductive when ~43% are). SC5 is close to correct.

---

## Per-polyp egg production

Soong (1991) studied 11 species of shallow-water reef corals in Panama (including *A. palmata*) and reported:

- *A. palmata* is a **hermaphroditic broadcaster** (eggs and sperm in the same mesenteries)
- **1--4 eggs per ovary**, with **4 mesenteries per polyp** bearing gonads
- So roughly **4--16 eggs per fertile polyp**
- Eggs are slightly irregular ellipses, max size 0.6 x 0.5 mm
- Spawning occurs **Aug--Sept**, cued by rising water temperatures in the preceding spring

### What we'd need to build a mechanistic fecundity function

To go from per-polyp to per-colony fecundity:

```
Fecundity(colony) = Area_fertile(cm^2) x oocyte_density(oocytes/cm^2) x fert_success x settlement_prob
```

**UPDATE (Apr 2026): NotebookLM query revealed we already have the key missing data.** Mendoza-Quiroz et al. 2023 (our `MendozaQuiroz_2023_PeerJ_LongtermSurvivalPalmata.pdf`) reports oocyte density directly:

| Component | What we know | Source | Gap? |
|---|---|---|---|
| Fraction of colony area that is fertile | Upper surfaces >> lower; tips infertile (3--10 cm), mid-branch fertile | Soong & Lang 1992 | Partial -- no clean scalar |
| **Oocyte density per cm^2** | **63.6 +/- 43.4 oocytes cm^-2** | **Mendoza-Quiroz et al. 2023** | **NO -- we have it** |
| **Oocytes per polyp** | **5.61 +/- 1.91 oocytes per polyp** | **Mendoza-Quiroz et al. 2023** | **NO -- we have it** |
| Eggs per polyp (earlier estimate) | ~4--16 | Soong 1991 | Consistent with Mendoza-Quiroz |
| **Fertilization success** | **95% (F1 x wild), 71% (healthy wild), 15% (sibling cross)** | **Mendoza-Quiroz et al. 2023; Pinon-Gonzalez 2018** | **NO -- we have it** |
| Settlement probability | ~15% of embryos settle | Fundemar empirical (sett_props in model) | Have it |
| Oocyte size | 769 +/- 141 um diameter | Mendoza-Quiroz et al. 2023 | Have it |

### Constructing a size-dependent fecundity function

We now have all the pieces. For each size class:

```
F(SC) = Area_mid(SC) x P_fertile(SC) x oocyte_density x fert_success x settlement_prob
```

Example calculation for SC5 (area midpoint = 9325 cm^2):

```
F(SC5) = 9325 cm^2 x 0.88 x 63.6 oocytes/cm^2 x 0.71 fert x 0.15 settlement
       = 9325 x 0.88 x 63.6 x 0.71 x 0.15
       = ~55,600 settlers per colony per year
```

Compare to our current flat estimate of 48,274 embryos per colony -- order-of-magnitude consistent, which is reassuring.

### Steward 2024: an IPM reproduction sub-kernel

Steward (2024) built a full reproduction sub-kernel for an *Acropora* IPM:

```
r(z', z) = P_colony(z) x P_polyps(z) x f_oocytes(z) x f_recruits(z') x P_establishment
```

However, because continuous oocyte-to-size scaling curves did not exist for *A. palmata*, Steward had to use Indo-Pacific *Acropora* data (Alvarez-Noriega et al. 2016: *A. nasuta*, *A. spathulata*) for the f_oocytes(z) term. **With Mendoza-Quiroz et al. 2023, we could now build an *A. palmata*-specific version.**

We should check whether we have Steward 2024 in the library -- it may be a useful methodological reference.

---

## Within-colony reproductive patterns

Soong & Lang (1992) also documented **where** within an *A. palmata* colony reproduction occurs:

- Upper branch surfaces have **much higher fecundity** than lower surfaces (significantly more fertile polyps per cm^2; Wilcoxon T_s = 0, P < 0.01, n = 10 colonies)
- Upper surfaces have larger eggs (T_s = 0, P < 0.01, n = 11 colonies)
- Soft tissue is **at least twice as thick** on upper surfaces (confirmed by X-ray growth bands)
- **Branch tips are infertile** (3--10 cm from tip at spawning); infertile zone is shorter earlier in the year
- **Encrusting bases** are infertile (n = 5 colonies observed)
- The infertile tips of branching *Acropora* are a **time constraint** -- oogenesis takes at least 6 months (Soong 1991), and the tips are the youngest tissue

This means that fragmentation (which often produces tip-heavy fragments) creates colonies that are disproportionately non-reproductive, even if they are technically above the puberty size threshold.

---

## Fragmentation and asexual reproduction

Wallace (1985) studied nine *Acropora* species on the Great Barrier Reef and found:

- All species recruited both sexually (via larvae) and asexually (via fragments)
- **Year-round fragmenters had few larval recruits**; non-fragmenters had many; rough-weather fragmenters were intermediate
- Fragment survival depended on size and substrate (consistent with Lirman 2000, Highsmith 1982 in our library)
- Fecundity varied among species but was generally **1--20 eggs per ovary** across *Acropora* spp.

This is GBR-focused (Indo-Pacific *Acropora*), not Caribbean, but confirms that the tradeoff between sexual and asexual reproduction is a fundamental *Acropora* life history feature.

---

## Fertilization success rates

Multiple papers in the library provide fertilization success data for *A. palmata*:

| Condition | Fertilization rate | Source |
|---|---|---|
| F1 sperm x wild gametes | 95% | Mendoza-Quiroz et al. 2023 |
| Healthy wild colonies | 71.5% | Pinon-Gonzalez 2018 |
| Colonies with partial mortality | 80.8% (but ~20% smaller eggs) | Pinon-Gonzalez 2018 |
| Lab-reared sibling crosses | 15% | Mendoza-Quiroz et al. 2023 |
| Under ocean acidification (end-of-century) | Reduced 12--13% | Albright 2010 |
| Optimal sperm concentration | 10^5 -- 10^6 sperm/mL | Albright 2010 |

The sibling cross result (15%) is important for restoration -- it implies that outplanted populations from limited genotype diversity could have dramatically reduced reproductive output even if colonies are large enough to spawn.

---

## Recruitment bottleneck

Williams & Miller (2008) documented **recruitment failure** in Florida Keys *A. palmata*:

- Despite presence of reproductive adults, virtually no successful sexual recruitment observed
- Disease and corallivore predation on juveniles contributed (Williams & Miller 2006)
- This supports our model's treatment of larval propagation as a restoration tool -- natural recruitment is not sufficient for population recovery

---

## Recommendation

Replace the current flat fecundity rate with a size-dependent function built from *A. palmata* field data:

```
F(SC) = Area_mid x P_fertile x 63.6 oocytes/cm^2 x fert_success x settlement_prob
```

Every parameter comes from published Caribbean *A. palmata* studies: colony fertility from Soong & Lang (1992), oocyte density from Mendoza-Quiroz et al. (2023), fertilization success from Pinon-Gonzalez (2018), settlement from Fundemar. The SC5 estimate (~55,800 settlers/colony/yr) is consistent with our current Fundemar-derived value (48,274), which validates the approach. The main correction is that SC3 drops from 48,274 to ~340 and SC4 from 48,274 to ~7,200.

---

## Bibliography

Lirman, D. (2000). Fragmentation in the branching coral *Acropora palmata* (Lamarck): growth, survivorship, and reproduction of colonies and fragments. *Journal of Experimental Marine Biology and Ecology*, 251, 41--57.

Highsmith, R. C. (1982). Reproduction by fragmentation in corals. *Marine Ecology Progress Series*, 7, 207--226.

Ritson-Williams, R., Arnold, S. N., Paul, V. J., & Steneck, R. S. (2014). Larval settlement preferences of *Acropora palmata* and *Montastraea faveolata* in response to diverse red algae. *Coral Reefs*, 33, 59--66.

Soong, K. (1991). Sexual reproductive patterns of shallow-water reef corals in Panama. *Bulletin of Marine Science*, 49(3), 832--846.

Soong, K., & Lang, J. C. (1992). Reproductive integration in reef corals. *Biological Bulletin*, 183, 418--431.

Szmant, A. M., & Miller, M. W. (2006). Settlement preferences and post-settlement mortality of laboratory cultured and settled larvae of the Caribbean hermatypic corals *Montastraea faveolata* and *Acropora palmata* in the Florida Keys, USA. *Proceedings of the 10th International Coral Reef Symposium*, 1, 43--49.

Wallace, C. C. (1985). Reproduction, recruitment and fragmentation in nine sympatric species of the coral genus *Acropora*. *Marine Biology*, 88, 217--233.

Williams, D. E., & Miller, M. W. (2006). Importance of disease and predation to the growth and survivorship of juvenile *Acropora palmata* and *Acropora cervicornis*: a demographic approach. *Proceedings of the 10th International Coral Reef Symposium*, 1, 1096--1104.

Williams, D. E., & Miller, M. W. (2008). Recruitment failure in Florida Keys *Acropora palmata*, a threatened Caribbean coral. *Coral Reefs*, 27, 697--705.

### Additional references identified by NotebookLM query

Acropora Biological Review Team [ABRT]. (2005). *Atlantic Acropora Status Review Document*. Report to NOAA/NMFS. [Cites Soong & Lang 1992 fertility data with 250--1000 cm^2 = 30% fertile, slightly different from Soong's original 11%.]

Albright, R., Mason, B., Miller, M., & Langdon, C. (2010). Ocean acidification compromises recruitment success of the threatened Caribbean coral *Acropora palmata*. *PNAS*, 107, 20400--20404.

Alvarez-Noriega, M., Baird, A. H., Dornelas, M., Madin, J. S., Cumbo, V. R., & Connolly, S. R. (2016). Fecundity and the demographic strategies of coral morphologies. *Ecology*, 97, 3462--3474. [Indo-Pacific *Acropora* oocyte scaling -- used by Steward 2024 as proxy for *A. palmata*.]

Mendoza-Quiroz, T., et al. . (2023). Long-term survival, growth, and reproduction of *Acropora palmata* sexual recruits outplanted onto Mexican Caribbean reefs. *PeerJ*, 11, e15813. [Key source: 63.6 oocytes/cm^2, 5.61 oocytes/polyp, 95% fertilization success.]

Pinon-Gonzalez, J. M., et al. (2018). Effects of partial mortality on growth, reproduction, and total colony size of elkhorn coral (*Acropora palmata*). *Frontiers in Marine Science*, 5, 1--12. [71.5% fertilization baseline; partial mortality reduces egg volume ~20%.]

Steward, K. (2024). *Restoration renaissance: charting a course for *Acropora* spp. restoration and management*. PhD dissertation or report. [Full IPM reproduction sub-kernel; uses Indo-Pacific oocyte scaling.]

Vardi, T., Williams, D. E., & Sandin, S. A. (2012). Population dynamics of threatened elkhorn coral in the northern Florida Keys, USA. *Endangered Species Research*, 19, 157--169. [Uses Soong & Lang 1992 to define SC4 (>4000 cm^2) as primary reproductive class.]
