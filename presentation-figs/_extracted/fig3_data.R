## AUTO-EXTRACTED Fig3 curves data (3301-3329)
#prop_all <- seq(from = 0, to = 1, length.out = 20) # main strategies to focus on

prop_all <- seq(from = 0, to = 1, length.out = 11)

lambda_Rs <- c(0, 1255111)

#lab_max <- 12000

#orch_D0 <- orch_exp_fun2(dem_pars_all = all_pars_R, n_pars = n_sample1, prop_set = prop_main, par_set2 = NULL, par2_name = "none", dist = F, dist_yrs = NULL, dist_pars_list = NULL)

tic()
orch_D0_all <- orch_exp_fun2(dem_pars_all = all_pars_R, n_pars = n_sample1, prop_set = prop_all, par_set2 = lambda_Rs, par2_name = "lambda_R", dist = F, dist_yrs = NULL, dist_pars_list = NULL)

# [slide: skipped disturbance run] orch_D3_all <- orch_exp_fun2(dem_pars_all = all_pars_R, n_pars = n_sample1, prop_set = prop_all, par_set2 = lambda_Rs, par2_name = "lambda_R", dist = T, dist_yrs = dist_yrs3, dist_pars_list = dist_pars_list3)
toc()

# process the output

orch_D0_all_dt5 <- full_dt_fun(sim_list = orch_D0_all, max_yr = 6, n_pars = n_sample1, prop_set = prop_all, par_set2 = lambda_Rs, par2_name = "lambda_R")
orch_D0_all_dt50 <- full_dt_fun(sim_list = orch_D0_all, max_yr = 51, n_pars = n_sample1, prop_set = prop_all, par_set2 = lambda_Rs, par2_name = "lambda_R")

# [slide: skipped disturbance run] orch_D3_all_dt5 <- full_dt_fun(sim_list = orch_D3_all, max_yr = 6, n_pars = n_sample1, prop_set = prop_all, par_set2 = lambda_Rs, par2_name = "lambda_R")
# [slide: skipped disturbance run] orch_D3_all_dt50 <- full_dt_fun(sim_list = orch_D3_all, max_yr = 51, n_pars = n_sample1, prop_set = prop_all, par_set2 = lambda_Rs, par2_name = "lambda_R")


#lab_max <- 4000

