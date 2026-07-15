## AUTO-EXTRACTED Fig4 data chunk (4021-4120)

# area outplanted: try to approximate the area of the orchard, so number of reef start in orchard x area per reef star. Estimate area of reef star as 0.337 m2 (from https://onlinelibrary.wiley.com/doi/full/10.1111/rec.12866)
area_out <- 1250#170 # 500*0.337 = 168.5; round up to 170. 1250 = avg area covered in full orchard
lambda_R_12345 <- round(area_out/(A_mids*0.0001)) #c(10000, 1000, 100, 10, 1)
out_sizes <- c(1, 2, 3, 4, 5)

lab_pars <- lab_pars_def

# make sure there's no orchard investment and all embryos are included
rest_pars <- rest_pars_def
rest_pars$reef_prop <- c(1,1)
rest_pars$reef_yield <- 1

# holding list for model output

mod_out_L <- list()

mod_ind <- matrix(NA, nrow = years, ncol = 5) # total number of individuals on reef
mod_area <- matrix(NA, nrow = years, ncol = 5) # total area covered on the reef

# total number in each size class after 5 and 50 years
mod_mat5 <- matrix(NA, nrow = 5, ncol = 5) # row = outplanting scenario
mod_mat50 <- matrix(NA, nrow = 5, ncol = 5)

dens_pars.r <- list()
dens_pars.r[[1]] <- list() # first reef treatment/subpop
dens_pars.r[[1]][[1]] <- 0 # first source to first reef (external recruits)
dens_pars.r[[1]][[2]] <- dens_pars.r[[1]][[1]] # second source to first reef (tiles outplanted immediately)
dens_pars.r[[1]][[3]] <- dens_pars.r[[1]][[1]] # third source to first reef (tiles retained in lab)

N0.l <- list()
N0.l[[1]] <- 0 # make sure there's nothing already in the lab
N0.l[[2]] <- 0 

for(j in 1:5){
  
 lambda_R_j <- lambda_R_12345[j]
  
  size_props <- matrix(NA, nrow = length(lab_treatments), ncol = n) # matrix for fractions of retained recruits in each size class at the end of their year in the lab
size_props[1, ] <- rep(0, 5) # first lab treatment (0_T1)
size_props[1, out_sizes[j]] <- 1
lab_pars <- list(s0 = matrix(1, nrow = years, ncol = 2), s1 = matrix(1, nrow = years, ncol = 2), m0 = 0, m1 = 0, sett_props = list(T1 = 1), size_props = size_props, size_props1 = size_props1)

sim_j <- rse_mod1(years, n, A_mids, surv_pars.rc, surv_pars.r, dens_pars.r, growth_pars.r, shrink_pars.r, frag_pars.r, fec_pars.r, surv_pars.o, dens_pars.o, growth_pars.o, shrink_pars.o, frag_pars.o, fec_pars.o, lambda, lambda_R = lambda_R_j, sigma_s, sigma_f, ext_rand, seeds, dist_yrs, dist_pars.r, dist_effects.r, dist_pars.o, dist_effects.o, orchard_treatments, reef_treatments, lab_treatments, lab_pars, rest_pars, N0.r, N0.o, N0.l)


  
mod_out_L[[j]] <- sim_j


mod_ind[,j] <- model_summ(model_sim = sim_j, location = "reef", metric = "ind", n_reef = length(reef_treatments), n_orchard = length(orchard_treatments), n_lab = length(lab_treatments))

mod_area[,j] <- model_summ(model_sim = sim_j, location = "reef", metric = "area_m2", n_reef = length(reef_treatments), n_orchard = length(orchard_treatments), n_lab = length(lab_treatments))

mod_ind1 <- model_summ(model_sim = sim_j, location = "reef", metric = "ind", n_reef = length(reef_treatments), n_orchard = length(orchard_treatments), n_lab = length(lab_treatments), size_classes = c(1))

mod_ind2 <- model_summ(model_sim = sim_j, location = "reef", metric = "ind", n_reef = length(reef_treatments), n_orchard = length(orchard_treatments), n_lab = length(lab_treatments), size_classes = c(2))

mod_ind3 <- model_summ(model_sim = sim_j, location = "reef", metric = "ind", n_reef = length(reef_treatments), n_orchard = length(orchard_treatments), n_lab = length(lab_treatments), size_classes = c(3))

mod_ind4 <- model_summ(model_sim = sim_j, location = "reef", metric = "ind", n_reef = length(reef_treatments), n_orchard = length(orchard_treatments), n_lab = length(lab_treatments), size_classes = c(4))

mod_ind5 <- model_summ(model_sim = sim_j, location = "reef", metric = "ind", n_reef = length(reef_treatments), n_orchard = length(orchard_treatments), n_lab = length(lab_treatments), size_classes = c(5))

mod_mat5[,j] <- c(mod_ind1[6], mod_ind2[6], mod_ind3[6], mod_ind4[6], mod_ind5[6])
mod_mat50[,j] <- c(mod_ind1[51], mod_ind2[51], mod_ind3[51], mod_ind4[51], mod_ind5[51])

}


# reset size props to default
lab_pars <- lab_pars_def

#size_props <- matrix(NA, nrow = length(lab_treatments), ncol = n)
#size_props[1, ] <- c(1, 0, 0, 0, 0) # first lab treatment 
#lab_pars <- list(s0 = s0, s1 = s1, m0 = m0, m1 = m1, sett_props = sett_props, size_props = size_props, size_props1 = size_props1)

# reset orchard investment
#rest_pars$reef_prop <- c(0.5, 1)
rest_pars <- rest_pars_def

# turn density dependence back on
dens_pars.r <- dens_pars.r_def

N0.l <- N0.l_def


# lambda_R_12345[1]
# mod_out_L[[1]]$reef_pops[[1]][[2]][1,2]
# lambda_R_12345[2]
# mod_out_L[[2]]$reef_pops[[1]][[2]][2,2]
# lambda_R_12345[3]
# mod_out_L[[3]]$reef_pops[[1]][[2]][3,2]
# lambda_R_12345[4]
# mod_out_L[[4]]$reef_pops[[1]][[2]][4,2]
# lambda_R_12345[5]
# mod_out_L[[5]]$reef_pops[[1]][[2]][5,2]

