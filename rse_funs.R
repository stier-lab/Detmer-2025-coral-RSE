# README: functions for simulating the model


#' Function for generating a single list with the transition matrix parameters at each
#' time point in the simulation
#' Arguments:
#' @param years number of years in simulation
#' @param n number of size classes
#' @param surv_pars mean survival probabilities in each size class
#' @param growth_pars transition probabilities for each size class
#' @param shrink_pars shrinkage probabilities for each size class
#' @param frag_pars fragmentation probabilities for each size class
#' @param fec_pars mean fecundities of each size class
#' @param sigma_s standard deviation of survival probabilities
#' @param sigma_f standard deviation of survival probabilities
#' @param seeds vector with seeds for the random number generation for survival, fecundity, and recruitment
#' @param dist_yrs vector of years where disturbance occurs
#' @param dist_pars list with survival, growth/shrinkage (transition matrix) and fecundity parameters for each disturbance year
#' @param dist_effects which demographic parameters are affected by each disturbance

mat_pars_fun <- function(years, n, surv_pars, growth_pars, shrink_pars, frag_pars, fec_pars,
                         sigma_s, sigma_f, seeds, dist_yrs, dist_pars, dist_effects){

  # survival parameters
  S_list <- Surv_fun(years, n, surv_pars, sigma_s, seed1 = seeds[1])

  # growth/shrinkage and fragmentation matrices
  all_mats <- G_fun(years, n, growth_pars, shrink_pars, frag_pars)
  G_list <- all_mats$G_list
  Fr_list <- all_mats$Fr_list

  # fecundity parameters
  F_list <- Rep_fun(years, n, fec_pars, sigma_f, seed1 = seeds[2])

  # update with disturbance effects
  if(is.na(dist_yrs[1])==F){

    for(i in dist_yrs){ # for each disturbance year

      if("survival" %in% dist_effects[[which(dist_yrs==i)]]){ # if the ith disturbance affected survival
        S_list[[i]] <- dist_pars$dist_surv[[which(dist_yrs==i)]]
      }

      if("Tmat" %in% dist_effects[[which(dist_yrs==i)]]){ # if the ith disturbance affected growth or shrinkage (transition matrix)
        G_list[[i]] <- dist_pars$dist_Tmat[[which(dist_yrs==i)]]
      }

      if("Fmat" %in% dist_effects[[which(dist_yrs==i)]]){ # if the ith disturbance affected fragmentation
        Fr_list[[i]] <- dist_pars$dist_Fmat[[which(dist_yrs==i)]]
      }

      if("fecundity" %in% dist_effects[[which(dist_yrs==i)]]){ # if the ith disturbance affected fecundity
        F_list[[i]] <- dist_pars$dist_fec[[which(dist_yrs==i)]]
      }

    }

  }


  return(list(survival = S_list, growth = G_list, fragmentation = Fr_list, fecundity = F_list))

}

#' function for generating lists with disturbance parameters for each subpopulation/source combination
#' @param dist_yrs vector of years where disturbance occurs
#' @param dist_effects which demographic parameters are affected by each disturbance
#' @param dist_surv0 list where ith element contains the survival probabilities for year with ith disturbance
#' @param dist_Tmat0 list where ith element contains the transition matrix for year with ith disturbance
#' @param dist_Fmat0 list where ith element contains the fragmentation matrix for year with ith disturbance
#' @param dist_fec0 list where ith element contains the fecundities for year with ith disturbance

dist_pars_fun <- function(dist_yrs, dist_effects, dist_surv0 = NULL, dist_Tmat0 = NULL, dist_Fmat0 = NULL, dist_fec0 = NULL){

  dist_surv <- list()
  dist_Tmat <- list()
  dist_Fmat <- list()
  dist_fec <- list()

  for(i in 1:length(dist_yrs)){ # for each disturbance

    if("survival" %in% dist_effects[[i]]){ # if the ith disturbance affected survival
      dist_surv[[i]] <- dist_surv0[[i]]
    } else{
      dist_surv[[i]] <- NULL
    }

    if("Tmat" %in% dist_effects[[i]]){ # if the ith disturbance affected growth or shrinkage (transition matrix)
      dist_Tmat[[i]] <- dist_Tmat0[[i]]
    } else{
      dist_Tmat[[i]] <- NULL
    }

    if("Fmat" %in% dist_effects[[i]]){ # if the ith disturbance affected fragmentation
      dist_Fmat[[i]] <- dist_Fmat0[[i]]
    } else{
      dist_Fmat[[i]] <- NULL
    }

    if("fecundity" %in% dist_effects[[i]]){ # if the ith disturbance affected fecundity
      dist_fec[[i]] <- dist_fec0[[i]]
    } else{
      dist_fec[[i]] <- NULL
    }

  } # end of loop over disturbance years


  dist_pars <- list(dist_surv = dist_surv, dist_Tmat = dist_Tmat, dist_Fmat = dist_Fmat, dist_fec = dist_fec)

  return(dist_pars)

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
#' @param shrink_pars.r list with shrinkage probabilities for each size class for each reef treatment
#' @param frag_pars.r list with fragmentation probabilities for each size class for each reef treatment
#' @param fec_pars.r list with mean fecundities of each size class for each reef treatment
#' @param surv_pars.o list with mean survival probabilities in each size class for each orchard treatment
#' @param growth_pars.o list with transition probabilities for each size class for each orchard treatment
#' @param shrink_pars.o list with shrinkage probabilities for each size class for each orchard treatment
#' @param frag_pars.o list with fragmentation probabilities for each size class for each orchard treatment
#' @param fec_pars.o list with mean fecundities of each size class for each orchard treatment
#' @param lambda mean number of external recruits each year
#' @param sigma_s standard deviation of survival probabilities
#' @param sigma_f standard deviation of fecundities
#' @param ext_rand whether external recruitment is stochastic (TRUE) or not (FALSE)
#' @param seeds vector with seeds for the random number generation for survival, fecundity, and recruitment
#' @param dist_yrs vector of years when reef disturbance occurs
#' @param dist_pars.r list with survival, growth/shrinkage (transition matrix) and fecundity parameters for each reef disturbance year
#' @param dist_effects.r which demographic parameters are affected by each reef disturbance
#' @param dist_pars.o list with survival, growth/shrinkage (transition matrix) and fecundity parameters for each orchard disturbance year
#' @param dist_effects.o which demographic parameters are affected by each orchard disturbance
#' @param orchard_treatments named list with all orchard treatments (including "none" for no treatment)
#' @param reef_treatments named list with all the reef treatments (including "none" for no treatment)
#' @param lab_treatments named list with all lab treatments (including "none" for no treatment)
#' @param lab_pars parameters with lab yields for the different lab treatments
#' @param rest_pars restoration strategy parameters for determining how many recruits go to each treatment lab, reef, and orchard
#' @param N0.r initial population sizes in each reef subpopulation
#' @param N0.o initial population sizes in each orchard subpopulation
#' @param N0.l initial population sizes in each lab subpopulation

rse_mod <- function(years, n, A_mids, surv_pars.r, growth_pars.r, shrink_pars.r, frag_pars.r,
                    fec_pars.r, surv_pars.o, growth_pars.o, shrink_pars.o, frag_pars.o,
                    fec_pars.o, lambda, sigma_s, sigma_f, ext_rand, seeds, dist_yrs,
                    dist_pars.r, dist_effects.r, dist_pars.o, dist_effects.o,
                    orchard_treatments, reef_treatments, lab_treatments, lab_pars, rest_pars,
                    N0.r, N0.o, N0.l){

  # reef subpops = length(lab_treatments)*length(reef_treatments)
  # lab subpops = length(lab_treatments)

  # orchard subpopulations:
  s_orchard <- length(orchard_treatments)

  # reef subpopulations:
  s_reef <- length(reef_treatments)

  # external recruitment
  ext_rec <- Ext_fun(years, lambda, rand = ext_rand, seed1 = seeds[3])
  # proportions going to each reef subpop:
  ext_props <- rest_pars$reef_areas/sum(rest_pars$reef_areas)

  # lab subpopulations
  s_lab <- length(lab_treatments)
  # subpopulations that will be outplanted immediately
  #s_lab0 <- length(which(substr(lab_treatments, start = 1, stop = 1) == "0"))
  # subpopulations that are retained in the lab for a year
  #s_lab1 <- length(which(substr(lab_treatments, start = 1, stop = 1) == "1"))

  # sources of new recruits
  source_reef <- s_lab + 1 # number of possible sources of reef recruits (+1 is for external recruits)
  source_orchard <- s_lab # number of possible sources of orchard recruits

  # set up holding lists
  reef_pops <- list() # holding list for population sizes of each reef subpopulation
  reef_rep <- list() # holding list for total reproductive output from each reef subpopulation
  reef_mat_pars <- list() # list with data frames with the transition matrix parameters for each reef subpop

  for(ss in 1:s_reef){

    # sublists for all the different sources of recruits to this reef
    reef_pops_ss <- list() # population sizes
    reef_rep_ss <- list() # total reproductive output
    reef_mat_pars_ss <- list() # matrix parameters

    if(reef_treatments[ss] == "none"){ # if this is the reference site

      # holding matrix for number of individuals in each size class of reference reef pop'n in each year
      reef_pops_ss[[1]] <- matrix(NA, nrow = n, ncol = years)

      # holding matrix for total reproductive output by ss^th subpop each year
      reef_rep_ss[[1]] <- rep(NA, years)

      # add initial conditions
      reef_pops_ss[[1]][,1] <- N0.r[[ss]][[1]]

      # and get the list with the transition matrix parameters
      reef_mat_pars_ss[[1]] <- mat_pars_fun(years, n, surv_pars.r[[ss]][[1]], growth_pars.r[[ss]][[1]],
                                          shrink_pars.r[[ss]][[1]], frag_pars.r[[ss]][[1]], fec_pars.r[[ss]][[1]],
                                          sigma_s, sigma_f, seeds, dist_yrs, dist_pars.r[[ss]][[1]],
                                          dist_effects.r[[ss]][[1]])

    } else{

      for(rr in 1:source_reef){ # for each possible source of recruits to this reef subpop

        # holding matrix for number of individuals in each size class of the ss^th reef subpop from the rr^th source in each year
        reef_pops_ss[[rr]] <- matrix(NA, nrow = n, ncol = years)

        # holding matrix for total reproductive output by individuals in the ss^th reef subpop from the rr^th source each year
        reef_rep_ss[[rr]] <- rep(NA, years)

        # add initial conditions
        reef_pops_ss[[rr]][,1] <- N0.r[[ss]][[rr]]

        # and get the list with the transition matrix parameters
        reef_mat_pars_ss[[rr]] <- mat_pars_fun(years, n, surv_pars.r[[ss]][[rr]], growth_pars.r[[ss]][[rr]],
                                            shrink_pars.r[[ss]][[rr]], frag_pars.r[[ss]][[rr]], fec_pars.r[[ss]][[rr]],
                                            sigma_s, sigma_f, seeds, dist_yrs, dist_pars.r[[ss]][[rr]],
                                            dist_effects.r[[ss]][[rr]])
        # fill in initial reproduction
        reef_rep_ss[[rr]][1] <- sum(reef_pops_ss[[rr]][,1]*reef_mat_pars_ss[[rr]]$fecundity[[1]])

      }


    }

    # put all the sublists in the outer holding lists for each reef subpop

    reef_pops[[ss]] <- reef_pops_ss
    reef_rep[[ss]] <- reef_rep_ss
    reef_mat_pars[[ss]] <- reef_mat_pars_ss


  }

  # repeat for orchard subpops
  orchard_pops <- list()
  orchard_rep <- list()
  orchard_mat_pars <- list()

  for(ss in 1:s_orchard){

    # sublists for all the different sources of recruits to the orchard
    orchard_pops_ss <- list() # population sizes
    orchard_rep_ss <- list() # total reproductive output
    orchard_mat_pars_ss <- list() # matrix parameters

    for(rr in 1:source_orchard){ # for each source of recruits to the ss^th orchard treatment

      # holding matrix for number of individuals in each size class of the ss^th reef subpop in each year
      orchard_pops_ss[[rr]] <- matrix(NA, nrow = n, ncol = years)

      # holding matrix for total reproductive output by ss^th subpop each year
      orchard_rep_ss[[rr]] <- rep(NA, years)

      # add initial conditions here too
      orchard_pops_ss[[rr]][,1] <- N0.o[[ss]][[rr]]

      # and calculate the data frames with the transition matrix parameters
      orchard_mat_pars_ss[[rr]] <- mat_pars_fun(years, n, surv_pars.o[[ss]][[rr]], growth_pars.o[[ss]][[rr]],
                                             shrink_pars.o[[ss]][[rr]], frag_pars.o[[ss]][[rr]],
                                             fec_pars.o[[ss]][[rr]], sigma_s, sigma_f, seeds, dist_yrs,
                                             dist_pars.o[[ss]][[rr]], dist_effects.o[[ss]][[rr]])
      # fill in initial reproduction
      orchard_rep_ss[[rr]][1] <- sum(orchard_pops_ss[[rr]][,1]*orchard_mat_pars_ss[[rr]]$fecundity[[1]])


    }


    orchard_pops[[ss]] <- orchard_pops_ss
    orchard_rep[[ss]] <- orchard_rep_ss
    orchard_mat_pars[[ss]] <- orchard_mat_pars_ss

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

      if(reef_treatments[ss] == "none"){ # if this is the reference site

        # get the transition matrix
        T_mat <- reef_mat_pars[[ss]][[1]]$growth[[i]]

        # get the fragmentation matrix
        F_mat <- reef_mat_pars[[ss]][[1]]$fragmentation[[i]]

        # if the reef is full, assume none of the fragments produced over the last year result in new colonies
        if(sum(reef_pops[[ss]][[1]][ ,i-1]*A_mids) >= rest_pars$reef_areas[ss]){
          F_mat <- 0*F_mat
        }

        # get the survival probabilities
        S_i <- reef_mat_pars[[ss]][[1]]$survival[[i]] # survival

        # UPDATE survival with density dependence here
        # (QUESTION: should this depend on total reef popn or just the subpopn size?)

        N_mat <- reef_pops[[ss]][[1]][,i-1] # population sizes in each size class at last time point
        N_mat <- N_mat*S_i # fractions surviving to current time point

        # now update the population sizes
        reef_pops[[ss]][[1]][ ,i] <- (T_mat + F_mat) %*% matrix(N_mat, nrow = n, ncol = 1) # new population sizes

        # amount of new larvae produced at the i^th time point:
        reef_rep[[ss]][[1]][i] <- sum(reef_pops[[ss]][[1]][ ,i]*reef_mat_pars[[ss]][[1]]$fecundity[[i]])

        # add external recruits if there's room
        tot_area1 <- rest_pars$reef_areas[ss] # total area devoted to the ss^th reef treatment
        occupied_area1 <- sum(reef_pops[[ss]][[1]][ ,i]*A_mids) # total area currently occupied
        open_area1 <- tot_area1 - occupied_area1 # area that is available for new recruits
        new_area1 <- ext_rec[i]*ext_props[ss]*A_mids[1] # area that the new recruits will need

        if(open_area1 <= 0){ # if there's no space left
          prop_rec <- 0 # proportion of new recruits that can be outplanted is 0
        } else if(new_area1 < open_area1){ # if all of them fit
          prop_rec <- 1 # all the new recruits can be outplanted
        } else{ # if only some will fit, calculate what proportion will fit
          prop_rec <- 1-((new_area1 - open_area1)/new_area1)
        }

        #prop_rec <- 1

        reef_pops[[ss]][[1]][1 ,i] <- reef_pops[[ss]][[1]][1 ,i] + ext_rec[i]*ext_props[ss]*prop_rec


      } else{

        for(rr in 1:source_reef){ # for each source of recruits

          # get the transition matrix
          T_mat <- reef_mat_pars[[ss]][[rr]]$growth[[i]]

          # get the fragmentation matrix
          F_mat <- reef_mat_pars[[ss]][[rr]]$fragmentation[[i]]

          # if the reef is full, assume none of the fragments produced over the last year result in new colonies
          if(sum(reef_pops[[ss]][[1]][ ,i-1]*A_mids) >= rest_pars$reef_areas[ss]){
            F_mat <- 0*F_mat
          }

          # get the survival probabilities
          S_i <- reef_mat_pars[[ss]][[rr]]$survival[[i]] # survival

          # UPDATE survival with density dependence here
          # (QUESTION: should this depend on total reef popn or just the subpopn size?)

          N_mat <- reef_pops[[ss]][[rr]][,i-1] # population sizes in each size class at last time point
          N_mat <- N_mat*S_i # fractions surviving to current time point

          # now update the population sizes
          reef_pops[[ss]][[rr]][ ,i] <- (T_mat + F_mat) %*% matrix(N_mat, nrow = n, ncol = 1) # new population sizes

          # amount of new larvae produced at the i^th time point:
          reef_rep[[ss]][[rr]][i] <- sum(reef_pops[[ss]][[rr]][ ,i]*reef_mat_pars[[ss]][[rr]]$fecundity[[i]])

          if(rr ==1){ # if this is the first source (external recruits)
            # add the external recruits if they fit
            tot_area1 <- rest_pars$reef_areas[ss] # total area devoted to the ss^th reef treatment
            occupied_area1 <- sum(reef_pops[[ss]][[rr]][ ,i]*A_mids) # total area currently occupied
            open_area1 <- tot_area1 - occupied_area1 # area that is available for new recruits
            new_area1 <- ext_rec[i]*ext_props[ss]*A_mids[1] # area that the new recruits will need

            if(open_area1 <= 0){ # if there's no space left
              prop_rec <- 0 # proportion of new recruits that can be outplanted is 0
            } else if(new_area1 < open_area1){ # if all of them fit
              prop_rec <- 1 # all the new recruits can be outplanted
            } else{ # if only some will fit, calculate what proportion will fit
              prop_rec <- 1-((new_area1 - open_area1)/new_area1)
            }

            reef_pops[[ss]][[rr]][1 ,i] <- reef_pops[[ss]][[rr]][1 ,i] + ext_rec[i]*ext_props[ss]*prop_rec
          }

        } # end of iterations over each source

      } # end of "else" statement


    } # end of iterations over each reef subpop


    # orchard dynamics
    for(ss in 1:s_orchard){ # for each orchard treatment

      # calculate total number of colonies in this orchard
      ind_tots_ss <- rep(NA, source_orchard)

      for(rr in 1:source_orchard){

        ind_tots_ss[rr] <- sum(orchard_pops[[ss]][[rr]][ ,i-1])
      }

      ind_tots_s <- sum(ind_tots_ss)

      for(rr in 1:source_orchard){ # for each source of orchard recruits

        # get the transition matrix from the last year
        #T_mat <- orchard_mat_pars[[ss]]$growth[[i-1]]

        # get the transition matrix for this year
        T_mat <- orchard_mat_pars[[ss]][[rr]]$growth[[i]]

        # get the fragmentation matrix
        F_mat <- orchard_mat_pars[[ss]][[rr]]$fragmentation[[i]]

        if(ind_tots_s >= rest_pars$orchard_size[ss]){
          F_mat <- 0*F_mat
        }

        # get the survival probabilities for this year
        S_i <- orchard_mat_pars[[ss]][[rr]]$survival[[i]] # survival

        # UPDATE survival with density dependence here
        # (QUESTION: should this depend on total reef popn or just the subpopn size?)

        N_mat <- orchard_pops[[ss]][[rr]][,i-1] # population sizes in each size class at last time point

        N_mat <- N_mat*S_i # fractions surviving to current time point

        # now update the population sizes:
        orchard_pops[[ss]][[rr]][ ,i] <- (T_mat + F_mat) %*% matrix(N_mat, nrow = n, ncol = 1)

        # amount of new larvae produced since the last time point:
        #orchard_rep[[ss]][i] <- sum(N_mat[, i-1]*orchard_mat_pars[[ss]]$fecundity[[i-1]])

        # amount of new larvae produced at i^th time point:
        orchard_rep[[ss]][[rr]][i] <- sum(orchard_pops[[ss]][[rr]][ ,i]*orchard_mat_pars[[ss]][[rr]]$fecundity[[i]])


      } # end of iterations over each orchard source


    } # end of iterations over each orchard treatment


    # calculate total new orchard babies collected
    new_babies.o <- matrix(NA, nrow = s_orchard, ncol = source_orchard) # rows = number of orchard treatments, col = number of sources to the orchard

    for(ss in 1:s_orchard){
      for(rr in 1:source_orchard){
        new_babies.o[ss,rr] <- orchard_rep[[ss]][[rr]][i]*rest_pars$orchard_yield # orchard_yield = percent of new orchard babies successfully collected
      }
    }

    # calculate total new reef babies collected
    new_babies.r <- matrix(NA, nrow = s_reef, ncol = source_reef)

    for(ss in 1:s_reef){

      if(reef_treatments[ss] == "none"){ # if this is the reference reef, there is only one source
        new_babies.r[ss,1] <- reef_rep[[ss]][[1]][i]*rest_pars$reef_yield # reef_yield = percent of new reef babies successfully collected
      } else{
        for(rr in 1:source_reef){
          new_babies.r[ss,rr] <- reef_rep[[ss]][[rr]][i]*rest_pars$reef_yield
        }
      }

    }

    tot_babies <- sum(new_babies.o) + sum(new_babies.r, na.rm = T) # total new babies collected

    # holding vector for settlers on each lab treatment that will be immediately outplanted

    out_settlers <- rep(0, s_lab)

    # put the new babies into each lab treatment and determine how many survive
    for(ss in 1:s_lab){

      # settlers = prop babies put in ss^th treatment x prop of babies that successfully settle in this treatment x total babies
      new_settlers <- min(rest_pars$lab_props[ss]*lab_pars$sett[ss]*tot_babies, rest_pars$lab_max[ss]) # rest_pars$lab_max[ss] = max number of settlers that can go in this treatment

      # settlers that survive initial settlement
      surv_settlers <- new_settlers*lab_pars$s[ss] # ADD density dependence here?

      # store these in the lab population

      lab_pops[[ss]][i] <- surv_settlers

      # determine which of these will be outplanted immediately vs. retained for a year
      # settlers that get retained for a year:
      #lab_pops[[ss]][i] <- min(lab_pars$n_retain[ss], surv_settlers) # ADD any mortality that occurs over the next year here

      # settlers that get outplanted immediately
     # out_settlers[ss] <- surv_settlers - lab_pops[[ss]][i]

      if(substr(lab_treatments[ss], start = 1, stop = 1)=="0"){ # if recruits in ss^th lab treatment are outplanted immediately
        out_settlers[ss] <- lab_pops[[ss]][i]
      }

    }


    # restoration actions: update all the population sizes based on restoration strategy
    # NOTE: any feedbacks on restoration actions would be updating the proportions of babies
    # and recruits going to different locations/treatments (lab_props, reef_prop, reef_out_props, orchard_out_props)

    # add the babies:
    # first make a matrix with the number of recruits going from each lab treatment to each reef treatment
    reef_outplants <- matrix(0, nrow = s_lab, ncol = s_reef) # from current timestep
    reef_outplants1 <- matrix(0, nrow = s_lab, ncol = s_reef) # from last time step

    for(ss in 1:s_lab){ # for each lab treatment

      reef_outplants[ss, ] <- out_settlers[ss]*rest_pars$reef_prop[ss]*rest_pars$reef_out_props[ss,]
      # reef_prop[ss] = proportion lab recruits from ss lab treatment going to reef
      # reef_out_props[ss,] = proportion of reef outplants from lab treatment ss going to treatment on reef

      if(substr(lab_treatments[ss], start = 1, stop = 1)=="1"){ # if recruits in ssth treatment were retained a year
        reef_outplants1[ss, ] <- lab_pops[[ss]][i-1]*rest_pars$reef_prop[ss]*rest_pars$reef_out_props[ss,]
      }

    }

    # apply space constraints: total recruits from all lab treatments going to a given reef
    # treatment can't exceed available space in that reef subpopulation
    # first calculate total number of recruits (from all lab treatments) going to each reef treatment
    #new_reef_tots <- apply(reef_outplants, 2, sum)

    # calculate total area currently occupied by each reef subpopulation
    area_tots <- rep(NA, s_reef)
    for(ss in 1:s_reef){

      if(ss == 1){
        area_tots[ss] <- sum(reef_pops[[ss]][[1]][ ,i]*A_mids)
      } else{

        area_tots_ss <- rep(NA, source_reef)

        for(rr in 1:source_reef){
          area_tots_ss[rr] <- sum(reef_pops[[ss]][[rr]][ ,i]*A_mids)
        }

        area_tots[ss] <- sum(area_tots_ss)
      }

    }

    # now calculate the fractions of new recruits that can get outplanted
    prop_fits <- rep(NA, s_reef)

    for(pp in 1:s_reef){

      tot_area_pp <- rest_pars$reef_areas[pp] # total area devoted to the pp^th reef treatment
      occupied_area_pp <- area_tots[pp] # total area currently occupied

      if(occupied_area_pp >= tot_area_pp){ # if the reef subpopulation is full
        prop_fits[pp] <- 0 # no new recruits can be outplanted
      } else{ # else if there's still space
        prop_fits[pp] <- 1 # outplant the recruits
      }

      # open_area_pp <- tot_area_pp - occupied_area_pp # area that is available for new recruits
      #
      # new_area_pp <- new_reef_tots[pp]*A_mids[1] # area that the new recruit outplants will need
      #
      # if(open_area_pp <= 0){ # if there's no space left
      #   prop_fits[pp] <- 0 # proportion of new recruits that can be outplanted is 0
      # } else if(new_area_pp < open_area_pp){ # if all of them fit
      #   prop_fits[pp] <- 1 # all the new recruits can be outplanted
      # } else{ # if only some will fit, calculate what proportion will fit
      #   prop_fits[pp] <- 1-((new_area_pp - open_area_pp)/new_area_pp)
      # }

      }

    # update outplant matrix (remember row = lab treatment where recruits originated, column = reef treatment where recruits are outplanted)
    #reef_outplants <- reef_outplants%*%matrix(prop_fits, nrow = length(reef_treatments), ncol = 1)
    for(ss in 1:s_lab){
      reef_outplants[ss,] <- reef_outplants[ss,]*prop_fits # Note: could update this to give priority to certain lab treatments?
      reef_outplants1[ss,] <- reef_outplants1[ss,]*prop_fits
    }

    # add the outplants to the reef subpopulations
    for(ss in 1:s_reef){

      if(reef_treatments[ss] != "none"){ # if this isn't a reference site (where zero outplants are added)

        for(rr in 2:source_reef){ # for each lab source (rr = 1 is for external recruits)
          reef_pops[[ss]][[rr]][1 ,i] <- reef_pops[[ss]][[rr]][1 ,i] + reef_outplants[rr-1,ss] # # need rr-1 here because the reef_outplants matrix only includes the lab treatments as sources (first source is external recruitment)

          # add the recruits from the previous year
          reef_pops[[ss]][[rr]][ ,i] <- reef_pops[[ss]][[rr]][ ,i] + reef_outplants1[rr-1,ss]*lab_pars$size_props[rr-1,] # size_props specifies the fractions of last years lab recruits that are now in each size class
        }

      }

      # if "none" treatment also got recruits:
      # for(rr in 1:(source_reef-1)){ # for each lab source (rr = 1 is for external recruits)
      #     reef_pops[[ss]][[rr]][1 ,i] <- reef_pops[[ss]][[rr]][1 ,i] + reef_outplants[ss,rr]


    }


    # repeat for orchard outplants
    orchard_outplants <- matrix(0, nrow = s_lab, ncol = s_orchard) # this year's
    orchard_outplants1 <- matrix(0, nrow = s_lab, ncol = s_orchard) # last year's

    for(ss in 1:s_lab){

      orchard_outplants[ss, ] <- out_settlers[ss]*(1-rest_pars$reef_prop[ss])*rest_pars$orchard_out_props[ss,]
      # 1-reef_prop[ss] = proportion lab recruits from ss lab treatment going to orchard
      # orchard_out_props[ss,] = proportion of the orchard outplants from lab treatment ss going to each orchard treatment

      if(substr(lab_treatments[ss], start = 1, stop = 1)=="1"){ # if recruits in ssth treatment were retained a year
        orchard_outplants1[ss, ] <- lab_pops[[ss]][i-1]*(1-rest_pars$reef_prop[ss])*rest_pars$orchard_out_props[ss,]
      }

    }

    # apply space constraints
    # calculate total number of recruits (from all lab treatments) going to each orchard treatment
    #new_orchard_tots <- apply(orchard_outplants, 2, sum)

    # calculate total number of corals currently in each orchard subpopulation
    ind_tots <- rep(NA, s_orchard)
    for(ss in 1:s_orchard){

     ind_tots_ss <- rep(NA, source_orchard)

      for(rr in 1:source_orchard){

        ind_tots_ss[rr] <- sum(orchard_pops[[ss]][[rr]][ ,i])
      }

     ind_tots[ss] <- sum(ind_tots_ss)

    }


    # now calculate the fractions of new recruits that will fit in each orchard treatment
    prop_fits2 <- rep(NA, s_orchard)

    for(pp in 1:s_orchard){

      tot_ind_pp <- rest_pars$orchard_size[pp] # total number of individuals that fit in pp^th orchard treatment
      occupied_ind_pp <- ind_tots[pp] # total individuals currently in this orchard subpop

      if(occupied_ind_pp >= tot_ind_pp){ # if the orchard is full
        prop_fits2[pp] <- 0 # no new recruits can be added
      } else{ # else if there's still space
        prop_fits2[pp] <- 1 # add the new recruits
      }

      # open_ind_pp <- tot_ind_pp - occupied_ind_pp # number of new recruits that could fit in the orchard subpop
      #
      # new_ind_pp <- new_orchard_tots[pp] # total number of new recruits to put in orchard
      #
      # if(open_ind_pp <= 0){ # if there's no space left
      #   prop_fits2[pp] <- 0 # proportion of new recruits that can be outplanted is 0
      # } else if(new_ind_pp < open_ind_pp){ # if all of them fit
      #   prop_fits2[pp] <- 1 # all the new recruits can be outplanted
      # } else{ # if only some will fit, calculate what proportion will fit
      #   prop_fits2[pp] <- 1-((new_ind_pp - open_ind_pp)/new_ind_pp)
      # }

    }

    # update outplant matrix (remember row = lab treatment where recruits originated, column = orchard treatment where recruits are outplanted)
   # orchard_outplants <- orchard_outplants%*%matrix(prop_fits2, nrow = length(orchard_treatments), ncol = 1)

    for(ss in 1:s_lab){
      orchard_outplants[ss,] <- orchard_outplants[ss,]*prop_fits2
      orchard_outplants1[ss,] <- orchard_outplants1[ss,]*prop_fits2
    }

    # add the outplants to the orchard subpopulations
    for(ss in 1:s_orchard){

        for(rr in 1:source_orchard){ # for each lab source
          orchard_pops[[ss]][[rr]][1 ,i] <- orchard_pops[[ss]][[rr]][1 ,i] + orchard_outplants[ss,rr]

          orchard_pops[[ss]][[rr]][ ,i] <- orchard_pops[[ss]][[rr]][ ,i] + orchard_outplants1[ss,rr]*lab_pars$size_props[rr,]

        }

    }


  } # end of iteration over each year

 # return all the population metrics

  return(list(reef_pops = reef_pops, orchard_pops = orchard_pops, lab_pops = lab_pops,
              reef_rep = reef_rep, orchard_rep = orchard_rep))

}


# make function for creating summary data frames (total cover, total reproductive output)










