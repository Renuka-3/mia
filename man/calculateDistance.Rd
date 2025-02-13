% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/calculateDistance.R
\name{calculateDistance}
\alias{calculateDistance}
\alias{calculateDistance,ANY-method}
\alias{calculateDistance,SummarizedExperiment-method}
\title{Calculate sample distances with \code{vegan}}
\usage{
calculateDistance(x, FUN = stats::dist, ...)

\S4method{calculateDistance}{ANY}(x, FUN = stats::dist, ...)

\S4method{calculateDistance}{SummarizedExperiment}(
  x,
  FUN = stats::dist,
  abund_values = exprs_values,
  exprs_values = "counts",
  transposed = FALSE,
  ...
)
}
\arguments{
\item{x}{a
\code{\link[SummarizedExperiment:SummarizedExperiment-class]{SummarizedExperiment}}
object containing a tree.}

\item{FUN}{a \code{function} for distance calculation. The function must
expect the input matrix as its first argument. With rows as samples
and columns as features.}

\item{...}{other arguments passed onto \code{FUN}}

\item{abund_values}{a single \code{character} value for specifying which
assay to use for calculation.}

\item{exprs_values}{a single \code{character} value for specifying which
assay to use for calculation.
(Use \code{abund_values} instead. \code{exprs_values} will be disabled.)}

\item{transposed}{Logical scalar, is x transposed with cells in rows?}
}
\value{
a sample-by-sample distance matrix, suitable for NMDS, etc.
}
\description{
Will be removed by Bioc 3.15
}
\details{
\code{calculateDistance} calculates a distance matrix between samples. The
type of distance calculated can be modified by setting \code{FUN}, which
expects a function with a matrix input as its first argument.
}
\examples{
# generate some example data
mat <- matrix(1:60, nrow = 6)
df <- DataFrame(n = c(1:6))
tse <- TreeSummarizedExperiment(assays = list(counts = mat),
                                rowData = df)
\dontrun{
calculateDistance(tse)
}

}
