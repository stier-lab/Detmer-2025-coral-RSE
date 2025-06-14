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

  # holding list for survival probabilities of each size class
  S_list <- list()

  # errors (or could generate these in the for loop below to make them different for each life stage)
  set.seed(seed1) # set seed
  surv_errors <- rnorm(years, mean = 0, sd = sigma_s) # generate random errors (on log scale)

  for(i in 1:years){ # for each year in simulation

    S_i <- surv_pars*exp(surv_errors[i])
    S_i[which(S_i > 1)] <- 1 # make sure survival is never > 1

    S_list[[i]] <- S_i

  }


  return(S_list)


}

# test this
test1 <- Surv_fun(years = 10, n = 4, surv_pars = c(0.1, 0.25, 0.5, 0.90), sigma_s = 0.2)
test1[[1]]

# density dependent survival: put in full model function for now


# growth/shrinkage/fragmentation
# leave stochasticity out of this for now
# if adding stochasticity: get the growth, shrinkage, and staying (1-G-Sh) probabilities, then divide each by sum to make sure they sum to 1

#' @param years number of years in simulation
#' @param n number of size classes
#' @param growth_pars list of transition probabilities for each size class (each element of list = vector of growth probabilities from that size class to all others)
#' @param shrink_pars list of shrinkage/fragmentation probabilities for each size class (each element of list = vector of shrinkage probabilities from that size class to all others)

G_fun <- function(years, n, growth_pars, shrink_pars){

  # holding list (each element is matrix with all the growth/shrink parameters for a given year)

  G_list <- list()

  for(i in 1:years){ # for each year in the simulation

    # holding matrix
    Ti_mat <- matrix(NA, nrow = n, ncol = n) # transition matrix

    for(cc in 1:n){ # for each column of the transition matrix (i.e., each size class)

      if(cc == 1){ # if this is the first size class, growth only and no shrinking
        Ti_mat[(cc+1):n,cc] <- growth_pars[[cc]]

      } else if(cc == n){ # if this is the last size class, shrinking only and no growth

        Ti_mat[1:(cc-1), cc] <- shrink_pars[[cc]]


      } else{ # if this is not the smallest or largest size class

        Ti_mat[(cc+1):n,cc] <- growth_pars[[cc]] # probabilities of growing into each larger size class
        Ti_mat[1:(cc-1), cc] <- shrink_pars[[cc]] # probabilities of shrinking into each larger size class

      }

    } # end of first loop over columns

    # now fill in the diagonals (probabilities of staying = 1-sum of probabilities of growing or shrinking)
    Ti_mat[1, 1] <- 1-sum(Ti_mat[2:n, 1])
    Ti_mat[n, n] <- 1-sum(Ti_mat[1:(n-1), n])

    for(cc in 2:(n-1)){ # for each column from 2 to 1-n

      for(rr in 2:(n-1)){ # for each row
        if(cc==rr){
          Ti_mat[rr, cc] <- 1-sum(Ti_mat[1:(rr-1), cc]) - sum(Ti_mat[(rr+1):n, cc])
        }
      }

    } # end of second loop over columns

   G_list[[i]] <- Ti_mat # store the transition matrix for the ith year


  } # end of loop over years



  return(G_list)

}

# test this
# test2 <- G_fun(years = 10, n = 4, growth_pars = list(c(0.5, 0.1, 0), c(0.15, 0.01), c(0.05), NULL),
#                shrink_pars = list(NULL, c(0.02), c(0.01, 0.02), c(0.02, 0.04, 0.1)))
# test2.1 <- test2[[1]]
# sum(test2.1[,4])


# density dependent growth: put in full model function


# reproduction function
#' Reproduction function to generate fecundities in each year of the simulation
#' @param years number of years in simulation
#' @param n number of size classes
#' @param fec_pars mean fecundities of each size class
#' @param sigma_f standard deviation of survival probabilities
#' @param seed1 seed for random number generation

Rep_fun <- function(years, n, fec_pars, sigma_f = 0, seed1 = 10){

  # holding list for survival probabilities of each size class
  F_list <- list()

  # errors (or could generate these in the for loop below to make them different for each life stage)
  set.seed(seed1) # set seed
  fec_errors <- rnorm(years, mean = 0, sd = sigma_f) # generate random errors


  for(i in 1:years){ # for each year in simulation

    F_i <- fec_pars*exp(fec_errors[i])

    F_list[[i]] <- F_i

  }


  return(F_list)


}

# test this
test3 <- Rep_fun(years = 10, n = 4, fec_pars = c(0, 0.1, 1, 3), sigma_f = 0.2)
test3


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




