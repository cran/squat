% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/qts-sample-class.R
\name{mean.qts_sample}
\alias{mean.qts_sample}
\title{QTS Geometric Mean}
\usage{
\method{mean}{qts_sample}(x, ...)
}
\arguments{
\item{x}{An object of class \code{\link{qts_sample}}.}

\item{...}{Further arguments passed to or from other methods.}
}
\value{
An object of class \code{\link{qts}} in which quaternions are the
pointwise geometric mean of the input QTS sample.
}
\description{
This function computes the pointwise geometric mean of a QTS sample.
}
\examples{
mean(vespa64$igp)
}
