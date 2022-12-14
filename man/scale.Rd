% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/qts-sample-class.R
\name{scale}
\alias{scale}
\alias{scale.default}
\alias{scale.qts_sample}
\title{QTS Sample Centering and Standardization}
\usage{
scale(x, center = TRUE, scale = TRUE, ...)

\method{scale}{default}(x, center = TRUE, scale = TRUE, ...)

\method{scale}{qts_sample}(
  x,
  center = TRUE,
  scale = TRUE,
  by_row = FALSE,
  keep_summary_stats = FALSE,
  ...
)
}
\arguments{
\item{x}{An object coercible into a numeric matrix or an object of class
\code{\link{qts_sample}} representing a sample of observed QTS.}

\item{center}{A boolean specifying whether to center the sample. If set to
\code{FALSE}, the original sample is returned, meaning that no standardization
is performed regardless of whether argument \code{scale} was set to \code{TRUE} or
not. Defaults to \code{TRUE}.}

\item{scale}{A boolean specifying whether to standardize the sample once it
has been centered. Defaults to \code{TRUE}.}

\item{...}{Extra arguments passed on to next methods.}

\item{by_row}{A boolean specifying whether the QTS scaling should happen for
each data point (\code{by_row = TRUE}) or for each time point (\code{by_row = FALSE}). Defaults to \code{FALSE}.}

\item{keep_summary_stats}{A boolean specifying whether the mean and standard
deviation used for standardizing the data should be stored in the output
object. Defaults to \code{FALSE} in which case only the list of properly
rescaled QTS is returned.}
}
\value{
A list of properly rescaled QTS stored as an object of class
\code{\link{qts_sample}} when \code{keep_summary_stats = FALSE}. Otherwise a list with
three components:
\itemize{
\item \code{rescaled_sample}: a list of properly rescaled QTS stored as an object of
class \code{\link{qts_sample}};
\item \code{mean}: a list of numeric vectors storing the corresponding quaternion
Fréchet means;
\item \code{sd}: a numeric vector storing the corresponding quaternion Fréchet
standard deviations.
}
}
\description{
QTS Sample Centering and Standardization
}
\examples{
x <- scale(vespa64$igp)
x[[1]]
}
