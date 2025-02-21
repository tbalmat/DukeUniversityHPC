# Duke University Computing Cluster
# For loops, lapply(), and mclapply()
# Example 1:  Implementation of for loop to be replaced by lapply()
# Note that for certain assignments, R recreates an entire object, instead of modifying elements referenced
# See http://adv-r.had.co.nz/memory.html
# The iterated appending of mod_results, edf_values, predictions, aic_values appears to recreate some or all of
# these aobjects instead of appending in place
# With a large number of sites, the time required to regenerate objects becomes a significant inefficiency

# Packages are loaded and data frames are prepared prior to the loop

t0 <- proc.time()

# Loop over each CpG site to fit the model
total_sites <- nrow(m_values_noSNP)  # Total number of CpG sites

# Initialize storage lists for results
mod_results <- vector("list", total_sites)
edf_values <- numeric(total_sites)
predictions <- vector("list", total_sites)
aic_values <- numeric(total_sites)

# Crossbasis penalty setup (done once)
cbgam1Pen <- cbPen(cbtemp)

# Loop over all CpG sites
for (i in 1:total_sites) {
  # Print progress every 1000 iterations or suitable interval
  if (i %% 1000 == 0) {
    cat("Completed", i, "of", total_sites, "iterations\n")
  }
 
  # Extract methylation data for the current CpG site
  methylation_data <- m_values_noSNP[i, ]
 
  # Fit the GAM with DLNM crossbasis term and penalty
  model <- gam(
    methylation_data ~ mom_age + cbtemp,
    family = gaussian(link = "identity"),
    data = pheno,
    paraPen = list(cbtemp = cbgam1Pen),
    method = 'REML'
  )
 
  # Store model object
  mod_results[[i]] <- model
 
  # Extract EDF for crossbasis terms (assuming names like 'xv%')
  edf_sum <- sum(model$edf[grepl('xv', names(model$edf))], na.rm = TRUE)
  edf_values[i] <- edf_sum
 
  # Calculate AIC using ML for model comparison purposes
  aic_values[i] <- AIC(
    gam(
      methylation_data ~ mom_age + cbtemp,
      family = gaussian(link = "identity"),
      data = pheno,
      paraPen = list(cbtemp = cbgam1Pen),
      method = 'ML'
    )
  )
 
  # Conditional crosspred (only if EDF > 0)
  if (edf_sum > 0 && model$converged) {
    crpred <- crosspred(cbtemp, model, at = minRange:maxRange)
    predictions[[i]] <- crpred
  } else {
    predictions[[i]] <- NULL  # Store NULL if EDF is zero or non-converged
  }
}

# Combine outputs into a results object (optional, for easier management)
results <- list(
  models = mod_results,
  edf = edf_values,
  predictions = predictions,
  aic = aic_values
)

t0-proc.time()

