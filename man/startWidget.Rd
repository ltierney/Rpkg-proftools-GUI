\name{startWidget}
\alias{startWidget}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Start Widget for proftools-GUI
}
\description{
Launches a GUI widget with interactive profiling tools for Rprof output, 
.R files, and R code.
}
\usage{
startGUI(pd = NULL, method = c("gwidgets", "shiny"),
         value = c("pct", "time", "hits"), self = FALSE, 
         gc = TRUE, memory = FALSE, srclines = TRUE)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{pd}{
 profile data as returned by \code{readProfileData}.
}
  \item{method}{
 character; use gwidgets view or shiny.
}
  \item{value}{
 character; show result as percentage, time, or hits.
}
  \item{self}{
 logical; include self cost or not.
}
  \item{gc}{
 logical; include GC information or not.
}
  \item{gc}{
 logical; include memory information or not.
}
  \item{srclines}{
 logical; include source information, if available, or not.
}

}
\details{
 All the arguments can be altered from within the UI, thus specifying them 
when calling the function is not necessary. Furthermore, the File menu in the 
gWidgets view can be 
used to select another stack file, to select and profile an R file, or to
 profile some R code.
 
 Source annotation will not be shown if the widget can't find the source files,
 thus it is crucial to make sure the working directory is inline with the source 
 file paths given in the stack file.
 
 Clicking a function will show source annotations if line information is 
 available. If not, an attempt will be made to show the function definition 
 from the source files. If that also can't be found, a final attempt will be made 
 to show annotation for the first callee for which annotation is available. 
 
}
\value{
No value is returned
}
\author{
Riad Jarjour
}
\note{
If the stack file contains the source filenames only, without their full paths, 
then the source files should be in the working directory, otherwise no source 
annotation will be shown because the widget can't find the source files.
}

\seealso{
\code{\link{Rprof}},
\code{\link{readProfileData}},
}
\examples{

\dontrun{

library(proftools)
library(gWidgets2)
library(gWidgets2RGtk2)
library(shiny)

## Read the profile data from the stack file 
pd <- readProfileData(system.file("samples", "Rprof-lmfit-mem.out", package = "proftools-GUI"))

## Start the GUI using shiny 
startGUI(pd, method = "shiny", value = "pct", gc=TRUE, self= FALSE, memory=TRUE)

## Start the GUI using gWidgets
startGUI(pd, method = "gwidgets", value = "pct", gc=TRUE, self= FALSE, memory=TRUE)

}
}
\keyword{profiling}
\keyword{programming}
\keyword{utilities}
