# Usefull functions potentially used everywhere in the package.
# These functions are only used inside of the package. They are not exported.

#' @title get Operating System
#'
#' @description Function used to detect the OS in which the package is run. Return "linux", "osx", or "windows", depending on the OS
#'
#' @noMd
#' @noRd
#'
get_os <- function(){
  sysinf <- Sys.info()
  if (!is.null(sysinf)){
    os <- sysinf['sysname']
    if (os == 'Darwine') {
      os <- "osx"
    } else {
      os <- .Platform$OS.type
      if (os == 'unix') {
        if (grepl("^darwin", R.version$os)) {
          os <- "osx"
        }
        if (grepl("linux-gnu", R.version$os)) {
          os <- "linux"
        }
      } else if (os != 'windows') {
        stop(paste0("Unrecognized Operating System : ", os, "!!\n"))
      }
    }
    return(tolower(os))
  }
  stop("Sys.info() function returned a null value")
}

#' @title Path to bgee release directory
#'
#' @description helper function to get the path to the bgee release directory
#'
get_bgee_release_path <- function(myBgeeMetadata, myUserMetadata) {
  return(file.path(myUserMetadata@working_path, paste0(myBgeeMetadata@bgee_prefix, myBgeeMetadata@bgee_release)))
}

#' @title Path to species directory
#'
#' @description helper function to get the path to the species directory
#'
#' @noMd
#' @noRd
#'
get_species_path <- function(myBgeeMetadata, myUserMetadata) {
  if(nchar(myUserMetadata@species_id) == 0) {
    stop("the object of the UserMetadata class must contains a species_id")
  }
  return(file.path(get_bgee_release_path(myBgeeMetadata, myUserMetadata), myUserMetadata@species_id))
}

#' @title Path to transcriptome directory
#'
#' @description helper function to get the path to one transcriptome with intergenic regions of one species
#'
#' @noMd
#' @noRd
#'
get_transcriptome_path <- function(myBgeeMetadata, myUserMetadata) {
  return(file.path(get_species_path(myBgeeMetadata, myUserMetadata), 
                   paste0("transcriptome_", gsub("\\.", "_", myUserMetadata@transcriptome_name))))
}

#' @title Path to annotation directory
#'
#' @description helper function to get the path to annotation directory of one species. This annotation directory will contain both gene2biotype and tx2gene files.
#'
#' @noMd
#' @noRd
#' 
get_annotation_path <- function(myBgeeMetadata, myUserMetadata) {
  return(file.path(get_species_path(myBgeeMetadata, myUserMetadata),
                   paste0("annotation_", gsub("\\.", "_", myUserMetadata@annotation_name))))
}

#' @title Path to abundance tool directory
#'
#' @description helper function to get the path to the abundance tool directory
#' 
#' @noMd
#' @noRd
#'
get_tool_path <- function(myAbundanceMetadata, myBgeeMetadata, myUserMetadata) {
  return(file.path(get_species_path(myBgeeMetadata, myUserMetadata), myAbundanceMetadata@tool_name))
}

#' @title Path to the index created directory
#'
#' @description helper function to get the path to transcriptome specific directory of one abundance tool.
#'
#' @noMd
#' @noRd
#'
get_tool_transcriptome_path <- function(myAbundanceMetadata, myBgeeMetadata, myUserMetadata) {
  return(file.path(get_tool_path(myAbundanceMetadata, myBgeeMetadata, myUserMetadata), 
                   paste0("transcriptome_", gsub("\\.", "_", myUserMetadata@transcriptome_name))))
}

#' @title Path to the output directory of one abundance tool
#'
#' @description helper function to get the path to the output directory of one abundance tool.
#'
#' @noMd
#' @noRd
#'
get_tool_output_path <- function(myAbundanceMetadata, myBgeeMetadata, myUserMetadata) {
  if(myUserMetadata@simple_arborescence == TRUE) {
    return(file.path(get_bgee_release_path(myBgeeMetadata, myUserMetadata), "all_results", get_output_dir(myUserMetadata)))
  }
  return(file.path(get_tool_transcriptome_path(myAbundanceMetadata, myBgeeMetadata, myUserMetadata), 
                   paste0("annotation_", gsub("\\.", "_", myUserMetadata@annotation_name)), get_output_dir(myUserMetadata)))
}

#' @title Download fasta intergenic
#'
#' @description Check if fasta intergenic file has already been downloaded. If not the file is downloaded.
#'
#' @noMd
#' @noRd
#'
download_fasta_intergenic <- function(myBgeeMetadata, myUserMetadata, bgee_intergenic_file) {
  bgee_intergenic_url <- gsub("SPECIES_ID", myUserMetadata@species_id, myBgeeMetadata@fasta_intergenic_url)
  success <- download.file(url = bgee_intergenic_url, destfile = bgee_intergenic_file)
  if (success != 0){
    stop("ERROR: Downloading Bgee intergenic regions from FTP was not successful.")
  }
}

#' @title Retireve name of fastq files
#'
#' @description Check the presence of fastq files in the fastq directory. 
#' * If no myUserMetadata@run_ids are provided it will find all distinct run ids. 
#'   These run will be considered as technical replicates and merged together. 
#'   With technical replicates it is not possible to have a combination of single-end AND paired-end run.
#'   Then if the first run is detected as paired-end (presence of 2 fastq files with names finishing with _1 and _2) all fastq files will be considered as paired-end fastq files.
#'   If a mix of single_end and paired_end run are detected the function will return an error
#' * If myUserMetadata@run_ids are provided they will be considered as technical replicates and run in the same transcript expression estimation analyse.
#'   For the same reason than described in previous section, it is not possible to combine single-end and paired-end runs.
#' 
#' @return A character containing the name of all fastq files
#'
#' @noMd
#' @noRd
#'
get_merged_fastq_file_names <- function(myUserMetadata) {
  fastq_files <- get_fastq_files(myUserMetadata)
  
  # filter list of fastq files if run_ids are provided
  if (length(myUserMetadata@run_ids) != 0) {
    fastq_files <- unique (grep(paste(myUserMetadata@run_ids,collapse="|"), fastq_files, value=TRUE))
  }
  fastq_files_names <- ""
  if (is_pair_end(fastq_files)) {
    first_files <- sort(grep("_1", fastq_files, value=TRUE))
    second_files <- sort(grep("_2", fastq_files, value=TRUE))
    if (length(first_files) != length(second_files)) {
      stop(paste0("Can not run a paired-end expression estimation if not same number of file finishing with _1 and _2... In library ", basename(myUserMetadata@rnaseq_lib_path)))
    }
    if (length(first_files) + length(second_files) != length(fastq_files)) {
      stop(paste0("Can not run a paired-end expression estimation if not all fastq file names end with _1 or _2... In library ", basename(myUserMetadata@rnaseq_lib_path)))
    }
    for (i in 1:length(first_files)) { 
      run_1 <- sub("^([^_]+).*", "\\1", first_files[i], perl=TRUE)
      run_2 <- sub("^([^_]+).*", "\\1", second_files[i], perl=TRUE)
      cat(paste0(run_1, " -> ", run_2, "\n"))
      if (run_1 == run_2) {
        # combine all fastq_files in a character like A_1 A_2 B_1 B_2 ...
        fastq_files_names = paste(fastq_files_names, file.path(myUserMetadata@rnaseq_lib_path,first_files[i]), file.path(myUserMetadata@rnaseq_lib_path,second_files[i]), sep = " ")
      }
    }
  } else {
    if (length(grep("_1", fastq_files, value=TRUE)) != 0 || length(grep("_1", fastq_files, value=TRUE)) != 0) {
      stop(paste0("Looks like a combination of single-end and paired-end (file name end with _1 or _2) fastq files for library ", basename(myUserMetadata@rnaseq_lib_path), ".\n"))
    }
    for (i in 1:length(fastq_files)) { 
      fastq_files_names = paste(fastq_files_names, file.path(myUserMetadata@rnaseq_lib_path,fastq_files[i]), sep = " ")
    }
  }
  return(fastq_files_names)
}

#' @title get fastq files
#' 
#' @description retrieve all fastq files names present in the myUserMetadata@rnaseq_lib_path directory
#'
#' @noMd
#' @noRd
#'  
get_fastq_files <- function(myUserMetadata) {
  
  # all files of the library directory
  library_files <- list.files(path = myUserMetadata@rnaseq_lib_path)
  fastq_files <- ""
  i <- 1
  for (library_file in library_files) {
    if (grepl(".fq$", library_file) || grepl(".fq.gz$", library_file) ||grepl(".fastq.gz$", library_file) || grepl(".fastq.gz$", library_file)) {
      fastq_files [i] <- library_file
      i <- i+1
    }
  }
  return(fastq_files)
}

#' @title is paired-end
#' 
#' @description check is the first element of a vector of fastq files names correspond to a paired-end file. Return a boolean
#' 
#' @noMd
#' @noRd
#' 
is_pair_end <- function(fastq_files) {
  return(grepl("_1.", fastq_files[1]) || grepl("_2.", fastq_files[1]))
}

#' @title Retrieve name of output directory
#'
#' @description Retireve name of output directory depending on myUserMetadata@rnaseq_lib_path and myUserMetadata@run_ids
#' if myUserMetadata@run_ids is empty then the output directory will correspond to name of the last directory of myUserMetadata@rnaseq_lib_path.
#' Otherwise the name of the output directory will be the concatenation of the name of the last directory of myUserMetadata@rnaseq_lib_path and all myUserMetadata@run_ids
#' 
#' @return Name of the output directory
#'
#' @noMd
#'
get_output_dir <- function(myUserMetadata) {
  if(length(myUserMetadata@rnaseq_lib_path) == 0) {
    stop("No fastq path provided. Please edit `rnaseq_lib_path` attribute of UserMetadata class")
  }
  if (length(myUserMetadata@run_ids) == 0) {
    return(basename(myUserMetadata@rnaseq_lib_path))
  } else {
    return(paste0(basename(myUserMetadata@rnaseq_lib_path),"_",paste(myUserMetadata@run_ids, collapse = "_") ))
  }
}

#' @title Remove transcript version from abundance file
#'
#' @description Remove the transcript version that can be present in transcript id of transcriptome files.
#' Removing the transcript version means detecting a dot in transcript id and removing the dot and all caracters following it.
#' This method has been develop because in some case the ignoreTxVersion attribut of the tximport package with kallisto was not working.
#' this method is called if the logical "ignoreTxVersion" attribut of the AbundanceMetadata class is set to TRUE.
#'
#' @noMd
#' @noRd
#'  
removeTxVersionFromAbundance <- function (myAbundanceMetadata, myBgeeMetadata,  myUserMetadata) {
  output_path <- get_tool_output_path(myAbundanceMetadata, myBgeeMetadata, myUserMetadata)
  abundance_path <- file.path(output_path, myAbundanceMetadata@abundance_file)
  abundance_data <- read.table(file = abundance_path, header = TRUE, sep = "\t")
  if(myAbundanceMetadata@tool_name == "kallisto") {
    abundance_data$target_id <- gsub(pattern = "\\..*", "", abundance_data$target_id )
  } else{
    stop(paste0("Removing transcript version for tool ", myAbundanceMetadata$tool_name, " is not implemented."))
  }
  write.table(x = abundance_data, file = abundance_path, sep = "\t", row.names = F, col.names = T, quote = F)
}

