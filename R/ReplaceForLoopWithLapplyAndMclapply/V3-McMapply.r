# Duke University Computing Cluster
# For loops, lapply(), and mclapply()
# Example 3:  Implement lapply() in parallel using mclapply()
# In this version, mclapply() replaces lapply()
# The results of mclapply() are identical to those of lapply() corresponds to site i
# The environment variable SLURM_CPUS_PER_TASK reports the number of cores available
# This is the maximum number of simultaneous tasks that can be executed and is specified using the
# CPUs (Threads) field of the DCC Open OnDemand configuration page or the cpus-per-task Slurm command
# switch in a DCC command line session
# Note that on Linux (as with the DCC), parallel processes are forked and share common memory

# Packages are loaded and data frames are prepared prior to the loop

library(parallel)

total_sites <- nrow(m_values_noSNP)  # Total number of CpG sites

# Crossbasis penalty setup (done once)
cbgam1Pen <- cbPen(cbtemp)

# Define the function to be executed in parallel
# i indicates site
f <- function(i) {

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
   
    # Extract EDF for crossbasis terms (assuming names like 'xv%')
    edf_sum <- sum(model$edf[grepl('xv', names(model$edf))], na.rm = TRUE)
   
    # Calculate AIC using ML for model comparison purposes
    aic_value <- AIC(
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
      prediction <- crpred
    } else {
      prediction <- NULL  # Store NULL if EDF is zero or non-converged
    }

    # Return results for current site
    list(
      model = model,
      edf = edf_sum,
      prediction = prediction,
      aic = aic_value
    )

  })

# Fit models in parallel
t0 <- proc.time()
results <- mclapply(1:total_sites, mc.cores=Sys.getenv("SLURM_CPUS_PER_TASK"), FUN=f)
t0-proc.time()

