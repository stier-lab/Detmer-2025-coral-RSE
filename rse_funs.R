# README: functions for simulating the model

# orchard_treatments
# lab_treatments
# reef_treatments

# reef subpops = length(lab_treatments)*length(reef_treatments)

# lab subpops = length(lab_treatments)


# set up holding matrices
# reef subpops
reef_pops <- list() # list with holding matrices for each reef subpopulation
reef_dfs <- list()

for(ss in 1:length(s_reef)){
  reef_pops[[ss]] <- matrix(NA, nrow = years, ncol = n)
  # add initial conditions here too

  # and calculate the data frames with the transition matrix parameters?
}

# orchard subpops
orchard_pops <- list()

for(ss in 1:length(s_orchard)){
  orchard_pops[[ss]] <- matrix(NA, nrow = years, ncol = n)
  # add initial conditions here too
}


# lab subpops
for(ss in 1:length(s_lab)){
  lab_pops[[ss]] <- matrix(NA, nrow = years, ncol = n)
  # add initial conditions here too
}


for(i in 1:years){

# restoration model: determines how many recruits/corals go in each treatment
# and also keeps track of the costs of each treatment
# feedback = numbers going in to each treatment depends on population sizes, env., etc.

# reef dynamics
# get total cover (for density dependence)

  for(ss in 1:length(s_reef)){

    GSF_df
    S_df

    T_mat <- matrix(NA, nrow = n, ncol = n) # transition matrix

  }

  # update survival probability with density dependence


}


# summary data frames (total cover, total reproductive output)













