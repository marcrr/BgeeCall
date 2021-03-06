#' @title UserMetadata S4 class
#' 
#' @description An S4 class containing all metadata that have to be provided by the user It is mandatory to edit `species_id`, `rnaseq_lib_path`, `transcriptome_path`, `annotation_name`, `annotation_object` and potentialy `run_ids` before using the package.
#'
#' @slot species_id The NCBI Taxon Id of the species
#' @slot run_ids A vector of charater. Has to be provided only if a subset of runs present in UserMetadata@rnaseq_lib_path has to be run. If empty, all fastq files present in the rnaseq_lib_path will be considered as technical replicates and merged to run one transcript expression estimation analyse.
#' @slot reads_size The size of the reads. If smaller than 50nt, an index with a kmer size of 15nt will be used.
#' @slot rnaseq_lib_path Path to the directory of the RNA-Seq library that contains fastq files. 
#' @slot transcriptome_name Name of the transcriptome used to generate arborescence of output repositories.
#' @slot transcriptome_object Object containing transcriptome 
#' @slot annotation_name Name of the annotation used to generate arborescence of output repositories. 
#' @slot annotation_object Object containing annotations from GTF or GFF file
#' @slot working_path Working directory. By default the working directory is defined with the `getwd()` function.
#' @slot simple_arborescence logical allowing to create a simple arborescence of directory. All library ids are on the same directory. Default value is `FALSE`. Do not use `TRUE` if you plan to generate expression calls for the same library using different transcriptomes or gene annotations, otherwise you will overwrite previous results

UserMetadata <- setClass(
  # Set the name for the class
  Class = "UserMetadata",
  
  # Define the slots
  representation = representation(
    species_id = "character",
    run_ids = "character",
    reads_size = "numeric",
    rnaseq_lib_path = "character",
    transcriptome_name = "character",
    transcriptome_object = "DNAStringSet",
    annotation_name = "character",
    annotation_object = "GRanges",
    working_path = "character",
    simple_arborescence = "logical"
  ),
  
  # Set the default values for the slots.
  prototype = prototype(
    working_path = getwd(),
    reads_size = 51,
    simple_arborescence = FALSE
  )
)

#' 
#' @title Set annotation_object of one UserMetadata object
#' 
#' @description Method of the class UserMetadata. Set annotation_object of one UserMetadata object 
#' by using one GRanges object as input.
#' 
#' @details GRanges object is used as input. The class GRanges comes from the rtacklayer package 
#' 
#' @param userObject UserMetadata object
#' @param annotationObject Object of the GRanges S4 class
#' @param annotationName Name of the annotation. Will be used to create annotation folders.
#' 
#' @return an object of UserMetadata
#' 
#' @exportMethod setAnnotationFromObject
#' 
setGeneric("setAnnotationFromObject", function(userObject, annotationObject, annotationName) {
  standardGeneric("setAnnotationFromObject")
})


setMethod(f="setAnnotationFromObject", 
          signature=c(userObject = "UserMetadata", annotationObject = "GRanges", annotationName = "character"),
          definition=function(userObject, annotationObject, annotationName) {
            if(typeof(annotationObject) == "S4") {
              userObject@annotation_object <- annotationObject
              userObject@annotation_name <- annotationName
            } else {
              stop("Please provide an object imported using rtracklayer::import()")
            }
            return(userObject)
})

#' 
#' @title Set transcriptome_object of one UserMetadata object
#' 
#' @description Method of the class UserMetadata. Set transcriptome_object of one UserMetadata object 
#' by using one DNAStringSet object as input.
#' 
#' @details Please use a DNAStringSet object as input. This class is defined in the Biostrings package
#' 
#' @param userObject UserMetadata object
#' @param transcriptomeObject Object of the DNAStringSet S4 class
#' @param transcriptomeName Name of the transcriptome. Will be used to create transcriptome folders.
#' 
#' @return an object of UserMetadata
#' 
#' @exportMethod setTranscriptomeFromObject
#' 
setGeneric("setTranscriptomeFromObject", function(userObject, transcriptomeObject, transcriptomeName) {
  standardGeneric("setTranscriptomeFromObject")
})

setMethod(f="setTranscriptomeFromObject", 
          signature=c(userObject = "UserMetadata", transcriptomeObject = "DNAStringSet", transcriptomeName = "character"),
          definition=function(userObject, transcriptomeObject, transcriptomeName) {
            if(typeof(transcriptomeObject) == "S4") {
              userObject@transcriptome_object <- transcriptomeObject
              userObject@transcriptome_name <- transcriptomeName
            } else {
              stop("Please provide an object imported using rtracklayer::import()")
            }
            return(userObject)
})


#' 
#' @title Set annotation_object of one UserMetadata object
#' 
#' @description Method of the class UserMetadata. Set annotation_object of one UserMetadata object 
#' by providing the path to a gtf file.
#' 
#' @param userObject The UserMetadata object
#' @param annotationPath Absolute path to the annotation file
#' @param annotationName (optional) Name of the annotation. Will be used to create folders. 
#' 
#' @details If no annotationName is provided the name of the file is used to create folders.
#' 
#' @return An object of the class UserMetadata
#' 
#' @exportMethod setAnnotationFromFile
#'
setGeneric(name="setAnnotationFromFile", def=function(userObject, annotationPath) {
  standardGeneric("setAnnotationFromFile")
})
setGeneric(name="setAnnotationFromFile", def=function(userObject, annotationPath, annotationName) {
  standardGeneric("setAnnotationFromFile")
})


setMethod(f="setAnnotationFromFile", 
          signature=c(userObject = "UserMetadata", annotationPath = "character"),
          definition=function(userObject, annotationPath) {
            userObject <- setAnnotationFromFile(userObject, annotationPath, "")
            return(userObject)
          })

setMethod(f="setAnnotationFromFile", 
          signature=c(userObject = "UserMetadata", annotationPath = "character", annotationName = "character"),
          definition=function(userObject, annotationPath, annotationName = "") {
            if(typeof(annotationPath) == "character") {
              if(file.exists(annotationPath)) {
                userObject@annotation_object <- rtracklayer::import(annotationPath)
              } else {
                stop(paste0("file ", annotationPath, " does not exist. Should be the full path to your annotation file"))
              }
            }
            if (annotationName == "") {
              userObject@annotation_name <- basename(annotationPath)
            } else {
              userObject@annotation_name <- annotationName
            }
            return(userObject)
})


#' 
#' @title Set transcriptome_object of one UserMetadata object
#' 
#' @description Method of the class UserMetadata. Set transcriptome_object of one UserMetadata object 
#' by providing the path to a fasta transcriptome file.
#' 
#' @param userObject The UserMetadata object
#' @param annotationPath Absolute path to the transcriptome file
#' @param annotationName (optional) Name of the trancriptome Will be used to create folders. 
#' 
#' @details If no annotationNAme is provided the name of the annotation file will be used to create folders. 
#' 
#' @return An object of the class UserMetadata
#' 
#' @exportMethod setTranscriptomeFromFile
#'
setGeneric(name="setTranscriptomeFromFile", def=function(userObject, transcriptomePath) {
  standardGeneric("setTranscriptomeFromFile")
})
setGeneric(name="setTranscriptomeFromFile", def=function(userObject, transcriptomePath, transcriptomeName) {
  standardGeneric("setTranscriptomeFromFile")
})

setMethod(f="setTranscriptomeFromFile", 
          signature=c(userObject = "UserMetadata", transcriptomePath = "character"), 
          definition=function(userObject, transcriptomePath) {
            userObject <- setTranscriptomeFromFile(userObject, transcriptomePath, "")
            return(userObject)
})

setMethod(f="setTranscriptomeFromFile", 
          signature=c(userObject = "UserMetadata", transcriptomePath = "character", transcriptomeName = "character"), 
          definition=function(userObject, transcriptomePath, transcriptomeName = "") {
            if(typeof(transcriptomePath) == "character") {
              if(file.exists(transcriptomePath)) {
                userObject@transcriptome_object <- readDNAStringSet(transcriptomePath)
              } else {
                stop(paste0("file ", transcriptomePath, " does not exist. Should be the full path to your transcriptome file"))
              }
            }
            if (length(transcriptomeName) == 0) {
              userObject@transcriptome_name <- basename(transcriptomePath)
            } else {
              userObject@transcriptome_name <- transcriptomeName
            }
            return(userObject)
})