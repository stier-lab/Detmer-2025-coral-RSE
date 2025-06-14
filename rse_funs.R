# README: functions for simulating the model


#' Function for generating a single list with the transition matrix parameters at each
#' time point in the simulation
#' Arguments:
#' @param years number of years in simulation
#' @param n number of size classes
#' @param surv_pars mean survival probabilities in each size class
#' @param growth_pars transition probabilities for each size class
#' @param shrink_pars shrinkage/fragmentation probabilities for each size class
#' @param fec_pars mean fecundities of each size class
#' @param sigma_s standard deviation of survival probabilities
#' @param sigma_f standard deviation of survival probabilities
#' @param seeds vector with seeds for the random number generation for survival, fecundity, and recruitment

mat_pars_fun <- function(years, n, surv_pars, growth_pars, shrink_pars, fec_pars,
                         sigma_s, sigma_f, seeds){

  # survival parameters
  S_list <- Surv_fun(years, n, surv_pars, sigma_s = 0, seed1 = seeds[1])

  # growth/shrinkage/fragmentation matrices
  G_list <- G_fun(years, n, growth_pars, shrink_pars)

  # fecundity parameters
  F_list <- Rep_fun(years, n, fec_pars, sigma_f = 0, seed1 = seeds[2])


  return(list(survival = S_list, growth = G_list, fecundity = F_list))

}


#' lab function
#' make a function that takes the number of new babies from the orchard as an input and
#' returns the number of outplants that can go to the reef
#' this may or may not be a full population dynamics model, but either way I think it can
#' be separate from the orchard and reef models

#' Population dynamics function
#' Arguments:
#' @param years number of years in simulation
#' @param n number of size classes
#' @param surv_pars.r list with mean survival probabilities in each size class for each reef treatment
#' @param growth_pars.r list with transition probabilities for each size class for each reef treatment
#' @param shrink_pars.r list with shrinkage/fragmentation probabilities for each size class for each reef treatment
#' @param fec_pars.r list with mean fecundities of each size class for each reef treatment
#' @param surv_pars.o list with mean survival probabilities in each size class for each orchard treatment
#' @param growth_pars.o list with transition probabilities for each size class for each orchard treatment
#' @param shrink_pars.o list with shrinkage/fragmentation probabilities for each size class for each orchard treatment
#' @param fec_pars.o list with mean fecundities of each size class for each orchard treatment
#' @param sigma_s standard deviation of survival probabilities
#' @param sigma_f standard deviation of survival probabilities
#' @param seeds vector with seeds for the random number generation for survival, fecundity, and recruitment
#' @param orchard_treatments named list with all orchard treatments (including "none" for no treatment)
#' @param reef_treatments named list with all the reef treatments (including "none" for no treatment)
#' @param lab_treatments named list with all lab treatments (including "none" for no treatment)
#' @param lab_pars parameters with lab yields for the different lab treatments

rse_mod <- function(years, n, surv_pars.r, growth_pars.r, shrink_pars.r, fec_pars.r,
                    surv_pars.o, growth_pars.o, shrink_pars.o, fec_pars.o,
                    sigma_s, sigma_f, seeds, orchard_treatments, reef_treatments,
                    lab_treatments, lab_pars){

  # reef subpops = length(lab_treatments)*length(reef_treatments)

  # lab subpops = length(lab_treatments)

  # orchard subpopulations:
  s_orchard <- length(orchard_treatments)

  # reef subpopulations:
  s_reef <- length(reef_treatments)*length(lab_treatments)

  # set up holding matrices
  # reef subpops
  reef_pops <- list() # list with holding matrices for each reef subpopulation
  reef_mat_pars <- list() # list with data frames with the transition matrix parameters for each reef subpop

  for(ss in 1:length(s_reef)){

    reef_pops[[ss]] <- matrix(NA, nrow = n, ncol = years)

    # add initial conditions
    reef_pops[[ss]][,1] <- N0.r[[ss]]

    # and get the list with the transition matrix parameters
    reef_mat_pars[[ss]] <- mat_pars_fun(years, n, surv_pars.r[[ss]], growth_pars.r[[ss]],
                                        shrink_pars.r[[ss]], fec_pars.r[[ss]], sigma_s,
                                        sigma_f, seeds)
  }

  # orchard subpops
  orchard_pops <- list()
  orchard_mat_pars <- list()

  for(ss in 1:length(s_orchard)){

    orchard_pops[[ss]] <- matrix(NA, nrow = n, ncol = years)

    # add initial conditions here too
    orchard_pops[[ss]][,1] <- N0.o[[ss]]

    # and calculate the data frames with the transition matrix parameters
    orchard_mat_pars[[ss]] <- mat_pars_fun(years, n, surv_pars.o[[ss]], growth_pars.o[[ss]],
                                           shrink_pars.o[[ss]], fec_pars.o[[ss]], sigma_s,
                                           sigma_f, seeds)
  }



  for(i in 1:years){


    # steps:
    # 1) corals from previous year grow/die
    # 2) corals reproduce and orchard babies are collected and go to lab
    # 3) lab recruits raised from previous year (CHECK TIMELINE) and external recruits go to reef

    # restoration model: determines how many recruits/corals go in each treatment
    # and also keeps track of the costs of each treatment
    # feedback = numbers going in to each treatment depends on population sizes, env., etc.

    # reef dynamics

    # update the population size using the transition matrix:

    for(ss in 1:length(s_reef)){ # for each reef subpopulation

      # get the transition matrix
      T_mat <- reef_mat_pars[[ss]]$growth[[i]]

      # get the survival probabilities
      S_i <- reef_mat_pars[[ss]]$survival[[i]] # survival

      # UPDATE survival with density dependence here
      # (QUESTION: should this depend on total reef popn or just the subpopn size?)

      N_mat <- reef_pops[[ss]][,i-1] # population sizes in each size class at last time point
      N_mat <- N_mat*S_i # fractions surviving to current time point

      reef_pops[[ss]][ ,i] <- T_mat %*% N_mat[, i-1]

      # ADD the recruits that were put into the lab at the last time point


    }


    # orchard dynamics
    for(ss in 1:length(s_orchard)){ # for each reef subpopulation

      # get the transition matrix
      T_mat <- orchard_mat_pars[[ss]]$growth[[i]]

      # get the survival probabilities
      S_i <- orchard_mat_pars[[ss]]$survival[[i]] # survival

      # UPDATE survival with density dependence here
      # (QUESTION: should this depend on total reef popn or just the subpopn size?)

      N_mat <- orchard_pops[[ss]][,i-1] # population sizes in each size class at last time point

      # now update the population sizes:
      N_mat <- N_mat*S_i # fractions surviving to current time point

      orchard_pops[[ss]][ ,i] <- T_mat %*% N_mat[, i-1]

      # COLLECT the babies that these corals produce



    }


    # lab dynamics: put the new babies in, calculate how many will survive to be outplanted next year



  }


  # summary data frames (total cover, total reproductive output)



}












