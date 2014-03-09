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
%%  ~~ If necessary, more details than the description above ~~
}
\value{
No value is returned
}
\author{
Riad Jarjour
}
\note{
If the stacks file contains the source filenames without their full paths, 
then the source files should be in the working directory.
}

\seealso{
\code{\link{Rprof}},
\code{\link{readProfileData}},
\code{\link{annotateSource}},
\code{\link{hotPaths}},
\code{\link{funSummary}}
}
\examples{
library(gWidgets2)
library(gWidgets2RGtk2)

## Only launch the widget menu
startWidget(NULL)

## Source annotations for below examples are not shown since source files 
## are not in the working directory
pd <- readProfileData(system.file("samples", "Rprof-lmfit-new.out", 
                                  package="proftools"))
startWidget(pd)


pd <- readProfileData(system.file("samples", "Rprof-rec.out", 
                                  package="proftools"))
startWidget(pd)

pd <- readProfileData(system.file("samples", "Rprof-rec1.out", 
                                  package="proftools"))
startWidget(pd)
}
\keyword{profiling}
\keyword{programming}
\keyword{utilities}
