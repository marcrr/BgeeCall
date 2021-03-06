% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/UserMetadata.R
\name{setAnnotationFromFile}
\alias{setAnnotationFromFile}
\title{Set annotation_object of one UserMetadata object}
\usage{
setAnnotationFromFile(userObject, annotationPath, annotationName)
}
\arguments{
\item{userObject}{The UserMetadata object}

\item{annotationPath}{Absolute path to the annotation file}

\item{annotationName}{(optional) Name of the annotation. Will be used to create folders.}
}
\value{
An object of the class UserMetadata
}
\description{
Method of the class UserMetadata. Set annotation_object of one UserMetadata object 
by providing the path to a gtf file.
}
\details{
If no annotationName is provided the name of the file is used to create folders.
}
