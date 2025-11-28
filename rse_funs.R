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
#' @param sigma_f standard deviation of fecundity probabilities
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

#' parameterization function
#' make a function that takes data frames with parameter values as inputs and returns them in list form for the model
#' @param par_type "survival", "growth", or "fragmentation"
#' @param sample_dt if T, randomly sample a row from the full dataframe; if F, use the summ_metric from the summ_df
#' @param summ_df data frame (or list of dataframes) with summarized values (mean and 95% confidence intervals)
#' @param summ_metric metric indicating which summarized value to use (mean, Q05, Q95)
#' @param full_df data frame (or list of dataframes) with all available estimates of parameter values
#' @param n_sample number of samples from the full data frame to take (if sample_dt == T)
#' 
par_list_fun <- function(par_type, sample_dt, summ_df, summ_metric, full_df, n_sample){
  
  
if(par_type == "survival"){ # survival data
  
  if(sample_dt == F){ # if using summarized data
    
    surv_pars <- summ_df[, summ_metric]
    
  } else{ # if taking a random sample
    
    surv_pars <- matrix(NA, nrow = n_sample, ncol = 5)
    
    for(k in unique(full_df$size_class)){ # for each size class present
      
      df_sub <- full_df[which(full_df$size_class == k), ] # parameters for kth size class
      
        all_index <- c(1:nrow(df_sub))
        
        if(n_sample > nrow(df_sub)){ # if n_sample is bigger than the number of parameter values to sample from
          
          print("sample size too big; resampling parameter values")
          
          ki <- sample(all_index, size = n_sample, replace = T)
      
        } else{
          
          ki <- sample(all_index, size = n_sample, replace = F)
        }
        
        surv_pars[, k] <- df_sub$prop_survived[ki]
      
    }
    
  } # end of ifelse for whether to sample survival parameter values
  
}  # end of if par_type == "survival"
  
  
  if(par_type == "growth"){ # growth data
    
    if(sample_dt == F){ # if using summarized data
      
      growth_pars <- list(summ_df[[1]][-1, summ_metric], 
                          summ_df[[2]][-c(1:2), summ_metric],
                          summ_df[[3]][-c(1:3), summ_metric],
                          summ_df[[4]][-c(1:4), summ_metric],
                          NULL)
      
      shrink_pars <- list(NULL, 
                          summ_df[[2]][1, summ_metric],
                          summ_df[[3]][c(1:2), summ_metric],
                          summ_df[[4]][c(1:3), summ_metric],
                          summ_df[[5]][c(1:4), summ_metric])
      
    } else{ # if taking random samples
      
  
      # get the vectors with the rows to sample
      ki_all <- matrix(NA, nrow = n_sample, ncol = 5)
      
      for(k in 1:5){ # for each size class present
        
        df_sub <- full_df[[k]] # parameters for kth size class
        
        all_index <- c(1:nrow(df_sub))
        
        if(n_sample > nrow(df_sub)){ # if n_sample is bigger than the number of parameter values to sample from
          
          print("sample size too big; resampling parameter values")
          
          ki <- sample(all_index, size = n_sample, replace = T)
          
        } else{
          
          ki <- sample(all_index, size = n_sample, replace = F)
        }
        
        ki_all[ ,k] <- ki
        
      }
      
      # now fill in the growth and shrink parameters
      growth_pars <- list()
      shrink_pars <- list()
      
      for(i in 1:n_sample){
        
        growth_pars[[i]] <- list(full_df[[1]][ki_all[i, 1], -1], 
                                 full_df[[2]][ki_all[i, 2], -c(1:2)],
                                 full_df[[3]][ki_all[i, 3], -c(1:3)],
                                 full_df[[4]][ki_all[i, 4], -c(1:4)],
                                 NULL)
        
        shrink_pars[[i]] <- list(NULL, 
                                 full_df[[2]][ki_all[i, 2], 1],
                                 full_df[[3]][ki_all[i, 3], c(1:2)],
                                 full_df[[4]][ki_all[i, 4], c(1:3)],
                                 full_df[[5]][ki_all[i, 5], c(1:4)])

      
      }
      
    } # end of ifelse for whether to sample growth/shrink parameter values
    
  } # end of if par_type = growth
  
  if(par_type == "fragmentation"){ # fragmentation data
    
    if(sample_dt == F){ # if using summarized data
      # list(NULL, c(0, 0), c(0, 0, 0), c(F4_SC1, F4_SC2, F4_SC3, F4_SC4), c(F5_SC1, F5_SC2, F5_SC3, F5_SC4, F5_SC5)) 
      
      frag_pars <- list(NULL, c(0, 0), c(0, 0, 0),
      c(summ_df[which(summ_df$frag_type == "F4_SC1") ,summ_metric], summ_df[which(summ_df$frag_type == "F4_SC2") ,summ_metric], summ_df[which(summ_df$frag_type == "F4_SC3") ,summ_metric], summ_df[which(summ_df$frag_type == "F4_SC4") ,summ_metric]),
      c(summ_df[which(summ_df$frag_type == "F5_SC1") ,summ_metric], summ_df[which(summ_df$frag_type == "F5_SC2") ,summ_metric], summ_df[which(summ_df$frag_type == "F5_SC3") ,summ_metric], summ_df[which(summ_df$frag_type == "F5_SC4") ,summ_metric], summ_df[which(summ_df$frag_type == "F5_SC5") ,summ_metric]))
      
    } else{ # if taking random sample
      
      all_index <- c(1:nrow(full_df))
      
      if(n_sample > nrow(full_df)){ # if n_sample is bigger than the number of parameter values to sample from
        
        print("sample size too big; resampling parameter values")
        
        ki <- sample(all_index, size = n_sample, replace = T)
        
      } else{
        
        ki <- sample(all_index, size = n_sample, replace = F)
      }
      
      # now fill in the fragmentation parameters
      frag_pars <- list()
      
      for(i in 1:n_sample){
        
        df_sub <- full_df[ki[i], ]
        
        frag_pars[[i]] <- list(NULL, c(0, 0), c(0, 0, 0),
                               c(df_sub$F4_SC1, df_sub$F4_SC2, df_sub$F4_SC3, df_sub$F4_SC4),
                               c(df_sub$F5_SC1, df_sub$F5_SC2, df_sub$F5_SC3, df_sub$F5_SC4, df_sub$F5_SC5))
        
      }
      
      
      
    } # end of ifelse for whether to sample 
    
  } # end of if par_type = fragmentation
  
  # return values
  if(par_type == "survival"){
    return(list(surv_pars = surv_pars))
  }
  
  if(par_type == "growth"){
    return(list(growth_pars = growth_pars, shrink_pars = shrink_pars))
  }
  
  if(par_type == "fragmentation"){
    return(list(frag_pars = frag_pars))
  }
  
} # end of function


# function for setting up reef and orchard survival, growth/shrinkage, and fragmentation parameter values using summarized data
# assumes all reefs have same parameters, all orchards have same parameters, and all lab treatments have same parameters
#' @param n_reef number of intervention reefs
#' @param n_orchard number of orchards
#' @param n_lab number of lab treatments
#' @param summ_metric_list named list specifying the summary metrics (mean, Q05, or Q95) to use for each type of parameter (field_surv, field_growth, field_shrink, field_frag, nurs_surv, nurs_growth, nurs_shrink)

default_pars_fun <- function(n_reef, n_orchard, n_lab, summ_metric_list, field_surv, field_growth, nurs_surv, nurs_growth, apal_frag_summ){
  
  # reef
  surv_pars.r <- list() # reef survival
  growth_pars.r <- list() # reef growth
  shrink_pars.r <- list() # reef shrinkage 
  frag_pars.r <- list() # reef fragmentation 
  
  # get the parameter values
  surv_pars1 <- par_list_fun(par_type = "survival", sample_dt = F, summ_df = field_surv$SC_surv_summ_df, summ_metric = summ_metric_list$field_surv, full_df = NA, n_sample = NA)$surv_pars
  growth_pars1 <- par_list_fun(par_type = "growth", sample_dt = F, summ_df = field_growth$summ_list, summ_metric = summ_metric_list$field_growth, full_df = NA, n_sample = NA)$growth_pars
  shrink_pars1 <- par_list_fun(par_type = "growth", sample_dt = F, summ_df = field_growth$summ_list, summ_metric = summ_metric_list$field_shrink, full_df = NA, n_sample = NA)$shrink_pars
  frag_pars1 <- par_list_fun(par_type = "fragmentation", sample_dt = F, summ_df = apal_frag_summ, summ_metric = summ_metric_list$field_frag, full_df = NA, n_sample = NA)$frag_pars
  
  for(i in 1:n_reef){ # for each reef
    
    surv_pars.r[[i]] <- list() # ith reef treatment/subpop
    growth_pars.r[[i]] <- list()
    shrink_pars.r[[i]] <- list()
    frag_pars.r[[i]] <- list()
    
    for(j in 1:(n_lab + 1)){ # for each source to each reef
      
      surv_pars.r[[i]][[j]] <- surv_pars1 # survival probabilities for jth source of recruits to ith reef subpop (external recruits)
      growth_pars.r[[i]][[j]] <- growth_pars1
      shrink_pars.r[[i]][[j]] <- shrink_pars1
      frag_pars.r[[i]][[j]] <- frag_pars1
    }
    
  }
  
  # orchard
  surv_pars.o <- list() # orchard survival
  growth_pars.o <- list() # orchard growth
  shrink_pars.o <- list() # orchard shrinkage 
  
  # get the parameter values
  surv_pars2 <- par_list_fun(par_type = "survival", sample_dt = F, summ_df = nurs_surv$SC_surv_summ_df, summ_metric = summ_metric_list$nurs_surv, full_df = NA, n_sample = NA)$surv_pars
  growth_pars2 <- par_list_fun(par_type = "growth", sample_dt = F, summ_df = nurs_growth$summ_list, summ_metric = summ_metric_list$nurs_growth, full_df = NA, n_sample = NA)$growth_pars
  shrink_pars2 <- par_list_fun(par_type = "growth", sample_dt = F, summ_df = nurs_growth$summ_list, summ_metric = summ_metric_list$nurs_shrink, full_df = NA, n_sample = NA)$shrink_pars
  
  # assuming no fragmentation in orchard
  frag_pars2 <- list(NULL, c(0, 0), c(0, 0, 0), c(0, 0, 0, 0), c(0, 0, 0, 0, 0)) 
  

  for(i in 1:n_orchard){ # for each orchard
    
    surv_pars.o[[i]] <- list() # ith reef treatment/subpop
    growth_pars.o[[i]] <- list()
    shrink_pars.o[[i]] <- list()
    frag_pars.o[[i]] <- list()
    
    for(j in 1:n_lab){ # for each source to each orchard
      
      surv_pars.o[[i]][[j]] <- surv_pars2 # survival probabilities for jth source of recruits to ith reef subpop (external recruits)
      growth_pars.o[[i]][[j]] <- growth_pars2
      shrink_pars.o[[i]][[j]] <- shrink_pars2
      frag_pars.o[[i]][[j]] <- frag_pars2
      
    }
    
  }
  
  return(list(surv_pars.r = surv_pars.r, growth_pars.r = growth_pars.r, shrink_pars.r = shrink_pars.r,
              frag_pars.r = frag_pars.r, surv_pars.o = surv_pars.o, growth_pars.o = growth_pars.o, 
              shrink_pars.o = shrink_pars.o, frag_pars.o = frag_pars.o))
  
}

#function for setting up reef and orchard survival, growth/shrinkage, and fragmentation parameter values that vary randomly
# assumes same parameters for all sources (all lab treatments plus external recruits), but parameters can differ across reefs and across orchards
#' @param n_reef number of intervention reefs
#' @param n_orchard number of orchards
#' @param n_lab number of lab treatments
rand_pars_fun <- function(n_reef, n_orchard, n_lab, n_sample, field_surv, field_growth, nurs_surv, nurs_growth, apal_frag){

  
  # reef
  surv_pars_L.r <- list() # outermost holding lists for random iterations
  growth_pars_L.r <- list() # outermost holding lists for random iterations
  shrink_pars_L.r <- list() # outermost holding lists for random iterations
  frag_pars_L.r <- list() # outermost holding lists for random iterations 
    
  # for(nn in 1:n_sample){ # fill in empty holding lists
  #   surv_pars_L.r[[nn]] <- list() # outermost holding lists for random iterations
  #   growth_pars_L.r[[nn]] <- list() # outermost holding lists for random iterations
  #   shrink_pars_L.r[[nn]] <- list() # outermost holding lists for random iterations
  #   frag_pars_L.r[[nn]] <- list() # outermost holding lists for random iterations 
  #   
  # }
  
  # get the parameter sets for each reef
  surv_pars1 <- list() # reef survival
  growth_pars1 <- list() # reef growth
  shrink_pars1 <- list() # reef shrinkage 
  frag_pars1 <- list() # reef fragmentation 
  
  for(i in 1:n_reef){
    surv_pars1[[i]] <- par_list_fun(par_type = "survival", sample_dt = T, summ_df = NA, summ_metric = NA, full_df = field_surv$SC_surv_df, n_sample = n_sample)$surv_pars
    growth_pars1[[i]] <- par_list_fun(par_type = "growth", sample_dt = T, summ_df = NA, summ_metric = NA, full_df = field_growth$mat_list, n_sample= n_sample)$growth_pars
    shrink_pars1[[i]] <- par_list_fun(par_type = "growth", sample_dt = T, summ_df = NA, summ_metric = NA, full_df = field_growth$mat_list, n_sample= n_sample)$shrink_pars
    frag_pars1[[i]] <- par_list_fun(par_type = "fragmentation", sample_dt = T, summ_df = NA, summ_metric = NA, full_df = apal_frag, n_sample = n_sample)$frag_pars
    
  }
  
    surv_pars.r <- list() # reef survival
    growth_pars.r <- list() # reef growth
    shrink_pars.r <- list() # reef shrinkage 
    frag_pars.r <- list() # reef fragmentation 
    
    for(nn in 1:n_sample){ # for each random iteration
    
    for(i in 1:n_reef){ # for each reef
      
      # get the parameter values
      # surv_pars1 <- par_list_fun(par_type = "survival", sample_dt = T, summ_df = NA, summ_metric = NA, full_df = field_surv$SC_surv_df, n_sample = n_sample)$surv_pars
      # growth_pars1 <- par_list_fun(par_type = "growth", sample_dt = T, summ_df = NA, summ_metric = NA, full_df = field_growth$mat_list, n_sample= n_sample)$growth_pars
      # shrink_pars1 <- par_list_fun(par_type = "growth", sample_dt = T, summ_df = NA, summ_metric = NA, full_df = field_growth$mat_list, n_sample= n_sample)$shrink_pars
      # frag_pars1 <- par_list_fun(par_type = "fragmentation", sample_dt = T, summ_df = NA, summ_metric = NA, full_df = apal_frag, n_sample = n_sample)$frag_pars
      # 
        
        # holding list for each source to each reef
        surv_pars.r[[i]] <- list() # ith reef treatment/subpop
        growth_pars.r[[i]] <- list()
        shrink_pars.r[[i]] <- list()
        frag_pars.r[[i]] <- list()
        
        for(j in 1:(n_lab + 1)){ # for each source to each reef
          
          surv_pars.r[[i]][[j]] <- surv_pars1[[i]][nn,] # survival probabilities for jth source of recruits to ith reef subpop (external recruits)
          growth_pars.r[[i]][[j]] <- growth_pars1[[i]][[nn]]
          shrink_pars.r[[i]][[j]] <- shrink_pars1[[i]][[nn]]
          frag_pars.r[[i]][[j]] <- frag_pars1[[i]][[nn]]
        }
        
        
      } # end of iterations over each reef
      
      
      surv_pars_L.r[[nn]] <- surv_pars.r # nn^th random iteration for i^th reef
      growth_pars_L.r[[nn]] <- growth_pars.r
      shrink_pars_L.r[[nn]] <- shrink_pars.r
      frag_pars_L.r[[nn]] <- frag_pars.r
      
    } # end of random iterations 
    
    
  
  
  # orchard
    surv_pars_L.o <- list() # outermost holding lists for random iterations
    growth_pars_L.o <- list() # outermost holding lists for random iterations
    shrink_pars_L.o <- list() # outermost holding lists for random iterations
    frag_pars_L.o <- list() # outermost holding lists for random iterations
    
    
    # get the parameter sets for each orchard
    surv_pars2 <- list() # orchard survival
    growth_pars2 <- list() # orchard growth
    shrink_pars2 <- list() # orchard shrinkage 
    frag_pars2 <- list() # orchard fragmentation
    
    for(i in 1:n_reef){
      surv_pars2[[i]] <- par_list_fun(par_type = "survival", sample_dt = T, summ_df = NA, summ_metric = NA, full_df = nurs_surv$SC_surv_df, n_sample = n_sample)$surv_pars
      growth_pars2[[i]] <- par_list_fun(par_type = "growth", sample_dt = T, summ_df = NA, summ_metric = NA, full_df = nurs_growth$mat_list, n_sample= n_sample)$growth_pars
      shrink_pars2[[i]] <- par_list_fun(par_type = "growth", sample_dt = T, summ_df = NA, summ_metric = NA, full_df = nurs_growth$mat_list, n_sample= n_sample)$shrink_pars
      frag_pars2[[i]] <- rep(list(list(NULL, c(0, 0), c(0, 0, 0), c(0, 0, 0, 0), c(0, 0, 0, 0, 0))), n_sample)
      
    }
    
    
  surv_pars.o <- list() # orchard survival
  growth_pars.o <- list() # orchard growth
  shrink_pars.o <- list() # orchard shrinkage
  frag_pars.o <- list() # orchard fragmentation
  
  for(nn in 1:n_sample){ # for each random iteration
  
  for(i in 1:n_orchard){ # for each orchard
      
      # holding list for each source to each reef
      surv_pars.o[[i]] <- list() # ith reef treatment/subpop
      growth_pars.o[[i]] <- list()
      shrink_pars.o[[i]] <- list()
      frag_pars.o[[i]] <- list()
      
      for(j in 1:(n_lab + 1)){ # for each source to each reef
        
        surv_pars.o[[i]][[j]] <- surv_pars2[[i]][nn,] # survival probabilities for jth source of recruits to ith reef subpop (external recruits)
        growth_pars.o[[i]][[j]] <- growth_pars2[[i]][[nn]]
        shrink_pars.o[[i]][[j]] <- shrink_pars2[[i]][[nn]]
        frag_pars.o[[i]][[j]] <- frag_pars2[[i]][[nn]]
    
      }
      
      surv_pars_L.o[[nn]] <- surv_pars.o # nn^th random iteration for i^th reef
      growth_pars_L.o[[nn]] <- growth_pars.o
      shrink_pars_L.o[[nn]] <- shrink_pars.o
      frag_pars_L.o[[nn]] <- frag_pars.o
      
      
    } # end of iterations over each orchard
    
    
  } # end of random iterations
  
  return(list(surv_pars_L.r = surv_pars_L.r, growth_pars_L.r = growth_pars_L.r, shrink_pars_L.r = shrink_pars_L.r,
              frag_pars_L.r = frag_pars_L.r, surv_pars_L.o = surv_pars_L.o, growth_pars_L.o = growth_pars_L.o, 
              shrink_pars_L.o = shrink_pars_L.o, frag_pars_L.o = frag_pars_L.o))
  
}

#' lab function
#' make a function that takes the number of new babies from the orchard as an input and
#' returns the number of outplants that can go to the reef
#' this may or may not be a full population dynamics model, but either way I think it can
#' be separate from the orchard and reef models


# make a simpler model with a constant reference reef population
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
#' @param lambda_R mean number of larvae produced by reference reefs each year
#' @param sigma_s standard deviation of survival probabilities
#' @param sigma_f standard deviation of fecundities
#' @param ext_rand whether 1) external recruitment and 2) reference reef reproduction is stochastic (TRUE) or not (FALSE)
#' @param seeds vector with seeds for the random number generation for survival, fecundity, and recruitment
#' @param dist_yrs vector of years when reef disturbance occurs
#' @param dist_pars.r list with survival, growth/shrinkage (transition matrix) and fecundity parameters for each reef disturbance year
#' @param dist_effects.r which demographic parameters are affected by each reef disturbance
#' @param dist_pars.o list with survival, growth/shrinkage (transition matrix) and fecundity parameters for each orchard disturbance year
#' @param dist_effects.o which demographic parameters are affected by each orchard disturbance
#' @param orchard_treatments named list with all orchard treatments (including "none" for no treatment)
#' @param reef_treatments named list with all the intervention reef treatments 
#' @param lab_treatments named list with all lab treatments (including "none" for no treatment)
#' @param lab_pars parameters with lab yields for the different lab treatments
#' @param rest_pars restoration strategy parameters for determining how many recruits go to each treatment lab, reef, and orchard
#' @param N0.r initial population sizes in each reef subpopulation
#' @param N0.o initial population sizes in each orchard subpopulation
#' @param N0.l initial population sizes in each lab subpopulation

rse_mod1 <- function(years, n, A_mids, surv_pars.r, dens_pars.r, growth_pars.r, shrink_pars.r, 
                     frag_pars.r, fec_pars.r, surv_pars.o, dens_pars.o, growth_pars.o, 
                     shrink_pars.o, frag_pars.o, fec_pars.o, lambda, lambda_R, sigma_s, sigma_f, 
                     ext_rand, seeds, dist_yrs, dist_pars.r, dist_effects.r, dist_pars.o, 
                     dist_effects.o, orchard_treatments, reef_treatments, lab_treatments, lab_pars, 
                     rest_pars, N0.r, N0.o, N0.l){
  
  # reef subpops = length(lab_treatments)*length(reef_treatments)
  # lab subpops = length(lab_treatments)
  
  # orchard subpopulations:
  s_orchard <- length(orchard_treatments)
  
  # reef subpopulations:
  s_reef <- length(reef_treatments)
  
  # external recruitment each year
  ext_rec <- Ext_fun(years, lambda, rand = ext_rand[1], seed1 = seeds[3])
  # proportions going to each reef subpop (proportional to areas of each reef):
  ext_props <- rest_pars$reef_areas/sum(rest_pars$reef_areas)
  
  # larvae collected from reference reef each year
  ref_babies <- Ext_fun(years, lambda_R, rand = ext_rand[2], seed1 = seeds[4])
  
  # lab subpopulations
  s_lab <- length(lab_treatments)
  # subpopulations that will be outplanted immediately
  #s_lab0 <- length(which(substr(lab_treatments, start = 1, stop = 1) == "0"))
  # subpopulations that are retained in the lab for a year
  s_lab1 <- length(which(substr(lab_treatments, start = 1, stop = 1) == "1")) # "1_TX" = outplanted after 1 yr, "0_TX" = outplanted in same year
  
  # tile types
  tile_types <- rep(NA, s_lab)
  
  for(ss in 1:s_lab){
    tile_types[ss] <- substr(lab_treatments[ss], start = 3, stop = 4) # T1, T2, etc.
  }
  
  # make sure there's no duplicates:
  #tile_types = unique(tile_types)
  
  # sources of new recruits
  source_reef <- 1 + s_lab # number of possible sources of reef recruits (+1 is for external recruits)
  source_orchard <- s_lab # number of possible sources of orchard recruits
  
  # set up holding lists
  reef_pops <- list() # holding list for population sizes of each reef subpopulation
  reef_rep <- list() # holding list for total reproductive output from each reef subpopulation
  reef_mat_pars <- list() # list with data frames with the transition matrix parameters for each reef subpop
  reef_out <- list() # number of recruits outplanted to reef
  reef_pops_pre <- list() # reef population sizes before outplanting
  
  for(ss in 1:s_reef){
    
    # sublists for all the different sources of recruits to this reef
    reef_pops_ss <- list() # population sizes
    reef_rep_ss <- list() # total reproductive output
    reef_out_ss <- list() # numbers outplanted
    reef_pops_pre_ss <- list() # population sizes before outplanting
    reef_mat_pars_ss <- list() # matrix parameters
      
      for(rr in 1:source_reef){ # for each possible source of recruits to this reef subpop
        
        # holding matrix for number of individuals in each size class of the ss^th reef subpop from the rr^th source in each year
        reef_pops_ss[[rr]] <- matrix(NA, nrow = n, ncol = years)
        
        # holding matrix for total reproductive output by individuals in the ss^th reef subpop from the rr^th source each year
        reef_rep_ss[[rr]] <- rep(NA, years)
        
        # holding matrix for number of recruits outplanted
        reef_out_ss[[rr]] <- rep(NA, years)
        
        # holding matrix reef population size before outplanting
        reef_pops_pre_ss[[rr]] <- matrix(NA, nrow = n, ncol = years)
        
        # add initial conditions
        reef_pops_ss[[rr]][,1] <- N0.r[[ss]][[rr]]
        reef_pops_pre_ss[[rr]][,1] <- N0.r[[ss]][[rr]]
        
        # and get the list with the transition matrix parameters
        reef_mat_pars_ss[[rr]] <- mat_pars_fun(years, n, surv_pars.r[[ss]][[rr]], growth_pars.r[[ss]][[rr]],
                                               shrink_pars.r[[ss]][[rr]], frag_pars.r[[ss]][[rr]], fec_pars.r[[ss]][[rr]],
                                               sigma_s, sigma_f, seeds, dist_yrs, dist_pars.r[[ss]][[rr]],
                                               dist_effects.r[[ss]][[rr]])
        # fill in initial reproduction
        reef_rep_ss[[rr]][1] <- sum(reef_pops_ss[[rr]][,1]*reef_mat_pars_ss[[rr]]$fecundity[[1]])
        
      }
      
    
    # put all the sublists in the outer holding lists for each reef subpop
    
    reef_pops[[ss]] <- reef_pops_ss
    reef_pops_pre[[ss]] <- reef_pops_pre_ss
    reef_rep[[ss]] <- reef_rep_ss
    reef_out[[ss]] <- reef_out_ss
    reef_mat_pars[[ss]] <- reef_mat_pars_ss
    
    
  }
  
  # repeat for orchard subpops
  orchard_pops <- list()
  orchard_pops_pre <- list()
  orchard_rep <- list()
  orchard_out <- list()
  orchard_mat_pars <- list()
  
  for(ss in 1:s_orchard){
    
    # sublists for all the different sources of recruits to the orchard
    orchard_pops_ss <- list() # population sizes
    orchard_pops_pre_ss <- list() # population sizes before outplanting
    orchard_rep_ss <- list() # total reproductive output
    orchard_out_ss <- list() # numbers outplanted
    orchard_mat_pars_ss <- list() # matrix parameters
    
    for(rr in 1:source_orchard){ # for each source of recruits to the ss^th orchard treatment
      
      # holding matrix for number of individuals in each size class of the ss^th reef subpop in each year
      orchard_pops_ss[[rr]] <- matrix(NA, nrow = n, ncol = years)
      
      # holding matrix for number of individuals before outplanting
      orchard_pops_pre_ss[[rr]] <- matrix(NA, nrow = n, ncol = years)
      
      # holding matrix for total reproductive output by ss^th subpop each year
      orchard_rep_ss[[rr]] <- rep(NA, years)
      
      # holding matrix for number of recruits outplanted 
      orchard_out_ss[[rr]] <- rep(NA, years)
      
      # add initial conditions here too
      orchard_pops_ss[[rr]][,1] <- N0.o[[ss]][[rr]]
      orchard_pops_pre_ss[[rr]][,1] <- N0.o[[ss]][[rr]]
      
      # and calculate the data frames with the transition matrix parameters
      orchard_mat_pars_ss[[rr]] <- mat_pars_fun(years, n, surv_pars.o[[ss]][[rr]], growth_pars.o[[ss]][[rr]],
                                                shrink_pars.o[[ss]][[rr]], frag_pars.o[[ss]][[rr]],
                                                fec_pars.o[[ss]][[rr]], sigma_s, sigma_f, seeds, dist_yrs,
                                                dist_pars.o[[ss]][[rr]], dist_effects.o[[ss]][[rr]])
      # fill in initial reproduction
      orchard_rep_ss[[rr]][1] <- sum(orchard_pops_ss[[rr]][,1]*orchard_mat_pars_ss[[rr]]$fecundity[[1]])
      
      
    }
    
    
    orchard_pops[[ss]] <- orchard_pops_ss
    orchard_pops_pre[[ss]] <- orchard_pops_pre_ss
    orchard_rep[[ss]] <- orchard_rep_ss
    orchard_out[[ss]] <- orchard_out_ss
    orchard_mat_pars[[ss]] <- orchard_mat_pars_ss
    
  }
  
  
  # lab subpopulations
  lab_pops <- list()
  
  for(ss in 1:s_lab){
    
    # holding vectors for number of individuals in the ss^th lab treatment
    lab_pops[[ss]] <- rep(NA, years)
    
    # initial conditions
    lab_pops[[ss]][1] <- N0.l[[ss]]
    
  }
  
  
  
  for(i in 2:years){
    
    
    # steps:
    # 1) corals from previous year grow/die and external recruits settle on the reefs
    # 2) corals reproduce and orchard babies are collected and go to lab
    # 3) add lab recruits from same year and/or previous year 
    
    # restoration model: determines how many recruits/corals go in each treatment
    # should also keep track of the costs of each treatment (doesn't yet)
    # feedbacks = numbers going in to each treatment depends on population sizes, env., etc. (currently none)
    
    # reef dynamics
    
    # update the population size using the transition matrix:
    
    for(ss in 1:s_reef){ # for each reef subpopulation
        
        for(rr in 1:source_reef){ # for each source of recruits to this reef
          
          # get the transition matrix (growth, shrinkage, staying)
          T_mat <- reef_mat_pars[[ss]][[rr]]$growth[[i]]
          
          # get the fragmentation matrix
          F_mat <- reef_mat_pars[[ss]][[rr]]$fragmentation[[i]]
          
          # if the reef is full, assume none of the fragments produced over the last year result in new colonies
          if(sum(reef_pops[[ss]][[1]][ ,i-1]*A_mids) >= rest_pars$reef_areas[ss]){
            F_mat <- 0*F_mat
          }
          
          # get the survival probabilities
          S_i <- reef_mat_pars[[ss]][[rr]]$survival[[i]] # survival
          
        
          # update survival of the smallest size class with density dependence: 
          # first need to get total population size across all size classes and sources to this reef subpopulation
          N_all <- rep(NA, source_reef)
          
          for(rrr in 1:source_reef){
            N_all[rrr] <- sum(reef_pops[[ss]][[rrr]][,i-1])
          }
          
          # now update survival based on the total population size on this reef
          S_i[1] <- S_i[1]*exp(-dens_pars.r[[ss]][[rr]]*sum(N_all))
          
          N_mat <- reef_pops[[ss]][[rr]][,i-1] # population sizes in each size class at last time point
          N_mat <- N_mat*S_i # fractions surviving to current time point
          
          # now update the population sizes
          reef_pops[[ss]][[rr]][ ,i] <- (T_mat + F_mat) %*% matrix(N_mat, nrow = n, ncol = 1) # new population sizes
          
          # record this as the pre-outplant population size (population size before lab settlers are outplanted)
          reef_pops_pre[[ss]][[rr]][ ,i] <- reef_pops[[ss]][[rr]][ ,i]
          
          # amount of new larvae produced by this reef population at the i^th time point:
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
            
            # record this as the pre-outplant population size
            reef_pops_pre[[ss]][[rr]][ ,i] <- reef_pops[[ss]][[rr]][ ,i]
          }
          
        } # end of iterations over each source
        
      
      
    } # end of iterations over each reef subpop
    
    
    # orchard dynamics
    for(ss in 1:s_orchard){ # for each orchard treatment
      
      # calculate total number of colonies in this orchard across all sources
      ind_tots_ss <- rep(NA, source_orchard)
      
      for(rr in 1:source_orchard){
        
        ind_tots_ss[rr] <- sum(orchard_pops[[ss]][[rr]][ ,i-1]) # total colonies from rr^th source
      }
      
      ind_tots_s <- sum(ind_tots_ss) # total across all sources
      
      for(rr in 1:source_orchard){ # for each source of orchard recruits
        
        # get the transition matrix for this year
        T_mat <- orchard_mat_pars[[ss]][[rr]]$growth[[i]]
        
        # get the fragmentation matrix
        F_mat <- orchard_mat_pars[[ss]][[rr]]$fragmentation[[i]]
        
        if(ind_tots_s >= rest_pars$orchard_size[ss]){ # if the orchard is full
          F_mat <- 0*F_mat # assume no fragments survive
        }
        
        # get the survival probabilities for this year
        S_i <- orchard_mat_pars[[ss]][[rr]]$survival[[i]] # survival
        
        # update survival of smallest size classes with density dependence 
        N_all <- rep(NA, source_orchard)
        
        for(rrr in 1:source_orchard){
          N_all[rrr] <- sum(orchard_pops[[ss]][[rrr]][,i-1]) # total number of corals from rrr^th source in ss^th orchard
        }
        
        S_i[1] <- S_i[1]*exp(-dens_pars.o[[ss]][[rr]]*sum(N_all))
        
        N_mat <- orchard_pops[[ss]][[rr]][,i-1] # population sizes in each size class at last time point
        N_mat <- N_mat*S_i # fractions surviving to current time point
        
        # now update the population sizes:
        orchard_pops[[ss]][[rr]][ ,i] <- (T_mat + F_mat) %*% matrix(N_mat, nrow = n, ncol = 1)
        
        # record this as the pre-outplant population size
        orchard_pops_pre[[ss]][[rr]][ ,i] <- orchard_pops[[ss]][[rr]][ ,i]
        
        # amount of new larvae produced at i^th time point:
        orchard_rep[[ss]][[rr]][i] <- sum(orchard_pops[[ss]][[rr]][ ,i]*orchard_mat_pars[[ss]][[rr]]$fecundity[[i]])
        
        
      } # end of iterations over each orchard source
      
      
    } # end of iterations over each orchard treatment
    
    
    # calculate total new orchard babies collected
    # holding matrix for new orchard babies from colonies originating from each source in each orchard
    new_babies.o <- matrix(NA, nrow = s_orchard, ncol = source_orchard) # rows = number of orchard treatments, col = number of sources to the orchard
    
    for(ss in 1:s_orchard){ # for each orchard
      for(rr in 1:source_orchard){ # for each source of colonies to that orchard
        # new babies collected from these colonies = new babies produced by these colonies x percent successfully collected
        new_babies.o[ss,rr] <- orchard_rep[[ss]][[rr]][i]*rest_pars$orchard_yield # orchard_yield = percent of new orchard babies successfully collected
      }
    }
    
    # calculate total new babies collected from reference reefs this year
    new_babies.r <- ref_babies[i]*rest_pars$reef_yield
    
    tot_babies <- sum(new_babies.o) + new_babies.r # total new babies collected from orchard and reference reefs
    
    # make sure these don't exceed max lab capacity (assumed lab capacity is proportional to number of tiles)
    tot_babies <- min(tot_babies, rest_pars$lab_max)
    
    if(s_lab1==0){ # if none of the lab treatments keep the recruits for a year
      
      tot_settlers0 <- tot_babies # all the babies will be outplanted this year
      tot_settlers1 <- 0 # no babies will be kept for a year
      
    } else{
      
      # update tot_settlers1 based on max capacity for retaining settlers
      tot_settlers1 <- min(tot_babies, rest_pars$lab_retain_max)
      
      # babies that don't fit get added to the group being outplanted right away
      tot_settlers0 <- tot_babies - tot_settlers1
    }
    
    
    # holding vector for settlers in each lab treatment that will be immediately outplanted
    out_settlers <- rep(0, s_lab)
    
    # put the new babies into each lab treatment and determine how many survive
    for(ss in 1:s_lab){ # for each lab treatment
      
      if(substr(lab_treatments[ss], start = 1, stop = 1)=="0"){ # if settlers in ss^th lab treatment are outplanted immediately
        # settlers from this treatment being outplanted this year = total being outplanted this year x prop. of larvae that settle on this treatment when offered it x proportion of lab space devoted to this treatment
        out_settlers[ss] <- tot_settlers0*lab_pars$sett_props[[which(names(lab_pars$sett_props)==tile_types[ss])]]*rest_pars$tile_props[[which(names(rest_pars$tile_props)==tile_types[ss])]]
        
        # update out_settlers[ss] with the fraction of these that survive to outplanting
        out_settlers[ss] <- out_settlers[ss]*lab_pars$s0[ss]*exp(-lab_pars$m0[ss]*out_settlers[ss]) # m0 = density dependent mortality rate
        
      }
      
      if(substr(lab_treatments[ss], start = 1, stop = 1)=="1"){ # if settlers in ss^th lab treatment are retained for a year
        # settlers from this treatment to keep until next year = total being retained x prop. larvae that settle on this treatment x prop. of lab space devoted to this treatment
        retain_settlers <- tot_settlers1*lab_pars$sett_props[[which(names(lab_pars$sett_props)==tile_types[ss])]]*rest_pars$tile_props[[which(names(rest_pars$tile_props)==tile_types[ss])]]
        lab_pops[[ss]][i] <- retain_settlers*lab_pars$s1[ss]*exp(-lab_pars$m1[ss]*retain_settlers) # store survivors in the lab population
      }
      
      
      
    }
    
    
    # restoration actions: update all the population sizes based on restoration strategy
    # feedbacks on restoration actions (currently none): could mean updating the proportions of babies
    # and recruits going to different locations/treatments (lab_props, reef_prop, reef_out_props, orchard_out_props)
    
    # add the babies:
    # first make a matrix with the number of recruits going from each lab treatment to each reef treatment
    reef_outplants <- matrix(0, nrow = s_lab, ncol = s_reef) # from current timestep
    reef_outplants1 <- matrix(0, nrow = s_lab, ncol = s_reef) # from last time step
    
    for(ss in 1:s_lab){ # for each lab treatment
      
      # outplants going from ss^th lab treatment to each reef treatment
      reef_outplants[ss, ] <- out_settlers[ss]*rest_pars$reef_prop[ss]*rest_pars$reef_out_props[ss,]
      # reef_prop[ss] = proportion total outplants from ss lab treatment going to reefs (1- prop. going to orchards)
      # reef_out_props[ss,] = proportion of reef outplants from lab treatment ss going to each reef treatment
      
      if(substr(lab_treatments[ss], start = 1, stop = 1)=="1"){ # if recruits in ssth treatment were retained a year
        # then they come from the lab population at the previous timepoint
        reef_outplants1[ss, ] <- lab_pops[[ss]][i-1]*rest_pars$reef_prop[ss]*rest_pars$reef_out_props[ss,]
      }
      
    }
    
    # apply space constraints: total recruits from all lab treatments going to a given reef treatment can't exceed available space in that reef subpopulation
    # first calculate total number of recruits (from all lab treatments) going to each reef treatment
    #new_reef_tots <- apply(reef_outplants, 2, sum)
    
    # calculate total area currently occupied by each reef subpopulation
    area_tots <- rep(NA, s_reef)
    for(ss in 1:s_reef){
      
      # if(ss == 1){
      #   area_tots[ss] <- sum(reef_pops[[ss]][[1]][ ,i]*A_mids) # area covered by all corals in ss^th reef
      # } else{
        
        area_tots_ss <- rep(NA, source_reef)
        
        for(rr in 1:source_reef){
          area_tots_ss[rr] <- sum(reef_pops[[ss]][[rr]][ ,i]*A_mids)
        }
        
        area_tots[ss] <- sum(area_tots_ss)
     # }
      
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
      
        for(rr in 2:source_reef){ # for each lab source (rr = 1 is for external recruits)
          reef_pops[[ss]][[rr]][ ,i] <- reef_pops[[ss]][[rr]][ ,i] + reef_outplants[rr-1,ss]*lab_pars$size_props[rr-1,] # # need rr-1 here because the reef_outplants matrix only includes the lab treatments as sources (first source is external recruitment)
          
          # add the recruits from the previous year
          reef_pops[[ss]][[rr]][ ,i] <- reef_pops[[ss]][[rr]][ ,i] + reef_outplants1[rr-1,ss]*lab_pars$size_props[rr-1,] # size_props1 specifies the fractions of last years lab recruits that are now in each size class
          
          # store the numbers being outplanted
          reef_out[[ss]][[rr]][i] <- reef_outplants[rr-1,ss] + reef_outplants1[rr-1,ss]
          
        }
      
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
    new_orchard_tots <- apply(orchard_outplants, 2, sum)
    
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
      
      # if(occupied_ind_pp >= tot_ind_pp){ # if the orchard is full
      #   prop_fits2[pp] <- 0 # no new recruits can be added
      # } else{ # else if there's still space
      #   prop_fits2[pp] <- 1 # add the new recruits
      # }
      
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
    
    for(ss in 1:s_lab){ # for each lab treatment
      orchard_outplants[ss,] <- orchard_outplants[ss,]*prop_fits2
      orchard_outplants1[ss,] <- orchard_outplants1[ss,]*prop_fits2
    }
    
    # add the outplants to the orchard subpopulations
    for(ss in 1:s_orchard){
      
      for(rr in 1:source_orchard){ # for each lab source
        orchard_pops[[ss]][[rr]][ ,i] <- orchard_pops[[ss]][[rr]][ ,i] + orchard_outplants[rr,ss]*lab_pars$size_props[rr,]
        
        orchard_pops[[ss]][[rr]][ ,i] <- orchard_pops[[ss]][[rr]][ ,i] + orchard_outplants1[rr,ss]*lab_pars$size_props[rr,]
        
        # store the numbers being outplanted
        orchard_out[[ss]][[rr]][i] <- orchard_outplants[rr,ss] + orchard_outplants1[rr,ss]
      }
      
    }
    
    # also make a holding matrix for the recruits that didn't fit in the orchard and go to the reef instead
    # want to distribute these evenly across all intervention reefs 
      
      extra_orchard_outplants <- matrix(0, nrow = s_lab, ncol = s_reef) # this year's
      extra_orchard_outplants1 <- matrix(0, nrow = s_lab, ncol = s_reef) # last year's
      
      for(ss in 1:s_lab){ # for each lab treatment
        
        #extra_orchard_outplants[ss,which(reef_treatments!="none")] <- rep(sum(orchard_outplants[ss,]*(1-prop_fits2))/(length(which(reef_treatments!="none"))), length(which(reef_treatments!="none"))) # this year's
        #extra_orchard_outplants1[ss,which(reef_treatments!="none")] <- rep(sum(orchard_outplants1[ss,]*(1-prop_fits2))/length(which(reef_treatments!="none")), length(which(reef_treatments!="none"))) # last year's
        
        extra_orchard_outplants[ss, ] <- rep(sum(orchard_outplants[ss,]*(1-prop_fits2))/length(reef_treatments), length(reef_treatments)) # this year's
        extra_orchard_outplants1[ss, ] <- rep(sum(orchard_outplants1[ss,]*(1-prop_fits2))/length(reef_treatments), length(reef_treatments)) # last year's
        
      }
      
      
      # add the extras to the reef subpopulations (if there's room on the reef)
      for(ss in 1:s_reef){
        if(prop_fits[ss] !=0){
          
            for(rr in 2:source_reef){ # for each lab source (rr = 1 is for external recruits)
              reef_pops[[ss]][[rr]][ ,i] <- reef_pops[[ss]][[rr]][ ,i] + extra_orchard_outplants[rr-1,ss]*lab_pars$size_props[rr-1,] # # need rr-1 here because the reef_outplants matrix only includes the lab treatments as sources (first source is external recruitment)
              
              # add the recruits from the previous year
              reef_pops[[ss]][[rr]][ ,i] <- reef_pops[[ss]][[rr]][ ,i] + extra_orchard_outplants1[rr-1,ss]*lab_pars$size_props[rr-1,] # size_props1 specifies the fractions of last years lab recruits that are now in each size class
              
              # update the numbers being outplanted
              reef_out[[ss]][[rr]][i] <- reef_out[[ss]][[rr]][i] + extra_orchard_outplants[rr-1,ss] + extra_orchard_outplants1[rr-1,ss]
            }
          
        }
      } # end of iteration over reef subpopulations
      
    
    # now add any colony transplants from the orchard to the reef
    
    if(rest_pars$transplant[i]==1){ # if colonies are moved from orchard to reef this year
      
      # get the corals that will be transplanted from each size class
      #colony_mats <- list() # holding list for matrices with number of transplant colonies
      
      for(ss in 1:s_orchard){ # for each orchard subpopulation
        
        #colony_mat_ss <- list()
        
        for(rr in 1:source_orchard){ # for each lab source
          
          trans_colonies <- rest_pars$trans_mats[[ss]][[rr]][i,]
          
          # make sure these don't exceed the numbers in the population
          for(nn in 1:n){ # for each size class
            # if number to transplant is greater than number available at this timepoint, then only transplant the number of colonies available
            trans_colonies[nn] <- ifelse(trans_colonies[nn] > orchard_pops[[ss]][[rr]][nn ,i], orchard_pops[[ss]][[rr]][nn ,i], trans_colonies[nn])
          }
          
          # add the colonies to the correct reef population
          ss.reef <- rest_pars$trans_reef[[ss]][[rr]][i,1] # [i,1] = reef receiving the corals from the ith transplant from the ss/rr^th orchard population
          rr.reef <- rest_pars$trans_reef[[ss]][[rr]][i,2] # [i, 2] = reef source subpopulation (e.g., lab treatment 1 outplants, etc.) receiving the corals from the ith transplant from the ss/rr^th orchard population
          
          if(prop_fits[ss.reef] !=0){ # if there's room on this reef
            reef_pops[[ss.reef]][[rr.reef]][ ,i] <-  reef_pops[[ss.reef]][[rr.reef]][ ,i] + trans_colonies
            # and substract these from the orchard
            orchard_pops[[ss]][[rr]][ ,i] <- orchard_pops[[ss]][[rr]][ ,i] - trans_colonies
          }
          
        } # end of iteration over all source subpopulations in ss^th orchard
        
      } # end of iteration over all orchards
      
    } # end of if statement for transplanting colonies
    
  } # end of iteration over each year
  
  # return all the population metrics
  
  return(list(reef_pops = reef_pops, orchard_pops = orchard_pops, lab_pops = lab_pops,
              reef_rep = reef_rep, orchard_rep = orchard_rep, reef_out = reef_out, 
              orchard_out = orchard_out, reef_pops_pre = reef_pops_pre, 
              orchard_pops_pre = orchard_pops_pre))
  
}

# function for calculating lambda from the transition matrix parameters

pop_lambda_fun <- function(surv_pars, growth_pars, shrink_pars, frag_pars){
  
  # growth/shrinkage and fragmentation matrices
  all_mats <- G_fun(1, n = 5, growth_pars, shrink_pars, frag_pars)
  G_list <- all_mats$G_list
  Fr_list <- all_mats$Fr_list
  
  Tmat.i <- G_list[[1]]
  Fmat.i <- Fr_list[[1]]
  
  # calculate lambda (population growth rate)
  pop_mat <-  (Tmat.i + Fmat.i) * matrix(surv_pars, nrow = 5, ncol = 5, byrow = T)
  lambda_1 <- Re(eigen(pop_mat)$values[1]) # leading eigenvalue
  
  return(lambda_1)
  
}

# function for summarizing model output
#' @param model_sim full output from model simulation
#' @param years number of years in model simulation
#' @param location "reef" or "orchard"
#' @param metric metric of choice ("ind" = number of individuals, "area_m2" = area covered in m2, "production" = reproductive output)
#' @param n_reef number of reefs
#' @param n_orchard number of orchards
#' @param n_lab number of treatments

model_summ <- function(model_sim, location, metric, n_reef, n_orchard, n_lab){
  
  if(location == "reef"){
    
    if(metric == "ind"){
      
      # holding matrix for total population size in each reef at each time point
      out_mat <- matrix(NA, nrow = years, ncol = n_reef)
      
      for(i in 1:n_reef){ # for each reef
        
        reef_tot <- apply(model_sim$reef_pops_pre[[i]][[1]], MARGIN = 2, sum)
        
        if(n_lab > 0){ # if there was at least one lab source
          
          for(j in 1:n_lab){ # add total individuals from each lab source
            
            reef_tot <- reef_tot + apply(model_sim$reef_pops_pre[[i]][[1 + j]], MARGIN = 2, sum)
          }
          
        }
        
        out_mat[,i] <- reef_tot
        
      }
      
    } # end of if metric == ind
    
    if(metric == "area_m2"){
      
      out_mat <- matrix(NA, nrow = years, ncol = n_reef)
      
      for(i in 1:n_reef){ # for each reef
        
        reef_tot <- rep(NA, years)
        
        for(tt in 1:years){ # for each timestep
          
          reef_tot_tt <- sum(model_sim$reef_pops_pre[[i]][[1]][,tt]*A_mids) # calculate total area covered by individuals on ith reef from first source
          
          if(n_lab > 0){ # if there was at least one lab source
            
            for(j in 1:n_lab){ # add total individuals from each lab source
              
              reef_tot_tt <- reef_tot_tt + sum(model_sim$reef_pops_pre[[i]][[1 + j]][,tt]*A_mids)
            }
            
          }
          
          reef_tot[tt] <- reef_tot_tt/10000 # convert from cm2 to m2
          
        }
        
        out_mat[,i] <- reef_tot
      }
      
    } # end of if metric == area_m2
    
    
    if(metric == "production"){
      
      # holding matrix for total population size in each reef at each time point
      out_mat <- matrix(NA, nrow = years, ncol = n_reef)
      
      for(i in 1:n_reef){ # for each reef
        
        reef_tot <- model_sim$reef_rep[[i]][[1]]
        
        if(n_lab > 0){ # if there was at least one lab source
          
          for(j in 1:n_lab){ # add total individuals from each lab source
            
            reef_tot <- reef_tot + model_sim$reef_rep[[i]][[1 + j]]
          }
          
        }
        
        out_mat[,i] <- reef_tot
        
      }
      
    } # end of if metric == production
    
    
  } # end of if location == reef
  
  
  if(location == "orchard"){
    
    if(metric == "ind"){
      
      # holding matrix for total population size in each orchard at each time point
      out_mat <- matrix(NA, nrow = years, ncol = n_orchard)
      
      for(i in 1:n_orchard){ # for each orchard
        
        orchard_tot <- 0 # placeholder vector
        
        if(n_lab > 0){ # if there was at least one lab source
          
          for(j in 1:n_lab){ # add total individuals from each lab source
            
            orchard_tot <- orchard_tot + apply(model_sim$orchard_pops_pre[[i]][[j]], MARGIN = 2, sum)
          }
          
        }
        
        out_mat[,i] <- orchard_tot
        
      }
      
    } # end of if metric == ind
    
    if(metric == "area_m2"){
      
      out_mat <- matrix(NA, nrow = years, ncol = n_orchard)
      
      for(i in 1:n_orchard){ # for each orchard
        
        orchard_tot <- rep(NA, years)
        
        for(tt in 1:years){ # for each timestep
          
          orchard_tot_tt <- 0 # placeholder vector
          
          if(n_lab > 0){ # if there was at least one lab source
            
            for(j in 1:n_lab){ # add total individuals from each lab source
              
              orchard_tot_tt <- orchard_tot_tt + sum(model_sim$orchard_pops_pre[[i]][[j]][,tt]*A_mids) # calculate total area covered by individuals on ith orchard from jth source
            }
            
          }
          
          orchard_tot[tt] <- orchard_tot_tt/10000
          
        }
        
        out_mat[,i] <- orchard_tot
      }
      
    } # end of if metric == area_m2
    
    
    if(metric == "production"){
      
      # holding matrix for total population size in each orchard at each time point
      out_mat <- matrix(NA, nrow = years, ncol = n_orchard)
      
      for(i in 1:n_orchard){ # for each orchard
        
        orchard_tot <- 0 # placeholder vector
        
        if(n_lab > 0){ # if there was at least one lab source
          
          for(j in 1:n_lab){ # add total individuals from each lab source
            
            orchard_tot <- orchard_tot + model_sim$orchard_rep[[i]][[j]]
          }
          
        }
        
        out_mat[,i] <- orchard_tot
        
      }
      
    } # end of if metric == production
    
    
  } # end of if location == orchard
  
  return(out_mat)
  
} 



#' more complicated function with restoration reef dynamics
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
  s_lab1 <- length(which(substr(lab_treatments, start = 1, stop = 1) == "1"))
  
  # tile types
  tile_types <- rep(NA, s_lab)
  
  for(ss in 1:s_lab){
    tile_types[ss] <- substr(lab_treatments[ss], start = 3, stop = 4) # T1, T2, etc.
  }
  
  # make sure there's no duplicates:
  #tile_types = unique(tile_types)

  # sources of new recruits
  source_reef <- 1 + s_lab # number of possible sources of reef recruits (+1 is for external recruits)
  source_orchard <- s_lab # number of possible sources of orchard recruits

  # set up holding lists
  reef_pops <- list() # holding list for population sizes of each reef subpopulation
  reef_rep <- list() # holding list for total reproductive output from each reef subpopulation
  reef_mat_pars <- list() # list with data frames with the transition matrix parameters for each reef subpop

  # number of recruits outplanted to reef
  reef_out <- list()
  
  # reef population sizes before outplanting
  reef_pops_pre <- list()
  
  for(ss in 1:s_reef){

    # sublists for all the different sources of recruits to this reef
    reef_pops_ss <- list() # population sizes
    reef_rep_ss <- list() # total reproductive output
    reef_out_ss <- list() # numbers outplanted
    reef_pops_pre_ss <- list() # population sizes before outplanting
    reef_mat_pars_ss <- list() # matrix parameters

    if(reef_treatments[ss] == "none"){ # if this is the reference site

      # holding matrix for number of individuals in each size class of reference reef pop'n in each year
      reef_pops_ss[[1]] <- matrix(NA, nrow = n, ncol = years)

      # holding matrix for total reproductive output by ss^th subpop each year
      reef_rep_ss[[1]] <- rep(NA, years)
      
      # holding matrix for number of recruits outplanted
      reef_out_ss[[1]] <- rep(NA, years)
      
      # reef population size before outplanting
      reef_pops_pre_ss[[1]] <- matrix(NA, nrow = n, ncol = years)

      # add initial conditions
      reef_pops_ss[[1]][,1] <- N0.r[[ss]][[1]]
      reef_pops_pre_ss[[1]][,1] <- N0.r[[ss]][[1]]

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
        
        # holding matrix for number of recruits outplanted
        reef_out_ss[[rr]] <- rep(NA, years)
        
        # holding matrix reef population size before outplanting
        reef_pops_pre_ss[[rr]] <- matrix(NA, nrow = n, ncol = years)

        # add initial conditions
        reef_pops_ss[[rr]][,1] <- N0.r[[ss]][[rr]]
        reef_pops_pre_ss[[rr]][,1] <- N0.r[[ss]][[rr]]

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
    reef_pops_pre[[ss]] <- reef_pops_pre_ss
    reef_rep[[ss]] <- reef_rep_ss
    reef_out[[ss]] <- reef_out_ss
    reef_mat_pars[[ss]] <- reef_mat_pars_ss


  }

  # repeat for orchard subpops
  orchard_pops <- list()
  orchard_pops_pre <- list()
  orchard_rep <- list()
  orchard_out <- list()
  orchard_mat_pars <- list()

  for(ss in 1:s_orchard){

    # sublists for all the different sources of recruits to the orchard
    orchard_pops_ss <- list() # population sizes
    orchard_pops_pre_ss <- list() # population sizes before outplanting
    orchard_rep_ss <- list() # total reproductive output
    orchard_out_ss <- list() # numbers outplanted
    orchard_mat_pars_ss <- list() # matrix parameters

    for(rr in 1:source_orchard){ # for each source of recruits to the ss^th orchard treatment

      # holding matrix for number of individuals in each size class of the ss^th reef subpop in each year
      orchard_pops_ss[[rr]] <- matrix(NA, nrow = n, ncol = years)
      
      # holding matrix for number of individuals before outplanting
      orchard_pops_pre_ss[[rr]] <- matrix(NA, nrow = n, ncol = years)

      # holding matrix for total reproductive output by ss^th subpop each year
      orchard_rep_ss[[rr]] <- rep(NA, years)
      
      # holding matrix for number of recruits outplanted 
      orchard_out_ss[[rr]] <- rep(NA, years)

      # add initial conditions here too
      orchard_pops_ss[[rr]][,1] <- N0.o[[ss]][[rr]]
      orchard_pops_pre_ss[[rr]][,1] <- N0.o[[ss]][[rr]]

      # and calculate the data frames with the transition matrix parameters
      orchard_mat_pars_ss[[rr]] <- mat_pars_fun(years, n, surv_pars.o[[ss]][[rr]], growth_pars.o[[ss]][[rr]],
                                             shrink_pars.o[[ss]][[rr]], frag_pars.o[[ss]][[rr]],
                                             fec_pars.o[[ss]][[rr]], sigma_s, sigma_f, seeds, dist_yrs,
                                             dist_pars.o[[ss]][[rr]], dist_effects.o[[ss]][[rr]])
      # fill in initial reproduction
      orchard_rep_ss[[rr]][1] <- sum(orchard_pops_ss[[rr]][,1]*orchard_mat_pars_ss[[rr]]$fecundity[[1]])


    }


    orchard_pops[[ss]] <- orchard_pops_ss
    orchard_pops_pre[[ss]] <- orchard_pops_pre_ss
    orchard_rep[[ss]] <- orchard_rep_ss
    orchard_out[[ss]] <- orchard_out_ss
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
        
        reef_pops_pre[[ss]][[1]][ ,i] <- reef_pops[[ss]][[1]][ ,i]
        


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

          # record this as the pre-outplant population size
          reef_pops_pre[[ss]][[rr]][ ,i] <- reef_pops[[ss]][[rr]][ ,i]
          
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
            
            # record this as the pre-outplant population size
            reef_pops_pre[[ss]][[rr]][ ,i] <- reef_pops[[ss]][[rr]][ ,i]
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
        
        # record this as the pre-outplant population size
        orchard_pops_pre[[ss]][[rr]][ ,i] <- orchard_pops[[ss]][[rr]][ ,i]

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
    
    # make sure these don't exceed max lab capacity
    tot_babies <- min(tot_babies, rest_pars$lab_max)
    
    if(s_lab1==0){ # if none of the lab treatments keep the recruits for a year
      
      tot_settlers0 <- tot_babies
      tot_settlers1 <- 0
      
    } else{
      
      # determine how many can stay for a year
      tot_settlers1 <- min(tot_babies, rest_pars$lab_retain_max)
      
      # remaining babies are outplanted right away
      tot_settlers0 <- tot_babies - tot_settlers1
    }
    
    
    # need parameter for max number that the lab can handle, and then a number for the max
    # that can be retained for a year, and then have a hierarchy so everything that can be retained
    # is and any leftovers get outplanted immediately
    
    # lab_pars$sett_props[[which(names(lab_pars$sett_props)==tile_types[ss])]]
    # tile_types

    # holding vector for settlers on each lab treatment that will be immediately outplanted
    out_settlers <- rep(0, s_lab)

    # put the new babies into each lab treatment and determine how many survive
    for(ss in 1:s_lab){
      
      if(substr(lab_treatments[ss], start = 1, stop = 1)=="0"){ # if settlers in ss^th lab treatment are outplanted immediately
        out_settlers[ss] <- tot_settlers0*lab_pars$sett_props[[which(names(lab_pars$sett_props)==tile_types[ss])]]*rest_pars$tile_props[[which(names(rest_pars$tile_props)==tile_types[ss])]]
        
        # determine the fraction of these that survive to outplanting
        out_settlers[ss] <- out_settlers[ss]*lab_pars$s0[ss] # ADD density dependence here?
        
      }
      
      if(substr(lab_treatments[ss], start = 1, stop = 1)=="1"){ # if settlers in ss^th lab treatment are retained for a year
        retain_settlers <- tot_settlers1*lab_pars$sett_props[[which(names(lab_pars$sett_props)==tile_types[ss])]]*rest_pars$tile_props[[which(names(rest_pars$tile_props)==tile_types[ss])]]
        lab_pops[[ss]][i] <- retain_settlers*lab_pars$s1[ss] # store these in the lab population
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
          reef_pops[[ss]][[rr]][ ,i] <- reef_pops[[ss]][[rr]][ ,i] + reef_outplants[rr-1,ss]*lab_pars$size_props[rr-1,] # # need rr-1 here because the reef_outplants matrix only includes the lab treatments as sources (first source is external recruitment)

          # add the recruits from the previous year
          reef_pops[[ss]][[rr]][ ,i] <- reef_pops[[ss]][[rr]][ ,i] + reef_outplants1[rr-1,ss]*lab_pars$size_props[rr-1,] # size_props1 specifies the fractions of last years lab recruits that are now in each size class
        
          # store the numbers being outplanted
          reef_out[[ss]][[rr]][i] <- reef_outplants[rr-1,ss] + reef_outplants1[rr-1,ss]
        
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
    new_orchard_tots <- apply(orchard_outplants, 2, sum)

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

    for(ss in 1:s_lab){ # for each lab treatment
      orchard_outplants[ss,] <- orchard_outplants[ss,]*prop_fits2
      orchard_outplants1[ss,] <- orchard_outplants1[ss,]*prop_fits2
    }
    
    # add the outplants to the orchard subpopulations
    for(ss in 1:s_orchard){
      
      for(rr in 1:source_orchard){ # for each lab source
        orchard_pops[[ss]][[rr]][ ,i] <- orchard_pops[[ss]][[rr]][ ,i] + orchard_outplants[rr,ss]*lab_pars$size_props[rr,]
        
        orchard_pops[[ss]][[rr]][ ,i] <- orchard_pops[[ss]][[rr]][ ,i] + orchard_outplants1[rr,ss]*lab_pars$size_props[rr,]
        
        # store the numbers being outplanted
        orchard_out[[ss]][[rr]][i] <- orchard_outplants[rr,ss] + orchard_outplants1[rr,ss]
      }
      
    }
    
    # also make a holding matrix for the recruits that didn't fit in the orchard and go to the reef instead
    # want to distribute these evenly across all intervention reefs 
    
    # if there is at least one intervention reef
    if(length(which(reef_treatments!="none")) > 0){
      
    extra_orchard_outplants <- matrix(0, nrow = s_lab, ncol = s_reef) # this year's
    extra_orchard_outplants1 <- matrix(0, nrow = s_lab, ncol = s_reef) # last year's
    
    for(ss in 1:s_lab){ # for each lab treatment
      
      extra_orchard_outplants[ss,which(reef_treatments!="none")] <- rep(sum(orchard_outplants[ss,]*(1-prop_fits2))/(length(which(reef_treatments!="none"))), length(which(reef_treatments!="none"))) # this year's
      extra_orchard_outplants1[ss,which(reef_treatments!="none")] <- rep(sum(orchard_outplants1[ss,]*(1-prop_fits2))/length(which(reef_treatments!="none")), length(which(reef_treatments!="none"))) # last year's
      
    }

    
    # add the extras to the reef subpopulations (if there's room on the reef)
      for(ss in 1:s_reef){
        if(prop_fits[ss] !=0){
        
        if(reef_treatments[ss] != "none"){ # if this isn't a reference site (where zero outplants are added)
          
          for(rr in 2:source_reef){ # for each lab source (rr = 1 is for external recruits)
            reef_pops[[ss]][[rr]][ ,i] <- reef_pops[[ss]][[rr]][ ,i] + extra_orchard_outplants[rr-1,ss]*lab_pars$size_props[rr-1,] # # need rr-1 here because the reef_outplants matrix only includes the lab treatments as sources (first source is external recruitment)
            
            # add the recruits from the previous year
            reef_pops[[ss]][[rr]][ ,i] <- reef_pops[[ss]][[rr]][ ,i] + extra_orchard_outplants1[rr-1,ss]*lab_pars$size_props[rr-1,] # size_props1 specifies the fractions of last years lab recruits that are now in each size class
            
            # update the numbers being outplanted
            reef_out[[ss]][[rr]][i] <- reef_out[[ss]][[rr]][i] + extra_orchard_outplants[rr-1,ss] + extra_orchard_outplants1[rr-1,ss]
          }
        }
      }
    } # end of iteration over reef subpopulations

  } # end of if(length(which(reef_treatments!="none")) > 0){

    # now add any colony transplants from the orchard to the reef

    if(rest_pars$transplant[i]==1){ # if colonies are moved from orchard to reef this year

        # get the corals that will be transplanted from each size class
        #colony_mats <- list() # holding list for matrices with number of transplant colonies

        for(ss in 1:s_orchard){ # for each orchard subpopulation

          #colony_mat_ss <- list()

          for(rr in 1:source_orchard){ # for each lab source

            trans_colonies <- rest_pars$trans_mats[[ss]][[rr]][i,]

            # make sure these don't exceed the numbers in the population
            for(nn in 1:n){ # for each size class
              # if number to transplant is greater than number available at this timepoint, then only transplant the number of colonies available
              trans_colonies[nn] <- ifelse(trans_colonies[nn] > orchard_pops[[ss]][[rr]][nn ,i], orchard_pops[[ss]][[rr]][nn ,i], trans_colonies[nn])
            }

            # add the colonies to the correct reef population
            ss.reef <- rest_pars$trans_reef[[ss]][[rr]][i,1] # [i,1] = reef area receiving the corals from the ith transplant from the ss/rr^th orchard population
            rr.reef <- rest_pars$trans_reef[[ss]][[rr]][i,2] # [i, 2] = reef source subpopulation receiving the corals from the ith transplant from the ss/rr^th orchard population

            if(prop_fits[ss.reef] !=0){ # if there's room on this reef
            reef_pops[[ss.reef]][[rr.reef]][ ,i] <-  reef_pops[[ss.reef]][[rr.reef]][ ,i] + trans_colonies
            # and substract these from the orchard
            orchard_pops[[ss]][[rr]][ ,i] <- orchard_pops[[ss]][[rr]][ ,i] - trans_colonies
            }

          } # end of iteration over all source subpopulations in ss^th orchard

        } # end of iteration over all orchards

    } # end of if statement for transplanting colonies

  } # end of iteration over each year

 # return all the population metrics

  return(list(reef_pops = reef_pops, orchard_pops = orchard_pops, lab_pops = lab_pops,
              reef_rep = reef_rep, orchard_rep = orchard_rep, reef_out = reef_out, 
              orchard_out = orchard_out, reef_pops_pre = reef_pops_pre, 
              orchard_pops_pre = orchard_pops_pre))

}


# make function for creating summary data frames (total cover, total reproductive output)


# simple function for doing population viability analyses (just need one population)
#' @param years number of years in simulation
#' @param n number of size classes
#' @param A_mids areas at the midpoint of each size class
#' @param surv_pars.r list with mean survival probabilities in each size class 
#' @param growth_pars.r list with transition probabilities for each size class 
#' @param shrink_pars.r list with shrinkage probabilities for each size class 
#' @param frag_pars.r list with fragmentation probabilities for each size class 
#' @param fec_pars.r list with mean fecundities of each size class 
#' @param lambda mean number of external recruits each year
#' @param sigma_s standard deviation of survival probabilities
#' @param sigma_f standard deviation of fecundities
#' @param ext_rand whether external recruitment is stochastic (TRUE) or not (FALSE)
#' @param seeds vector with seeds for the random number generation for survival, fecundity, and recruitment
#' @param dist_yrs vector of years when reef disturbance occurs
#' @param dist_pars.r list with survival, growth/shrinkage (transition matrix) and fecundity parameters for each reef disturbance year
#' @param dist_effects.r which demographic parameters are affected by each reef disturbance
#' @param out_pars number of individuals in each size class to outplant at each timepoint
#' @param N0.r initial population sizes 

popvi_mod <- function(years, n, A_mids, surv_pars.r, growth_pars.r, shrink_pars.r, frag_pars.r,
                      fec_pars.r, lambda, sigma_s, sigma_f, ext_rand, seeds, dist_yrs,
                      dist_pars.r, dist_effects.r, out_pars, N0.r){
  
  
  
  # reef subpopulations:
  s_reef <- 1
  
  # external recruitment
  ext_rec <- Ext_fun(years, lambda, rand = ext_rand, seed1 = seeds[3])
  
  # sources of new recruits
  source_reef <- 2 # number of possible sources of reef recruits (external and outplanted)
  
  # set up holding lists
  reef_pops <- list() # holding list for population sizes of each reef subpopulation
  reef_rep <- list() # holding list for total reproductive output from each reef subpopulation
  reef_mat_pars <- list() # list with data frames with the transition matrix parameters for each reef subpop
  
  # reef population sizes before outplanting
  reef_pops_pre <- list()
  
  for(ss in 1:s_reef){
    
    # sublists for all the different sources of recruits to this reef
    reef_pops_ss <- list() # population sizes
    reef_rep_ss <- list() # total reproductive output
    reef_pops_pre_ss <- list() # population sizes before outplanting
    reef_mat_pars_ss <- list() # matrix parameters
    

      
      for(rr in 1:source_reef){ # for each possible source of recruits to this reef subpop
        
        # holding matrix for number of individuals in each size class of the ss^th reef subpop from the rr^th source in each year
        reef_pops_ss[[rr]] <- matrix(NA, nrow = n, ncol = years)
        
        # holding matrix for total reproductive output by individuals in the ss^th reef subpop from the rr^th source each year
        reef_rep_ss[[rr]] <- rep(NA, years)
        
        # holding matrix reef population size before outplanting
        reef_pops_pre_ss[[rr]] <- matrix(NA, nrow = n, ncol = years)
        
        # add initial conditions
        reef_pops_ss[[rr]][,1] <- N0.r[[ss]][[rr]]
        reef_pops_pre_ss[[rr]][,1] <- N0.r[[ss]][[rr]]
        
        # and get the list with the transition matrix parameters
        reef_mat_pars_ss[[rr]] <- mat_pars_fun(years, n, surv_pars.r[[ss]][[rr]], growth_pars.r[[ss]][[rr]],
                                               shrink_pars.r[[ss]][[rr]], frag_pars.r[[ss]][[rr]], fec_pars.r[[ss]][[rr]],
                                               sigma_s, sigma_f, seeds, dist_yrs, dist_pars.r[[ss]][[rr]],
                                               dist_effects.r[[ss]][[rr]])
        # fill in initial reproduction
        reef_rep_ss[[rr]][1] <- sum(reef_pops_ss[[rr]][,1]*reef_mat_pars_ss[[rr]]$fecundity[[1]])
        
      }
      
      
    
    
    # put all the sublists in the outer holding lists for each reef subpop
    
    reef_pops[[ss]] <- reef_pops_ss
    reef_pops_pre[[ss]] <- reef_pops_pre_ss
    reef_rep[[ss]] <- reef_rep_ss
    reef_mat_pars[[ss]] <- reef_mat_pars_ss
    
    
  }
  
  
  for(i in 2:years){
    
    
    # reef dynamics
    
    # update the population size using the transition matrix:
    
    for(ss in 1:s_reef){ # for each reef subpopulation
        
        for(rr in 1:source_reef){ # for each source of recruits
          
          # get the transition matrix
          T_mat <- reef_mat_pars[[ss]][[rr]]$growth[[i]]
          
          # get the fragmentation matrix
          F_mat <- reef_mat_pars[[ss]][[rr]]$fragmentation[[i]]
          
          
          # get the survival probabilities
          S_i <- reef_mat_pars[[ss]][[rr]]$survival[[i]] # survival
          
          # UPDATE survival with density dependence here
          # (QUESTION: should this depend on total reef popn or just the subpopn size?)
          
          N_mat <- reef_pops[[ss]][[rr]][,i-1] # population sizes in each size class at last time point
          N_mat <- N_mat*S_i # fractions surviving to current time point
          
          # now update the population sizes
          reef_pops[[ss]][[rr]][ ,i] <- (T_mat + F_mat) %*% matrix(N_mat, nrow = n, ncol = 1) # new population sizes
          
          # record this as the pre-outplant population size
          reef_pops_pre[[ss]][[rr]][ ,i] <- reef_pops[[ss]][[rr]][ ,i]
          
          # amount of new larvae produced at the i^th time point:
          reef_rep[[ss]][[rr]][i] <- sum(reef_pops[[ss]][[rr]][ ,i]*reef_mat_pars[[ss]][[rr]]$fecundity[[i]])
          
          if(rr ==1){ # if this is the first source (external recruits)
            
            # add the external recruits
            reef_pops[[ss]][[rr]][1 ,i] <- reef_pops[[ss]][[rr]][1 ,i] + ext_rec[i]
            
            # record this as the pre-outplant population size
            reef_pops_pre[[ss]][[rr]][ ,i] <- reef_pops[[ss]][[rr]][ ,i]
          }
          
          
          if(rr ==2){ # if this the second source (outplants)
            # add the outplants to each size class
            
            reef_pops[[ss]][[rr]][ ,i] <- reef_pops[[ss]][[rr]][ ,i] + out_pars[i,]
            
          }
          
          
        } # end of iterations over each source
        
      
      
    } # end of iterations over each reef subpop
    
    
  } # end of iteration over each year
  
  # return all the population metrics
  
  return(list(reef_pops = reef_pops, reef_rep = reef_rep, reef_pops_pre = reef_pops_pre))
  
  
}







