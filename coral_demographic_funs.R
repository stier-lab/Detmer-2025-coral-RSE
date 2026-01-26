#' README: demographic functions for creating datasets with coral growth, survival, and
#' reproduction parameters for each time step in the model simulation


#' @title Survival Function
#' @description Generates survival probabilities with environmental stochasticity for each
#'   year in the simulation. Survival values are modified by log-normal errors to introduce
#'   interannual variability while ensuring probabilities remain bounded between 0 and 1.
#'   No density dependence is included in this function.
#' @param years Number of years to simulate
#' @param n Number of size classes
#' @param surv_pars Vector of baseline survival probabilities for each size class
#' @param sigma_s Standard deviation for environmental variation (on log scale). Default = 0 (no stochasticity)
#' @param seed1 Random seed for reproducibility. Default = 10
#' @return List of length 'years' where each element is a vector of survival probabilities
#'   for each size class in that year
#' @export
Surv_fun <- function(years, n, surv_pars, sigma_s = 0, seed1 = 10){

  # holding list for survival probabilities of each size class
  S_list <- list()

  # errors (or could generate these in the for loop below to make them different for each life stage)
  set.seed(seed1) # set seed
  surv_errors <- rnorm(years, mean = 0, sd = sigma_s) # generate random errors (on log scale)

  for(i in 1:years){ # for each year in simulation

    # FIX: Properly bound survival between 0 and 1 (prevents negative values from extreme errors)
    S_i <- pmax(0, pmin(1, surv_pars * exp(surv_errors[i])))

    S_list[[i]] <- S_i

  }


  return(S_list)


}

# Test code removed - see function_tests.Rmd for testing
# test1 <- Surv_fun(years = 10, n = 4, surv_pars = c(0.1, 0.25, 0.5, 0.90), sigma_s = 0.2)
# test1[[1]]

# density dependent survival: put in full model function for now


#' @title Growth/Shrinkage/Fragmentation Function
#' @description Constructs transition matrices for coral size class dynamics including growth,
#'   shrinkage (partial mortality), and fragmentation. Transition matrices ensure column sums
#'   equal 1 (conservation of individuals), while fragmentation matrices can have column sums > 1
#'   since new individuals are created.
#' @details Currently does not include stochasticity. If adding stochasticity in future:
#'   get the growth, shrinkage, and staying (1-G-Sh) probabilities, then divide each by
#'   sum to make sure they sum to 1.
#' @param years Number of years in simulation
#' @param n Number of size classes
#' @param growth_pars List of transition probabilities for each size class. Each element is a
#'   vector of growth probabilities from that size class to all larger classes
#' @param shrink_pars List of shrinkage probabilities for each size class. Each element is a
#'   vector of shrinkage probabilities from that size class to all smaller classes
#' @param frag_pars List of fragmentation probabilities for each size class. Each element is a
#'   vector of probabilities of that size class creating fragments in each of the other size classes
#' @return List with two elements:
#'   \itemize{
#'     \item G_list: List of n x n transition matrices (growth/shrinkage) for each year
#'     \item Fr_list: List of n x n fragmentation matrices for each year
#'   }
#' @export
G_fun <- function(years, n, growth_pars, shrink_pars, frag_pars){

  # holding list (each element is matrix with all the growth/shrink parameters for a given year)

  G_list <- list() # for transition matrices at each timepoint
  Fr_list <- list() # for fragmentation matrices at each timepoint

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
        Ti_mat[1:(cc-1), cc] <- shrink_pars[[cc]] # probabilities of shrinking into each smaller size class

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

    # FIX: Validate that diagonal elements (stay probabilities) are non-negative
    if(any(diag(Ti_mat) < 0)) {
      warning("Growth + shrinkage probabilities exceed 1 for some size classes. Clamping to valid range.")
      diag(Ti_mat) <- pmax(0, diag(Ti_mat))
    }

    G_list[[i]] <- Ti_mat # store the transition matrix for the ith year

    # now make the fragmentation matrix
    Fi_mat <- matrix(0, nrow = n, ncol = n) # fragmentation matrix

    # now add the fragmentation probabilities (with these, columns can sum to >1 because new individuals are created by the fragments)
    # FIX: Fragments should only go to SMALLER size classes (rows 1 to cc-1, not 1 to cc)
    # UPDATE: Fragments can go to the same size class (e.g., if a large coral produced a large fragment, and both the fragment and original coral were both large enough to be in the original coral's size class)
    for(cc in 2:n){ # for each column of the transition matrix (i.e., each size class) except the smallest

       #Ti_mat[1:(cc-1), cc] <- Ti_mat[1:(cc-1), cc] + frag_pars[[cc]] # add probabilities of producing fragments in each smaller size class
      #Fi_mat[1:(cc-1), cc] <- frag_pars[[cc]][1:(cc-1)]  # Only smaller classes receive fragments
      Fi_mat[1:cc, cc] <- frag_pars[[cc]]

    } # end of third loop over columns


    Fr_list[[i]] <- Fi_mat # store the fragmentation matrix for the ith year


  } # end of loop over years



  return(list(G_list = G_list, Fr_list = Fr_list))

}

# Test code removed - see function_tests.Rmd for testing
# test2 <- G_fun(years = 10, n = 4, growth_pars = list(c(0.5, 0.1, 0), c(0.15, 0.01), c(0.05), NULL),
#                shrink_pars = list(NULL, c(0.02), c(0.01, 0.02), c(0.02, 0.04, 0.1)),
#                frag_pars = list(NULL, c(0), c(0.01, 0.02), c(0.02, 0.04, 0.1)))
# test2.1 <- test2[[1]]
# sum(test2.1[,4])


# density dependent growth: put in full model function


#' @title Reproduction Function
#' @description Generates fecundity values with environmental stochasticity for each year
#'   in the simulation. Fecundity represents the number of larvae/recruits produced by
#'   individuals in each size class. Values are modified by log-normal errors to introduce
#'   interannual variability.
#' @param years Number of years to simulate
#' @param n Number of size classes
#' @param fec_pars Vector of mean fecundities for each size class
#' @param sigma_f Standard deviation for environmental variation in fecundity (on log scale).
#'   Default = 0 (no stochasticity)
#' @param seed1 Random seed for reproducibility. Default = 10
#' @return List of length 'years' where each element is a vector of fecundity values
#'   for each size class in that year
#' @export
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

# Test code removed - see function_tests.Rmd for testing
# test3 <- Rep_fun(years = 10, n = 4, fec_pars = c(0, 0.1, 1, 3), sigma_f = 0.2)
# test3


#' @title External Recruitment Function
#' @description Generates external recruitment (settlers from outside the modeled population)
#'   for each year in the simulation. Can be constant or stochastic (Poisson-distributed).
#' @param years Number of years to simulate
#' @param lambda Mean number of external recruits per year
#' @param rand Logical. If TRUE, recruitment follows a Poisson distribution with mean lambda.
#'   If FALSE, recruitment is constant and equal to lambda every year. Default = FALSE
#' @param seed1 Random seed for reproducibility (only used if rand = TRUE). Default = 10
#' @return Vector of length 'years' containing the number of external recruits for each year
#' @export
Ext_fun <- function(years, lambda, rand = FALSE, seed1 = 10){

 if(rand == F){

   recruits <- rep(lambda, years)

 } else{

   set.seed(seed1)
   recruits <- rpois(years, lambda)
 }

  return(recruits)

}

# Test code removed - see function_tests.Rmd for testing
# test4 <- Ext_fun(10, 1, rand = T)




