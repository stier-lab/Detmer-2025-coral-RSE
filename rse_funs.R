# =============================================================================
# RSE MODEL FUNCTIONS
# =============================================================================
# Restoration Strategy Evaluation (RSE) model for Acropora palmata (Elkhorn
# Coral). Simulates coral populations across three locations — reefs, orchards
# (nurseries), and labs — to evaluate restoration strategies.
#
# The model tracks corals by (location) x (source), where source = lab
# treatment origin or external (wild) recruits. Each year the simulation:
#   1. Updates demographics (survival, growth, fragmentation) on reefs & orchards
#   2. Collects larvae from orchards and reference reefs
#   3. Processes larvae through the lab (settlement, survival)
#   4. Allocates and outplants tiles to orchards and reefs
#   5. Optionally transplants mature colonies from orchards to reefs
#
# Core demographic equation (per subpopulation, per source):
#   N(t) = (T_mat + F_mat) %*% (S_i * N(t-1)) + outplants + external_recruits
#   where S_i = survival, T_mat = transition (growth/shrink/stay),
#         F_mat = fragmentation (asexual reproduction)
#
# DEPENDS ON: coral_demographic_funs.R (Surv_fun, G_fun, Rep_fun, Ext_fun)
#
# FUNCTION INDEX:
#   mat_pars_fun      (line ~25)   Assemble demographic parameters for each year
#   dist_pars_fun     (line ~69)   Create disturbance parameter lists
#   par_list_fun      (line ~129)  Sample parameters from empirical data
#   default_pars_fun  (line ~307)  Build default parameter sets for all subpops
#   rand_pars_fun     (line ~385)  Generate random parameter ensembles
#   rse_mod1          (line ~571)  *** MAIN MODEL (current, with density dep.) ***
#   pop_lambda_fun    (line ~1464) Calculate asymptotic population growth rate
#   model_summ        (line ~1493) Summarize model output (individuals, area, reproduction)
#   rse_mod           (line ~1707) Legacy model (no density dep., area-based constraints)
#   popvi_mod         (line ~2478) Simplified population viability model
# =============================================================================


#' @title Matrix Parameters Function
#' @description Generates all demographic parameter matrices (survival, growth/shrinkage,
#'   fragmentation, fecundity) for each time point in the simulation. Incorporates disturbance
#'   events that can modify any demographic parameter in specific years.
#' @param years Number of years in simulation
#' @param n Number of size classes
#' @param surv_pars Vector of mean survival probabilities for each size class
#' @param growth_pars List of transition probabilities for growth between size classes
#' @param shrink_pars List of shrinkage probabilities between size classes
#' @param frag_pars List of fragmentation probabilities for each size class
#' @param fec_pars Vector of mean fecundities for each size class
#' @param sigma_s Standard deviation for environmental stochasticity in survival (log scale)
#' @param sigma_f Standard deviation for environmental stochasticity in fecundity (log scale)
#' @param seeds Vector of random seeds for survival, fecundity, and recruitment
#' @param dist_yrs Vector of years when disturbance events occur
#' @param dist_pars List containing modified parameters for each disturbance year
#' @param dist_effects List specifying which parameters are affected by each disturbance
#'   (options: "survival", "Tmat", "Fmat", "fecundity")
#' @return List with four elements: survival, growth, fragmentation, fecundity - each containing
#'   parameter values/matrices for each year of the simulation
#' @export
mat_pars_fun <- function(years, n, surv_pars, growth_pars, shrink_pars, frag_pars, fec_pars,
                         sigma_s, sigma_f, seeds, dist_yrs, dist_pars, dist_effects){

  # survival parameters — SEE: coral_demographic_funs.R::Surv_fun()
  S_list <- Surv_fun(years, n, surv_pars, sigma_s, seed1 = seeds[1])

  # growth/shrinkage and fragmentation matrices — SEE: coral_demographic_funs.R::G_fun()
  all_mats <- G_fun(years, n, growth_pars, shrink_pars, frag_pars)
  G_list <- all_mats$G_list
  Fr_list <- all_mats$Fr_list

  # fecundity parameters — SEE: coral_demographic_funs.R::Rep_fun()
  F_list <- Rep_fun(years, n, fec_pars, sigma_f, seed1 = seeds[2])

  # WHY: Disturbances override stochastic parameters for specific years, allowing
  # sudden events (e.g., hurricanes, bleaching) to be modeled as deterministic
  # parameter replacements in the affected year(s).
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

#' @title Disturbance Parameters Function
#' @description Creates structured lists of disturbance parameters for each subpopulation/source
#'   combination. Disturbances can affect survival, growth/shrinkage (transition matrix),
#'   fragmentation, and/or fecundity in specified years.
#' @param dist_yrs Vector of years when disturbance events occur
#' @param dist_effects List specifying which demographic parameters are affected by each
#'   disturbance event (options: "survival", "Tmat", "Fmat", "fecundity")
#' @param dist_surv0 List where element i contains survival probabilities for the i-th disturbance.
#'   Default = NULL
#' @param dist_Tmat0 List where element i contains the transition matrix for the i-th disturbance.
#'   Default = NULL
#' @param dist_Fmat0 List where element i contains the fragmentation matrix for the i-th disturbance.
#'   Default = NULL
#' @param dist_fec0 List where element i contains fecundities for the i-th disturbance.
#'   Default = NULL
#' @return List with four elements: dist_surv, dist_Tmat, dist_Fmat, dist_fec - each containing
#'   the disturbance parameters (or NULL if not affected) for each disturbance year
#' @export
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

#' @title Parameter List Function
#' @description Converts data frames of parameter values into list format required by the model.
#'   Can either extract summarized values (mean, quantiles) or randomly sample from full datasets
#'   for uncertainty analysis.
#' @param par_type Type of parameter: "survival", "growth", or "fragmentation"
#' @param sample_dt Logical. If TRUE, randomly sample rows from full_df. If FALSE, use
#'   summarized values from summ_df
#' @param summ_df Data frame (or list of data frames for growth) with summarized values
#'   including mean and 95% confidence intervals
#' @param summ_metric Column name indicating which summarized value to use ("mean", "Q05", "Q95")
#' @param full_df data frame (or list of dataframes) with all available estimates of parameter values
#' @param n_sample number of samples from the full data frame to take (if sample_dt == T)
#' @return Depends on \code{par_type}:
#'   \describe{
#'     \item{If \code{par_type = "survival"}}{List with one element:
#'       \code{$surv_pars}. If \code{sample_dt = FALSE}: numeric vector (length 5).
#'       If \code{sample_dt = TRUE}: matrix (n_sample x 5), one row per random draw.}
#'     \item{If \code{par_type = "growth"}}{List with two elements:
#'       \code{$growth_pars} and \code{$shrink_pars}. If \code{sample_dt = FALSE}:
#'       each is a list of 5 vectors (growth[k] = transitions FROM size class k to
#'       larger classes; shrink[k] = transitions from k to smaller classes).
#'       If \code{sample_dt = TRUE}: list of n_sample elements, each containing
#'       the 5-vector list structure described above.}
#'     \item{If \code{par_type = "fragmentation"}}{List with one element:
#'       \code{$frag_pars}. Structure: list of 5 elements where SC1-SC3 = NULL or
#'       zero vectors (small colonies do not fragment), SC4 and SC5 = vectors of
#'       fragment production rates to each smaller size class.
#'       If \code{sample_dt = TRUE}: list of n_sample such lists.}
#'   }
#' @details The growth/shrinkage indexing follows the transition matrix convention:
#'   \code{growth_pars[[k]]} contains transition probabilities FROM size class k
#'   TO all larger classes. For example, \code{growth_pars[[1]]} has 4 elements
#'   (SC1 -> SC2, SC1 -> SC3, SC1 -> SC4, SC1 -> SC5), while
#'   \code{growth_pars[[5]]} is NULL (SC5 cannot grow larger). Shrinkage is the
#'   reverse: \code{shrink_pars[[5]]} has 4 elements (SC5 -> SC4, ..., SC5 -> SC1).
#' @export
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
      
      # WHY: Assume only size classes 4 and 5 (>900 cm^2) produce fragments in A. palmata (Vardi et al. 2012).
      # Smaller colonies lack the branching architecture for storm-driven breakage to
      # generate viable fragments. SC1-3 produce zero fragments by construction.
      # "F4_SC1" = fragments from SC4 colonies that land in SC1, etc.
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


#' @title Default Parameter Assembly
#' @description Assembles demographic parameter sets for all reefs and orchards using
#'   summarized (mean or quantile) values from the empirical data. We assume all reefs
#'   share one set of field-derived parameters, all orchards share one set of nursery-derived
#'   parameters, and all lab treatment sources within a location share the same demographics.
#'   This function is the deterministic counterpart to \code{rand_pars_fun()}.
#' @param n_reef Integer. Number of intervention reefs.
#' @param n_orchard Integer. Number of nursery orchards.
#' @param n_lab Integer. Number of lab treatments (determines how many source subpopulations
#'   each reef tracks: n_lab + 1, where +1 = external/wild recruits).
#' @param summ_metric_list Named list specifying which summary statistic to use for each
#'   parameter type. Names: \code{field_surv}, \code{field_growth}, \code{field_shrink},
#'   \code{field_frag}, \code{nurs_surv}, \code{nurs_growth}, \code{nurs_shrink}. Values:
#'   column names from the summary data frames (typically "mean", "Q05", or "Q95").
#' @param field_surv Field survival data object from the parameters repo
#'   (\code{field_surv_pars.rds}). Must contain \code{$SC_surv_summ_df} (summary by size class).
#' @param field_growth Field growth data object (\code{field_growth_pars.rds}).
#'   Must contain \code{$summ_list} (list of 5 transition summary data frames, one per size class).
#' @param nurs_surv Nursery survival data object (\code{nurs_surv_pars.rds}).
#'   Same structure as \code{field_surv}. Covers only SC1–SC2; caller must fill in SC3–SC5
#'   from field data before passing.
#' @param nurs_growth Nursery growth data object (\code{nurs_growth_pars.rds}).
#'   Same structure as \code{field_growth}. SC3–SC5 must be filled from field data.
#' @param apal_frag_summ Data frame of fragmentation summary statistics
#'   (\code{apal_fragmentation_summ.csv}). Columns include \code{frag_type} (e.g., "F4_SC1")
#'   and summary columns (mean, Q05, Q95).
#' @return Named list with 8 elements, each a nested list:
#'   \code{[[location]][[source]]} = parameter vector or list.
#'   \describe{
#'     \item{surv_pars.r}{\code{[[reef]][[source]]} -> numeric vector (length 5), survival per SC}
#'     \item{growth_pars.r}{\code{[[reef]][[source]]} -> list of growth transition vectors}
#'     \item{shrink_pars.r}{\code{[[reef]][[source]]} -> list of shrinkage vectors}
#'     \item{frag_pars.r}{\code{[[reef]][[source]]} -> list of fragmentation vectors (SC4-5 only)}
#'     \item{surv_pars.o}{\code{[[orchard]][[source]]} -> same as reef survival}
#'     \item{growth_pars.o}{\code{[[orchard]][[source]]} -> same as reef growth}
#'     \item{shrink_pars.o}{\code{[[orchard]][[source]]} -> same as reef shrinkage}
#'     \item{frag_pars.o}{\code{[[orchard]][[source]]} -> all zeros (no fragmentation in orchards)}
#'   }
#' @seealso \code{\link{rand_pars_fun}} for stochastic parameter sampling,
#'   \code{\link{par_list_fun}} for the underlying parameter extraction.
#' @export
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
  frag_pars.o <- list() # orchard fragmentation
  
  # get the parameter values
  surv_pars2 <- par_list_fun(par_type = "survival", sample_dt = F, summ_df = nurs_surv$SC_surv_summ_df, summ_metric = summ_metric_list$nurs_surv, full_df = NA, n_sample = NA)$surv_pars
  growth_pars2 <- par_list_fun(par_type = "growth", sample_dt = F, summ_df = nurs_growth$summ_list, summ_metric = summ_metric_list$nurs_growth, full_df = NA, n_sample = NA)$growth_pars
  shrink_pars2 <- par_list_fun(par_type = "growth", sample_dt = F, summ_df = nurs_growth$summ_list, summ_metric = summ_metric_list$nurs_shrink, full_df = NA, n_sample = NA)$shrink_pars
  
  # No fragmentation in orchards: managed nursery substrates are not subject to
  # storm-driven breakage. We set all fragment production to zero.
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

#' @title Random Parameter Assembly
#' @description Assembles demographic parameter sets by randomly sampling from empirical
#'   distributions. We draw \code{n_sample} independent parameter sets, enabling Monte Carlo
#'   uncertainty analysis. Each draw samples a complete row from the empirical data (preserving
#'   correlations across size classes within a study). All sources within a reef share the same
#'   draw; different reefs can receive different draws.
#' @param n_reef Integer. Number of intervention reefs.
#' @param n_orchard Integer. Number of nursery orchards.
#' @param n_lab Integer. Number of lab treatments.
#' @param n_sample Integer. Number of random parameter sets to generate. Each produces
#'   an independent realization suitable for one model run.
#' @param field_surv Field survival data object. Must contain \code{$SC_surv_df}
#'   (individual-level survival data frame with columns \code{size_class} and
#'   \code{prop_survived}).
#' @param field_growth Field growth data object. Must contain \code{$mat_list}
#'   (list of 5 transition probability data frames, one per size class).
#' @param nurs_surv Nursery survival data object. Same structure as \code{field_surv}.
#'   Caller must fill SC3–SC5 from field data before passing.
#' @param nurs_growth Nursery growth data object. Same structure as \code{field_growth}.
#'   SC3–SC5 must be filled from field data.
#' @param apal_frag Fragmentation data frame (\code{apal_fragmentation.csv}). Each row
#'   is one empirical observation with columns \code{F4_SC1}, \code{F4_SC2}, etc.
#' @return Named list with 8 elements, each a nested list with an outer iteration dimension:
#'   \code{[[iteration]][[location]][[source]]} = parameter vector or list.
#'   \describe{
#'     \item{surv_pars_L.r}{\code{[[iter]][[reef]][[source]]} -> numeric vector (length 5)}
#'     \item{growth_pars_L.r}{\code{[[iter]][[reef]][[source]]} -> list of growth vectors}
#'     \item{shrink_pars_L.r}{\code{[[iter]][[reef]][[source]]} -> list of shrinkage vectors}
#'     \item{frag_pars_L.r}{\code{[[iter]][[reef]][[source]]} -> list of fragmentation vectors}
#'     \item{surv_pars_L.o}{\code{[[iter]][[orchard]][[source]]} -> same as reef}
#'     \item{growth_pars_L.o}{\code{[[iter]][[orchard]][[source]]} -> same as reef}
#'     \item{shrink_pars_L.o}{\code{[[iter]][[orchard]][[source]]} -> same as reef}
#'     \item{frag_pars_L.o}{\code{[[iter]][[orchard]][[source]]} -> all zeros}
#'   }
#'   To use iteration \code{nn}: pass \code{surv_pars_L.r[[nn]]} as \code{surv_pars.r}
#'   to \code{rse_mod1()}, and likewise for all 8 elements.
#' @seealso \code{\link{default_pars_fun}} for deterministic parameter assembly.
#' @export
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
      
      # holding list for each source to each orchard
      surv_pars.o[[i]] <- list() # ith orchard treatment/subpop
      growth_pars.o[[i]] <- list()
      shrink_pars.o[[i]] <- list()
      frag_pars.o[[i]] <- list()
      
      for(j in 1:n_lab){ # for each source to each orchard
        
        surv_pars.o[[i]][[j]] <- surv_pars2[[i]][nn,] # survival probabilities for jth source of recruits to ith orchard
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
 # return(list(surv_pars.r = surv_pars_L.r, growth_pars.r = growth_pars_L.r, shrink_pars.r = shrink_pars_L.r,
            #  frag_pars.r = frag_pars_L.r, surv_pars.o = surv_pars_L.o, growth_pars.o = growth_pars_L.o, 
             # shrink_pars.o = shrink_pars_L.o, frag_pars.o = frag_pars_L.o))
  
}

#' lab function (not made; lab dynamics are currently in the full rse_mod1 function)
#' make a function that takes the number of new babies from the orchard as an input and
#' returns the number of outplants that can go to the reef
#' this may or may not be a full population dynamics model, but either way it could
#' be separate from the orchard and reef models


# full rse model with a constant reference reef population
#' Population dynamics function
#' Arguments:
#' @param years number of years in simulation
#' @param n number of size classes
#' @param A_mids areas at the midpoint of each size class
#' @param surv_pars.r list with mean survival probabilities in each size class for each reef treatment
#' @param dens_pars.r Post-outplanting density-dependent survival coefficients for reefs.
#'   Nested list: \code{[[reef]][[source]]} = numeric scalar. Applied at outplanting time
#'   as Ricker-type survival: \code{surviving = outplants * exp(-dens_par * tile_density) *
#'   size_props}, where \code{tile_density} = settlers per tile on outplanting day. Higher
#'   density on each tile reduces post-outplanting survival, reflecting competition and
#'   post-settlement mortality on crowded substrates.
#'   NOTE: An earlier version applied DD to SC1 survival based on total reef population
#'   (see commented-out code at ~line 938); the current implementation operates on per-tile
#'   density at the moment of outplanting.
#' @param growth_pars.r list with transition probabilities for each size class for each reef treatment
#' @param shrink_pars.r list with shrinkage probabilities for each size class for each reef treatment
#' @param frag_pars.r list with fragmentation probabilities for each size class for each reef treatment
#' @param fec_pars.r list with mean fecundities of each size class for each reef treatment
#' @param surv_pars.o list with mean survival probabilities in each size class for each orchard treatment
#' @param dens_pars.o Post-outplanting density-dependent survival coefficients for orchards.
#'   Same structure and mechanism as \code{dens_pars.r} but indexed as
#'   \code{[[orchard]][[source]]}.
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
#' @param lab_pars Named list defining lab settlement and survival. Controls how larvae
#'   become outplantable recruits. Elements:
#'   \describe{
#'     \item{sett_props}{Named list (e.g., \code{list(T1 = 0.15)}). Fraction of larvae
#'       that successfully settle on each tile type. Estimated from Fundemar's 2025 spawning
#'       data (~15\% for cement tiles; see \code{rest_pars.rmd}).}
#'     \item{s0}{Matrix (years x n_lab). Annual survival probability of settled larvae from
#'       settlement to immediate outplanting, for each lab treatment. Allows year-specific
#'       values (e.g., to model lab disturbance events).}
#'     \item{s1}{Matrix (years x n_lab). Annual survival of retained settlers in lab (1-year
#'       grow-out treatments). Typically lower than \code{s0} because colonies are held longer.}
#'     \item{m0}{Numeric vector (length = n_lab). Density-dependent mortality coefficient for
#'       immediate-outplant treatments. Applied as Ricker-type survival:
#'       \code{survivors = settlers * s0 * exp(-m0 * density)}.}
#'     \item{m1}{Numeric vector (length = n_lab). Same as \code{m0} but for 1-year retained
#'       treatments.}
#'     \item{size_props}{Matrix (n_lab x n_size_classes). Size class distribution of recruits
#'       at the time of immediate outplanting. Row i defines where lab treatment i's recruits
#'       land in the size distribution (typically all in SC1).}
#'     \item{size_props1}{Matrix (n_lab x n_size_classes). Same as \code{size_props} but for
#'       1-year retained recruits (may have grown to SC2 during lab retention).}
#'   }
#' @param rest_pars Named list defining the restoration strategy. Controls how larvae
#'   are allocated across labs, orchards, and reefs each year. Elements:
#'   \describe{
#'     \item{tile_props}{Named list (e.g., \code{list(T1 = 0.25, T2 = 0.75)}). Fraction
#'       of lab tile capacity devoted to each tile type. Names must match tile types in
#'       \code{lab_treatments}. Sums to 1.}
#'     \item{orchard_yield}{Numeric 0–1. Fraction of orchard larvae successfully collected
#'       each spawning season. Set to 0 if the orchard does not contribute larvae to the lab.}
#'     \item{reef_yield}{Numeric 0–1. Fraction of reference reef larvae successfully collected
#'       and fertilized. Represents field collection efficiency.}
#'     \item{spawn_target}{Numeric. Target number of embryos to collect from the orchard each
#'       year. If the orchard cannot meet this target, the shortfall is supplemented from the
#'       reference reef (up to \code{reef_yield * lambda_R}). Set to 0 for no settlement collection.}
#'     \item{reef_prop}{Numeric vector (length = number of lab treatments), each value 0–1.
#'       Fraction of tiles from each lab treatment that go to the reef (remainder goes to orchards until orchards are full, then goes back to reef).}
#'     \item{reef_out_props}{Matrix (n_lab x n_reef). Row i, column j = fraction of reef-bound
#'       tiles from lab treatment i allocated to reef j. Rows sum to 1.}
#'     \item{orchard_out_props}{Matrix (n_lab x n_orchard). Orchard allocation; follows same logic as for reef allocation.}
#'     \item{reef_areas}{Numeric vector (length = n_reef). Available substrate area for each
#'       reef in cm^2. Could determines carrying capacity (once occupied area reaches this limit,
#'       no new recruits or fragments establish), but currently that isn't implemented in the model.}
#'     \item{lab_max}{Integer. Total tile capacity of the lab (tiles that can be processed
#'       in a single spawning season). We assume 100 tiles per tank.}
#'     \item{lab_retain_max}{Integer. Maximum tiles that can be held in the lab for 1-year
#'       grow-out. Must be <= \code{lab_max}. If > 0, at least one lab treatment must use the
#'       "1_TX" (retained) naming convention.}
#'     \item{tank_min}{Numeric. Minimum embryos per tank. If larval supply falls below
#'       \code{tank_min * lab_max / 100}, we reduce the number of tanks used rather than
#'       spreading larvae too thin (avoids unrealistically low settlement densities).}
#'     \item{tank_max}{Numeric. Maximum embryos per tank. Caps larval loading to prevent
#'       unrealistically high densities. We chose the default (33,333) to produce ~50 embryos
#'       per tile assuming 15\% settlement and 100 tiles per tank.}
#'     \item{orchard_size}{Numeric vector (length = n_orchard). Maximum tiles each orchard
#'       can accommodate. Surplus tiles are redirected to reefs.}
#'     \item{transplant}{Integer vector (length = years). 1 in years when mature colonies are
#'       transplanted from orchards to reefs, 0 otherwise.}
#'     \item{trans_mats}{Nested list: \code{[[orchard]][[source]]} = matrix (years x n size
#'       classes). Maximum colonies of each size class to transplant per year from that
#'       orchard-source combination.}
#'     \item{trans_reef}{Nested list: \code{[[orchard]][[source]]} = matrix (years x 2).
#'       Column 1 = destination reef index, column 2 = destination source index within
#'       that reef.}
#'   }
#' @param N0.r initial population sizes in each reef subpopulation
#' @param N0.o initial population sizes in each orchard subpopulation
#' @param N0.l initial population sizes in each lab subpopulation

rse_mod1 <- function(years, n, A_mids, surv_pars.r, dens_pars.r, growth_pars.r, shrink_pars.r, 
                     frag_pars.r, fec_pars.r, surv_pars.o, dens_pars.o, growth_pars.o, 
                     shrink_pars.o, frag_pars.o, fec_pars.o, lambda, lambda_R, sigma_s, sigma_f, 
                     ext_rand, seeds, dist_yrs, dist_pars.r, dist_effects.r, dist_pars.o, 
                     dist_effects.o, orchard_treatments, reef_treatments, lab_treatments, lab_pars, 
                     rest_pars, N0.r, N0.o, N0.l){
  
  # ========================================================================
  # ALGORITHMIC OVERVIEW
  # ========================================================================
  # This function simulates coral population dynamics across reefs, orchards,
  # and labs over multiple years. Each year proceeds in this order:
  #
  #   STEP 1 — REEF DYNAMICS: Apply survival (element-wise), then growth/
  #            shrinkage/fragmentation (matrix multiplication), add external
  #            wild recruits to smallest size class.
  #   STEP 2 — ORCHARD DYNAMICS: Same demographic update as reef, plus a
  #            one-adult-per-tile cap (managed nursery substrate constraint).
  #   STEP 3 — LARVAL COLLECTION: Collect larvae from orchards first; if the
  #            spawn target isn't met, supplement from the reference reef.
  #   STEP 4 — LAB PROCESSING: Distribute larvae across tile treatments,
  #            apply settlement, lab survival, and density-dependent mortality.
  #   STEP 5 — TILE ALLOCATION: Decide tile distribution to orchards vs. reefs
  #            based on reef_prop; handle orchard capacity overflow → redirect
  #            surplus tiles to reefs.
  #   STEP 6 — OUTPLANTING: Add surviving recruits to reef and orchard
  #            populations with post-outplanting density-dependent survival.
  #   STEP 7 — COLONY TRANSPLANTING (if transplant vector is 1 that year): Move mature colonies
  #            from orchards to reefs.
  #
  # INDEX KEY for main data structures:
  #   reef_pops[[ss]][[rr]][nn, i]
  #     ss = reef subpopulation (1..s_reef)
  #     rr = recruit source (1 = external/wild, 2..s_lab+1 = lab treatments)
  #     nn = size class (1..5: 1=recruits <10cm², 2=small, 3=medium,
  #          4=large, 5=very large >4000cm²)
  #     i  = year (1..years, where year 1 = initial conditions)
  #
  #   orchard_pops[[ss]][[rr]][nn, i] — same structure, but:
  #     ss = orchard subpopulation (1..s_orchard)
  #     rr = lab treatment source (1..s_lab; no external recruit source)
  #
  #   lab_pops[[ss]][i] — ss = lab treatment, i = year
  #
  # Lab treatment naming convention: "X_TY"
  #   X = retention time: "0" = outplanted same year, "1" = retained 1 year
  #   TY = tile type: "T1" = cement, "T2" = ceramic, etc.
  #   Example: "0_T1" = cement tile, outplanted immediately
  # ========================================================================

  # orchard subpopulations:
  s_orchard <- length(orchard_treatments)
  
  # reef subpopulations:
  s_reef <- length(reef_treatments)
  
  # external recruitment each year
  ext_rec <- Ext_fun(years, lambda, rand = ext_rand[1], seed1 = seeds[3])
  # proportions going to each reef subpop (proportional to areas of each reef):
  # Protect against division by zero when reef_areas sum to zero
  reef_area_sum <- sum(rest_pars$reef_areas)
  if(reef_area_sum > 0) {
    ext_props <- rest_pars$reef_areas / reef_area_sum
  } else {
    ext_props <- rep(0, length(rest_pars$reef_areas))
  }
  
  # larvae collected from reference reef each year
  # SEE: coral_demographic_funs.R::Ext_fun() — lambda_R = mean annual embryo production
  ref_babies <- Ext_fun(years, lambda_R, rand = ext_rand[2], seed1 = seeds[4])

  # WHY: When a disturbance reduces reef survival, it also reduces reference reef
  # larval production proportionally. The ratio (disturbed_survival / baseline_survival)
  # for reproductive size classes [3:5] = SC3-SC5 gives the proportional reduction in larval supply.
  # Uses reef 1, source 1 (ext. recruits) disturbance params as representative of the reference reef.
  if(is.na(dist_yrs[1])==F){
  for(i in dist_yrs){

    if("survival" %in% dist_effects.r[[1]][[1]][[which(dist_yrs==i)]]){
      ref_babies[i] <- ref_babies[i]*mean(dist_pars.r[[1]][[1]]$dist_surv[[which(dist_yrs==i)]][3:5]/surv_pars.r[[1]][[1]][3:5], na.rm = T)
    }
  }
  }
  
  
  
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
  
  # holding vectors for recording total babies collected from orchard and reference reefs each year
  orchard_babies <- rep(NA, years) # babies collected from the orchard
  reef_babies <- rep(NA, years) # babies collected from reference reef
  
  orchard_babies[1] <- 0 # babies collected from the orchard
  reef_babies[1] <- 0 # babies collected from reference reef
  
  # holding vectors for recording total babies from orchard and reference reefs that were used year
  orchard_babies_used <- rep(NA, years) # babies collected from the orchard
  reef_babies_used <- rep(NA, years) # babies collected from reference reef
  
  orchard_babies_used[1] <- 0 # babies collected from the orchard
  reef_babies_used[1] <- 0 # babies collected from reference reef
  
  
  # holding vectors for total number of tiles being outplanted each year
  tiles_out0 <- rep(NA, years) # tiles outplanted immediately
  tiles_out1 <- rep(NA, years) # tiles outplanted after lab grow-out
  tiles_out_tot <- rep(NA, years) # total tiles
  tiles_out0[1] <- 0
  tiles_out1[1] <- 0
  reef_tiles_out <- rep(NA, years) # tiles outplanted to reef each year
  orchard_tiles_out <- rep(NA, years) # tiles outplanted to orchard each year
  reef_tiles_out[1] <- 0 # tiles outplanted to reef each year
  orchard_tiles_out[1] <- 0 # tiles outplanted to orchard each year
  
  
  # WHY +1 for reef: Reef populations track individuals from each lab treatment
  # PLUS external (wild) recruits. Source rr=1 = external, rr=2..s_lab+1 = lab treatments.
  # Orchards only receive lab-sourced recruits (assume no wild settlement in managed nurseries).
  source_reef <- 1 + s_lab
  source_orchard <- s_lab

  # ========================================================================
  # INITIALIZATION: Set up tracking structures for all subpopulations
  # ========================================================================
  # Each list is nested: outer = subpopulation, inner = recruit source.
  # Holding matrices have rows = size classes (1..n), columns = years (1..years).

  reef_pops <- list()     # population sizes [[ss]][[rr]][nn, i]
  reef_rep <- list()      # reproductive output [[ss]][[rr]][i]
  reef_mat_pars <- list() # demographic parameters [[ss]][[rr]]$survival/growth/fragmentation/fecundity
  reef_out <- list()      # number outplanted [[ss]][[rr]][i]
  reef_pops_pre <- list() # population sizes BEFORE outplanting (so the just-outplanted recruits aren't counted in that year's population size)
  
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
  
  orchard_tiles <- list() # number of tiles in each orchard
  
  for(ss in 1:s_orchard){
    
    # sublists for all the different sources of recruits to the orchard
    orchard_pops_ss <- list() # population sizes
    orchard_pops_pre_ss <- list() # population sizes before outplanting
    orchard_rep_ss <- list() # total reproductive output
    orchard_out_ss <- list() # numbers outplanted
    orchard_mat_pars_ss <- list() # matrix parameters
    
    orchard_tiles[[ss]] <- rep(NA, years)
    
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
    
    orchard_tiles[[ss]][1] <- sum(unlist(N0.o[[ss]])) # assume initial number of tiles = initial number of corals in orchard
    
  }
  
  
  # lab subpopulations
  lab_pops <- list()
  
  for(ss in 1:s_lab){
    
    # holding vectors for number of individuals in the ss^th lab treatment
    lab_pops[[ss]] <- rep(NA, years)
    
    # initial conditions
    lab_pops[[ss]][1] <- N0.l[[ss]]
    
  }
  
  
  
  # Density-dependent mortality coefficients for post-outplanting survival.
  # Used in STEP 6 as: surviving_outplants = outplants * exp(-dd_pars * density)
  # This is a Ricker-type density-dependent survival on the outplanting tiles.
  # WHY rr+1 offset: dens_pars.r[[ss]] includes external recruits at position 1,
  # but dd_pars.r only indexes lab sources, so lab treatment j = dens_pars position j+1.
  dd_pars.r <- matrix(NA, nrow = s_reef, ncol = s_lab)
  for(ss in 1:s_reef){

    for(rr in 1:s_lab){

      dd_pars.r[ss, rr] <- dens_pars.r[[ss]][[rr + 1]]
    }
    
  }
  
  # orchard
  dd_pars.o <- matrix(NA, nrow = s_orchard, ncol = s_lab)
  for(ss in 1:s_orchard){
    
    for(rr in 1:source_orchard){ # for each lab source (rr = 1 is for external recruits)
      
      dd_pars.o[ss, rr] <- dens_pars.o[[ss]][[rr]]
    }
    
  }
  
  # ========================================================================
  # SIMULATION LOOP: Year-by-year population dynamics (year 2..years)
  # ========================================================================
  # Year 1 = initial conditions (set above). Each subsequent year applies
  # Steps 1-7 as described in the algorithmic overview.

  for(i in 2:years){

    # --- STEP 1: REEF POPULATION UPDATE ---
    # Apply survival, then growth/shrinkage/fragmentation via matrix projection.
    # WHY survival is element-wise before matrix mult: Mortality occurs in the
    # individual's current size class before it transitions. This is a
    # pre-breeding census formulation where S acts on N(t-1) first.

    for(ss in 1:s_reef){ # for each reef subpopulation
        
        for(rr in 1:source_reef){ # for each source of recruits to this reef
          
          # get the transition matrix (growth, shrinkage, staying)
          T_mat <- reef_mat_pars[[ss]][[rr]]$growth[[i]]
          
          # get the fragmentation matrix
          F_mat <- reef_mat_pars[[ss]][[rr]]$fragmentation[[i]]
          
          # if the reef is full, assume none of the fragments produced over the last year result in new colonies
          # if(sum(reef_pops[[ss]][[1]][ ,i-1]*A_mids) >= rest_pars$reef_areas[ss]){
          #   F_mat <- 0*F_mat
          # }
          
          # get the survival probabilities
          S_i <- reef_mat_pars[[ss]][[rr]]$survival[[i]] # survival
          
        
          # update survival of the smallest size class with density dependence: 
          # first need to get total population size across all size classes and sources to this reef subpopulation
          # N_all <- rep(NA, source_reef)
          # 
          # for(rrr in 1:source_reef){
          #   N_all[rrr] <- sum(reef_pops[[ss]][[rrr]][,i-1])
          # }
          # 
          # # now update survival based on the total population size on this reef
          # S_i[1] <- S_i[1]*exp(-dens_pars.r[[ss]][[rr]]*sum(N_all))
          
          # Core demographic update: N(t) = (T + F) %*% (S * N(t-1))
          N_mat <- reef_pops[[ss]][[rr]][,i-1] # N(t-1): population by size class
          N_mat <- N_mat*S_i                   # apply survival element-wise

          reef_pops[[ss]][[rr]][ ,i] <- (T_mat + F_mat) %*% matrix(N_mat, nrow = n, ncol = 1)

          # snapshot before outplanting (used to measure natural dynamics separately)
          reef_pops_pre[[ss]][[rr]][ ,i] <- reef_pops[[ss]][[rr]][ ,i]

          # reproductive output this year (larvae produced)
          reef_rep[[ss]][[rr]][i] <- sum(reef_pops[[ss]][[rr]][ ,i]*reef_mat_pars[[ss]][[rr]]$fecundity[[i]])

          if(rr ==1){ # WHY only rr==1: only external/wild recruits settle naturally
            # add the external recruits if they fit
            # tot_area1 <- rest_pars$reef_areas[ss] # total area devoted to the ss^th reef treatment
            # occupied_area1 <- sum(reef_pops[[ss]][[rr]][ ,i]*A_mids) # total area currently occupied
            # open_area1 <- tot_area1 - occupied_area1 # area that is available for new recruits
            # new_area1 <- ext_rec[i]*ext_props[ss]*A_mids[1] # area that the new recruits will need
            # 
            # if(open_area1 <= 0){ # if there's no space left
            #   prop_rec <- 0 # proportion of new recruits that can be outplanted is 0
            # } else if(new_area1 < open_area1){ # if all of them fit
            #   prop_rec <- 1 # all the new recruits can be outplanted
            # } else{ # if only some will fit, calculate what proportion will fit
            #   prop_rec <- 1-((new_area1 - open_area1)/new_area1)
            # }
            # 
            # reef_pops[[ss]][[rr]][1 ,i] <- reef_pops[[ss]][[rr]][1 ,i] + ext_rec[i]*ext_props[ss]*prop_rec
            # 
            
            # record the population size before new recruitment
            reef_pops_pre[[ss]][[rr]][ ,i] <- reef_pops[[ss]][[rr]][ ,i]
            
            # add external recruits
            reef_pops[[ss]][[rr]][1 ,i] <- reef_pops[[ss]][[rr]][1 ,i] + ext_rec[i]*ext_props[ss]
            
          }
          
        } # end of iterations over each source
        
      
      
    } # end of iterations over each reef subpop
    
    # --- STEP 2: ORCHARD POPULATION UPDATE ---
    # Same demographic update as reef, plus a one-adult-per-tile cap.
    # Orchards are managed nurseries with limited physical substrate.

    # Total tiles across all orchards (needed for density calculations below)
    tot_tiles1 <- rep(NA, s_orchard)
    for(ss in 1:s_orchard){
      tot_tiles1[ss] <- orchard_tiles[[ss]][i-1]
    }
    tot_tiles1 <- sum(tot_tiles1)

    for(ss in 1:s_orchard){ # for each orchard
      
      # calculate total number of colonies in this orchard across all sources
      # ind_tots_ss <- rep(NA, source_orchard)
      # 
      # for(rr in 1:source_orchard){
      #   
      #   ind_tots_ss[rr] <- sum(orchard_pops[[ss]][[rr]][ ,i-1]) # total colonies from rr^th source
      # }
      # 
      # ind_tots_s <- sum(ind_tots_ss) # total across all sources
      
      for(rr in 1:source_orchard){ # for each source of orchard recruits
        
        # get the transition matrix for this year
        T_mat <- orchard_mat_pars[[ss]][[rr]]$growth[[i]]
        
        # get the fragmentation matrix
        F_mat <- orchard_mat_pars[[ss]][[rr]]$fragmentation[[i]]
        
        # if(ind_tots_s >= rest_pars$orchard_size[ss]){ # if the orchard is full
        #   F_mat <- 0*F_mat # assume no fragments survive
        # }
        
        # get the survival probabilities for this year
        S_i <- orchard_mat_pars[[ss]][[rr]]$survival[[i]] # survival
        
        # update survival of smallest size classes with density dependence 
        # N_all <- rep(NA, source_orchard)
        # 
        # for(rrr in 1:source_orchard){
        #   N_all[rrr] <- sum(orchard_pops[[ss]][[rrr]][,i-1]) # total number of corals from rrr^th source in ss^th orchard
        # }
        # 
        # S_i[1] <- S_i[1]*exp(-dens_pars.o[[ss]][[rr]]*sum(N_all))
        # 
        
        N_mat <- orchard_pops[[ss]][[rr]][,i-1] # population sizes in each size class at last time point
        N_mat <- N_mat*S_i # fractions surviving to current time point
        
        # now update the population sizes:
        orchard_pops[[ss]][[rr]][ ,i] <- (T_mat + F_mat) %*% matrix(N_mat, nrow = n, ncol = 1)
        
        
        # ONE-ADULT-PER-TILE CAP
        # WHY: In physical orchards, assume each tile/reef star can support at most one
        # mature colony. If the matrix projection predicts more adults (SC3-SC5,
        # indices [3:5]) than tiles, the excess die. We remove from the smallest
        # adult class first (SC3), then SC4 if needed. SC5 is never reduced
        # (assumes large established colonies persist). This mimics competitive
        # exclusion on limited managed substrate.
        #
        # tiles from rr-th lab treatment in ss-th orchard =
        #   total_tiles x tile_type_proportion x orchard_allocation_proportion
        tot_tiles_rr <- tot_tiles1*rest_pars$tile_props[[which(names(rest_pars$tile_props)==tile_types[rr])]]*rest_pars$orchard_out_props[rr,ss] #*(1-rest_pars$reef_prop[rr])
        
        if(tot_tiles_rr > 0){ # if there were tiles in this orchard
          if(sum(orchard_pops[[ss]][[rr]][c(3:5) ,i]) > tot_tiles_rr){ # if there is more than one adult per tile
            
            # cap the number of juveniles that were able to mature by removing the extra new adults
            extra_adults <- sum(orchard_pops[[ss]][[rr]][c(3:5) ,i]) - tot_tiles_rr
            
            if(extra_adults > 0){
              # remove from size class 3 first (most new juveniles would enter this size class)
              sz3_new <- orchard_pops[[ss]][[rr]][3 ,i] - min(extra_adults, orchard_pops[[ss]][[rr]][3 ,i])
              
              # any remaining extra adults:
              extra_adults2 <- extra_adults - min(extra_adults, orchard_pops[[ss]][[rr]][3 ,i])
              
              # if the number of extra adults was greater than the number of class 3 adults, remove the remainder from size class 4
              if(extra_adults2 > 0){
                sz4_new <- orchard_pops[[ss]][[rr]][4 ,i] - min(extra_adults2, orchard_pops[[ss]][[rr]][4 ,i])
                
              } else{
                sz4_new <- orchard_pops[[ss]][[rr]][4 ,i]
              }
              
              # update the population sizes
              orchard_pops[[ss]][[rr]][3 ,i] <- sz3_new
              orchard_pops[[ss]][[rr]][4 ,i] <- sz4_new
              
            }
          
          }
        } # end of adding artificial caps
        
        
        # record this as the pre-outplant population size
        orchard_pops_pre[[ss]][[rr]][ ,i] <- orchard_pops[[ss]][[rr]][ ,i]
        
        # amount of new larvae produced at i^th time point:
        orchard_rep[[ss]][[rr]][i] <- sum(orchard_pops[[ss]][[rr]][ ,i]*orchard_mat_pars[[ss]][[rr]]$fecundity[[i]])
        
        
      } # end of iterations over each orchard source
      
      
    } # end of iterations over each orchard treatment
    
    
    # --- STEP 3: LARVAL COLLECTION FROM ORCHARDS AND REFERENCE REEFS ---
    # WHY orchard-first priority: Orchard larvae come from managed stock. 
    # Reference reef larvae are only collected to make up any
    # shortfall below spawn_target, minimizing impact on wild populations.

    new_babies.o <- matrix(NA, nrow = s_orchard, ncol = source_orchard)
    
    for(ss in 1:s_orchard){ # for each orchard
      for(rr in 1:source_orchard){ # for each source of colonies to that orchard
        # new babies collected from these colonies = new babies produced by these colonies x percent successfully collected
        new_babies.o[ss,rr] <- orchard_rep[[ss]][[rr]][i]*rest_pars$orchard_yield # orchard_yield = percent of new orchard babies successfully collected
      }
    }
    
    # calculate max possible new babies that could be collected from reference reefs this year
    new_babies.r <- ref_babies[i]*rest_pars$reef_yield
    
    #tot_babies <- sum(new_babies.o) + new_babies.r # total new babies collected from orchard and reference reefs
    
    # calculate total new babies collected from the orchards this year
    tot_new_babies.o <- sum(new_babies.o)
    
    orchard_babies[i] <- tot_new_babies.o # babies collected from the orchard
    reef_babies[i] <- new_babies.r # babies collected from reference reef
    
    # tot_babies <- tot_new_babies.o + new_babies.r # total new babies collected from orchard and reference reefs
    
    # if total new babies from orchard is less than target, collect from the reference reefs until target is reached 
    if(tot_new_babies.o < rest_pars$spawn_target){ # if target wasn't reached by orchard alone
      tot_babies <- tot_new_babies.o + min(new_babies.r, (rest_pars$spawn_target - tot_new_babies.o))
      
      # then need to track embryos collected from orchard vs. reference reef (for cost estimates)
      orchard_babies_used[i] <- tot_new_babies.o # babies used from the orchard
      reef_babies_used[i] <- min(new_babies.r, (rest_pars$spawn_target - tot_new_babies.o)) # babies used from reference reef
      
      
      
    } else{
      
      tot_babies <- tot_new_babies.o
      
      orchard_babies_used[i] <- tot_new_babies.o # babies used from the orchard
      reef_babies_used[i] <- 0 # babies used from reference reef
      
    }
    
    # TILES_PER_TANK = 100. Fundemar's standard tank setup holds ~100 settlement tiles.
    # Safety cap: total larvae cannot exceed (max_embryos/tank) * (total_tiles) / (tiles/tank).
    # This prevents unrealistically high embryo densities in the lab.
    tot_babies <- min(tot_babies, rest_pars$tank_max*rest_pars$lab_max/100)
    
    # if this is the beginning of the simulation, also add the initial population in the lab
    if(i == 2){
      tot_babies <- tot_babies + N0.l[[1]]
    }
    
    # make sure these don't exceed max lab capacity (assumed lab capacity is proportional to number of tiles)
    #tot_babies <- min(tot_babies, rest_pars$lab_max)
    
    
    # --- STEP 4: LAB SETTLEMENT AND SURVIVAL ---
    # Split larvae into two streams:
    #   tot_settlers0 = larvae for IMMEDIATE outplanting ("0_TX" treatments)
    #   tot_settlers1 = larvae RETAINED in lab for 1 year ("1_TX" treatments)
    # The split is proportional to lab_retain_max / lab_max.

    if(s_lab1==0){ # if none of the lab treatments keep the recruits for a year

      tot_settlers0 <- tot_babies
      tot_settlers1 <- 0
      
      # calculate total densities
     # tot_dens0 <- tot_settlers0/rest_pars$lab_max
     # tot_dens1 <- NA
      
    } else{
      
      # update tot_settlers1 based on max capacity for retaining settlers
      #tot_settlers1 <- min(tot_babies, rest_pars$lab_retain_max)
      
      # update tot_settlers1 based on proportion of tiles that can be retained for a year
      tot_settlers1 <- tot_babies*rest_pars$lab_retain_max/rest_pars$lab_max
      
      # babies that don't fit get added to the group being outplanted right away
      tot_settlers0 <- tot_babies - tot_settlers1
      
      # calculate total densities
     # tot_dens0 <- ifelse(rest_pars$lab_max > rest_pars$lab_retain_max, tot_settlers0/(rest_pars$lab_max - rest_pars$lab_retain_max), NA)
     # tot_dens1 <- tot_settlers1/rest_pars$lab_retain_max
    }
    
    
    # holding vector for settlers in each lab treatment that will be immediately outplanted
    out_settlers <- rep(0, s_lab)
    lab_tiles <- rep(NA, s_lab) # number of tiles
    
    # prop_use = fraction of lab capacity actually used this year (0 to 1).
    # Formula: (total_larvae / min_embryos_per_tank * 100_tiles_per_tank) / total_tiles
    # If larvae supply is less than lab capacity, we use fewer tiles.
    # Assume 100 tiles per tank (same constant as the safety cap above).
    prop_use <- min(1, (tot_babies/rest_pars$tank_min*100)/rest_pars$lab_max)
    
    
    # check to make sure there's no dividing by zero: at a minimum, use one tile
    if(prop_use == 0){
      prop_use <- 1 - (rest_pars$lab_max-1)/rest_pars$lab_max
    }
    
    # update number of babies used
    orchard_babies_used[i] <- prop_use*orchard_babies_used[i]
    reef_babies_used[i] <- prop_use*reef_babies_used[i]
    
    
    # For each lab treatment, calculate settlers and apply survival.
    # Settlement chain: total_larvae x settlement_rate x tile_type_proportion
    # Survival: Ricker-type density-dependent: survivors = settlers * s0 * exp(-m0 * density)
    for(ss in 1:s_lab){ # for each lab treatment

      if(substr(lab_treatments[ss], start = 1, stop = 1)=="0"){ # immediate outplanting
        # settlers = total_larvae x sett_prop_for_tile_type x lab_space_fraction_for_tile_type
        out_settlers[ss] <- tot_settlers0*lab_pars$sett_props[[which(names(lab_pars$sett_props)==tile_types[ss])]]*rest_pars$tile_props[[which(names(rest_pars$tile_props)==tile_types[ss])]]
        
        # number of tiles
        lab_tiles[ss] <- (prop_use*(rest_pars$lab_max - rest_pars$lab_retain_max)*rest_pars$tile_props[[which(names(rest_pars$tile_props)==tile_types[ss])]])
        
        # calculate densities on the tiles
       # dens_ss <- out_settlers[ss]/lab_tiles[ss]
        dens_ss <- ifelse(lab_tiles[ss] > 0, out_settlers[ss]/lab_tiles[ss], 0) 
        
        # update out_settlers[ss] with the fraction of these that survive to outplanting
        #out_settlers[ss] <- out_settlers[ss]*lab_pars$s0[ss]*exp(-lab_pars$m0[ss]*out_settlers[ss]) # m0 = density dependent mortality rate
        out_settlers[ss] <- out_settlers[ss]*lab_pars$s0[i, ss]*exp(-lab_pars$m0[ss]*dens_ss)
        
      }
      
      if(substr(lab_treatments[ss], start = 1, stop = 1)=="1"){ # if settlers in ss^th lab treatment are retained for a year
        # settlers from this treatment to keep until next year = total being retained x prop. larvae that settle on this treatment x prop. of lab space devoted to this treatment
        retain_settlers <- tot_settlers1*lab_pars$sett_props[[which(names(lab_pars$sett_props)==tile_types[ss])]]*rest_pars$tile_props[[which(names(rest_pars$tile_props)==tile_types[ss])]]
        
        # number of tiles
        lab_tiles[ss] <- (prop_use*rest_pars$lab_retain_max*rest_pars$tile_props[[which(names(rest_pars$tile_props)==tile_types[ss])]])
        
        # calculate densities on the tiles
        # dens_ss <- retain_settlers/lab_tiles[ss]
        dens_ss <- ifelse(lab_tiles[ss] > 0, retain_settlers/lab_tiles[ss], 0)
        
        #lab_pops[[ss]][i] <- retain_settlers*lab_pars$s1[ss]*exp(-lab_pars$m1[ss]*retain_settlers) # store survivors in the lab population
        lab_pops[[ss]][i] <- retain_settlers*lab_pars$s1[i, ss]*exp(-lab_pars$m1[ss]*dens_ss) # store survivors in the lab population
      }
      
      
      
    }
    
    # record the total number of tiles being outplanted
    tiles_out0[i] <- sum(lab_tiles[which(substr(lab_treatments, start = 1, stop = 1)=="0")])
    tiles_out1[i] <- sum(lab_tiles[which(substr(lab_treatments, start = 1, stop = 1)=="1")])
    
    tiles_out_tot[i] <- tiles_out0[i] + tiles_out1[i-1]
    
    # --- STEP 5: TILE ALLOCATION (orchards vs. reefs) ---
    # Three sub-steps:
    #   5a) Calculate total tiles going to each orchard from each lab source
    #   5b) Check orchard capacity; redirect surplus tiles to reefs (overflow)
    #   5c) Calculate outplant numbers (tiles x density x survival)
    
    
    # figure out how many can go to the orchard populations
    # calculate total number of corals and adult corals currently in each orchard subpopulation
    ind_tots <- rep(NA, s_orchard) # all corals
    adult_tots <- rep(NA, s_orchard) # adults only
    for(ss in 1:s_orchard){

    ind_tots_ss <- rep(NA, source_orchard)
     adult_tots_ss <- rep(NA, source_orchard)

      for(rr in 1:source_orchard){

        # all corals
        ind_tots_ss[rr] <- sum(orchard_pops[[ss]][[rr]][ ,i])
        # adults only:
        adult_tots_ss[rr] <- sum(orchard_pops[[ss]][[rr]][c(3:5) ,i])
      }

     ind_tots[ss] <- sum(ind_tots_ss)
     adult_tots[ss] <- sum(adult_tots_ss)
      
      # if number of individuals in ss^th orchard is less than the number of tiles, update number of tiles to be equal to number of individuals (i.e., you remove substrates/outplant over substrates with no corals)
      if(ind_tots[ss] < orchard_tiles[[ss]][i-1]){
        orchard_tiles[[ss]][i-1] <- ind_tots[ss]#floor(ind_tots[ss])
      }

    }
    
    
    # calculate total coral area in the orchards
    
    # area_tots <- rep(NA, s_orchard)
    # 
    # for(ss in 1:s_orchard){ # for each orchard
    #   
    #   area_tots_ss <- rep(NA, source_orchard)
    #   
    #   for(rr in 1:source_orchard){ # for each source to each orchard
    #     
    #     area_tots_ss[rr] <- sum(orchard_pops[[ss]][[rr]][ ,i]*A_mids)
    #   }
    #   
    #   area_tots[ss] <- sum(area_tots_ss)
    # }
    # 
    
    # Orchard space = max capacity minus whichever is larger: current tiles or adult colonies.
    # WHY max(tiles, adults): Space is constrained by physical substrate (tiles) AND
    # by biological occupancy (adult colonies). A tile with no adult coral still takes space;
    # a coral that outgrew its tile still occupies a position.
    orchard_space <- rep(NA, s_orchard)

    for(ss in 1:s_orchard){

     orchard_space[ss] <- max(0, rest_pars$orchard_size[ss] - max(orchard_tiles[[ss]][i-1], adult_tots[ss]))
     # orchard_space[ss] <- max(0, rest_pars$orchard_size[ss] - adult_tots[ss]) # number of tiles ss^th orchard has space for
      
    }
    
    
    # calculate numbers of tiles that will go to each orchard and each reef from each lab source
    orchard_tiles_all <- matrix(NA, nrow = length(lab_treatments), ncol = length(orchard_treatments))
    reef_tiles_all <- matrix(NA, nrow = length(lab_treatments), ncol = length(reef_treatments))
    
    for(ss in 1:s_lab){ # for each lab treatment
      
      for(rr in 1:s_orchard){ # for each orchard
        orchard_tiles_all[ss, rr] <- lab_tiles[ss]*(1-rest_pars$reef_prop[ss])*rest_pars$orchard_out_props[ss,rr]
      }
      
      for(rr in 1:s_reef){
        reef_tiles_all[ss, rr] <- lab_tiles[ss]*rest_pars$reef_prop[ss]*rest_pars$reef_out_props[ss,rr]
      }
      
    }
    
    # WHY overflow to reef: When orchards are full, surplus tiles go to the first
    # reef rather than being wasted. This reflects operational practice where
    # produced tiles are always deployed somewhere.
    for(rr in 1:s_orchard){ # for each orchard
      
      if(orchard_space[rr] == 0){ # if there's no space in this orchard
        # add all the orchard tiles to the first reef
        reef_tiles_all[ ,1] <- reef_tiles_all[ ,1] + orchard_tiles_all[, rr]
        orchard_tiles_all[,rr] <- orchard_tiles_all[, rr] - orchard_tiles_all[, rr]
        
        orchard_tiles[[rr]][i] <- orchard_tiles[[rr]][i-1] # number of tiles in orchard stays the same
      }
      
      if(orchard_space[rr] > 0 & sum(orchard_tiles_all[, rr]) <= orchard_space[rr]){ # if all the new tiles fit in this orchard
        # update number of tiles in orchard and don't need to modify orchard_tiles_all
        orchard_tiles[[rr]][i] <- orchard_tiles[[rr]][i-1] + sum(orchard_tiles_all[, rr])#floor(sum(orchard_tiles_all[, rr]))
      }
      
      if(orchard_space[rr] > 0 & sum(orchard_tiles_all[, rr]) > orchard_space[rr]){ # if there's some space but not enough for all

        # proportion of tiles that fit:
       # prop_fits <- orchard_space[rr]/sum(orchard_tiles_all[, rr])
        prop_fits <- ifelse(sum(orchard_tiles_all[, rr]) > 0, orchard_space[rr]/sum(orchard_tiles_all[, rr]), 0)
        
        # move the extra tiles to reef one
        reef_tiles_all[ ,rr] <- reef_tiles_all[ ,rr] + orchard_tiles_all[, rr]*(1-prop_fits)
        orchard_tiles_all[, rr] <- orchard_tiles_all[, rr]*prop_fits
        
        # # n_extra <- floor(sum(orchard_tiles_all[, rr]) - orchard_space[rr]) # number of extra tiles
        # for(xx in 1:n_extra){ # move extra tiles from each source to reef proportional to the number of tiles per source
        #   indx <- which(orchard_tiles_all[, rr] == max(orchard_tiles_all[, rr]))[1] # source with the most tiles
        #   orchard_tiles_all[indx, rr] <- orchard_tiles_all[indx, rr] - min(1, orchard_tiles_all[indx, rr]) # remove one tile
        #   
        #   # add this to the reef (for simplicity, add to first reef only -- "spillover reef"). indx = lab source
        #   reef_tiles_all[indx ,1] <- reef_tiles_all[indx ,1] + min(1, orchard_tiles_all[indx, rr]) 
        # 
        # }
        
        # update number of tiles in orchard
        orchard_tiles[[rr]][i] <- orchard_tiles[[rr]][i-1] + sum(orchard_tiles_all[, rr])#floor(sum(orchard_tiles_all[, rr]))
      }
      
      
    }
    
    # lab_tiles[ss]
    
    # store total number of tiles being outplanted to reefs and orchards
    reef_tiles_out[i] <- sum(as.vector(reef_tiles_all))
    orchard_tiles_out[i] <- sum(as.vector(orchard_tiles_all))
    
    
    # --- STEP 6: OUTPLANTING EXECUTION ---
    # Calculate actual outplant numbers (tiles x density_per_tile) and add to
    # reef/orchard populations with post-outplanting density-dependent survival.

    reef_outplants <- matrix(0, nrow = s_lab, ncol = s_reef)  # immediate outplants
    reef_outplants1 <- matrix(0, nrow = s_lab, ncol = s_reef) # retained outplants (from previous year's lab)
    
    # holding vector for outplanting densities (will be used to calculate post-outplanting density dependent survival)
    dens_out <- rep(NA, s_lab)
    
    for(ss in 1:s_lab){ # for each lab treatment
      
      # calculate per tile densities to update survival with density dependence (assuming this is per tile and unaffected by total number of tiles in a location)
      # same denominator as above, just updating the numerator following any mortality that happened in the lab
      if(substr(lab_treatments[ss], start = 1, stop = 1)=="0"){
      
      #dens_ss <- out_settlers[ss]/lab_tiles[ss]
      dens_ss <- ifelse(lab_tiles[ss] > 0, out_settlers[ss]/lab_tiles[ss], 0)
      dens_out[ss] <- dens_ss
      
      # outplants going from ss^th lab treatment to each reef treatment
      # number of tiles x settlers per tile x prop. surviving
      reef_outplants[ss, ] <- reef_tiles_all[ss ,]*dens_ss#*exp(-dd_pars.r[,ss]*dens_ss)
      # reef_tiles_all[ss ,] = number of tiles going from ss^th lab treatment to each reef treatment
      }
      
      if(substr(lab_treatments[ss], start = 1, stop = 1)=="1"){ # if recruits in ssth treatment were retained a year
        
        # calculate per tile densities to update survival with density dependence (assuming this is per tile and unaffected by total number of tiles in a location)
        #dens_ss <- lab_pops[[ss]][i-1]/lab_tiles[ss]
        dens_ss <- ifelse(lab_tiles[ss] > 0, lab_pops[[ss]][i-1]/lab_tiles[ss], 0)
        dens_out[ss] <- dens_ss
        
        # they come from the lab population at the previous timepoint
        reef_outplants1[ss, ] <- reef_tiles_all[ss ,]*dens_ss#*exp(-dd_pars.r[,ss]*dens_ss)
      }
      
    }
    
    
    # Add outplants to reef populations.
    # WHY rr-1 offset: reef_outplants is indexed by lab treatment (1..s_lab), but
    # reef_pops sources start at rr=1 (external). Lab treatment j maps to source rr=j+1.
    # Post-outplanting survival: exp(-dd_pars * density) = Ricker density dependence.
    # size_props distributes settlers across size classes (most go to SC1).
    # size_props1 = size distribution for settlers retained 1 year (potentially shifted to larger classes).
    for(ss in 1:s_reef){

        for(rr in 2:source_reef){ # rr starts at 2: skip external recruits (rr=1)
          if(substr(lab_treatments[rr-1], start = 1, stop = 1)=="0"){
          reef_pops[[ss]][[rr]][ ,i] <- reef_pops[[ss]][[rr]][ ,i] + reef_outplants[rr-1,ss]*exp(-dd_pars.r[,rr-1]*dens_out[rr-1])*lab_pars$size_props[rr-1,]
          }
          
          # add the recruits from the previous year
          if(substr(lab_treatments[rr-1], start = 1, stop = 1)=="1"){
          reef_pops[[ss]][[rr]][ ,i] <- reef_pops[[ss]][[rr]][ ,i] + reef_outplants1[rr-1,ss]*exp(-dd_pars.r[,rr-1]*dens_out[rr-1])*lab_pars$size_props1[rr-1,] # size_props1 specifies the fractions of last years lab recruits that are now in each size class
          }
          
          # store the numbers being outplanted
          reef_out[[ss]][[rr]][i] <- reef_outplants[rr-1,ss] + reef_outplants1[rr-1,ss]
          
        }
      
    }
    
    
    # repeat for orchard outplants
    
    # orchard_space[ss] # number of tiles that will fit in ss^th orchard
    orchard_outplants <- matrix(0, nrow = s_lab, ncol = s_orchard) # this year's
    orchard_outplants1 <- matrix(0, nrow = s_lab, ncol = s_orchard) # last year's
    
    dens_out <- rep(NA, s_lab)
    
    for(ss in 1:s_lab){
      
      
      if(substr(lab_treatments[ss], start = 1, stop = 1)=="0"){
      # calculate per tile densities to update survival with density dependence (assuming this is per tile and unaffected by total number of tiles in a location)
      #dens_ss <- out_settlers[ss]/lab_tiles[ss]
      dens_ss <- ifelse(lab_tiles[ss] > 0, out_settlers[ss]/lab_tiles[ss], 0) 
      
      
      dens_out[ss] <- dens_ss
      
      orchard_outplants[ss, ] <- orchard_tiles_all[ss, ]*dens_ss#*exp(-dd_pars.o[,ss]*dens_ss)
      # 1-reef_prop[ss] = proportion lab recruits from ss lab treatment going to orchard
      # orchard_out_props[ss,] = proportion of the orchard outplants from lab treatment ss going to each orchard treatment
      }
      
      
      if(substr(lab_treatments[ss], start = 1, stop = 1)=="1"){ # if recruits in ssth treatment were retained a year
        # calculate per tile densities to update survival with density dependence (assuming this is per tile and unaffected by total number of tiles in a location)
        #dens_ss <- lab_pops[[ss]][i-1]/lab_tiles[ss]
        dens_ss <- ifelse(lab_tiles[ss] > 0, lab_pops[[ss]][i-1]/lab_tiles[ss], 0) 
        
        dens_out[ss] <- dens_ss
        
        orchard_outplants1[ss, ] <- orchard_tiles_all[ss, ]*dens_ss#*exp(-dd_pars.o[,ss]*dens_ss)
        
      }
      
    }
    
    
    # add the outplants to the orchard subpopulations
    for(ss in 1:s_orchard){
      
      for(rr in 1:source_orchard){ # for each lab source
        
        if(substr(lab_treatments[rr], start = 1, stop = 1)=="0"){
        orchard_pops[[ss]][[rr]][ ,i] <- orchard_pops[[ss]][[rr]][ ,i] + orchard_outplants[rr,ss]*exp(-dd_pars.o[,rr]*dens_out[rr])*lab_pars$size_props[rr,]
        }
        
        if(substr(lab_treatments[rr], start = 1, stop = 1)=="1"){
        orchard_pops[[ss]][[rr]][ ,i] <- orchard_pops[[ss]][[rr]][ ,i] + orchard_outplants1[rr,ss]*exp(-dd_pars.o[,rr]*dens_out[rr])*lab_pars$size_props1[rr,]
        }
        
        # store the numbers being outplanted
        orchard_out[[ss]][[rr]][i] <- orchard_outplants[rr,ss] + orchard_outplants1[rr,ss]
      }
      
    }
    
    
      
    # --- STEP 7: COLONY TRANSPLANTING (orchard → reef) ---
    # WHY: Mature orchard colonies can be physically moved to reefs to
    # immediately boost reproductive capacity. rest_pars$transplant[i] is a
    # binary flag indicating whether transplanting occurs this year.
    # trans_mats specifies how many colonies of each size class to move.
    # trans_reef specifies the destination reef and source subpopulation.

    if(rest_pars$transplant[i]==1){
      
      for(ss in 1:s_orchard){ # for each orchard subpopulation
        
        #colony_mat_ss <- list()
        
        for(rr in 1:source_orchard){ # for each lab source
          
          trans_colonies <- rest_pars$trans_mats[[ss]][[rr]][i,] # number of colonies to transplant
          
          # make sure these don't exceed the numbers in the population
          for(nn in 1:n){ # for each size class
            # if number to transplant is greater than number available at this timepoint, then only transplant the number of colonies available
            trans_colonies[nn] <- ifelse(trans_colonies[nn] > orchard_pops[[ss]][[rr]][nn ,i], orchard_pops[[ss]][[rr]][nn ,i], trans_colonies[nn])
          }
          
          # add the colonies to the correct reef population
          ss.reef <- rest_pars$trans_reef[[ss]][[rr]][i,1] # [i,1] = reef receiving the corals from the ith transplant from the ss/rr^th orchard population
          rr.reef <- rest_pars$trans_reef[[ss]][[rr]][i,2] # [i, 2] = reef source subpopulation (e.g., lab treatment 1 outplants, etc.) receiving the corals from the ith transplant from the ss/rr^th orchard population
          
         # if(prop_fits[ss.reef] !=0){ # if there's room on this reef
            reef_pops[[ss.reef]][[rr.reef]][ ,i] <-  reef_pops[[ss.reef]][[rr.reef]][ ,i] + trans_colonies*rest_pars$trans_surv
            # and substract these from the orchard
            orchard_pops[[ss]][[rr]][ ,i] <- orchard_pops[[ss]][[rr]][ ,i] - trans_colonies
         # }
          
        } # end of iteration over all source subpopulations in ss^th orchard
        
      } # end of iteration over all orchards
      
    } # end of if statement for transplanting colonies
    
  } # end of iteration over each year
  
  # RETURN VALUE: List with 17 elements
  #   reef_pops         — reef population sizes [[ss]][[rr]][size_class, year]
  #   orchard_pops      — orchard population sizes [[ss]][[rr]][size_class, year]
  #   lab_pops          — lab population sizes [[ss]][year]
  #   reef_rep          — reef reproductive output (larvae) [[ss]][[rr]][year]
  #   orchard_rep       — orchard reproductive output [[ss]][[rr]][year]
  #   reef_out          — number outplanted to each reef [[ss]][[rr]][year]
  #   orchard_out       — number outplanted to each orchard [[ss]][[rr]][year]
  #   reef_pops_pre     — reef sizes BEFORE outplanting (for measuring natural dynamics)
  #   orchard_pops_pre  — orchard sizes BEFORE outplanting
  #   orchard_babies    — total larvae collected from orchards [year]
  #   reef_babies       — total larvae available from reference reef [year]
  #   orchard_babies_used — orchard larvae actually used [year]
  #   reef_babies_used    — reef larvae actually used [year]
  #   tiles_out_tot     — total tiles outplanted [year]
  #   reef_tiles_out    — tiles outplanted to reefs [year]
  #   orchard_tiles_out — tiles outplanted to orchards [year]
  #   orchard_tiles     — tile inventory in each orchard [[ss]][year]

  return(list(reef_pops = reef_pops, orchard_pops = orchard_pops, lab_pops = lab_pops,
              reef_rep = reef_rep, orchard_rep = orchard_rep, reef_out = reef_out,
              orchard_out = orchard_out, reef_pops_pre = reef_pops_pre,
              orchard_pops_pre = orchard_pops_pre, orchard_babies = orchard_babies,
              reef_babies = reef_babies, orchard_babies_used = orchard_babies_used,
              reef_babies_used = reef_babies_used, tiles_out_tot = tiles_out_tot,
              reef_tiles_out = reef_tiles_out, orchard_tiles_out = orchard_tiles_out,
              orchard_tiles = orchard_tiles))

}

# =============================================================================
#' @title Population Growth Rate (Lambda) Calculator
#' @description Calculates the asymptotic population growth rate (lambda) from
#'   demographic parameters. Lambda > 1 = growing, lambda < 1 = declining.
#'   Uses the leading eigenvalue of the projection matrix A = (T + F) %*% diag(S).
#' @param surv_pars Vector of survival probabilities for each size class
#' @param growth_pars List of growth transition probabilities
#' @param shrink_pars List of shrinkage probabilities
#' @param frag_pars List of fragmentation probabilities
#' @return Numeric: leading eigenvalue (lambda) of the projection matrix
#' @note Hardcodes n=5 size classes. SEE: coral_demographic_funs.R::G_fun()
#' @export
pop_lambda_fun <- function(surv_pars, growth_pars, shrink_pars, frag_pars){

  # Build transition + fragmentation matrices for a single year
  all_mats <- G_fun(1, n = 5, growth_pars, shrink_pars, frag_pars)
  G_list <- all_mats$G_list
  Fr_list <- all_mats$Fr_list
  
  Tmat.i <- G_list[[1]]
  Fmat.i <- Fr_list[[1]]
  
  # calculate lambda (population growth rate)
  # FIX: Apply survival column-wise (via diagonal matrix) to match simulation behavior
  pop_mat <- (Tmat.i + Fmat.i) %*% diag(surv_pars)
  lambda_1 <- Re(eigen(pop_mat)$values[1]) # leading eigenvalue
  
  return(lambda_1)
  
}

#' @title Model Output Summary Function
#' @description Summarizes simulation output into a matrix of yearly values for
#'   a chosen metric (individuals, area, or reproductive output) across all
#'   subpopulations of a given location type. Uses pre-outplant population sizes
#'   (reef_pops_pre / orchard_pops_pre) to measure natural dynamics separately
#'   from restoration additions.
#' @param model_sim Full output list from rse_mod1() or rse_mod()
#' @param location "reef" or "orchard"
#' @param metric "ind" (individuals), "area_m2" (coral cover in m^2), or "production" (larvae)
#' @param n_reef Number of reef subpopulations
#' @param n_orchard Number of orchard subpopulations
#' @param n_lab Number of lab treatments
#' @param size_classes Size classes to include (default: all 5)
#' @return Matrix with rows = years, columns = subpopulations
#' @note Requires A_mids (size class midpoint areas in cm^2) in the calling
#'   environment for the "area_m2" metric. Division by 10000 converts cm^2 to m^2.

model_summ <- function(model_sim, location, metric, n_reef, n_orchard, n_lab, 
                       size_classes = c(1, 2, 3, 4, 5)){
  
  years <- length(model_sim$reef_pops_pre[[1]][[1]][1, ])
  
  if(location == "reef"){
    
    if(metric == "ind"){
      
      # holding matrix for total population size in each reef at each time point
      out_mat <- matrix(NA, nrow = years, ncol = n_reef)
      
      for(i in 1:n_reef){ # for each reef
        
        reef_tot <- apply(model_sim$reef_pops_pre[[i]][[1]][size_classes, ], MARGIN = 2, sum)
        
        if(n_lab > 0){ # if there was at least one lab source
          
          for(j in 1:n_lab){ # add total individuals from each lab source
            
            reef_tot <- reef_tot + apply(model_sim$reef_pops_pre[[i]][[1 + j]][size_classes, ], MARGIN = 2, sum)
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
          
          reef_tot_tt <- sum(model_sim$reef_pops_pre[[i]][[1]][size_classes,tt]*A_mids[size_classes]) # calculate total area covered by individuals on ith reef from first source
          
          if(n_lab > 0){ # if there was at least one lab source
            
            for(j in 1:n_lab){ # add total individuals from each lab source
              
              reef_tot_tt <- reef_tot_tt + sum(model_sim$reef_pops_pre[[i]][[1 + j]][size_classes,tt]*A_mids[size_classes])
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
            
            orchard_tot <- orchard_tot + apply(model_sim$orchard_pops_pre[[i]][[j]][size_classes, ], MARGIN = 2, sum)
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
              
              orchard_tot_tt <- orchard_tot_tt + sum(model_sim$orchard_pops_pre[[i]][[j]][size_classes,tt]*A_mids[size_classes]) # calculate total area covered by individuals on ith orchard from jth source
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

# ==========================================================================
# LEGACY MODEL VERSION — Use rse_mod1() for current analyses
# ==========================================================================
# rse_mod() was the original implementation. Key differences from rse_mod1():
#   - No density-dependent mortality (dens_pars.r, dens_pars.o not used)
#   - No tile tracking (orchard_tiles not returned)
#   - No reference reef larval collection (lambda_R not a parameter)
#   - Space constraints are area-based (A_mids) rather than tile-count-based
#   - Includes "none" treatment handling for reference reefs
#   - Orchard overflow uses extra_orchard_outplants logic (different from rse_mod1)
#   - lab_pars$s0/s1 are scalars (not year-indexed matrices as in rse_mod1)
#
# Retained for backward compatibility with function_tests.Rmd.
# SEE: rse_mod1() above for the fully documented current model.
# ==========================================================================

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
  # FIX: Protect against division by zero when reef_areas sum to zero
  reef_area_sum <- sum(rest_pars$reef_areas)
  if(reef_area_sum > 0) {
    ext_props <- rest_pars$reef_areas / reef_area_sum
  } else {
    ext_props <- rep(0, length(rest_pars$reef_areas))
  }

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


#' @title Population Viability Analysis (PVA) Model
#' @description Simplified single-reef model for population viability analysis.
#'   Tracks two sources of recruits (external/wild settlers and outplants) on a
#'   single reef WITHOUT orchard or lab dynamics. Used to evaluate long-term
#'   population persistence under different outplanting scenarios.
#' @details Unlike rse_mod1(), this function:
#'   - Models only a single reef (no orchards, no labs)
#'   - Takes outplant numbers as direct input (out_pars) rather than modeling
#'     the full lab pipeline
#'   - Does not include space constraints or density dependence
#'   - Does not include tile tracking or fragmentation suppression
#'   Core equation: N(t) = (T + F) %*% (S * N(t-1)) + outplants + recruits
#' @return List with 3 elements:
#'   reef_pops — population sizes [[ss]][[rr]][size_class, year] (ss=1, rr=1..2)
#'   reef_rep — reproductive output [[ss]][[rr]][year]
#'   reef_pops_pre — population sizes before outplanting
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







