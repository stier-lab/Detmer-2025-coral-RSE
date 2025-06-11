#' README: demographic functions for creating datasets with coral growth, survival, and
#' reproduction parameters for each time step in the model simulation


#' Survival function to generate baseline survival probabilities for each year in the simulation
#` (no density dependence)
#' @param years number of years in simulation
#' @param n number of size classes
#' @param surv_pars mean survival probabilities in each size class
#' @param sigma_s standard deviation of survival probabilities
#' @param seed1 seed for random number generation

Surv_fun <- function(years, n, surv_pars, sigma_s = 0, seed1 = 10){

  # errors (or could generate these in the for loop below to make them different for each life stage)
  set.seed(seed1) # set seed
  surv_errors <- rnorm(years, mean = 0, sd = sigma_s) # generate random errors

  for(i in 1:n){ # for each size class

    S_i <- rep(surv_pars[i], years) + surv_errors # survival probabilities at each time point

    # make sure survival is between 0 and 1 (should probably make the errors multiplicative to avoid this)
    for(j in 1:years){
      S_i[j] <- max(0, min(S_i[j], 1))
    }

    # store as data frame
    S_dfi <- data.frame(
      year = c(1:years), # year in simulation
      surv = S_i, # survival probabilities
      class = rep(i, years) # size class
    )

    if(i == 1){
      S_df <- S_dfi

    } else{

      S_df <- rbind(S_df, S_dfi)

    }

  }

  return(S_df)


}

# test this
# test1 <- Surv_fun(years = 10, n = 4, surv_pars = c(0.1, 0.25, 0.5, 0.90), sigma_s = 0.2)
# View(test1)

# density dependent survival: put in full model function for now


# growth/shrinkage/fragmentation
# leave stochasticity out of this for now
# but if adding stochasticity: get the growth, fragmentation, and shrinkage probabilities, then divide each by sum to make sure they sum to 1

#' @param years number of years in simulation
#' @param n number of size classes
#' @param growth_pars transition probabilities for each size class
#' @param shrink_pars shrinkage probabilities for each size class
#' @param frag_pars fragmentation probabilities for each size class

GSF_fun <- function(years, n, growth_pars, shrink_pars, frag_pars){

  for(i in 1:n){ # for each size class

    # store parameters as data frame
    GSF_dfi <- data.frame(
      year = c(1:years), # year in simulation
      G = growth_pars[i], # transition probabilities
      Sh = shrink_pars[i], # shrinkage probabilities
      Fr = frag_pars[i], # fragmentation probabilities
      class = rep(i, years) # size class
    )

    if(i == 1){
      GSF_df <- GSF_dfi

    } else{

      GSF_df <- rbind(GSF_df, GSF_dfi)

    }

  }

  return(GSF_df)

}

# test this
# test2 <- GSF_fun(years = 10, n = 4, growth_pars = c(0.1, 0.25, 0.5, 0.90), shrink_pars = c(0, 0.1, 0.2, 0.3), frag_pars = c(0, 0.2, 0.3, 0.4))
# View(test2)


# density dependent growth: put in full model function for now


# reproduction function
#' Reproduction function to generate fecundities in each year of the simulation
#' @param years number of years in simulation
#' @param n number of size classes
#' @param fec_pars mean fecundities of each size class
#' @param sigma_f standard deviation of survival probabilities
#' @param seed1 seed for random number generation

Rep_fun <- function(years, n, fec_pars, sigma_f = 0, seed1 = 10){

  # errors (or could generate these in the for loop below to make them different for each life stage)
  set.seed(seed1) # set seed
  fec_errors <- rnorm(years, mean = 0, sd = sigma_f) # generate random errors

  for(i in 1:n){ # for each size class

    if(fec_pars[i] == 0){ # if this stage is not reproductively mature
      F_i <- rep(fec_pars[i], years)
    } else{

      F_i <- rep(fec_pars[i], years) + fec_errors
    }


    # make sure fecundity isn't negative
    for(j in 1:years){
      F_i[j] <- max(0, F_i[j])
    }

    # store as data frame
    F_dfi <- data.frame(
      year = c(1:years), # year in simulation
      fecundity = F_i, # fecundities
      class = rep(i, years) # size class
    )

    if(i == 1){
      F_df <- F_dfi

    } else{

      F_df <- rbind(F_df, F_dfi)

    }

  }

  return(F_df)


}

# test this
# test3 <- Rep_fun(years = 10, n = 4, fec_pars = c(0, 0.1, 1, 3), sigma_f = 0.2)
# View(test3)


# external recruitment
#' @param years number of years in simulation
#' @param lambda mean number of recruits
#' @param rand logical, TRUE means recruitment is random, FALSE means it is constant and equal to lambda every year
#' @param seed1 seed for random number generation (if rand = T)
Ext_fun <- function(years, lambda, rand = FALSE, seed1 = 10){

 if(rand == F){

   recruits <- rep(lambda, years)

 } else{

   set.seed(seed1)
   recruits <- rpois(years, lambda)
 }

  return(recruits)

}

# test this
#test4 <- Ext_fun(10, 1, rand = T)




