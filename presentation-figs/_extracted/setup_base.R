## AUTO-EXTRACTED setup chunks from rse_new_scenario_analyses.rmd (do not edit; regenerate via extract)

# command + option + i for new code chunk
# command + shift + enter to run entire code chunk
# command + enter to run single line of code

# load packages
library(tidyverse) # command + shift + m for %>%
library(tictoc)

# load the model functions
source("coral_demographic_funs.R")
source("rse_funs.R")

library(popbio) # for elasticity analyses (from https://cran.r-project.org/web/packages/popbio/popbio.pdf)


# NOTE: Data files are stored in the separate Detmer-2025-coral-parameters repository.
# Update DATA_PATH to point to your local copy of that repository.
DATA_PATH <- "../Detmer-2025-coral-parameters"

# fragmentation data
apal_frag_summ <- read.csv(file.path(DATA_PATH, "05_data/standardized/apal_fragmentation_summ.csv"))
apal_frag <- read.csv(file.path(DATA_PATH, "05_data/standardized/apal_fragmentation.csv"))


# survival data
field_surv <- readRDS(file.path(DATA_PATH, "parameter_lists/field_surv_pars.rds"))
nurs_surv <- readRDS(file.path(DATA_PATH, "parameter_lists/nurs_surv_pars.rds"))
lab_surv <- readRDS(file.path(DATA_PATH, "parameter_lists/lab_surv_pars.rds"))

# recruit survival
recruit_surv <- readRDS(file.path(DATA_PATH, "parameter_lists/recruit_surv_pars.rds"))

# growth data
field_growth <- readRDS(file.path(DATA_PATH, "parameter_lists/field_growth_pars.rds"))
nurs_growth <- readRDS(file.path(DATA_PATH, "parameter_lists/nurs_growth_pars.rds"))
lab_growth <- readRDS(file.path(DATA_PATH, "parameter_lists/lab_growth_pars.rds"))

# short-term lab survival data
apal_lab_short_surv <- read.csv(file.path(DATA_PATH, "05_data/standardized/apal_surv_lab_short.csv"))


# change 1: format the growth data to be formatted as transition matrices and add these to the growth lists
field_Tmats <- growth_format(growth_dt = field_growth)
field_growth$mat_list <- field_Tmats$mat_list
field_growth$summ_list <- field_Tmats$summ_list

# nurs_Tmats <- growth_format(growth_dt = nurs_growth)
# nurs_growth$mat_list <- nurs_Tmats$mat_list
# nurs_growth$summ_list <- nurs_Tmats$summ_list

# TEMPORARY NEED TO FIX: currently don't have a trans_summary for the nursery data so just sub the field data for now
nurs_growth$mat_list <- field_Tmats$mat_list
nurs_growth$summ_list <- field_Tmats$summ_list


# update formatting of the recruit survival to match field survival data
recruit_surv$SC_surv_df <- data.frame(
  prop_survived = recruit_surv$survival_boot,
  size_class = rep(1, length(recruit_surv$survival_boot)),
  replicate = c(1:length(recruit_surv$survival_boot))
)

recruit_surv$SC_surv_summ_df <- recruit_surv$survival_summary %>% rename(mean = mean_survival, sd = sd_survival) %>% select(-ci_lower, -ci_upper)
size_class_col <- data.frame(
  size_class = rep(1, nrow(recruit_surv$SC_surv_summ_df))
)

recruit_surv$SC_surv_summ_df <- cbind(size_class_col, recruit_surv$SC_surv_summ_df)




# set upt the orchard, reef, and lab treatments
orchard_treatments <- c("orchard1") # orchards (could have multiple orchards and/or orchards with different post-outplanting treatments)
reef_treatments <- c("reef1") # reef treatments/subpopulations (e.g., could have "urchin outplanting" or "algal removal" or other postoutplanting treatments)
lab_treatments <- c("0_T1", "1_T1") # lab treatments "TX" is tile type/treatment, "X_" indicates whether recruits are outplanted immediately (0_) or the next year (0_1)


# demographic parameters for each orchard and reef
field_surv1 <- field_surv
recruit_surv1 <- recruit_surv # recruit survival rates in field (= reef)
field_growth1 <- field_growth
nurs_surv1 <- nurs_surv
nurs_growth1 <- nurs_growth

# calculate mean parameter values (survival, growth, shrinkage, fragmentation) for each 
all_pars <- default_pars_fun(n_reef = length(reef_treatments), n_orchard = length(orchard_treatments), n_lab = length(lab_treatments), summ_metric_list = list(field_surv = "mean", recruit_surv = "mean", field_growth = "mean", field_shrink = "mean", field_frag = "mean", nurs_surv = "mean", nurs_growth = "mean", nurs_shrink = "mean"), field_surv1, recruit_surv1, field_growth1, nurs_surv1, nurs_growth1, apal_frag_summ)


# calculate random parameter sets
n_sample1 <- 100 # number of parameter sets

set.seed(500)
all_pars_R <- rand_pars_fun(n_reef = length(reef_treatments), n_orchard = length(orchard_treatments), n_lab = length(lab_treatments), n_sample = n_sample1, field_surv = field_surv1, recruit_surv = recruit_surv1, field_growth = field_growth1, nurs_surv = nurs_surv1, nurs_growth = nurs_growth1, apal_frag)



years <- 51 # number of years in simulation
n <- 5 # number of size classes

# define size class boundaries
SC1 <- 0
SC2 <- 10
SC3 <- 100
SC4 <- 900
SC5 <- 4000

A_mids <- c((SC1 + SC2)/2, (SC2 + SC3)/2, (SC3 + SC4)/2, (SC4 + SC5)/2, 9325) # midpoint areas of each size class (cm^2); last value is the 50% quantile of observations greater than SC5 in the standardized data from the literature

A_reef <- mean(c(4492.011, 10076.67, 8943.55)) # area of the reef (very rough estimates from kml file of Fundemar's sites)


# reef parameters: survival
surv_pars.r <- all_pars$surv_pars.r
surv_pars.rc <- all_pars$surv_pars.rc

surv_pars.r_def <- surv_pars.r
surv_pars.rc_def <- surv_pars.rc

# reef parameters: growth
growth_pars.r <- all_pars$growth_pars.r
# reef parameters: shrinkage
shrink_pars.r <- all_pars$shrink_pars.r
# reef parameters: fragmentation
frag_pars.r <- all_pars$frag_pars.r

# density dependent survival (within first year post-outplanting only)
dens_pars.r <- list()
dens_pars.r[[1]] <- list() # first reef treatment/subpop
dens_pars.r[[1]][[1]] <- 0.026 # first source to first reef (external recruits)
dens_pars.r[[1]][[2]] <- dens_pars.r[[1]][[1]] # second source to first reef (tiles outplanted immediately)
dens_pars.r[[1]][[3]] <- dens_pars.r[[1]][[1]] # third source to first reef (tiles retained in lab)
dens_pars.r_def <- dens_pars.r

# reef fecundity
fec_pars.r <- list()
fec_pars.r[[1]] <- list()
fec_pars.r[[1]][[1]] <- c(0, 0, 3180, 67002, 521901)
fec_pars.r[[1]][[2]] <- fec_pars.r[[1]][[1]]
fec_pars.r[[1]][[3]] <- fec_pars.r[[1]][[1]]

# orchard parameters: survival
surv_pars.o <-all_pars$surv_pars.o 
# orchard parameters: growth
growth_pars.o <- all_pars$growth_pars.o
# orchard parameters: shrinkage
shrink_pars.o <- all_pars$shrink_pars.o
# orchard parameters: fragmentation
frag_pars.o <- all_pars$frag_pars.o

# density dependent survival (smallest size class only for now)
dens_pars.o <- list()
dens_pars.o[[1]] <- list() # first orchard
dens_pars.o[[1]][[1]] <- 0.026
dens_pars.o[[1]][[2]] <- dens_pars.o[[1]][[1]]

# orchard parameters: fecundity
fec_pars.o <- list()
fec_pars.o[[1]] <- list() # first treatment
fec_pars.o[[1]][[1]] <- c(0, 0, 3180, 67002, 521901)# first source
fec_pars.o[[1]][[2]] <- c(0, 0, 3180, 67002, 521901)# second source

lambda <- 0 # external recruitment to reef
lambda_def <- lambda

lambda_R <- 1255111 # babies collected from the reference reef each year; from Table 1 of Fundemar's report (total embryos collected in 2025)

# stochasticity parameters
sigma_s <- 0 # sd in in survival
sigma_f <- 0 # sd in fecundity
ext_rand <- c(FALSE, FALSE) # whether 1) external recruitment and 2) reference reef reproduction is stochastic 
seeds <- c(1000, 5000, 10000, 40000)


# disturbance parameters
dist_yrs <- NA# years when disturbance occurs

# effects of disturbance on each reef subpop
dist_effects.r <- list()
dist_effects.r[[1]] <- list() # list where each element is the effects of disturbance on corals from each source in the 1st reef subpop (either "survival" for survival, "Tmat" for growth/survival, "Fmat" for fragmentation, or "fecundity" for reproduction)
dist_effects.r[[1]][[1]] <- list() # effects of disturbances on corals from first source in first reef subpop
dist_effects.r[[1]][[1]][[1]] <- c("survival") # [[1]][[1]][[x]] = effects of xth disturbance on corals from first source in first reef subpop
dist_effects.r[[1]][[2]] <- list() # second source
dist_effects.r[[1]][[2]][[1]] <- c("survival")
dist_effects.r[[1]][[3]] <- list() # third source
dist_effects.r[[1]][[3]][[1]] <- c("survival")



# disturbance severity (survival parameters in disturbance year)
DS.r <- surv_pars.r
DS.r[[1]][[1]] <- DS.r[[1]][[1]]*0.1
DS.r[[1]][[2]] <- DS.r[[1]][[2]]*0.1
DS.r[[1]][[3]] <- DS.r[[1]][[3]]*0.1

DS.rc <- surv_pars.rc
DS.rc[[1]][[1]] <- DS.rc[[1]][[1]]*0.1
DS.rc[[1]][[2]] <- DS.rc[[1]][[2]]*0.1
DS.rc[[1]][[3]] <- DS.rc[[1]][[3]]*0.1

DS.o <- surv_pars.o
DS.o[[1]][[1]] <- DS.o[[1]][[1]]*1
DS.o[[1]][[2]] <- DS.o[[1]][[2]]*1

# disturbance parameters for each reef subpop (what happens to the population parameters at each disturbance eve)
dist_pars.r <- list()

# first reef population
dist_pars.r[[1]] <- list() 
# first source to first reef subpop
dist_pars.r[[1]][[1]] <- dist_pars_fun(dist_yrs = dist_yrs, dist_effects.r[[1]][[1]], dist_surv0 = list(DS.r[[1]][[1]]), dist_surv_rc0 = list(DS.rc[[1]][[1]]), dist_Tmat0 = NULL, dist_Fmat0 = NULL, dist_fec0 = NULL) # list of disturbance parameters for the first source to the first reef population (defaults for each parameter type are NULL unless the disturbance affects them, as specified in dist_effects)
# second source to first reef subpop (lab tiles)
dist_pars.r[[1]][[2]] <- dist_pars_fun(dist_yrs = dist_yrs, dist_effects.r[[1]][[2]], dist_surv0 = list(DS.r[[1]][[2]]), dist_surv_rc0 = list(DS.rc[[1]][[2]]), dist_Tmat0 = NULL, dist_Fmat0 = NULL, dist_fec0 = NULL)
dist_pars.r[[1]][[3]] <- dist_pars_fun(dist_yrs = dist_yrs, dist_effects.r[[1]][[3]], dist_surv0 = list(DS.r[[1]][[3]]), dist_surv_rc0 = list(DS.rc[[1]][[3]]), dist_Tmat0 = NULL, dist_Fmat0 = NULL, dist_fec0 = NULL)


# disturbance effects for each orchard subpop
dist_effects.o <- list()

dist_effects.o[[1]] <- list() 
dist_effects.o[[1]][[1]] <- list() 
dist_effects.o[[1]][[1]][[1]] <- c("survival") 
dist_effects.o[[1]][[2]] <- list() 
dist_effects.o[[1]][[2]][[1]] <- c("survival") 

# disturbance parameters for each orchard subpop
dist_pars.o <- list()

# first orchard treatment
dist_pars.o[[1]] <- list() 
# first source in first orchard treatment
dist_pars.o[[1]][[1]] <- dist_pars_fun(dist_yrs = dist_yrs, dist_effects.o[[1]][[1]], dist_surv0 = list(DS.o[[1]][[1]]), dist_Tmat0 = NULL, dist_Fmat0 = NULL, dist_fec0 = NULL) 
# second source in first orchard
dist_pars.o[[1]][[2]] <- dist_pars_fun(dist_yrs = dist_yrs, dist_effects.o[[1]][[2]], dist_surv0 = list(DS.o[[1]][[2]]), dist_Tmat0 = NULL, dist_Fmat0 = NULL, dist_fec0 = NULL) 


# lab parameters
# fractions of settled larvae in each lab treatment that survive to immediate outplanting each year
s0 <- matrix(NA, nrow = years, ncol = 2)
s0[,1] <- rep(0.98, years)
s0[,2] <- rep(0.98, years)

#s0[10,1] <- 0.05
#s0[10,2] <- 0.05

# fractions of settled larvae in each lab treatment that survive to 1 yr outplanting
s1 <- matrix(NA, nrow = years, ncol = 2)
s1[,1] <- rep(0.7, years)
s1[,2] <- rep(0.7, years)

m0 <- c(0.02, 0.02) # density dependent mortality rate of larvae in each lab treatment that get outplanted immediately
m1 <- c(0.02, 0.02) # density dependent mortality rate of larvae in each lab treatment that get outplanted after 1 year
#sett_props <- list(T1 = 0.15, T2 = 0.15) # proportion of larvae that settle on each tile type
sett_props <- list(T1 = 0.15) # proportion of larvae that settle on each tile type
size_props <- matrix(NA, nrow = length(lab_treatments), ncol = n) # matrix for fractions of retained recruits in each size class at the end of their year in the lab
size_props[1, ] <- c(1, 0, 0, 0, 0) # first lab treatment 
#size_props[2, ] <- c(1, 0, 0, 0, 0) # second lab treatment 
size_props1 <- matrix(NA, nrow = length(lab_treatments), ncol = n) # matrix for fractions of retained recruits in each size class at the end of their year in the lab
#size_props1[1, ] <- c(1, 0, 0, 0, 0) # first lab treatment 
size_props1[2, ] <- c(1, 0, 0, 0, 0) # second lab treatment 

lab_pars <- list(s0 = s0, s1 = s1, m0 = m0, m1 = m1, sett_props = sett_props, size_props = size_props, size_props1 = size_props1)

# save as default
lab_pars_def <- lab_pars

# restoration strategy parameters
tile_props <- list(T1 = 1) # proportion of tiles that are each type
orchard_yield <- 0.72 # percent of new orchard babies successfully collected
reef_yield <- 0.72 # percent of new reef babies successfully collected and fertilized
spawn_target <- 2000000 # target number of embryos to collect from orchard each year (note: if this is set to zero, there won't be any settlers)
reef_prop <- c(0.5, 1) # proportion of lab recruits from each lab treatment outplanted to reef (1-proportion outplanted to orchard)
reef_out_props <- matrix(NA, nrow = length(lab_treatments), ncol = length(reef_treatments)) # proportion recruits going from each lab treatment to each reef treatment (row = origin lab treatment, column = destination reef treatment)
reef_out_props[1,] <- c(1) # from first lab treatment to each reef treatment (here there's just on intervention reef so they all go there)
reef_out_props[2,] <- c(1) # from second lab treatment to each reef treatment 

orchard_out_props <- matrix(NA, nrow = length(lab_treatments), ncol = length(orchard_treatments)) # proportion recruits going from each lab treatment to each orchard treatment
orchard_out_props[1,] <- c(1) # from first lab treatment to each orchard 
orchard_out_props[2,] <- c(1) # from second lab treatment to each orchard 

# sizes allocated to each treatment
reef_areas <- c(A_reef)*10000 # m^2 given to each post-outplanting reef treatment/subpopulation, convert to cm^2 by multiplying by 10,000
lab_max <- 4000 # total number of tiles that the lab can accommodate 
lab_retain_max <- 0 # 3100*0.5 # total number of tiles that the lab can keep for a year (must be less than or equal to lab_max; if > 0 then must have at least one "1_" lab treatment, if equal to lab max then must have all treatments be "1_")
tank_min <- 14600 # min number of embryos to put in a tank 
tank_max <- 33333 # max number of embryos to put in a tank

orchard_size <- c(30*500) # number of tiles each orchard has space for (500 stars x 30 tiles per star)

# coral transplanting
transplant <- rep(0, years) # years in which corals get transplanted from the orchard
#transplant[10] <- 1 # in 10th year, move corals from orchard to reef

# null_mat <- matrix(0, nrow = years, ncol = n)
null_mat <- matrix(c(0, 0.75*orchard_size, 0, 0, 0), nrow = years, ncol = n, byrow = T)
#trans_mats[[1]][[1]][which(transplant!=0)[1],] <- c(0, 0, 0, 2,0)# max number of colonies of each size class to move to reef in first transplant event
trans_mats <- list()
trans_mats[[1]] <- list() # first orchard 
trans_mats[[1]][[1]] <- null_mat # number of corals in each size class that originated from the first source of colonies for this orchard to transplant at each timepoint
trans_mats[[1]][[2]] <- null_mat # number of corals in each size class that originated from the second source of colonies for this orchard to transplant at each timepoint

# where on the reef to put the transplants
#trans_reef[[1]][[1]][which(transplant!=0)[1],] <- c(1, 1)# reef and source subpop to transport the corals to
trans_reef <- list()
trans_reef[[1]] <- list() # first orchard
trans_reef[[1]][[1]] <- matrix(c(1, 2), nrow = years, ncol = 2, byrow = T) # first source corals in this orchard get transplanted to the second source of corals in the first reef
trans_reef[[1]][[2]] <- matrix(c(1, 3), nrow = years, ncol = 2, byrow = T) # second source corals in this orchard get transplanted to the third source of corals in the second reef

trans_surv <- c(1, 1, 1, 1, 1) # proportion of colonies of each size class that survival transplanting

rest_pars <- list(tile_props = tile_props, orchard_yield = orchard_yield, reef_yield = reef_yield, spawn_target = spawn_target, reef_prop = reef_prop, reef_out_props = reef_out_props, orchard_out_props = orchard_out_props, reef_areas = reef_areas, lab_max = lab_max, lab_retain_max = lab_retain_max, tank_min = tank_min, tank_max = tank_max, orchard_size = orchard_size, transplant = transplant, trans_mats = trans_mats, trans_reef = trans_reef, trans_surv = trans_surv)

# save as default
rest_pars_def <- rest_pars

# initial conditions in each reef subpopulation
N0.r <- list()
N0.r[[1]] <- list() # second reef subpop
# N0.r[[1]][[1]] <- rep(0, n) # first source (external recruits)
N0.r[[1]][[1]] <- c(1, 0, 0,0,0) # first source (external recruits)
N0.r[[1]][[2]] <- rep(0, n) # second source
N0.r[[1]][[3]] <- rep(0, n) # third source

# initial conditions in each orchard subpopulation
N0.o <- list()
N0.o[[1]] <- list() # first orchard treatment
N0.o[[1]][[1]] <- rep(0, n) # first source
N0.o[[1]][[2]] <- rep(0, n) # second source

N0.l <- list()
N0.l[[1]] <- 1000 # start with some babies in the lab
N0.l[[2]] <- 0 

# save as defaults
N0.r_def <- N0.r
N0.o_def <- N0.o
N0.l_def <- N0.l

sim1 <- rse_mod1(years, n, A_mids, surv_pars.rc, surv_pars.r, dens_pars.r, growth_pars.r, shrink_pars.r, frag_pars.r, fec_pars.r, surv_pars.o, dens_pars.o, growth_pars.o, shrink_pars.o, frag_pars.o, fec_pars.o, lambda, lambda_R, sigma_s, sigma_f, ext_rand, seeds, dist_yrs, dist_pars.r, dist_effects.r, dist_pars.o, dist_effects.o, orchard_treatments, reef_treatments, lab_treatments, lab_pars, rest_pars, N0.r, N0.o, N0.l)

