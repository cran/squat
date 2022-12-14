% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/qts-transformations.R
\name{qts2nts}
\alias{qts2nts}
\title{QTS Transformation To Norm Time Series}
\usage{
qts2nts(x, disable_normalization = FALSE)
}
\arguments{
\item{x}{An object of class \link{qts}.}

\item{disable_normalization}{A boolean specifying whether quaternion
normalization should be disabled. Defaults to \code{FALSE}.}
}
\value{
A time series stored as a \link[tibble:tibble]{tibble::tibble} with columns \code{time} and
\code{norm} in which \code{norm} measures the angular distance between the current
quaternion and the identity.
}
\description{
This function computes a univariate time series representing the norm of the
quaternions.
}
\examples{
qts2nts(vespa64$igp[[1]])
}
