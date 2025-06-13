# README: functions for simulating the model


#' Function for generating the dataframes with the transition matrix parameters at each
#' time point in the simulation
#' Arguments:
#' @param years number of years in simulation
#' @param n number of size classes
#' @param surv_pars mean survival probabilities in each size class
#' @param growth_pars transition probabilities for each size class
#' @param frag_pars fragmentation probabilities for each size class
#' @param fec_pars mean fecundities of each size class
#' @param sigma_s standard deviation of survival probabilities
#' @param sigma_f standard deviation of survival probabilities
#' @param seeds vector with seeds for the random number generation for survival, fecundity, and recruitment

mat_data_fun <- function(years, n, surv_pars, growth_pars, frag_pars, fec_pars,
                         sigma_s, sigma_f, seeds){

  # survival dataframe
  S_df <- Surv_fun(years, n, surv_pars, sigma_s = 0, seed1 = seeds[1])

  # growth/shrinkage/fragmentation dataframe
  GSF_df <- GSF_fun(years, n, growth_pars, shrink_pars, frag_pars)

  # fecundity dataframe
  F_df <- Rep_fun(years, n, fec_pars, sigma_f = 0, seed1 = seeds[2])


  return(list(survival = S_df, growth = GSF_df, fecundity = F_df))

}


#' lab function
#' make a function that takes the number of new babies from the orchard as an input and
#' returns the number of outplants that can go to the reef
#' this may or may not be a full population dynamics model, but either way I think it can
#' be separate from the orchard and reef models

#' Population dynamics function
# arguments:
# dataframes
# orchard_treatments (named list, including "none")
# lab_treatments (named list)
# parameters for lab yields for the different treatments
# reef_treatments (named list, including "none")



# reef subpops = length(lab_treatments)*length(reef_treatments)

# lab subpops = length(lab_treatments)

# orchard subpopulations:
s_orchard <- length(orchard_treatments)
s_reef <- length(reef_treatments)*length(lab_treatments)

# set up holding matrices
# reef subpops
reef_pops <- list() # list with holding matrices for each reef subpopulation
reef_mat_dfs <- list() # list with data frames with the transition matrix parameters for each reef subpop

for(ss in 1:length(s_reef)){

  reef_pops[[ss]] <- matrix(NA, nrow = n, ncol = years)

  # add initial conditions
  reef_pops[[ss]][,1] <- N0.r[[ss]]

  # and calculate the data frames with the transition matrix parameters
  reef_mat_dfs[[ss]] <- mat_data_fun(years, n, surv_pars.r[[ss]], growth_pars.r[[ss]],
                                     frag_pars.r[[ss]], fec_pars.r[[ss]], sigma_s,
                                     sigma_f, seeds)
}

# orchard subpops
orchard_pops <- list()
orchard_mat_dfs <- list()

for(ss in 1:length(s_orchard)){
  orchard_pops[[ss]] <- matrix(NA, nrow = n, ncol = years)

  # add initial conditions here too
  orchard_pops[[ss]][,1] <- N0.o[[ss]]

  # and calculate the data frames with the transition matrix parameters
  orchard_mat_dfs[[ss]] <- mat_data_fun(years, n, surv_pars.o[[ss]], growth_pars.o[[ss]],
                                     frag_pars.o[[ss]], fec_pars.o[[ss]], sigma_s,
                                     sigma_f, seeds)
}



for(i in 1:years){


  # steps:
  # 1) corals from previous year grow/die/reproduce
  # 2) orchard babies are collected and go to lab
  # 3) lab recruits raised from previous year (CHECK timing) and external recruits go to reef

# restoration model: determines how many recruits/corals go in each treatment
# and also keeps track of the costs of each treatment
# feedback = numbers going in to each treatment depends on population sizes, env., etc.

# reef dynamics

  # update the population size using the transition matrix:

  for(ss in 1:length(s_reef)){ # for each reef subpopulation

    # get the transition matrix parameters
    GSF_df <- reef_mat_dfs[[ss]]$growth
    G_pars <- G_df$G[which(G_df$year==i)] # growth
    Sh_pars <- G_df$Sh[which(G_df$year==i)] # shrinkage
    Fr_pars <- G_df$Fr[which(G_df$year==i)] # fragmentation

    S_df <- reef_mat_dfs[[ss]]$survival # survival
    S_pars <- S_df$surv[which(S_df$year==i)]

    # UPDATE survival with density dependence here
    # (QUESTION: should this depend on total reef popn or just the subpopn size?)

    T_mat <- matrix(NA, nrow = n, ncol = n) # transition matrix

    N_mat <- reef_pops[[ss]] # holding matrix for the population
    reef_pops[[ss]][ ,i] <- T_mat %*% N_mat[, i-1]


  }




}


# summary data frames (total cover, total reproductive output)













