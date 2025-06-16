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
#'
#' ADD disturbance effects here (years of disturbance and corresponding parameter values)

mat_pars_fun <- function(years, n, surv_pars, growth_pars, shrink_pars, fec_pars,
                         sigma_s, sigma_f, seeds){

  # survival parameters
  S_list <- Surv_fun(years, n, surv_pars, sigma_s, seed1 = seeds[1])

  # growth/shrinkage/fragmentation matrices
  G_list <- G_fun(years, n, growth_pars, shrink_pars)

  # fecundity parameters
  F_list <- Rep_fun(years, n, fec_pars, sigma_f, seed1 = seeds[2])


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
#' @param lambda mean number of external recruits each year
#' @param sigma_s standard deviation of survival probabilities
#' @param sigma_f standard deviation of survival probabilities
#' @param ext_rand whether external recruitment is stochastic (TRUE) or not (FALSE)
#' @param seeds vector with seeds for the random number generation for survival, fecundity, and recruitment
#' @param orchard_treatments named list with all orchard treatments (including "none" for no treatment)
#' @param reef_treatments named list with all the reef treatments (including "none" for no treatment)
#' @param lab_treatments named list with all lab treatments (including "none" for no treatment)
#' @param lab_pars parameters with lab yields for the different lab treatments
#' @param rest_pars restoration strategy parameters for determining how many recruits go to each treatment lab, reef, and orchard
#' @param N0.r initial population sizes in each reef subpopulation
#' @param N0.o initial population sizes in each orchard subpopulation
#' @param N0.l initial population sizes in each lab subpopulation

rse_mod <- function(years, n, surv_pars.r, growth_pars.r, shrink_pars.r, fec_pars.r,
                    surv_pars.o, growth_pars.o, shrink_pars.o, fec_pars.o,
                    lambda, sigma_s, sigma_f, ext_rand, seeds, orchard_treatments,
                    reef_treatments, lab_treatments, lab_pars, rest_pars, N0.r, N0.o, N0.l){

  # reef subpops = length(lab_treatments)*length(reef_treatments)
  # lab subpops = length(lab_treatments)

  # orchard subpopulations:
  s_orchard <- length(orchard_treatments)

  # reef subpopulations:
  s_reef <- length(reef_treatments)*length(lab_treatments)

  # external recruitment
  ext_rec <- Ext_fun(years, lambda, rand = ext_rand, seed1 = seeds[3])

  # lab subpopulations
  s_lab <- length(lab_treatments)

  # set up holding lists
  reef_pops <- list() # holding list for population sizes of each reef subpopulation
  reef_rep <- list() # holding list for total reproductive output from each reef subpopulation
  reef_mat_pars <- list() # list with data frames with the transition matrix parameters for each reef subpop

  for(ss in 1:length(s_reef)){

    # holding matrix for number of individuals in each size class of the ss^th reef subpop in each year
    reef_pops[[ss]] <- matrix(NA, nrow = n, ncol = years)

    # holding matrix for total reproductive output by ss^th subpop each year
    reef_rep[[ss]] <- rep(NA, years)

    # add initial conditions
    reef_pops[[ss]][,1] <- N0.r[[ss]]

    # and get the list with the transition matrix parameters
    reef_mat_pars[[ss]] <- mat_pars_fun(years, n, surv_pars.r[[ss]], growth_pars.r[[ss]],
                                        shrink_pars.r[[ss]], fec_pars.r[[ss]], sigma_s,
                                        sigma_f, seeds)
    # fill in initial reproduction
    reef_rep[[ss]][1] <- sum(reef_pops[[ss]][,1]*reef_mat_pars[[ss]]$fecundity[[1]])
  }

  # repeat for orchard subpops
  orchard_pops <- list()
  orchard_rep <- list()
  orchard_mat_pars <- list()

  for(ss in 1:length(s_orchard)){

    # holding matrix for number of individuals in each size class of the ss^th reef subpop in each year
    orchard_pops[[ss]] <- matrix(NA, nrow = n, ncol = years)

    # holding matrix for total reproductive output by ss^th subpop each year
    orchard_rep[[ss]] <- rep(NA, years)

    # add initial conditions here too
    orchard_pops[[ss]][,1] <- N0.o[[ss]]

    # and calculate the data frames with the transition matrix parameters
    orchard_mat_pars[[ss]] <- mat_pars_fun(years, n, surv_pars.o[[ss]], growth_pars.o[[ss]],
                                           shrink_pars.o[[ss]], fec_pars.o[[ss]], sigma_s,
                                           sigma_f, seeds)
    # fill in initial reproduction
    orchard_rep[[ss]][1] <- sum(orchard_pops[[ss]][,1]*orchard_mat_pars[[ss]]$fecundity[[1]])


  }


  # lab subpopulations
  lab_pops <- list()
  # lab_mat_pars <- list()

  for(ss in 1:length(s_lab)){

    # holding vectors for number of individuals in the lab
    lab_pops[[ss]] <- rep(NA, years)

    # initial conditions
    lab_pops[[ss]][1] <- N0.l[[ss]]

  }



  for(i in 2:years){


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

      # now update the population sizes
      reef_pops[[ss]][ ,i] <- T_mat %*% matrix(N_mat, nrow = n, ncol = 1) # new population sizes


      # amount of new larvae produced at the i^th time point:
      reef_rep[[ss]][i] <- sum(reef_pops[[ss]][ ,i]*reef_mat_pars[[ss]]$fecundity[[i]])



      # add external recruits
      reef_pops[[ss]][1 ,i] <- reef_pops[[ss]][1 ,i] + ext_rec[i]


    }


    # orchard dynamics
    for(ss in 1:length(s_orchard)){ # for each reef subpopulation

      # get the transition matrix from the last year
      #T_mat <- orchard_mat_pars[[ss]]$growth[[i-1]]

      # get the transition matrix for this year
      T_mat <- orchard_mat_pars[[ss]]$growth[[i]]

      # get the survival probabilities for this year
      S_i <- orchard_mat_pars[[ss]]$survival[[i]] # survival

      # UPDATE survival with density dependence here
      # (QUESTION: should this depend on total reef popn or just the subpopn size?)

      N_mat <- orchard_pops[[ss]][,i-1] # population sizes in each size class at last time point

      N_mat <- N_mat*S_i # fractions surviving to current time point

      # now update the population sizes:
      orchard_pops[[ss]][ ,i] <- T_mat %*% matrix(N_mat, nrow = n, ncol = 1)

      # amount of new larvae produced since the last time point:
      #orchard_rep[[ss]][i] <- sum(N_mat[, i-1]*orchard_mat_pars[[ss]]$fecundity[[i-1]])

      # amount of new larvae produced at i^th time point:
      orchard_rep[[ss]][i] <- sum(orchard_pops[[ss]][ ,i]*orchard_mat_pars[[ss]]$fecundity[[i]])





    }


    # calculate total new orchard babies
    new_babies <- rep(NA, length(s_orchard))

    for(ss in 1:length(s_orchard)){
      new_babies[ss] <- orchard_rep[[ss]][i]*rest_pars$orchard_yield # orchard_yield = percent of new orchard babies successfully collected
    }

    tot_babies <- sum(new_babies) # total new babies collected from the orchard

    # put the new orchard babies into each lab treatment and determine how many survive
    for(ss in 1:length(s_lab)){

      # settlers = prop babies put in ss^th treatment x prop of babies that successfully settle in this treatment x total babies
      new_settlers <- rest_pars$lab_props[ss]*lab_pars$sett[ss]*tot_babies

      # settlers that survive to be outplanted in the next timepoint
      lab_pops[[ss]][i] <- new_settlers*lab_pars$s[ss] # ADD density dependence here?

    }


    # restoration actions: update all the population sizes based on restoration strategy
    # NOTE: any feedbacks on restoration actions would be updating the proportions of babies
    # and recruits going to different locations/treatments (lab_props, reef_prop, reef_out_props, orchard_out_props)

    # add the orchard babies from the previous time step:
    # first make a vector with the number of recruits going to each reef treatment
    reef_outplants <- matrix(NA, nrow = length(s_lab), ncol = length(s_reef))

    for(ss in 1:length(s_lab)){

      reef_outplants[ss, ] <- lab_pops[[ss]][i-1]*rest_pars$reef_prop*rest_pars$reef_out_props[ss,]
      # reef_prop = proportion lab recruits going to reef, reef_out_props[ss,] = proportion of outplants from lab treatment ss going to each reef treatment

    }

    # turn this matrix into a vector where the first n elements are the outplants from the
    # first lab treatment to the each of n reef treatments, second n elements are the outplants
    # from the second lab treatment to each of n reef treatments, etc.
    # as.vector(matrix(c(1, 2, 3, 4, 5, 6), nrow = 2, ncol = 3))
    # as.vector(t(matrix(c(1, 2, 3, 4, 5, 6), nrow = 2, ncol = 3)))
    # matrix(c(1, 2, 3), nrow = 1)
    reef_outplants <- as.vector(t(reef_outplants))

    # add the outplants to the reef subpopulations
    for(ss in 1:length(s_reef)){

        reef_pops[[ss]][1 ,i] <- reef_pops[[ss]][1 ,i] + reef_outplants[ss]

    }


    # repeat for orchard outplants
    orchard_outplants <- matrix(NA, nrow = length(s_lab), ncol = length(s_orchard))

    for(ss in 1:length(s_lab)){

      orchard_outplants[ss, ] <- lab_pops[[ss]][i-1]*(1-rest_pars$reef_prop)*rest_pars$orchard_out_props[ss,]
      # 1-reef_prop = proportion lab recruits going to orchard, orchard_out_props[ss,] = proportion of outplants from lab treatment ss going to each orchard treatment

    }

    orchard_outplants <- as.vector(t(orchard_outplants))

    # add the outplants to the orchard subpopulations
    for(ss in 1:length(s_orchard)){

      orchard_pops[[ss]][1 ,i] <- orchard_pops[[ss]][1 ,i] + orchard_outplants[ss]

    }


  } # end of iteration over each year

 # return all the population metrics

  return(list(reef_pops = reef_pops, orchard_pops = orchard_pops, lab_pops = lab_pops,
              reef_rep = reef_rep, orchard_rep = orchard_rep))

}


# make function for creating summary data frames (total cover, total reproductive output)










