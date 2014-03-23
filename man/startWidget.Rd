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
startWidget(pd = NULL, value = c("pct", "time", "hits"), self = FALSE, 
            srclines = TRUE, gc = TRUE, maxdepth = 10, treeType = "funSum")
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{pd}{
 profile data as returned by \code{readProfileData}.
}
  \item{value}{
 character; show result as percentage, time, or hits.
}
  \item{self}{
 logical; include self cost or not.
}
  \item{srclines}{
 logical; include source information, if available, or not.
}
  \item{gc}{
 logical; include GC information or not.
}
  \item{maxdepth}{
 integer; In treeType = "hotPaths", stacks are truncated to have at most
 \code{maxdepth} elements.
}
  \item{treeType}{
 "funSum" gives function summary view listing all functions, while "hotPaths" 
gives the Hot Paths view.
}
}
\details{
 All the arguments can be altered from within the widget, thus specifying them 
when calling the function is not necessary. Furthermore, the File menu can be 
used to select another stack file, to select and profile an R file, or to
 profile some R code. Thus one can simply call startWidget(NULL) and proceed 
 from there.
 
 Source annotation will not be shown if the widget can't find the source files,
 thus it is crucial to make sure the working directory is inline with the source 
 file paths given in the stack file.
 
 Clicking a function will show source annotations if line information is 
 available. If not, an attempt will be made to show the function definition 
 from the source files. If that also can't be found, a final attempt will be made 
 to show annotation for the first callee for which annotation is available. 
 
Right clicking on a function in the tree gives the option to plot a call graph, 
tree map, or flame graph, all focused on that particular function.
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
\code{\link{annotateSource}},
\code{\link{hotPaths}},
\code{\link{funSummary}}
}
\examples{

\dontrun{

library(proftools)
library(gWidgets2)
library(gWidgets2RGtk2)


## Only launch the widget menu, proceed from there
startWidget(NULL)


## Source annotations for the below example are not shown since source files 
## are not in the working directory
pd <- readProfileData(system.file("samples", "Rprof-lmfit.out", 
                                  package="proftools"))
startWidget(pd)

## We can fix that by temporarily changing the working directory
## to the samples directory in the proftools package
oldDir <- getwd()
setwd(system.file("samples", package="proftools"))
pd <- readProfileData(system.file("samples", "Rprof-lmfit.out", 
                                  package="proftools"))
startWidget(pd)

## When done, change back the working directory
setwd(oldDir)


## A couple of other examples
pd <- readProfileData(system.file("samples", "Rprof-rec.out", 
                                  package="proftools"))
startWidget(pd)

pd <- readProfileData(system.file("samples", "Rprof-rec1.out", 
                                  package="proftools"))
startWidget(pd)
}
}
\keyword{profiling}
\keyword{programming}
\keyword{utilities}
