# these functions should be part of presenceAbsence.R
# they mainly correspond to duplicated code between the pipeline and this package. They do not need to be exported
# We decided to move them in a different file to easily update them when the pipeline is updated.
# XXX We should maybe centralise these functions somewhere outside of the package and the bgee pipeline

#' @title Calculate TPM cutoff
#'
#' @description This function calculate the TPM cutoff. This cutoff will correspond to the minimal value of TPM for which the ratio of genes and intergenic regions is equal to 0.05 or lower (first test if at least 1 TPM value has this property):

#'
#' @param counts TPM information for both genic and intergenic regions
#' @param selected_coding TPM information for both protein_coding regions
#' @param selected_intergenic TPM information for intergenic regions
#'
#' @return the TPM cutoff and the value of r (fixed proportion of intergenic regions considered as present)
#'
#' @author Julien Roux
#' @author Julien Wollbrett
#' 
#' @noMd
#' @noRd
#'
calculate_abundance_cutoff <- function(counts, selected_coding, selected_intergenic){
  ## r = (number of intergenic regions with TPM values higher than x * number of coding regions) /
  ##     (number of coding regions with TPM values higher than x * number of intergenic regions)
  ##   = 0.05
  ## What is value of x (cutoff)? calculate the distribution of r for a range of TPMs, then select the closest value to 0.05

  ## Counting how many intergenic regions have equal or higher value of TPM for every value of TPM
  ## For each gene's TPM (sorted), calculate r
  summed_intergenic <- sapply(unique(sort(counts$abundance[selected_coding])), function(x){
    return( sum(counts$abundance[selected_intergenic] >= x) )
  })
  ## It is not necessary to do the same for coding regions: for a sorted vector the number of greater elements is equal to lenght(vector) - position + 1. Here, it is a bit trickier since we do not consider all coding TPM values, but the unique ones, so we use the rle function to know the lengths of the runs of similar values and sum them
  summed_coding <- c(0, cumsum(rle(sort(counts$abundance[selected_coding]))$lengths))
  summed_coding <- summed_coding[-(length(summed_coding))]
  summed_coding <- sum(selected_coding) - summed_coding

  ## Now we can calculate r
  r <- ( summed_intergenic / sum(selected_intergenic) ) /
    ( summed_coding / sum(selected_coding) )
  ## This is twice faster as code above!

  ## Select the minimal value of TPM for which the ratio of genes and intergenic regions is equal to 0.05 or lower (first test if at least 1 TPM value has this property):
  if (sum(r < 0.05) == 0){
    abundance_cutoff <- sort(unique(counts$abundance[selected_coding]))[which(r == min(r))[1]]
    r_cutoff <- min(r)
    cat(paste0("There is no TPM cutoff for which 95% of the expressed genes would be coding. TPM cutoff is fixed at the first value with maximum coding/intergenic ratio. r=", r_cutoff, "at TPM=", abundance_cutoff,"\n"))
  } else {
    abundance_cutoff <- sort(unique(counts$abundance[selected_coding]))[which(r < 0.05)[1]]
    r_cutoff <- 0.05
    cat(paste0("TPM cutoff for which 95% of the expressed genes are coding found at TPM = ", abundance_cutoff,"\n"))
  }

  ## Plot TPMs vs. ratio: should mostly go down
  #plot(log2(sort(unique(counts$abundance[selected_coding]))+10e-6), r, pch=16, xlab="log2(TPM + 10^-6)", type="l")
  #abline(h=0.05, lty=2, col="gray")
  #if (r_cutoff > 0.05){
  #  abline(h=0.05, lty=3, col="gray")
  #}
  #arrows(log2(abundance_cutoff + 10e-6), par("usr")[3], log2(abundance_cutoff + 10e-6), par("usr")[4]/2, col="gray", lty=1, lwd=2, angle=160, length=0.1)
  return(c(abundance_cutoff, r_cutoff))
}

#' @title plot distribution of TPMs
#'
#' @description Plotting of the distribution of TPMs for coding and intergenic regions + cutoff
#'
#' @param counts TPM information for both genic and intergenic regions
#' @param selected_coding TPM information for protein_coding regions
#' @param selected_intergenic TPM information for intergenic regions
#' @param cutoff TPM cutoff below which calls are considered as absent
#' @param myUserMetadata A Reference Class UserMetadata object. This object has to be edited before running kallisto @seealso UserMetadata.R
#'
#' @author Julien Roux
#' @author Julien Wollbrett
#'
#' @noMd
#' @noRd
#'
plot_distributions <- function(counts, selected_coding, selected_intergenic, cutoff, myUserMetadata){
  ## Plotting of the distribution of TPMs for coding and intergenic regions + cutoff
  ## Note: this code is largely similar to plotting section in rna_seq_analysis.R

  par(mar=c(5,6,1,1)) ## bottom, left, top and right margins
  dens <- density(log2(na.omit(counts$abundance) + 10^-6))

  ## protein-coding genes only (had to take care of NAs strange behavior)
  dens_coding <- density(log2(counts$abundance[selected_coding] + 10^-6))
  ## Normalize density for number of observations
  dens_coding$y <- dens_coding$y * sum(selected_coding) / length(counts$abundance)

  ## intergenic
  dens_intergenic <- density(log2(counts$abundance[selected_intergenic] + 10^-6))
  dens_intergenic$y <- dens_intergenic$y * sum(selected_intergenic) / length(counts$abundance)

  ## Plot whole distribution
  title <- basename(myUserMetadata@rnaseq_lib_path)
  plot(dens, ylim=c(0, max(dens$y)*1.1), xlim=c(-23, 21), lwd=2, main=title, bty="n", axes=F, xlab="")
  axis(2, las=1)

  ## Plot the TPM cutoff
  ## abline(v=cutoff, col="gray", lty=1, lwd=2)
  arrows(log2(cutoff + 10e-6), par("usr")[3], log2(cutoff + 10e-6), par("usr")[4]/2, col="gray", lty=1, lwd=2, angle=160, length=0.1)

  ## Add subgroups distributions (coding, intergenic, etc):
  ## protein-coding genes
  lines(dens_coding, col="firebrick3", lwd=2, lty=2)
  ## intergenic
  lines(dens_intergenic, col="dodgerblue3", lwd=2, lty=2)

  ## legend
  legend("topright", c("all", "selected protein-coding genes", "selected intergenic regions"), lwd=2, col=c("black", "firebrick3", "dodgerblue3"), lty=c(1, 2, 2), bty="n")
  return();
}

# this function is not exactly the same than in the bgee pipeline.
# We removed the max_intergenic variable. In the pipeline this variable was used to define the the reference intergenic regions.
# We do not need it anymore in this package as we precomputed the list of intergenic regions
# we also remove TPM_final_cutoff, FPKM_cutoff, FPKM_final_cutoff

#' @title Cutoff information
#'
#' @description Calculate summary statistics to export in cutoff info file
#'
#' @param counts TPM information for both genic and intergenic regions
#' @param column Name of the column containing presence/absence information
#' @param abundance_cutoff TPM cutoff below which calls are considered as absent
#' @param r_cutoff Proportion of intergenic regions considered as present
#' @param myUserMetadata A Reference Class UserMetadata object. This object has to be edited before running kallisto @seealso UserMetadata.R
#'
#' @return summary statistics to export in cutoff info file
#'
#' @author Julien Roux
#' @author Julien Wollbrett
#' 
#' @noMd
#' @noRd
#'
cutoff_info <- function(counts, column, abundance_cutoff, r_cutoff, myUserMetadata){
  ## Calculate summary statistics to export in cutoff info file
  genic_present <- sum(counts[[column]][counts$type == "genic"] == "present")/sum(counts$type == "genic") * 100
  number_genic_present <- sum(counts[[column]][counts$type == "genic"] == "present")

  coding_present <- sum(counts[[column]][counts$biotype %in% "protein_coding"] == "present")/sum(counts$biotype %in% "protein_coding") * 100
  number_coding_present <- sum(counts[[column]][counts$biotype %in% "protein_coding"] == "present")

  intergenic_present <- sum(counts[[column]][counts$type == "intergenic"] == "present")/sum(counts$type == "intergenic") * 100
  number_intergenic_present <- sum(counts[[column]][counts$type == "intergenic"] == "present")

  ## Export cutoff_info_file
  to_export <- c(basename(myUserMetadata@rnaseq_lib_path),
                 abundance_cutoff,
                 genic_present, number_genic_present, sum(counts$type == "genic"),
                 coding_present,  number_coding_present, sum(counts$biotype %in% "protein_coding"),
                 intergenic_present, number_intergenic_present, sum(counts$type == "intergenic"),
                 r_cutoff
  )
  names(to_export) <- c("libraryId",
                        "cutoffTPM",
                        "proportionGenicPresent", "numberGenicPresent", "numberGenic",
                        "proportionCodingPresent", "numberPresentCoding", "numberCoding",
                        "proportionIntergenicPresent", "numberIntergenicPresent", "numberIntergenic",
                        "ratioIntergenicCodingPresent")
  return(to_export)
}

#' @title Recalculate TPMs
#'
#' @description Recalculate TPMs using functions from ```https://haroldpimentel.wordpress.com/2014/05/08/what-the-fpkm-a-review-rna-seq-expression-units/```
#'
#' @param counts A list of extimated counts
#' @param effLen A list of effective length
#'
#' @return A list of recalculated TPMs
#'
#' @noMd
#' @noRd
#' 
countToTpm <- function(counts, effLen){
  rate <- log(counts) - log(effLen)
  denom <- log(sum(exp(rate)))
  exp(rate - denom + log(1e6))
}
