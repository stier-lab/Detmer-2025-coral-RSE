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
#' @param A_mids areas at the midpoint of each size class
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

rse_mod <- function(years, n, A_mids, surv_pars.r, growth_pars.r, shrink_pars.r, fec_pars.r,
                    surv_pars.o, growth_pars.o, shrink_pars.o, fec_pars.o,
                    lambda, sigma_s, sigma_f, ext_rand, seeds, orchard_treatments,
                    reef_treatments, lab_treatments, lab_pars, rest_pars, N0.r, N0.o, N0.l){

  # reef subpops = length(lab_treatments)*length(reef_treatments)
  # lab subpops = length(lab_treatments)

  # orchard subpopulations:
  s_orchard <- length(orchard_treatments)*length(lab_treatments)

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

  for(ss in 1:s_reef){

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

  for(ss in 1:s_orchard){

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

  for(ss in 1:s_lab){

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

    for(ss in 1:s_reef){ # for each reef subpopulation

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
      # external recruits going to the ss^th reef subpopulation:
      #ext_rec_ss <- ext_rec[i]*rest_pars$reef_areas[ss]/sum(rest_pars$reef_areas) # proportional to area of reef given to this subpop

      #reef_pops[[ss]][1 ,i] <- reef_pops[[ss]][1 ,i] + ext_rec_ss

      #  # UPDATE: need to fix recruits since there are more reef subpops than reef areas due to lab treatment part


    }


    # orchard dynamics
    for(ss in 1:s_orchard){ # for each reef subpopulation

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
    new_babies <- rep(NA, s_orchard)

    for(ss in 1:s_orchard){
      new_babies[ss] <- orchard_rep[[ss]][i]*rest_pars$orchard_yield # orchard_yield = percent of new orchard babies successfully collected
    }

    tot_babies <- sum(new_babies) # total new babies collected from the orchard

    # put the new orchard babies into each lab treatment and determine how many survive
    for(ss in 1:s_lab){

      # settlers = prop babies put in ss^th treatment x prop of babies that successfully settle in this treatment x total babies
      new_settlers <- min(rest_pars$lab_props[ss]*lab_pars$sett[ss]*tot_babies, rest_pars$lab_max[ss]) # rest_pars$lab_max[ss] = max number of settlers that can go in this treatment

      # settlers that survive to be outplanted in the next timepoint
      lab_pops[[ss]][i] <- new_settlers*lab_pars$s[ss] # ADD density dependence here?

    }


    # restoration actions: update all the population sizes based on restoration strategy
    # NOTE: any feedbacks on restoration actions would be updating the proportions of babies
    # and recruits going to different locations/treatments (lab_props, reef_prop, reef_out_props, orchard_out_props)

    # add the orchard babies from the previous time step:
    # first make a matrix with the number of recruits going from each lab treatment to each reef treatment
    reef_outplants <- matrix(NA, nrow = s_lab, ncol = length(reef_treatments))

    for(ss in 1:s_lab){ # for each lab treatment

      reef_outplants[ss, ] <- lab_pops[[ss]][i-1]*rest_pars$reef_prop*rest_pars$reef_out_props[ss,]
      # reef_prop = proportion lab recruits going to reef, reef_out_props[ss,] = proportion of outplants from lab treatment ss going to each reef treatment

    }

    # apply space constraints: total recruits from all lab treatments going to a given reef
    # treatment can't exceed available space in that reef subpopulation


    # calculate total number of recruits (from all lab treatments) going to each reef treatment
    new_reef_tots <- apply(reef_outplants, 2, sum)

    # calculate total area currently occupied by each reef subpopulation
    area_tots <- rep(NA, s_reef)
    for(ss in 1:s_reef){
      area_tots[ss] <- sum(reef_pops[[ss]][ ,i]*A_mids)

    }
    # now turn this into a matrix where each row is the lab treatment that outplanted individuals originated in
    area_tots <- matrix(area_tots, nrow = s_lab, ncol = length(reef_treatments))
    # now sum across lab treatments to get total area occupied in each reef treatment
    area_tots <- apply(area_tots, 2, sum)

    # now calculate the fractions of new recruits that will fit in each reef treatment
    prop_fits <- rep(NA, length(reef_treatments))

    for(pp in 1:length(reef_treatments)){

      tot_area_pp <- rest_pars$reef_areas[pp] # total area devoted to the pp^th reef treatment
      occupied_area_pp <- area_tots[pp] # total area currently occupied

      open_area_pp <- tot_area_pp - occupied_area_pp # area that is available for new recruits

      new_area_pp <- new_reef_tots[pp]*A_mids[1] # area that the new recruit outplants will need

      if(open_area_pp <= 0){ # if there's no space left
        prop_fits[pp] <- 0 # proportion of new recruits that can be outplanted is 0
      } else if(new_area_pp < open_area_pp){ # if all of them fit
        prop_fits[pp] <- 1 # all the new recruits can be outplanted
      } else{ # if only some will fit, calculate what proportion will fit
        prop_fits[pp] <- 1-((new_area_pp - open_area_pp)/new_area_pp)
      }

      }

    # update outplant matrix (remember row = lab treatment where recruits originated, column = reef treatment where recruits are outplanted)
    #reef_outplants <- reef_outplants%*%matrix(prop_fits, nrow = length(reef_treatments), ncol = 1)
    for(ss in 1:s_lab){
      reef_outplants[ss,] <- reef_outplants[ss,]*prop_fits
    }


    # turn outplant matrix into a vector where the first n elements are the outplants from the
    # first lab treatment to each of the n reef treatments, second n elements are the outplants
    # from the second lab treatment to each of the n reef treatments, etc.
    # also multiply by proportion of the outplants that will fit in each reef treatment
    # as.vector(matrix(c(1, 2, 3, 4, 5, 6), nrow = 2, ncol = 3))
    # as.vector(t(matrix(c(1, 2, 3, 4, 5, 6), nrow = 2, ncol = 3)))
    # matrix(c(1, 2, 3), nrow = 1)
    reef_outplants <- as.vector(t(reef_outplants))


    # add the outplants to the reef subpopulations
    for(ss in 1:s_reef){

        reef_pops[[ss]][1 ,i] <- reef_pops[[ss]][1 ,i] + reef_outplants[ss]

    }


    # repeat for orchard outplants
    orchard_outplants <- matrix(NA, nrow = s_lab, ncol = s_orchard)

    for(ss in 1:s_lab){

      orchard_outplants[ss, ] <- lab_pops[[ss]][i-1]*(1-rest_pars$reef_prop)*rest_pars$orchard_out_props[ss,]
      # 1-reef_prop = proportion lab recruits going to orchard, orchard_out_props[ss,] = proportion of outplants from lab treatment ss going to each orchard treatment

    }

    # apply space constraints
    # calculate total number of recruits (from all lab treatments) going to each orchard treatment
    new_orchard_tots <- apply(orchard_outplants, 2, sum)

    # calculate total number of corals currently in each orchard subpopulation
    ind_tots <- rep(NA, s_orchard)
    for(ss in 1:s_orchard){
      ind_tots[ss] <- sum(orchard_pops[[ss]][ ,i])

    }

    # now turn this into a matrix where each row is the lab treatment that outplanted individuals originated in
    ind_tots <- matrix(ind_tots, nrow = s_lab, ncol = length(orchard_treatments))
    # now sum across lab treatments to get total individuals in each orchard treatment
    ind_tots <- apply(ind_tots, 2, sum)

    # now calculate the fractions of new recruits that will fit in each orchard treatment
    prop_fits2 <- rep(NA, length(orchard_treatments))

    for(pp in 1:length(orchard_treatments)){

      tot_ind_pp <- rest_pars$orchard_size[pp] # total number of individuals that fit in pp^th orchard treatment
      occupied_ind_pp <- ind_tots[pp] # total individuals currently in this orchard subpop

      open_ind_pp <- tot_ind_pp - occupied_ind_pp # number of new recruits that could fit in the orchard subpop

      new_ind_pp <- new_orchard_tots[pp] # total number of new recruits to put in orchard

      if(open_ind_pp <= 0){ # if there's no space left
        prop_fits2[pp] <- 0 # proportion of new recruits that can be outplanted is 0
      } else if(new_ind_pp < open_ind_pp){ # if all of them fit
        prop_fits2[pp] <- 1 # all the new recruits can be outplanted
      } else{ # if only some will fit, calculate what proportion will fit
        prop_fits2[pp] <- 1-((new_ind_pp - open_ind_pp)/new_ind_pp)
      }

    }

    # update outplant matrix (remember row = lab treatment where recruits originated, column = orchard treatment where recruits are outplanted)
   # orchard_outplants <- orchard_outplants%*%matrix(prop_fits2, nrow = length(orchard_treatments), ncol = 1)

    for(ss in 1:s_lab){
      orchard_outplants[ss,] <- orchard_outplants[ss,]*prop_fits2
    }


    orchard_outplants <- as.vector(t(orchard_outplants))

    # add the outplants to the orchard subpopulations
    for(ss in 1:s_orchard){

      orchard_pops[[ss]][1 ,i] <- orchard_pops[[ss]][1 ,i] + orchard_outplants[ss]

    }


  } # end of iteration over each year

 # return all the population metrics

  return(list(reef_pops = reef_pops, orchard_pops = orchard_pops, lab_pops = lab_pops,
              reef_rep = reef_rep, orchard_rep = orchard_rep))

}


# make function for creating summary data frames (total cover, total reproductive output)










