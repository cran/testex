% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fn.R
\name{fn_roxygen}
\alias{fn_roxygen}
\title{Test Function}
\usage{
fn_roxygen(x)
}
\arguments{
\item{x}{A thing}
}
\value{
The pasted thing
}
\description{
This example introduces the \verb{@test} tag, either a value or an expression
using the \code{.}-syntax to test the last example result.
}
\examples{
\dontshow{
  value <- "testing"
}

fn_roxygen(value)
\testonly{
testex::testex(srcref = "fn.R:47:47", 
identical(., "testing 1 2 3"))}
\dontrun{
  stop("this won't work")
}

fn_roxygen("testing")
\testonly{
testex::testex(srcref = "fn.R:54:54", 
grepl("\\\\d", .))}
\testonly{
testex::testex(srcref = "fn.R:55:55", 
startsWith(., "testing"))}
fn_roxygen("testing")
\testonly{
testex::testex(srcref = "fn.R:58:60", 
identical(., {
  "testing 1 2 3"
}))}

fn_roxygen("testing")
# untested trailing example
}
