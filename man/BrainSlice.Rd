% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/BrainSlice.R
\name{BrainSlice}
\alias{BrainSlice}
\title{BrainSlice constructor}
\usage{
BrainSlice(data, space, indices = NULL)
}
\arguments{
\item{data}{data vector or matrix}

\item{space}{an instance of class BrainSpace}

\item{indices}{linear indices corresponding used if \code{data} is a 1D vector.}
}
\description{
BrainSlice constructor
}
\examples{
bspace <- BrainSpace(c(64,64), spacing=c(1,1))
dat <- array(rnorm(64*64), c(64,64))
bslice <- BrainSlice(dat,bspace)
print(bslice) 
}

