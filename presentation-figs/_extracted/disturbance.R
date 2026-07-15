## AUTO-EXTRACTED disturbance regimes (616-660)

dist_yrs3 <- c(1:max(years))[c(F, T,F)] # years when disturbance occurs: once every 3 years

# list where elements are for each group, each element is matrix where rows are time points with disturbances and columns are size classes

dist_mat.r <- matrix(0.2, nrow = length(dist_yrs3), ncol = 5)
dist.r <- list(dist_mat.r, dist_mat.r, dist_mat.r) # disturbance impacts on survival for each source on the reef

#dist_mat.o <- matrix(0.4, nrow = length(dist_yrs3), ncol = 5)
dist_mat.o <- matrix(1, nrow = length(dist_yrs3), ncol = 5)
dist.o <- list(dist_mat.o, dist_mat.o) # disturbance impacts on survival for each source on the orchard

dist_pars_list3 <- list(dist.r = dist.r, dist.o = dist.o)


# repeat for disturbance every 5 years
dist_yrs5 <- c(1:max(years))[c(F, T, F, F, F)] # years when disturbance occurs: once every 5 years but with first disturbance in year 3

# list where elements are for each group, each element is matrix where rows are time points with disturbances and columns are size classes

dist_mat.r <- matrix(0.2, nrow = length(dist_yrs5), ncol = 5)
dist.r <- list(dist_mat.r, dist_mat.r, dist_mat.r) # disturbance impacts on survival for each source on the reef

dist_mat.o <- matrix(1, nrow = length(dist_yrs5), ncol = 5)
dist.o <- list(dist_mat.o, dist_mat.o) # disturbance impacts on survival for each source on the orchard

dist_pars_list5 <- list(dist.r = dist.r, dist.o = dist.o)


# repeat for disturbance every 7 years
dist_yrs7 <- c(1:max(years))[c(F, T,F, F, F, F, F)] # years when disturbance occurs: once every 7 years, with first disturbance in year 3

# list where elements are for each group, each element is matrix where rows are time points with disturbances and columns are size classes

dist_mat.r <- matrix(0.2, nrow = length(dist_yrs7), ncol = 5)
dist.r <- list(dist_mat.r, dist_mat.r, dist_mat.r) # disturbance impacts on survival for each source on the reef

dist_mat.o <- matrix(1, nrow = length(dist_yrs7), ncol = 5)
dist.o <- list(dist_mat.o, dist_mat.o) # disturbance impacts on survival for each source on the orchard

dist_pars_list7 <- list(dist.r = dist.r, dist.o = dist.o)


