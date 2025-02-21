# Duke University Computing Cluster
# For loops, lapply(), and mclapply()
# Example 2:  Replace for loop with lapply()
# In this version, for() is replaced with lapply()
# lapply() generates a list containing results for each site
# Individual lists are then appended into a list of lists where element i corresponds to site i
# Note that lapply() keeps track of individual site lists and no recreation of objects is done

# Packages are loaded and data frames are prepared prior to the loop

t0 <- proc.time()

total_sites <- nrow(m_values_noSNP)  # Total number of CpG sites

# Crossbasis penalty setup (done once)
cbgam1Pen <- cbPen(cbtemp)

results <- lapply(1:total_sites,

  function(i) {

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

t0-proc.time()

