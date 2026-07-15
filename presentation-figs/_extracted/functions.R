## AUTO-EXTRACTED functions block (670-1628)


# function for running orchard expansion simulations with different restoration parameter values
# prop_set = vector with proportions of substrates to outplant to orchard
# dem_pars = set of demographic parameters to use
# par_set2 = values of the second parameter to iterate over
# par2_name = name of the second parameter to iterate over (NOTE: function currently only allows for parameters that are in rest_pars list, lab_pars list, or "lambda_R", "frag_pars.o", fec_pars.o, "surv_pars.o_1", and "surv_pars.r_12")
# dist = whether or not there is a disturbance regime (T or F)
orch_exp_fun1 <- function(dem_pars, prop_set, par_set2 = NULL, par2_name = "none", dist = F, dist_yrs = NULL, dist_pars_list = NULL){
  
  out_list <- list()


# outer loop = demographic parameter values
# inner loop = proportion to outplant to the reef

  dens_pars.r_def <- dens_pars.r
  dens_pars.o_def <- dens_pars.o

L_outer <- ifelse(par2_name == "none", 1, length(par_set2))  

for(i in 1:L_outer){ # for each parameter set
  
  # set up the parameters
  
  surv_pars.r <- dem_pars$surv_pars.r
  surv_pars.rc <- dem_pars$surv_pars.rc
  growth_pars.r <- dem_pars$growth_pars.r
  shrink_pars.r <- dem_pars$shrink_pars.r
  frag_pars.r <- dem_pars$frag_pars.r
  surv_pars.o <- dem_pars$surv_pars.o
  growth_pars.o <- dem_pars$growth_pars.o
  shrink_pars.o <- dem_pars$shrink_pars.o
  frag_pars.o <- dem_pars$frag_pars.o
  
  if(par2_name == "frag_pars.o"){
frag_pars.o[[1]][[1]][[4]] <- frag_pars.r[[1]][[1]][[4]]*par_set2[i]

frag_pars.o[[1]][[1]][[5]] <- frag_pars.r[[1]][[1]][[5]]*par_set2[i]

 }
  
 if(par2_name == "dens_pars.r"){
   
dens_pars.r[[1]][[1]] <- dens_pars.r_def[[1]][[1]]*par_set2[i]
dens_pars.r[[1]][[2]] <- dens_pars.r_def[[1]][[2]]*par_set2[i]
dens_pars.r[[1]][[3]] <- dens_pars.r_def[[1]][[3]]*par_set2[i]

 }
  
  if(par2_name == "dens_pars.o"){
dens_pars.o[[1]][[1]] <- dens_pars.o_def[[1]][[1]]*par_set2[i]
dens_pars.o[[1]][[2]] <- dens_pars.o_def[[1]][[2]]*par_set2[i]

 }
  
  if(par2_name == "surv_pars.o_1"){
surv_pars.o[[1]][[1]][1] <- surv_pars.r[[1]][[1]][1]*par_set2[i]

  }
  
  if(par2_name == "surv_pars.r_12"){ # survival of 1-yr lab outplants
surv_pars.r[[1]][[3]][1] <- min(surv_pars.r[[1]][[3]][1]*par_set2[i], 1)
surv_pars.r[[1]][[3]][2] <- min(surv_pars.r[[1]][[3]][2]*par_set2[i], 1)

surv_pars.rc[[1]][[3]][1] <- min(surv_pars.rc[[1]][[3]][1]*par_set2[i], 1)


  }
  
  if(par2_name == "fec_pars.o"){
    fec_pars.o <- list()
    fec_pars.o[[1]] <- list() # first treatment
    fec_pars.o[[1]][[1]] <- c(0, 0, rep(1255111/26, 3))*par_set2[i]
  }
  
  # set up disturbance
  if(dist == F){
    
    dist_yrs <- NA
    
  } else{
    # update with disturbance effects
  
# effects of disturbance on each reef subpop
dist_effects.r <- list()
dist_effects.r[[1]] <- list() 
dist_effects.r[[1]][[1]] <- list() # effects of disturbances on corals from first source in first reef subpop
dist_effects.r[[1]][[1]] <- as.list(rep("survival", length(dist_yrs))) # effects of each disturbance on corals from first source in first reef subpop 
dist_effects.r[[1]][[2]] <- list() # second source
dist_effects.r[[1]][[2]] <- as.list(rep("survival", length(dist_yrs)))
dist_effects.r[[1]][[3]] <- list() # third source
dist_effects.r[[1]][[3]] <- as.list(rep("survival", length(dist_yrs)))


# disturbance effects for each orchard subpop
dist_effects.o <- list()

dist_effects.o[[1]] <- list() 
dist_effects.o[[1]][[1]] <- list() # effects of disturbances on corals from first source in first orchard treatment
dist_effects.o[[1]][[1]] <- as.list(rep("survival", length(dist_yrs))) 
dist_effects.o[[1]][[2]] <- list() # second source
dist_effects.o[[1]][[2]] <- as.list(rep("survival", length(dist_yrs))) 


surv_pars.r1 <- list(list(), list(), list()) # holding list for survival following disturbance events for each source to the reef
surv_pars.rc1 <- list(list(), list(), list()) # same for recruit survival
surv_pars.o1 <- list(list(), list()) # holding list for survival following disturbance events for each source to the orchard

for(jj in 1:length(dist_yrs)){ # for each year with a disturbance
  
  dist_pars_list$dist.r[[1]][jj,]
  
  # update the survival parameters
  surv_pars.r1[[1]][[jj]] <- surv_pars.r[[1]][[1]]*dist_pars_list$dist.r[[1]][jj,] # note this is the same as the proportional reduction in reference reef production
  surv_pars.r1[[2]][[jj]] <- surv_pars.r[[1]][[2]]*dist_pars_list$dist.r[[2]][jj,]
  surv_pars.r1[[3]][[jj]] <- surv_pars.r[[1]][[3]]*dist_pars_list$dist.r[[3]][jj,]
  
  surv_pars.rc1[[1]][[jj]] <- surv_pars.rc[[1]][[1]]*dist_pars_list$dist.rc[[1]][jj] # note this is the same as the proportional reduction in reference reef production
  surv_pars.rc1[[2]][[jj]] <- surv_pars.rc[[1]][[2]]*dist_pars_list$dist.rc[[2]][jj]
  surv_pars.rc1[[3]][[jj]] <- surv_pars.rc[[1]][[3]]*dist_pars_list$dist.rc[[3]][jj]
  
  surv_pars.o1[[1]][[jj]] <- surv_pars.o[[1]][[1]]*dist_pars_list$dist.o[[1]][jj,]
  surv_pars.o1[[2]][[jj]] <- surv_pars.o[[1]][[2]]*dist_pars_list$dist.o[[2]][jj,]

}


# disturbance parameters for each reef subpop (what happens to the population parameters at each disturbance event)
dist_pars.r <- list()
dist_pars.r[[1]] <- list() 
dist_pars.r[[1]][[1]] <- dist_pars_fun(dist_yrs = dist_yrs, dist_effects.r[[1]][[1]], dist_surv0 = surv_pars.r1[[1]], dist_surv_rc0 = surv_pars.rc1[[1]], dist_Tmat0 = NULL, dist_Fmat0 = NULL, dist_fec0 = NULL) 
dist_pars.r[[1]][[2]] <- dist_pars_fun(dist_yrs = dist_yrs, dist_effects.r[[1]][[2]], dist_surv0 = surv_pars.r1[[2]], dist_surv_rc0 = surv_pars.rc1[[2]], dist_Tmat0 = NULL, dist_Fmat0 = NULL, dist_fec0 = NULL)
dist_pars.r[[1]][[3]] <- dist_pars_fun(dist_yrs = dist_yrs, dist_effects.r[[1]][[3]], dist_surv0 = surv_pars.r1[[3]], dist_surv_rc0 = surv_pars.rc1[[3]], dist_Tmat0 = NULL, dist_Fmat0 = NULL, dist_fec0 = NULL)


# disturbance parameters for each orchard subpop
dist_pars.o <- list()
dist_pars.o[[1]] <- list() 
dist_pars.o[[1]][[1]] <- dist_pars_fun(dist_yrs = dist_yrs, dist_effects.o[[1]][[1]], dist_surv0 = surv_pars.o1[[1]], dist_Tmat0 = NULL, dist_Fmat0 = NULL, dist_fec0 = NULL)
dist_pars.o[[1]][[2]] <- dist_pars_fun(dist_yrs = dist_yrs, dist_effects.o[[1]][[2]], dist_surv0 = surv_pars.o1[[2]], dist_Tmat0 = NULL, dist_Fmat0 = NULL, dist_fec0 = NULL)
  
  
  }
  

  
  # holding list for model simulations with this parameter set
  mod_list <- list()
  
  for(j in 1:length(prop_set)){ # for each proportion outplanted to reef
    
    lab_pars_ij <- lab_pars
    rest_pars_ij <- rest_pars
    
    rest_pars_ij$reef_prop <- c(prop_set[j], 1) # proportion of tiles outplanted to reef for each treatment
    
    if(par2_name %in% names(rest_pars_ij)[c(2:4, 9:13)]){ # all restoration parameters that are just a single parameter
      rest_pars_ij[[which(names(rest_pars_ij) == par2_name)]] <- par_set2[i]
    } 
    
    # if(par2_name %in% names(lab_pars_ij)){
    #   lab_pars_ij[[which(names(lab_pars_ij) == par2_name)]] <- par_set2[i]
    # } 
    
    if(par2_name == "m0"){
      lab_pars_ij$m0 <- lab_pars_ij$m0*par_set2[i]
    } 
    
    # m0, s0, sett_props
    
    if(par2_name == "s0"){
      lab_pars_ij$s0 <- lab_pars_ij$s0*par_set2[i]
    } 
    
    if(par2_name == "sett_props"){
      lab_pars_ij$sett_props$T1 <- lab_pars_ij$sett_props$T1*par_set2[i]
    } 
    
    if(par2_name == "lambda_R"){
      lambda_R <- par_set2[i]
    } 
    
    # run the model
    sim_ij <- rse_mod1(years, n, A_mids, surv_pars.rc, surv_pars.r, dens_pars.r, growth_pars.r, shrink_pars.r, frag_pars.r, fec_pars.r, surv_pars.o, dens_pars.o, growth_pars.o, shrink_pars.o, frag_pars.o, fec_pars.o, lambda, lambda_R, sigma_s, sigma_f, ext_rand, seeds, dist_yrs, dist_pars.r, dist_effects.r, dist_pars.o, dist_effects.o, orchard_treatments, reef_treatments, lab_treatments, lab_pars_ij, rest_pars_ij, N0.r, N0.o, N0.l)
    
    # save the output
    mod_list[[j]] <- sim_ij
    
  } # end of iterations over outplanting proportions
  
  
  out_list[[i]] <- mod_list
  
} # end of iterations over parameter sets

return(out_list)
  
}


# wrapper function for iterating over multiple demographic parameter sets
# dem_pars_all = list with all sets of demographic parameters
# n_pars = number of parameter sets in dem_pars_all
# SC2_lists = randomly generated parameter lists for the uncertain parameters related to SC2 scenarios (transplanting and lab grow out). Default is null; otherwise includes transplant survival (for orchard transplanting scenario), annual growth rates in lab, annual survival in lab, and outplant survival post-year in lab (all for lab grow out scenario)

orch_exp_fun2 <- function(dem_pars_all, n_pars, prop_set, par_set2 = NULL, par2_name = "none", dist = F, dist_yrs = NULL, dist_pars_list = NULL, SC2_lists = NULL){
  
  out_list2 <- list() # holding list
  
  for(i in 1:n_pars){
    
    dem_pars <- sapply(dem_pars_all, "[[", i) # select the i^th element from each component of the full list of demographic parameters
    
    dem_pars <- list(surv_pars.r = list(dem_pars$surv_pars_L.r), surv_pars.rc = list(dem_pars$surv_pars_L.rc), growth_pars.r = list(dem_pars$growth_pars_L.r), shrink_pars.r = list(dem_pars$shrink_pars_L.r), frag_pars.r = list(dem_pars$frag_pars_L.r), surv_pars.o = list(dem_pars$surv_pars_L.o), growth_pars.o = list(dem_pars$growth_pars_L.o), shrink_pars.o = list(dem_pars$shrink_pars_L.o), frag_pars.o = list(dem_pars$frag_pars_L.o))
    
    if(is.null(SC2_lists)==F){
      rest_pars$trans_surv <- SC2_lists$trans_surv_list[[i]]
      lab_pars$s1[,1] <- rep(SC2_lists$lab_surv1_list[[i]], years)
      lab_pars$s1[,2] <- lab_pars$s1[,1]
      
      lab_pars$size_props1[2,] <- c(1-SC2_lists$lab_growth1_list[[i]], SC2_lists$lab_growth1_list[[i]], 0, 0, 0)
      
      dem_pars$surv_pars.r[[1]][[3]][1] <- min(dem_pars$surv_pars.r[[1]][[3]][1]*SC2_lists$lab_out_surv1_list[[i]], 1)
      
      dem_pars$surv_pars.r[[1]][[3]][2] <- min(dem_pars$surv_pars.r[[1]][[3]][2]*SC2_lists$lab_out_surv1_list[[i]], 1)
      
      dem_pars$surv_pars.rc[[1]][[3]] <- min(dem_pars$surv_pars.rc[[1]][[3]]*SC2_lists$lab_out_surv1_list[[i]],1)
      
    }
    
    
    out_list2[[i]] <- orch_exp_fun1(dem_pars, prop_set, par_set2, par2_name, dist, dist_yrs, dist_pars_list)
    
  }
  
  return(out_list2)
  
}


# https://stackoverflow.com/questions/44176908/r-list-get-first-item-of-each-element
#sapply(all_pars_R, "[[", 100)


# function for running orchard expansion simulations with different restoration parameter values
# growth_set = vector with growth of babies kept in lab or in orchard (proportion that transition from size class 1 to 2 after one year)
# surv_set = vector with survival rates in lab/after transplanting to reef
# out_par_type = either "lab_growth" (growing out babies in lab for a year) or "orch_trans" (transplanting corals from the orchard to the reef)
# dem_pars = set of demographic parameters to use
# par_set2 = values of the second parameter to iterate over
# par2_name = name of the second parameter to iterate over (NOTE: function currently only allows for parameters that are in rest_pars list or "lambda_R", "frag_pars.o", fec_pars.o, "surv_pars.o_1", and "surv_pars.r_1")
# dist = whether or not there is a disturbance regime (T or F)
lab_trans_fun1 <- function(dem_pars, growth_set, surv_set, out_par_type, par_set2 = NULL, par2_name = "none", dist = F, dist_yrs = NULL, dist_pars_list = NULL){
  
  out_list <- list()


# outer loop = demographic parameter values
# inner loop = proportion to outplant to the reef

L_outer <- ifelse(par2_name == "none", 1, length(par_set2))  

for(i in 1:L_outer){ # for each parameter set
  
  # set up the parameters
  
  surv_pars.r <- dem_pars$surv_pars.r
  surv_pars.rc <- dem_pars$surv_pars.rc
  growth_pars.r <- dem_pars$growth_pars.r
  shrink_pars.r <- dem_pars$shrink_pars.r
  frag_pars.r <- dem_pars$frag_pars.r
  surv_pars.o <- dem_pars$surv_pars.o
  growth_pars.o <- dem_pars$growth_pars.o
  shrink_pars.o <- dem_pars$shrink_pars.o
  frag_pars.o <- dem_pars$frag_pars.o
  
 if(par2_name == "frag_pars.o"){
frag_pars.o[[1]][[1]][[4]] <- frag_pars.r[[1]][[1]][[4]]*par_set2[i]

frag_pars.o[[1]][[1]][[5]] <- frag_pars.r[[1]][[1]][[5]]*par_set2[i]

 }
  
  if(par2_name == "surv_pars.o_1"){
surv_pars.o[[1]][[1]][1] <- surv_pars.r[[1]][[1]][1]*par_set2[i]

  }
  
  if(par2_name == "surv_pars.r_1"){
#surv_pars.r[[1]][[1]][1] <- surv_pars.r[[1]][[1]][1]*par_set2[i]
#surv_pars.r[[1]][[2]][1] <- surv_pars.r[[1]][[1]][1]*par_set2[i]
#surv_pars.r[[1]][[3]][1] <- surv_pars.r[[1]][[1]][1]*par_set2[i]

surv_pars.r[[1]][[3]][1] <- min(surv_pars.r[[1]][[3]][1]*par_set2[i], 1)
surv_pars.r[[1]][[3]][2] <- min(surv_pars.r[[1]][[3]][2]*par_set2[i], 1)

surv_pars.rc[[1]][[3]][1] <- min(surv_pars.rc[[1]][[3]][1]*par_set2[i], 1)


  }
  
  if(par2_name == "fec_pars.o"){
    fec_pars.o <- list()
    fec_pars.o[[1]] <- list() # first treatment
    fec_pars.o[[1]][[1]] <- c(0, 0, rep(1255111/26, 3))*par_set2[i]
  }
  
  # set up disturbance
  if(dist == F){
    
    dist_yrs <- NA
    
  } else{
    # update with disturbance effects
  
# effects of disturbance on each reef subpop
dist_effects.r <- list()
dist_effects.r[[1]] <- list() 
dist_effects.r[[1]][[1]] <- list() # effects of disturbances on corals from first source in first reef subpop
dist_effects.r[[1]][[1]] <- as.list(rep("survival", length(dist_yrs))) # effects of each disturbance on corals from first source in first reef subpop 
dist_effects.r[[1]][[2]] <- list() # second source
dist_effects.r[[1]][[2]] <- as.list(rep("survival", length(dist_yrs)))
dist_effects.r[[1]][[3]] <- list() # third source
dist_effects.r[[1]][[3]] <- as.list(rep("survival", length(dist_yrs)))


# disturbance effects for each orchard subpop
dist_effects.o <- list()

dist_effects.o[[1]] <- list() 
dist_effects.o[[1]][[1]] <- list() # effects of disturbances on corals from first source in first orchard treatment
dist_effects.o[[1]][[1]] <- as.list(rep("survival", length(dist_yrs))) 
dist_effects.o[[1]][[2]] <- list() # second source
dist_effects.o[[1]][[2]] <- as.list(rep("survival", length(dist_yrs))) 


surv_pars.r1 <- list(list(), list(), list()) # holding list for survival following disturbance events for each source to the reef
surv_pars.rc1 <- list(list(), list(), list()) # same for recruits
surv_pars.o1 <- list(list(), list()) # holding list for survival following disturbance events for each source to the orchard

for(jj in 1:length(dist_yrs)){ # for each year with a disturbance
  
  dist_pars_list$dist.r[[1]][jj,]
  
  # update the survival parameters
  surv_pars.r1[[1]][[jj]] <- surv_pars.r[[1]][[1]]*dist_pars_list$dist.r[[1]][jj,] # note this is the same as the proportional reduction in reference reef production
  surv_pars.r1[[2]][[jj]] <- surv_pars.r[[1]][[2]]*dist_pars_list$dist.r[[2]][jj,]
  surv_pars.r1[[3]][[jj]] <- surv_pars.r[[1]][[3]]*dist_pars_list$dist.r[[3]][jj,]
  
  
  surv_pars.rc1[[1]][[jj]] <- surv_pars.rc[[1]][[1]]*dist_pars_list$dist.rc[[1]][jj] # note this is the same as the proportional reduction in reference reef production
  surv_pars.rc1[[2]][[jj]] <- surv_pars.rc[[1]][[2]]*dist_pars_list$dist.rc[[2]][jj]
  surv_pars.rc1[[3]][[jj]] <- surv_pars.rc[[1]][[3]]*dist_pars_list$dist.rc[[3]][jj]
  
  surv_pars.o1[[1]][[jj]] <- surv_pars.o[[1]][[1]]*dist_pars_list$dist.o[[1]][jj,]
  surv_pars.o1[[2]][[jj]] <- surv_pars.o[[1]][[2]]*dist_pars_list$dist.o[[2]][jj,]

}


# disturbance parameters for each reef subpop (what happens to the population parameters at each disturbance event)
dist_pars.r <- list()
dist_pars.r[[1]] <- list() 
dist_pars.r[[1]][[1]] <- dist_pars_fun(dist_yrs = dist_yrs, dist_effects.r[[1]][[1]], dist_surv0 = surv_pars.r1[[1]], dist_surv_rc0 = surv_pars.rc1[[1]], dist_Tmat0 = NULL, dist_Fmat0 = NULL, dist_fec0 = NULL) 
dist_pars.r[[1]][[2]] <- dist_pars_fun(dist_yrs = dist_yrs, dist_effects.r[[1]][[2]], dist_surv0 = surv_pars.r1[[2]], dist_surv_rc0 = surv_pars.rc1[[2]], dist_Tmat0 = NULL, dist_Fmat0 = NULL, dist_fec0 = NULL)
dist_pars.r[[1]][[3]] <- dist_pars_fun(dist_yrs = dist_yrs, dist_effects.r[[1]][[3]], dist_surv0 = surv_pars.r1[[3]], dist_surv_rc0 = surv_pars.rc1[[3]], dist_Tmat0 = NULL, dist_Fmat0 = NULL, dist_fec0 = NULL)


# disturbance parameters for each orchard subpop
dist_pars.o <- list()
dist_pars.o[[1]] <- list() 
dist_pars.o[[1]][[1]] <- dist_pars_fun(dist_yrs = dist_yrs, dist_effects.o[[1]][[1]], dist_surv0 = surv_pars.o1[[1]], dist_Tmat0 = NULL, dist_Fmat0 = NULL, dist_fec0 = NULL)
dist_pars.o[[1]][[2]] <- dist_pars_fun(dist_yrs = dist_yrs, dist_effects.o[[1]][[2]], dist_surv0 = surv_pars.o1[[2]], dist_Tmat0 = NULL, dist_Fmat0 = NULL, dist_fec0 = NULL)
  
  
  }
  

  
  # holding list for model simulations with this parameter set
  mod_list <- list()
  
  for(j in 1:length(growth_set)){ # for each growth rate
    
     mod_list_h <- list()
    
    for(h in 1:length(surv_set)){ # for each survival rate
    
    lab_pars_ij <- lab_pars
    rest_pars_ij <- rest_pars
    
    if(par2_name %in% names(rest_pars_ij)){
      rest_pars_ij[[which(names(rest_pars_ij) == par2_name)]] <- par_set2[i]
    } 
    
    if(par2_name %in% names(lab_pars_ij)){
      lab_pars_ij[[which(names(lab_pars_ij) == par2_name)]] <- par_set2[i]
    } 
    
    if(par2_name == "lambda_R"){
      lambda_R <- par_set2[i]
    } 
    
  
    if(out_par_type == "lab_growth"){
    
    surv_pars.r_j <- surv_pars.r
    surv_pars.rc_j <- surv_pars.rc
    
   #LS_mat <- matrix(NA, nrow = length(LS_set), ncol = 2)
   #LS_mat[,2] <- LS_set # SC2 survival rates
   #LS_mat[,1] <- LS_set*surv_pars.r[[1]][[2]][1]/surv_pars.r[[1]][[2]][2]
   # #surv_pars.r_j[[1]][[3]][c(1,2)] <- LS_mat[h,]
   
   # SC1 survival rates: preserve same ratio between SC1 and SC2 survival as in field parameters
   # surv_pars.rc_j[[1]][[3]][1] <- LS_set[h]*surv_pars.rc[[1]][[2]][1]/surv_pars.r[[1]][[2]][2]
    # SC2 survival rates:
   # surv_pars.r_j[[1]][[3]][2] <- LS_set[h]
    
    lab_pars_ij$size_props1[2, ] <- c(1-growth_set[j], growth_set[j], 0, 0,0)
    
    lab_pars_ij$s1[,1] <- rep(LS_set[h], years)
    lab_pars_ij$s1[,2] <- lab_pars_ij$s1[,1]
      
      
    sim_ij <- rse_mod1(years, n, A_mids, surv_pars.rc_j, surv_pars.r_j, dens_pars.r, growth_pars.r, shrink_pars.r, frag_pars.r, fec_pars.r, surv_pars.o, dens_pars.o, growth_pars.o, shrink_pars.o, frag_pars.o, fec_pars.o, lambda, lambda_R, sigma_s, sigma_f, ext_rand, seeds, dist_yrs, dist_pars.r, dist_effects.r, dist_pars.o, dist_effects.o, orchard_treatments, reef_treatments, lab_treatments, lab_pars_ij, rest_pars_ij, N0.r, N0.o, N0.l)
    }
    
    if(out_par_type == "orch_trans"){
      
      growth_pars.o_j <- growth_pars.o
      growth_pars.o_j[[1]][[1]][[1]][1] <- growth_set[j]
      
      trans_surv_j <- rep(surv_set[h], 5)
      rest_pars_ij$trans_surv <- trans_surv_j
    
      sim_ij <- rse_mod1(years, n, A_mids, surv_pars.rc, surv_pars.r, dens_pars.r, growth_pars.r, shrink_pars.r, frag_pars.r, fec_pars.r, surv_pars.o, dens_pars.o, growth_pars.o_j, shrink_pars.o, frag_pars.o, fec_pars.o, lambda, lambda_R, sigma_s, sigma_f, ext_rand, seeds, dist_yrs, dist_pars.r, dist_effects.r, dist_pars.o, dist_effects.o, orchard_treatments, reef_treatments, lab_treatments, lab_pars_ij, rest_pars_ij, N0.r, N0.o, N0.l)
    }
    
    
    
    # save the output
    mod_list_h[[h]] <- sim_ij
    
  } # end of iterations over survival rates
    
     # save the output
    mod_list[[j]] <- mod_list_h
     
  } # end of iterations over growth rates
  
  
  out_list[[i]] <- mod_list
  
} # end of iterations over parameter sets

return(out_list)
  
}


# wrapper function for iterating over multiple demographic parameter sets
# dem_pars_all = list with all sets of demographic parameters
# n_pars = number of parameter sets in dem_pars_all

lab_trans_fun2 <- function(dem_pars_all, n_pars, growth_set, surv_set, out_par_type, par_set2 = NULL, par2_name = "none", dist = F, dist_yrs = NULL, dist_pars_list = NULL, SC2_lists = NULL){

  
  out_list2 <- list() # holding list
  
  for(i in 1:n_pars){
    
    dem_pars <- sapply(dem_pars_all, "[[", i) # select the i^th element from each component of the full list of demographic parameters
    
    dem_pars <- list(surv_pars.r = list(dem_pars$surv_pars_L.r), surv_pars.rc = list(dem_pars$surv_pars_L.rc), growth_pars.r = list(dem_pars$growth_pars_L.r), shrink_pars.r = list(dem_pars$shrink_pars_L.r), frag_pars.r = list(dem_pars$frag_pars_L.r), surv_pars.o = list(dem_pars$surv_pars_L.o), growth_pars.o = list(dem_pars$growth_pars_L.o), shrink_pars.o = list(dem_pars$shrink_pars_L.o), frag_pars.o = list(dem_pars$frag_pars_L.o))
    
    if(is.null(SC2_lists)==F){
     # rest_pars$trans_surv <- SC2_lists$trans_surv_list[[i]]
     # lab_pars$s1[,1] <- rep(SC2_lists$lab_surv1_list[[i]], years)
     # lab_pars$s1[,2] <- lab_pars$s1[,1]
      
     # lab_pars$size_props1[2,] <- c(1-SC2_lists$lab_growth1_list[[i]], SC2_lists$lab_growth1_list[[i]], 0, 0, 0)
      
      dem_pars$surv_pars.r[[1]][[3]][1] <- min(dem_pars$surv_pars.r[[1]][[3]][1]*SC2_lists$lab_out_surv1_list[[i]], 1)
      
      dem_pars$surv_pars.r[[1]][[3]][2] <- min(dem_pars$surv_pars.r[[1]][[3]][2]*SC2_lists$lab_out_surv1_list[[i]], 1)
      
      dem_pars$surv_pars.rc[[1]][[3]] <- min(dem_pars$surv_pars.rc[[1]][[3]]*SC2_lists$lab_out_surv1_list[[i]],1)
      
    }
    
    
    out_list2[[i]] <- lab_trans_fun1(dem_pars, growth_set, surv_set, out_par_type, par_set2, par2_name, dist, dist_yrs, dist_pars_list)
    
    
  }
  
  return(out_list2)
  
}



# second wrapper function for making the data frames
# wrapper function for combining data frames from multiple parameter sets
# sim_list = list with model simulation output for multiple parameters
# max_yr = end of time interval over which to calculate the metrics
# n_pars = number of demographic parameter sets used in sim_list
# prop_set = vector with proportions of substrates to outplant to orchard
# par_set2 = values of the second parameter to iterate over
# par2_name = name of the second parameter iterated over in sim_list
full_dt_fun2 <- function(sim_list, max_yr, n_pars, growth_set, surv_set, out_par_type, par_set2, par2_name, annual_costs = F){
  
  costs_list <- list()
  
  for(i in 1:n_pars){
    costs_list_i <- list()
  
  for(j in 1:length(par_set2)){
    
    costs_list_j <- list()
    
    for(k in 1:length(growth_set)){
      
      costs_list_k <- list()
      
      for(h in 1:length(surv_set)){
        
        if(n_pars == 1){
          sim_ijk <- sim_list[[j]][[k]][[h]]
        } else{
          sim_ijk <- sim_list[[i]][[j]][[k]][[h]]
        }
      
        if(annual_costs == F){
          dt_ijk <- metrics_dt_fun(sim_ijk, max_yr , annual_costs)
        } else{
          metrics_ijk <- metrics_dt_fun(sim_ijk, max_yr, annual_costs)
        
        dt_ijk <- metrics_ijk$dt_i
        
        costs_list_k[[h]] <- metrics_ijk$tot_costs_yr
        }
      
      
      dt_ijk$par_rep <- i
      dt_ijk$growth_par <- growth_set[k]
      dt_ijk$surv_par <- surv_set[h]
      dt_ijk$par2 <- par_set2[j]
      
      
        
        if(h == 1){
        dt_h <- dt_ijk
      } else{
        dt_h <- rbind(dt_h, dt_ijk)
      }
      
      } # end of h loop
      
      costs_list_j[[k]] <- costs_list_k
      
      
      if(k == 1){
        dt_k <- dt_h
      } else{
        dt_k <- rbind(dt_k, dt_h)
      }
    } # end of k loop
    
    costs_list_i[[j]] <- costs_list_j
    
    if(j == 1){
      dt_j <- dt_k
    } else{
      dt_j <- rbind(dt_j, dt_k)
    }
    
  } # end of j loop
  
  if(i == 1){
    dt_i <- dt_j
  } else{
    dt_i <- rbind(dt_i, dt_j)
  }
    
    costs_list[[i]] <- costs_list_i
  
  } # end of i loop
  
  
  dt_i$par_name2 <- par2_name
  dt_i$out_par_type <- out_par_type
  
  if(annual_costs == F){
    return(dt_i)
  } else{
    return(list(dt_i = dt_i, costs_list = costs_list))
  }
  
  return(dt_i)
}



# function for extracting performance metrics from the simulations
# sim = model simulation output
# max_yr = end of time interval over which to calculate the metrics
# annual costs = whether or not to also return vector with total costs each year from year 2 to max_yr
metrics_dt_fun <- function(sim, max_yr, annual_costs = F){
  
  if(max_yr == 1){
    yr_seq <- 1
  } else{
    yr_seq <- c(2:max_yr)
  }
  
      r_inf <- 0.056 # inflation rate
      
      # fixed costs
      c_RS <- 84.6*rest_pars$orchard_size/30 + 1200 # reef stars (cost of reef stars plus cost of boat rental for installation); no inflation because assume this is only an initial cost
      
      # fixed costs that are per year (need to account for inflation)
      # c_perm <- 400*length(2:max_yr)
      c_perm <- sum(400*(1 + r_inf)^(yr_seq)) # permits for collecting babies (400 per year)
      c_boat <- sum(1200*4*(1 + r_inf)^(yr_seq)) # boat maintenance (1200 every 3 months/4x per year)
      c_log <- sum(500*12*(1 + r_inf)^(yr_seq)) # logistics/personnel (500 per month/12x per year)
      
      c_fixed <- c_RS + c_perm + c_boat + c_log
  
  
    # make the holding data frame
      L1 <- 1
    dt_i <- data.frame(
  reef_cover_mean = rep(NA, L1), # m2 of coral cover on reef (mean over years 1 to max_yr)
  reef_function_mean = rep(NA, L1), # avg area covered by large/reproductive (size classes 3-5) corals on reef
  reef_tiles_out_tot = rep(NA, L1), # total number of tiles outplanted to reef
  reef_area_out_tot = rep(NA, L1), # total area of reef over which tiles were outplanted 
  reef_recruits_out_tot = rep(NA, L1), # total recruits outplanted to reef
  reef_ROI_mean = rep(NA, L1), # average coral cover on reef per dollar spent, averaged over max_yr years
  reefI_ROI_mean = rep(NA, L1), # average number of corals on reef per dollar spent, averaged over max_yr years
  tot_ROI_mean = rep(NA, L1), # average total ROI (total area covered by corals on reef and orchard per dollar spent)
  totI_ROI_mean = rep(NA, L1), # average total ROI in terms of individuals (total number of corals on reef and orchard per dollar spent)
  orch_function_mean = rep(NA, L1), # avg area covered by large/reproductive (size classes 3-5) corals in orchard
 tot_costs = rep(NA, L1), # total amount spent over length of simulation
 c_fixed = rep(NA, L1), # fixed costs
 c_subs = rep(NA, L1), # costs of substrates
 c_out = rep(NA, L1), # outplanting costs
 c_maint = rep(NA, L1), # orchard maintenance costs
 c_lab = rep(NA, L1), # lab costs
 c_spawn = rep(NA, L1), # costs of collecting spawn
 c_trans = rep(NA, L1) # costs of transplanting corals
)
    
  j <- 1
    
      sim_ij <- sim
      
      # reef cover
      reef_cover_ij <- model_summ(model_sim = sim_ij, location = "reef", metric = "area_m2", n_reef = length(reef_treatments), n_orchard = length(orchard_treatments), n_lab = length(lab_treatments))
      
      # reef individuals
      reef_ind_ij <- model_summ(model_sim = sim_ij, location = "reef", metric = "ind", n_reef = length(reef_treatments), n_orchard = length(orchard_treatments), n_lab = length(lab_treatments))
      
      # reef function
      reef_fun_ij <- model_summ(model_sim = sim_ij, location = "reef", metric = "area_m2", n_reef = length(reef_treatments), n_orchard = length(orchard_treatments), n_lab = length(lab_treatments), size_classes = c(3, 4, 5))

      # orchard rep
#orch_rep_ij <- model_summ(model_sim = sim_ij, location = "orchard", metric = "production", n_reef = length(reef_treatments), n_orchard = length(orchard_treatments), n_lab = length(lab_treatments))
      
      # orchard cover
    orch_cover_ij <- model_summ(model_sim = sim_ij, location = "orchard", metric = "area_m2", n_reef = length(reef_treatments), n_orchard = length(orchard_treatments), n_lab = length(lab_treatments))
    
    # orchard individuals
    orch_ind_ij <- model_summ(model_sim = sim_ij, location = "orchard", metric = "ind", n_reef = length(reef_treatments), n_orchard = length(orchard_treatments), n_lab = length(lab_treatments))

      # orchard function
orch_fun_ij <- model_summ(model_sim = sim_ij, location = "orchard", metric = "area_m2", n_reef = length(reef_treatments), n_orchard = length(orchard_treatments), n_lab = length(lab_treatments), size_classes = c(3, 4, 5))

      dt_i$reef_cover_mean[j] <- mean(reef_cover_ij[yr_seq], na.rm = T)
      dt_i$reef_function_mean[j] <- mean(reef_fun_ij[yr_seq], na.rm = T)
      dt_i$reef_tiles_out_tot[j] <- sum(sim_ij$reef_tiles_out[yr_seq], na.rm = T)
      dt_i$reef_area_out_tot[j] <- dt_i$reef_tiles_out_tot[j]*5
      dt_i$reef_recruits_out_tot[j] <- sum(sim_ij$reef_out[[1]][[2]][yr_seq], na.rm = T)
      dt_i$orch_function_mean[j] <- mean(orch_fun_ij[yr_seq], na.rm = T)
      
    
      
       # variable costs
      # substrate costs
      c_subs_yr <- (sim_ij$reef_tiles_out[yr_seq] + sim_ij$orchard_tiles_out[yr_seq]) *(0.5*1 + 0.5*7)*(1 + r_inf)^(yr_seq) # substrate costs each year
      c_subs <- sum((sim_ij$reef_tiles_out[yr_seq] + sim_ij$orchard_tiles_out[yr_seq]) *(0.5*1 + 0.5*7)*(1 + r_inf)^(yr_seq)) # total substrate costs over time interval
      
      
    # outplanting and orchard maintenance costs
      c_reef <- rep(NA, length(yr_seq)) # reef
      c_orch <- rep(NA, length(yr_seq)) # orchard
      c_maint <- rep(NA, length(yr_seq)) # orchard maintenance
      
      # transplanting costs (ESTIMATED)
      c_trans <- rep(NA, length(yr_seq)) # transplanting from orchard to reef
      
      for(ii in yr_seq){
        #print(ii)
        
 # outplanting costs (assuming you can outplant ~1,250 substrates per day to the reef and 800 per day to the orchard)
        c_reef[ii-1] <- 300*ceiling(sim_ij$reef_tiles_out[ii]/1250) + 200*sim_ij$reef_tiles_out[ii]/1250 + 380/2000*sim_ij$reef_tiles_out[ii]
        
        c_reef[ii-1] <- c_reef[ii-1]*(1 + r_inf)^(ii)
        
       c_orch[ii-1] <- 300*ceiling(sim_ij$orchard_tiles_out[ii]/800) + 200*sim_ij$orchard_tiles_out[ii]/800 + 250/2000 * sim_ij$orchard_tiles_out[ii]
       
       c_orch[ii-1] <- c_orch[ii-1]*(1 + r_inf)^(ii)
        
        # currently occupied reef stars in the orchard:
        RS_ii <- rep(NA, length(orchard_treatments))
        for(kk in 1:length(orchard_treatments)){ # in case there's more than one orchard
          RS_ii[kk] <- sim_ij$orchard_tiles[[kk]][ii]/30 # 30 tiles per reef star
        }
        
        RS_ii <- sum(RS_ii) # filled reef stars in orchard this year
        
        c_maint[ii-1] <- ifelse(RS_ii == 0, 0, (1.5*530-530)/(2*123-123)*RS_ii + 265) 
        c_maint[ii-1] <- c_maint[ii-1]*2*(1 + r_inf)^(ii) # assume maintenance is performed 2x per year, also add inflation
        
        # transplanting costs (ESTIMATED: assume you can collect 1000 corals from the orchard per day and outplant that many to the reef in one more day)
        # trans_colonies_tot
        c_trans[ii-1] <- (300*ceiling(sim_ij$trans_colonies_tot[ii]/1000) + 200*sim_ij$trans_colonies_tot[ii]/1000)*2 # boat costs + diver costs, x2 for collecting from orchard and then outplanting on reef
        
      } # end of loop over 2:max_yr
      
      c_out_yr <- c_reef + c_orch
      c_maint_yr <- c_maint
      c_trans_yr <-  c_trans
      
      c_out <- sum(c_reef) + sum(c_orch)
      c_maint <- sum(c_maint)
      c_trans <-  sum(c_trans)
 
      # lab costs
     # c_lab <- (432*7 + 200*7)*length(2:max_yr) # assume all tiles are only kept in the lab for two weeks
      
      
      if(rest_pars$lab_retain_max[1] == 0){ # if all tiles are only kept in the lab for two weeks
      c_lab <- sum((432*7 + 200*7)*(1 + r_inf)^(yr_seq))
      c_lab_yr <- (432*7 + 200*7)*(1 + r_inf)^(yr_seq)
      
      } else{
      c_lab2w <- (432*7 + 200*7)*(1 + r_inf)^(yr_seq) # cost of initial two weeks for all substrates
      c_lab1yr <- (200*(12*30 - 14))*(1 + r_inf)^(yr_seq)# cost of keeping substrates for 12 months in the lab (subtract the first 2 weeks = 14 days from length of time in lab)
      c_lab <- sum(c_lab2w) + sum(c_lab1yr)
      c_lab_yr <- c_lab2w + c_lab1yr
        
        
      }
  
      # spawning costs    
      c_spawn <- rep(NA, length(yr_seq))
      for(ii in yr_seq){
        c_spawn[ii-1] <- ifelse(sim_ij$reef_babies_used[ii] > 0, 6500, 0) + ifelse(sim_ij$orchard_babies_used[ii] > 0, 3250, 0)
        c_spawn[ii-1] <- c_spawn[ii-1]*(1 + r_inf)^(ii)
        
      }
     
      c_spawn_yr <- c_spawn
      c_spawn <- sum(c_spawn)
      
      # total costs over length of specified time interval
     tot_costs <- c_fixed + c_subs + c_out + c_maint + c_lab + c_spawn + c_trans
     # total costs each year:
     tot_costs_yr <- rep(c_fixed, length(yr_seq)) + c_subs_yr + c_out_yr + c_maint_yr + c_lab_yr + c_spawn_yr + c_trans_yr
     
     dt_i$c_fixed[j] <- c_fixed
     dt_i$c_subs[j] <- c_subs
     dt_i$c_out[j] <- c_out
     dt_i$c_maint[j] <- c_maint
     dt_i$c_lab[j] <- c_lab
     dt_i$c_spawn[j] <- c_spawn
     dt_i$c_trans[j] <- c_trans
     dt_i$tot_costs[j] <- tot_costs
     
     dt_i$reef_ROI_mean[j] <- mean(reef_cover_ij[yr_seq]/tot_costs_yr)
      
      # invert ROI
     # dt_i$reef_ROI_mean[j] <- mean(tot_costs_yr/reef_cover_ij[yr_seq])
      
      
     dt_i$tot_ROI_mean[j] <- mean((reef_cover_ij[yr_seq] + orch_cover_ij[yr_seq])/tot_costs_yr)
      
     # dt_i$tot_ROI_mean[j] <- mean(tot_costs_yr/(reef_cover_ij[yr_seq] + orch_cover_ij[yr_seq]))
      
     dt_i$reefI_ROI_mean[j] <- mean(reef_ind_ij[yr_seq]/tot_costs_yr)
      
     # dt_i$reefI_ROI_mean[j] <- mean(tot_costs_yr/reef_ind_ij[yr_seq])
      
      dt_i$totI_ROI_mean[j] <- mean((reef_ind_ij[yr_seq] + orch_ind_ij[yr_seq])/tot_costs_yr)
      
     # dt_i$totI_ROI_mean[j] <- mean(tot_costs_yr/(reef_ind_ij[yr_seq] + orch_ind_ij[yr_seq]))
  
      
  if(annual_costs == F){
    return(dt_i) # return the data frame
  } else{
    return(list(dt_i = dt_i, tot_costs_yr = tot_costs_yr))
  }
  
}



# function that returns mean and error bars for coral cover and orchard function at each time point across demographic parameters
# sim_list = full list of simulations across demographic parameters, orchard outplanting proportions, and an optional second parameter
ts_fun <- function(sim_list, n_pars, max_yr, prop_choice, par2_choice = 1){
  
  # holding matrix for total coral cover at each timepoint (row) and parameter combination (columns)
  reef_cover <- matrix(NA, nrow = max_yr, ncol = n_pars)
  
  # repeat for orchard function
  orch_fun <- matrix(NA, nrow = max_yr, ncol = n_pars)
  
  for(i in 1:n_pars){
    
    sim_i <- sim_list[[i]][[par2_choice]][[prop_choice]]
    
    reef_cover[,i] <- model_summ(model_sim = sim_i, location = "reef", metric = "area_m2", n_reef = length(reef_treatments), n_orchard = length(orchard_treatments), n_lab = length(lab_treatments))[1:max_yr]
    
    orch_fun[,i] <- model_summ(model_sim = sim_i, location = "orchard", metric = "area_m2", n_reef = length(reef_treatments), n_orchard = length(orchard_treatments), n_lab = length(lab_treatments), size_classes = c(3, 4, 5))
    
  }
  
  # now calculate the mean, 95%, and 5% quantiles, and standard deviations  across parameter values at each time point
  reef_cover_mn <- apply(reef_cover, 1, function(x) mean(x, na.rm = T))
  reef_cover_low <- apply(reef_cover, 1, function(x) quantile(x, 0.95, na.rm = T))
  reef_cover_up <- apply(reef_cover, 1, function(x) quantile(x, 0.05, na.rm = T))
  
  reef_cover_sd <- apply(reef_cover, 1, function(x) sd(x, na.rm = T))
  
  orch_fun_mn <- apply(orch_fun, 1, function(x) mean(x, na.rm = T))
  orch_fun_low <- apply(orch_fun, 1, function(x) quantile(x, 0.95, na.rm = T))
  orch_fun_up <- apply(orch_fun, 1, function(x) quantile(x, 0.05, na.rm = T))
  orch_fun_sd <- apply(orch_fun, 1, function(x) sd(x, na.rm = T))
  
  
  # return mean, 75% quantile, 25% quantile, and full matrixes for each metric
  
  return(list(reef_cover_mn = reef_cover_mn, reef_cover_low = reef_cover_low, reef_cover_up = reef_cover_up, reef_cover_sd = reef_cover_sd, orch_fun_mn = orch_fun_mn, orch_fun_low = orch_fun_low, orch_fun_up = orch_fun_up, orch_fun_sd = orch_fun_sd, reef_cover_all = reef_cover, orch_fun_all = orch_fun))
  
}




# wrapper function for combining data frames from multiple parameter sets
# sim_list = list with model simulation output for multiple parameters
# max_yr = end of time interval over which to calculate the metrics
# n_pars = number of demographic parameter sets used in sim_list
# prop_set = vector with proportions of substrates to outplant to orchard
# par_set2 = values of the second parameter to iterate over
# par2_name = name of the second parameter iterated over in sim_list
full_dt_fun <- function(sim_list, max_yr, n_pars, prop_set, par_set2, par2_name, annual_costs = F){
  
  costs_list <- list()
  
  for(i in 1:n_pars){
  
    costs_list_i <- list()
    
  for(j in 1:length(par_set2)){
    
    costs_list_j <- list()
    
    for(k in 1:length(prop_set)){
      
      
      if(n_pars == 1){
        sim_ijk <- sim_list[[j]][[k]]
      } else{
        sim_ijk <- sim_list[[i]][[j]][[k]]
      }
      
      
      if(annual_costs == F){
        dt_ijk <- metrics_dt_fun(sim_ijk, max_yr, annual_costs)
      
      } else{
        
        metrics_ijk <- metrics_dt_fun(sim_ijk, max_yr, annual_costs)
        
        dt_ijk <- metrics_ijk$dt_i
        
        costs_list_j[[k]] <- metrics_ijk$tot_costs_yr

      }
      
      dt_ijk$par_rep <- i
      dt_ijk$prop_out <- prop_set[k]
      dt_ijk$par2 <- par_set2[j]
      
      if(k == 1){
        dt_k <- dt_ijk
      } else{
        dt_k <- rbind(dt_k, dt_ijk)
      }
    }
    
    costs_list_i[[j]] <- costs_list_j
    
    if(j == 1){
      dt_j <- dt_k
    } else{
      dt_j <- rbind(dt_j, dt_k)
    }
    
  }
  
  if(i == 1){
    dt_i <- dt_j
  } else{
    dt_i <- rbind(dt_i, dt_j)
  }
  
    
    costs_list[[i]] <- costs_list_i
  }
  
  
  dt_i$par_name2 <- par2_name
  
  if(annual_costs == F){
    return(dt_i)
  } else{
    return(list(dt_i = dt_i, costs_list = costs_list))
  }

}


