## AUTO-EXTRACTED Fig2 trajectory data (1780-1811)
# reef cover for the three restoration levels, no disturbance

N0.r <- list()
N0.r[[1]] <- list() # second reef subpop
N0.r[[1]][[1]] <- rep(0, n) # first source (external recruits)
N0.r[[1]][[2]] <- rep(10, n) # second source. Start with some corals
N0.r[[1]][[3]] <- rep(0, n) # third source


orch_D0_50 <- orch_exp_fun2(dem_pars_all = all_pars_R, n_pars = n_sample1, prop_set = prop_main[1], par_set2 = lambda_Rs[2], par2_name = "lambda_R", dist = F, dist_yrs = NULL, dist_pars_list = NULL)

orch_D0_100 <- orch_exp_fun2(dem_pars_all = all_pars_R, n_pars = n_sample1, prop_set = prop_main[2], par_set2 = lambda_Rs[2], par2_name = "lambda_R", dist = F, dist_yrs = NULL, dist_pars_list = NULL)

orch_D0_0 <- orch_exp_fun2(dem_pars_all = all_pars_R, n_pars = n_sample1, prop_set = prop_main[2], par_set2 = lambda_Rs[1], par2_name = "lambda_R", dist = F, dist_yrs = NULL, dist_pars_list = NULL)

# repeat with lambda = 100
# [slide: skipped lambda=100 SM] lambda <- 100
# [slide: skipped lambda=100 SM] orch_D0_50_100 <- orch_exp_fun2(dem_pars_all = all_pars_R, n_pars = n_sample1, prop_set = prop_main[1], par_set2 = lambda_Rs[2], par2_name = "lambda_R", dist = F, dist_yrs = NULL, dist_pars_list = NULL)

# [slide: skipped lambda=100 SM] orch_D0_100_100 <- orch_exp_fun2(dem_pars_all = all_pars_R, n_pars = n_sample1, prop_set = prop_main[2], par_set2 = lambda_Rs[2], par2_name = "lambda_R", dist = F, dist_yrs = NULL, dist_pars_list = NULL)

# [slide: skipped lambda=100 SM] orch_D0_0_100 <- orch_exp_fun2(dem_pars_all = all_pars_R, n_pars = n_sample1, prop_set = prop_main[2], par_set2 = lambda_Rs[1], par2_name = "lambda_R", dist = F, dist_yrs = NULL, dist_pars_list = NULL)

# reset initial conditions to default
N0.r <- N0.r_def

# reset lambda
lambda <- lambda_def


