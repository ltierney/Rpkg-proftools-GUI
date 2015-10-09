
offspring <- function(path, self.gc) {
    DF <- offspringData
    if(length(path) > 0){
        pathLength <- length(path)
        path <- paste(path, collapse=" -> ")
        offspringDF <- DF[path == sapply(strsplit(DF$path, " -> "), 
                                       function(x){ if(length(x) > pathLength)
                                                        x <- x[1:pathLength]
                                                    paste(x, collapse=" -> ")}),]
        sonsDepth <- offspringDF$depth[1]+1
        sons <- which(offspringDF$depth==sonsDepth)
        if(sons[length(sons)] == nrow(offspringDF))
            nextDepths <- c(offspringDF$depth[sons[-length(sons)]+1], 0)
        else nextDepths <- offspringDF$depth[sons+1]
        haveSons <- (nextDepths > offspringDF$depth[sons])
        offspringDF <- data.frame(Function=offspringDF$name[sons], 
                                  haveSons=haveSons, 
                                  total=offspringDF$total[sons], 
                                  self=offspringDF$self[sons],
                                  GC=offspringDF$GC[sons],
                                  GC.Self=offspringDF$GC.Self[sons], 
                                  stringsAsFactors=FALSE)
    }    
    else{ 
        foundingFathers <- which(DF$depth==1)
        if(foundingFathers[length(foundingFathers)] == nrow(DF))
            nextDepths <- c(DF$depth[foundingFathers[-length(foundingFathers)]+1]
                            , 0)
        else nextDepths <- DF$depth[foundingFathers+1]
        haveSons <- (nextDepths > DF$depth[foundingFathers])
        offspringDF <- data.frame(Function=DF$name[foundingFathers], 
                                  haveSons=haveSons, 
                                  total=DF$total[foundingFathers], 
                                  self=DF$self[foundingFathers],
                                  GC=DF$GC[foundingFathers],
                                  GC.Self=DF$GC.Self[foundingFathers], 
                                  stringsAsFactors=FALSE)
    }
    if(!self.gc[1]) {
        offspringDF$self = NULL
        offspringDF$GC.Self = NULL
    }
    if(!self.gc[2]) {
        offspringDF$GC = NULL
        offspringDF$GC.Self = NULL
    }
    return(offspringDF)
}

setOffspringDF <- function(pd, value = c("pct", "time", "hits"),
                           self = FALSE, srclines = TRUE, gc = TRUE,
                           maxdepth = 10){
    pathData <- hotPaths(pd, value, self, srclines, gc, maxdepth, short = "-> ")
    x <- strsplit(pathData$path, "-> ")
    ## Plugs function names into paths and gets depth of each line
    y <- sapply(1:length(x), 
                function(i) {
                    x[[i]][length(x[[i]])] <<- sub("^(.+?) *$", "\\1", 
                                                   x[[i]][length(x[[i]])])
                    if(length(x[[i]])>1)
                        x[[i]][1:length(x[[i]])-1] <<- x[[i-1]][1:length(x[[i]])-1]
                    c(paste(x[[i]], collapse=" -> "), x[[i]][length(x[[i]])], 
                      length(x[[i]]))
                }
          )
    pathData <- fixSumDF(pathData, self, gc, value)
    ## Reason for global assignment is tcltk toolkit has problems passing the 
    ## dataframe to get children of foundingFathers
    offspringData <<- data.frame(path=as.character(y[1,]), 
                                 name=as.character(y[2,]), depth=as.numeric(y[3,]), 
                                 total=pathData$total, self=pathData$self,
                                 GC=pathData$gc, GC.Self=pathData$gcself,
                                 stringsAsFactors = F)
}

fixSumDF <- function(DF, self, gc, value){
    names(DF) <- sub(paste(".", value[1], sep=""), "", names(DF), fixed=T)
    if(!gc){
        DF$gc <- rep("", nrow(DF))
        DF$gcself <- rep("", nrow(DF))
    }
    if(!self){
        DF$self <- rep("", nrow(DF))
        DF$gcself <- rep("", nrow(DF))
    }
    DF
}

offspringFunSum <- function(path, self.gc) {
    if(length(path) > 0){
        fcnName <- path[length(path)]
        fcn <- paste(" ", fcnName, " ->", sep="")
        calledFcns <- grep(fcn, row.names(callSum), fixed=TRUE)
        calledFcns <- callSum[calledFcns,]
        splitFcns <- unlist(strsplit(row.names(calledFcns), "-> ", fixed=T))
        calledFcnsNames <- splitFcns[seq(2,length(splitFcns), by=2)]
        calledFcnsSrch <- paste(" ", calledFcnsNames, " ->", sep="")
        haveSons <- sapply(calledFcnsSrch, 
                           function(x) { any(grepl(x, row.names(callSum),
                                             fixed=TRUE)) })
        offspringDF <- data.frame(Function = calledFcnsNames, 
                                  haveSons = haveSons, 
                                  total=calledFcns$total, 
                                  self=calledFcns$self,
                                  GC=calledFcns$gc,
                                  GC.Self=calledFcns$gcself, 
                                  stringsAsFactors=FALSE)
    }    
    else{ 
        foundingFathers <- row.names(fcnSummary)
        foundingFathersSrch <- paste(" ", foundingFathers, " ->", sep="")
        haveSons <- sapply(foundingFathersSrch, 
                           function(x) { any(grepl(x, row.names(callSum),
                                             fixed=TRUE)) })       
        offspringDF <- data.frame(Function = foundingFathers, 
                                  haveSons = haveSons, 
                                  total=fcnSummary$total, 
                                  self=fcnSummary$self,
                                  GC=fcnSummary$gc,
                                  GC.Self=fcnSummary$gcself,
                                  stringsAsFactors=FALSE)
    }
    if(!self.gc[1]) {
        offspringDF$self = NULL
        offspringDF$GC.Self = NULL
    }
    if(!self.gc[2]) {
        offspringDF$GC = NULL
        offspringDF$GC.Self = NULL
    }
    return(offspringDF)
}

startWidget <- function(pd = NULL, value = c("pct", "time", "hits"),
                        self = FALSE, srclines = TRUE, gc = TRUE,
                        maxdepth = 10, interval = NULL,
                        treeType="funSum", toolkit="RGtk2"){
    if (is.character(pd))
        pd <- readProfileData(pd)
    options(guiToolkit = toolkit)
    win <- gwindow("Hot Path Tree", height=700, width=1000)
    ## Remove widgetMenu from previous session
    if(exists("widgetMenu")) 
        remove(widgetMenu, pos=.GlobalEnv)
    processWidget(pd, value, self, srclines, gc, maxdepth, interval, treeType,
                  win)
}

processWidget <- function(pd, value = c("pct", "time", "hits"),
                          self = FALSE, srclines = TRUE, gc = TRUE,
                          maxdepth = 10, interval, treeType="funSum", win){
    group <- ggroup(horizontal=FALSE,container=win)
    if(!is.null(pd)){
        buttonCont <- ggroup(container=group)
        passedList <- list(pd=pd, value=value, self=self, srclines=srclines, 
                           gc=gc, maxdepth=maxdepth, interval=interval,
                           treeType=treeType, win=win, group=group)
        glabel("Summary: ", container=buttonCont)
        SummaryView <- ifelse(treeType == "funSum", "Function", "Hot Paths")
        summaryCombo <- gcombobox(c(SummaryView, "Function", "Hot Paths"), 
                                  container=buttonCont, handler=summaryHandler, 
                                  action=passedList)
        size(summaryCombo) <- c(100, -1)
        glabel("Units: ", container=buttonCont)
        units <- gcombobox(c(value[1], "pct", "time", "hits"), container=buttonCont, 
                           handler=unitsHandler, action=passedList)
        size(units) <- c(50, -1)
        checkBoxes <- c("self", "gc"); checked=c(self,gc)
        if(!pd$haveGC){
            checkBoxes <- checkBoxes[-2]
            checked <- checked[-2]
            gc <- FALSE
        }
        checkBox <- gcheckboxgroup(checkBoxes, checked=checked, 
                                   container=buttonCont, horizontal=T,
                                   handler=checkHandler, action=passedList)
        addSpinners(pd, value, self, srclines, gc, maxdepth, interval, treeType, win, group)
        if(!is.null(interval))
            filteredPD <- filterProfileData(pd, interval = interval)
        else filteredPD <- pd
        attemptAnnot <- function(){
            tryCatch(srcAnnotate <- annotateSource(filteredPD, value, gc, show=FALSE), 
                     error = function(e) srcAnnotate <<- NULL,
                     warning = function(w){srcAnnotate <<- NULL})
            srcAnnotate
        }
        srcAnnotate <- attemptAnnot(); conf <- FALSE
        if(is.null(srcAnnotate))
            conf <- gconfirm(paste0('Could not find source files in the ',
                                    'working directory, press OK to locate the', 
                                    ' directory with source files, or Cancel',
                                    ' to continue without source annotations.'), 
                             title="Source files not found", icon="warning")
        if(conf){
            directory <- gfile(type="selectdir")
            setwd(directory)
            srcAnnotate <- attemptAnnot()
        }
        if(treeType=="funSum")
            funSumTree(filteredPD, value, self, srclines, gc, srcAnnotate, win,
                       group)
        else
            hotPathsTree(filteredPD, value, self, srclines, gc, maxdepth, 
                         srcAnnotate, win, group)
        update(win)
    }
    addMenu(pd, value, self, srclines, gc, maxdepth, interval, treeType, win, group)
    plot.new()
    plotProfileCallGraph(pd, style = google.style)
}

addSpinners <- function(pd, value = c("pct", "time", "hits"), self = FALSE, 
                      srclines = TRUE, gc = TRUE, maxdepth=10, interval, 
                      treeType, win, group){
    if(is.null(interval)) interval <- c(1, pd$total)
    spinnerCont <- gframe(text = "Filter Selection", container=group, 
                         horizontal = FALSE)
    sCont <- ggroup(container=spinnerCont)
    glabel("Start: ", container=sCont)
    s1Handler <- function(h, ...){
        if(svalue(s1) > svalue(s2))
            svalue(s1) <- svalue(s2)
        interval <<- c(svalue(s1), svalue(s2))
    }
    s2Handler <- function(h, ...){
        if(svalue(s2) < svalue(s1))
            svalue(s2) <- svalue(s1)
        interval <<- c(svalue(s1), svalue(s2))
    }
    filterHandler <- function(h, ...){
        delete(win, group)
        processWidget(pd, value, self, srclines, gc, maxdepth, 
                      interval, treeType, win)
    }    
    s1 <- gspinbutton(from=1, to=pd$total, by=1, value=interval[1], 
                  handler = s1Handler, cont=sCont)
    glabel("Stop: ", container=sCont)
    s2 <- gspinbutton(from=1, to=pd$total, by=1, value=interval[2], 
                  handler = s2Handler, cont=sCont) 
    filterButton <- gbutton("Filter Selection", handler = filterHandler, 
                            cont=sCont)
}
addMenu <- function(pd, value = c("pct", "time", "hits"), self = FALSE, 
                    srclines = TRUE, gc = TRUE, maxdepth=10, interval, treeType, 
                    win, group){
    browseStack <- function(h, ...){
        stackBrowse <- gfile("Choose a Stack file", quote=FALSE, filter = 
                             list("Stack files"=list(patterns=c("*.out", "*.txt"))))
        pd <- readProfileData(stackBrowse)
        stopIfEmpty(pd, group)
        delete(win, group)
        processWidget(pd, value, self, srclines, gc, maxdepth, interval, 
                      treeType, win)
    }
    
    browseR <- function(h, ...){
        sourceBrowse <- gfile("Source and profile an R file", quote=FALSE,
                              filter = list("Stack files"=
                                            list(patterns=c("*.R", "*.txt"))))
        Rprof(tmp <- tempfile(), gc.profiling = TRUE, line.profiling = TRUE)
        source(sourceBrowse)
        Rprof(NULL)
        pd <- readProfileData(tmp)
        stopIfEmpty(pd, group)
        delete(win, group)
        processWidget(filterProfileData(pd,"source",focus=T), value, self,
                      srclines, gc, maxdepth, interval, treeType, win)
        unlink(tmp)
    }    
    profileRCode <- function(h, ...){
        profileCode(pd, value, self, srclines, gc, maxdepth, NULL, treeType, win, group)
    }    
    mn <- list(); mn$File <- list();
    mn$File[['Select a stack file']] <- gaction("Select a stack file", 
                                                handler=browseStack) 
    mn$File[['Source an R file']] <- gaction("Source an R file", handler=browseR)   
    mn$File[['Profile some R code']] <- gaction("Profile some R code", 
                                                handler=profileRCode) 
    if(!is.null(interval))
        filteredPD <- filterProfileData(pd, interval = interval)
    else filteredPD <- pd
    mn$Plot <- list();
    plotType <<- 'plotCallgraph'
    mn$Plot[['Plot Callgraph']] <- gaction('Plot Callgraph', handler=function(h,...){
        plotProfileCallGraph(filteredPD, style = google.style)
        plotType <<- 'plotCallgraph'
    })
    mn$Plot[['Plot Tree Map']] <- gaction('Plot Tree Map', handler=function(h,...){
        calleeTreeMap(filteredPD)
        plotType <<- 'plotTreemap'
    })
    mn$Plot[['Plot Flame Graph']] <- gaction('Plot Flame Graph', handler=function(h,...){
        flameGraph(filteredPD, order="hot")
        plotType <<- 'plotFlamegraph'
    })
    mn$Plot[['Plot Time Graph']] <- gaction('Plot Time Graph', handler=function(h,...){
        flameGraph(filteredPD, order="time")
        plotType <<- 'plotTimegraph'
    }) 
    if(exists("widgetMenu"))
        svalue(widgetMenu) <<- mn
    else
        widgetMenu <<- gmenu(mn, container=win)
}
profileCode <- function(pd, value = c("pct", "time", "hits"), self = FALSE, 
                        srclines = TRUE, gc = TRUE, maxdepth=10, interval,
                        treeType, win, group){
    codeWindow <- gwindow("Profile R code", width=500, height=500)
    codeGroup <- ggroup(horizontal=FALSE,container=codeWindow)
    profileText <- gtext("## Enter some R code here to profile", 
                         container=codeGroup, wrap=FALSE, 
                         font.attr=list(family="monospace"), expand=TRUE, 
                         fill="both")
    btn <- gbutton("Profile It", container=codeGroup)
    addHandlerChanged(btn, handler = function(h, ...) {
        tmp1 <- paste(tempfile(), ".R", sep="")
        write(svalue(profileText), file=tmp1)
        Rprof(tmp <- tempfile(), gc.profiling = TRUE, line.profiling = TRUE)
        source(tmp1)
        Rprof(NULL)
        pd <- readProfileData(tmp)
        stopIfEmpty(pd, group)
        mydepth <- length(sys.calls())
        pd <- skipPD(pd, mydepth+4)
        delete(win, group)
        dispose(codeWindow)
        processWidget(pd, value, self, srclines, gc, maxdepth, NULL, treeType,
                      win)
    })
}
# Give an error message if stack file is empty
stopIfEmpty <- function(pd, group){
    if(pd$total == 0){
        gmessage('Your code produced a stack file of zero lines', title = "Error", 
                 icon = "error", parent=group)
        stop('Your code produced a stack file of zero lines')         
    }
}

funSumTree <- function(pd, value = c("pct", "time", "hits"), self = FALSE, 
                       srclines = TRUE, gc = TRUE, srcAnnotate, win, group){
    treeType <- "funSum"
    callSum <- callSummary(pd, byTotal = TRUE, value, srclines, gc)
    row.names(callSum) <- paste(" ", row.names(callSum), sep="")
    callSum <<- fixSumDF(callSum, self, gc, value)
    fcnSummary <- funSummary(pd, byTotal = TRUE, value, srclines, gc)
    fcnSummary <<- fixSumDF(fcnSummary, self, gc, value)
    gPane <- gpanedgroup(horizontal=FALSE, container=group, expand=TRUE)
    g <- gpanedgroup(container=gPane)
    treeCont <- gframe(text="Function Summary", container=g, expand=TRUE)
    gg <- ggraphics(container=g, expand=TRUE)
    svalue(g) <- .5
    fcnAnnotCont <- gframe(text="Function Annotations", container=gPane, 
                           expand=TRUE, fill="both")
    tree <<- gtree(offspring=offspringFunSum, offspring.data = c(self,gc),
                  container=treeCont, expand=TRUE, fill="both")
    fcnAnnot <- gtext("", container=fcnAnnotCont, wrap=FALSE,
                      font.attr=list(family="monospace"), expand=TRUE, 
                      fill="both")
    addHandlers(tree, fcnAnnot, treeType, srcAnnotate, pd)
}

hotPathsTree <- function(pd, value = c("pct", "time", "hits"), self = FALSE,
                         srclines = TRUE, gc = TRUE, maxdepth = 10, srcAnnotate,
                         win, group){
    treeType <- "hotPaths"
    setOffspringDF(pd, value, self, srclines, gc, maxdepth)
    gPane <- gpanedgroup(horizontal=FALSE, container=group, expand=TRUE)
    g <- gpanedgroup(container=gPane)
    treeCont <- gframe(text="Hot Paths", container=g, expand=TRUE, 
                       fill="both")
    gg <- ggraphics(container=g, expand=TRUE)
    svalue(g) <- .5
    fcnAnnotCont <- gframe(text="Function Annotations", container=gPane, 
                           expand=TRUE, fill="both")
    tree <- gtree(offspring = offspring, offspring.data = c(self,gc), 
                  container=treeCont, expand=TRUE, fill="both")
    fcnAnnot <- gtext("", container=fcnAnnotCont, wrap=FALSE,
                      font.attr=list(family="monospace"), expand=TRUE, 
                      fill="both")
    addHandlers(tree, fcnAnnot, treeType, srcAnnotate, pd)
}

parseOffspring <- function(path, treetype, id=NULL){
    if(treetype == 'hotpaths') 
        offspringDF <- offspring(path, c(TRUE,TRUE))
    else offspringDF <- offspringFunSum(path, c(TRUE,TRUE))
    paste(sapply(1:nrow(offspringDF), parseSon, offspringDF, path, id, treetype), 
          collapse=",")
}
## gets function name without line info
getFname <- function(annotName){
    fcnName <- annotName
    hasLine <- regexpr("(", fcnName, fixed=T)
    if(hasLine[1]>0)
        fcnName <- substr(fcnName, 1, hasLine[1]-2)
    fcnName
}
## Matches a vector in a sequence
vecIn <- function(a,b){
    which(Reduce('+', lapply(seq_along(y <- lapply(b, '==', a)), 
                             function(x){
                                y[[x]][x:(length(a) - length(b) +x)]
                             })) == length(b))
} 
parseSon <- function(i, offspringDF, path, id, treetype){
    if(length(path)) parent <- paste0(',"_parentId":', id)
    else parent <- NULL
    #parentID <- substr(id[1], 1, nchar(id[1])-1)
    newID <- paste0(length(path)+1,id,i)
    x <- paste("{\"id\":", newID, ",\"name\":\"", offspringDF$Function[i],
    "\",\"total\":\"", offspringDF$total[i], "\",\"self\":\"",
    offspringDF$self[i], "\",\"GC\":\"", offspringDF$GC[i], "\",\"GCself\":\"",
    offspringDF$GC.Self[i], "\"", parent, sep="")
    if(length(path) && (treetype == "funSum")){
        lastTwo <- c(getFname(path[length(path)]), 
                     getFname(as.character(offspringDF$Function[i])))
        makeSons <- !(any(as.logical(lapply(cycles, vecIn, lastTwo)), na.rm=TRUE) 
                          || (lastTwo[1] == lastTwo[2]))
    }
    else
        makeSons <- TRUE
    if(offspringDF$haveSons[i] && makeSons)
        x <- paste(x, "},",
                   parseOffspring(c(path, as.character(offspringDF$Function[i]))
                                  , treetype, newID))
    else
        x <- paste(x,"}")
    x
}

generateJSON <- function(pd, path, value = c("pct", "time", "hits"),
                         self = FALSE, srclines = TRUE, gc = TRUE,
                         maxdepth = 10){
    setOffspringDF(pd, value, self, srclines, gc, maxdepth)
    callSum <- callSummary(pd, byTotal = TRUE, value, srclines, gc)
    row.names(callSum) <- paste(" ", row.names(callSum), sep="")
    callSum <<- fixSumDF(callSum, self, gc, value)
    fcnSummary <- funSummary(pd, byTotal = TRUE, value, srclines, gc)
    fcnSummary <<- fixSumDF(fcnSummary, self, gc, value)
    cycles <- profileDataCycles(pd, TRUE)
    cycles <<- lapply(cycles, function(x) c(x, x[1]))
    write(c("{\"rows\":[",parseOffspring(c(), 'hotpaths'),"]}"), 
          paste(path, "/www/hotpaths.JSON", sep=""))         
    write(c("{\"rows\":[",parseOffspring(c(), 'funSum'),"]}"), 
          paste(path, "/www/funsum.JSON", sep="")) 
}

runShiny <- function(pd, value = c("pct", "time", "hits"),
                     self = FALSE, srclines = TRUE, gc = TRUE,
                     maxdepth = 10){
    pd$files <- normalizePath(pd$files)

    srcAnnotate <<- annotateSource(pd, value, gc, show=FALSE)
    cols <- c("<th field=\"self\" width=\"150\">Self</th>",
              "<th field=\"GC\" width=\"150\">GC</th>",
              "<th field=\"GCself\" width=\"150\">GC.Self</th>")
    # if(!gc)
        # cols[2:3] <- ""
    # if(!self)
        # cols[c(1,3)] <- ""
    path <- system.file("appdir", package="proftoolsGUI")
    #path <- "C:/Users/Big-Rod/Documents/GitHub/Rpkg-proftools-GUI/inst/appdir"
    index <- readLines(file.path(path, "www", "index.html"))
    index[145] <- paste0('  <option value="', value, '" selected>', value, '</option>')
    checked <- ifelse(c(self, gc), rep(' checked', 2), c('', ''))
    index[150:151] <- paste0(c('<input id="self" type="checkbox" name="self" value="1"',
                               '<input id="gc" type="checkbox" name="gc" value="1" '),
                             checked, c('> Self', '> GC'))
    write(index,file.path(path, "www", "index.html"))
    generateJSON(pd, path, value, self, srclines, gc, maxdepth)
    shiny::runApp(path)
}
?runapp
outputAnnot <- function(output, fcnAnnot = NULL, font.attr = NULL, where = 'end'){
    ## Below runs only if Shiny, since fcnAnnot (which is the annotion textbox)
    ## will be null in this case    
    if(is.null(fcnAnnot))
        if(is.null(font.attr))
            cat('<br />', paste(output, collapse='<br />'), sep='')
        else
            cat('<br />', paste('<span class="red">', 
                                paste(output, collapse='<br />'),
                                '</span>',sep=''), sep='')
    else
        insert(fcnAnnot, output, font.attr = font.attr, where = where)
}
# annotName is the name along with possible line info, fcnName strips those
functionAnnotate <- function(fcnName, annotName, path, srcAnnotate, fileName, 
                             lineNumber, treeType, fcnAnnot){
    ## fileName used in Shiny
    fileName <<- NULL
    if(is.null(srcAnnotate)) {
        outputAnnot("R file could not be found in the working directory", fcnAnnot)
        return()
    }
    fcnAnnotate <- functionAnnotation(fcnName, srcAnnotate, fileName, lineNumber,
                                      fcnAnnot)
    # Can't find function annotation or code, try the same for its first child                                  
    if(is.null(fcnAnnotate) && (length(path) > 1)){
        if(treeType=="hotPaths")
            siblingsDF <- offspring(path[-length(path)],c(TRUE,TRUE)) 
        else siblingsDF <- offspringFunSum(path[-length(path)],c(TRUE,TRUE))
        fcnDF <- siblingsDF[siblingsDF$Function==annotName,]
        if(fcnDF$haveSons){
            if(treeType=="hotPaths")
                sonsDF <- offspring(path,c(TRUE,TRUE))
            else sonsDF <- offspringFunSum(path,c(TRUE,TRUE))
            for(i in 1:nrow(sonsDF)){
                fcnInfo <- parseLineInfo(as.character(sonsDF$Function[i]),
                                         srcAnnotate)
                fcnAnnotate <- unlist(lapply(fcnInfo$fcnName, functionAnnotation,
                                             srcAnnotate, fcnInfo$fileName, 
                                             fcnInfo$lineNumber, fcnAnnot))
                if(!is.null(fcnAnnotate)){
                    return(invisible(TRUE))
                }    
            }
            outputAnnot("Selected Function has no available annotations", fcnAnnot)
        }
        else
            outputAnnot("Selected Function has no available annotations", fcnAnnot)
    }
}
functionAnnotation <- function(fcnName, srcAnnotate, fileName, lineNumber, 
                               fcnAnnot){
    if(length(fileName)){
        x <- srcAnnotate[[fileName]][lineNumber]
        fileEnd <- length(srcAnnotate[[fileName]])
        ends <- min(lineNumber+7, fileEnd)
        if(lineNumber != 1)
            outputAnnot(srcAnnotate[[fileName]][1:(lineNumber-1)],fcnAnnot)
        outputAnnot(srcAnnotate[[fileName]][lineNumber], fcnAnnot, 
                    font.attr=list(color="red"))
        if(lineNumber != ends)
            outputAnnot(srcAnnotate[[fileName]][(lineNumber+1):ends], fcnAnnot)
        if(ends != fileEnd)
            outputAnnot(srcAnnotate[[fileName]][(ends+1):fileEnd], 
                        fcnAnnot=fcnAnnot, where="at.cursor")
        return(TRUE)
    }
    else{
        unlist(lapply(seq_along(srcAnnotate), findFunction, fcnName, fcnAnnot))
    }
}

findFunction <- function(i, fcnName, fcnAnnot){
    srcCode <- srcAnnotate[[i]]
    defineFcns <- grep("function", srcCode, fixed=T)
    haveFcn <- grep(paste("[[:blank:]]+", 
                          sub(".", "\\.", fcnName, fixed=T), 
                          "[[:blank:]]*(<-|=)[[:blank:]]*function", 
                          sep=""), srcCode[defineFcns])
    if(length(haveFcn)){
        x <- srcCode[defineFcns[haveFcn]]
        lineNumber <- defineFcns[haveFcn]
        fileEnd <- length(srcCode)
        ends <- min(lineNumber+7, fileEnd)
        if(lineNumber != 1)
            outputAnnot(srcCode[1:(lineNumber-1)], fcnAnnot)
        outputAnnot(srcCode[lineNumber], fcnAnnot, 
                    font.attr=list(color="red"))
        if(lineNumber != ends)
            outputAnnot(srcCode[(lineNumber+1):ends], fcnAnnot)
        if(ends != fileEnd)
            outputAnnot(srcCode[(ends+1):fileEnd], fcnAnnot=fcnAnnot,
                        where="at.cursor")
        ## fileName used in Shiny
        fileName <<- names(srcAnnotate)[i]
        return(TRUE)
    }
    else
        NULL
}
parseLineInfo <- function(fcnName, srcAnnotate){
    hasLine <- regexpr("(", fcnName, fixed=T)
    if(hasLine[1]>0){
        lineProf <- unlist(strsplit(substr(fcnName, hasLine[1]+1, 
                                           nchar(fcnName)-1), ":", fixed=T))
        fileName <- lineProf[1]
        fileName <- grep(fileName, names(srcAnnotate), value=TRUE, fixed=TRUE)
        lineNumber <- as.numeric(lineProf[2])
        fcnName <- substr(fcnName, 1, hasLine[1]-2)
    }
    else{
        fileName <- lineNumber <- NULL
    }
    list(fcnName=fcnName,lineNumber=lineNumber,fileName=fileName)
}

addHandlers <- function(tree, fcnAnnot, treeType, srcAnnotate, pd){
    addHandlerClicked(tree, handler=function(h,...) {
        fcnAnnot <- h$action
        path <- svalue(h$obj, drop=FALSE)
        if(length(path) == 0){
            plotProfileCallGraph(pd, style = google.style)
            return(FALSE)
        }
        annotName <- path[length(path)]
        parseLine <- parseLineInfo(annotName, srcAnnotate)
        fcnNameRClick <<- parseLine$fcnName
        do.call(plotType, list())
        svalue(fcnAnnot) <- ''
        functionAnnotate(parseLine$fcnName, annotName, path, 
                         srcAnnotate, parseLine$fileName, 
                         parseLine$lineNumber, treeType, fcnAnnot)
    }, action=fcnAnnot)
    plotCallgraph <- function(h, ...){
        filtered <- filterProfileData(pd,fcnNameRClick,focus=T)
        plotProfileCallGraph(filtered, style = google.style)
        plotType <<- 'plotCallgraph'        
    }
    plotTreemap <- function(h, ...){
        filtered <- filterProfileData(pd,fcnNameRClick,focus=T)
        calleeTreeMap(filtered)    
        plotType <<- 'plotTreemap'        
    }
    plotFlamegraph <- function(h, ...){
        filtered <- filterProfileData(pd,fcnNameRClick,focus=T)
        flameGraph(filtered, order="hot")
        plotType <<- 'plotFlamegraph'
    }
    plotTimegraph <- function(h, ...){
        filtered <- filterProfileData(pd,fcnNameRClick,focus=T)
        flameGraph(filtered, order="time")
        plotType <<- 'plotTimegraph'        
    }
    ml <- list()
    ml[['Plot Callgraph']] <- gaction('Plot Callgraph', handler=plotCallgraph)
    ml[['Plot Tree Map']] <- gaction('Plot Tree Map', handler=plotTreemap)    
    ml[['Plot Flamegraph']] <- gaction('Plot Flamegraph', handler=plotFlamegraph)
    ml[['Plot Timegraph']] <- gaction('Plot Timegraph', handler=plotTimegraph)    
    add3rdmousePopupMenu(tree,menulist=ml)
}
summaryHandler <- function(h, ...){
    summaryView <- ifelse(svalue(h$obj) == "Function", "funSum", "hotPaths")
    delete(h$action$win, h$action$group)
    processWidget(h$action$pd, h$action$value, h$action$self, h$action$srclines, 
                  h$action$gc, h$action$maxdepth, h$action$interval, summaryView, h$action$win)
}
unitsHandler <- function(h, ...){
    value <- svalue(h$obj)
    delete(h$action$win, h$action$group)
    processWidget(h$action$pd, value, h$action$self, h$action$srclines, 
                  h$action$gc, h$action$maxdepth, h$action$interval, h$action$treeType, h$action$win)
}
checkHandler <- function(h, ...){
    self.gc <- c("self", "gc") %in% svalue(h$obj)
    delete(h$action$win, h$action$group)
    processWidget(h$action$pd, h$action$value, self.gc[1], h$action$srclines,
                  self.gc[2], h$action$maxdepth, h$action$interval, h$action$treeType, h$action$win)
}
myShiny <- function(input, output, session) {
    observe({
        srcAnnotate <<- annotateSource(pd, input$value, input$gc, show=FALSE)
        path <- system.file("appdir", package="proftoolsGUI")
        #path <- "C:/Users/Big-Rod/Documents/GitHub/Rpkg-proftools-GUI/inst/appdir"
        generateJSON(pd, path, input$value, input$self, srclines=TRUE, input$gc,
                     maxdepth=10)
        session$sendCustomMessage(type = 'testmessage', 
                                  message = list(value = input$value, 
                                                 self = input$self,
                                                 gc = input$gc))
    })

    output$fcnAnnot <- renderPrint({
        if(nchar(input$fcnName)){
            path <- rev(unlist(strsplit(input$fcnName, ",", fixed = TRUE)))
            parseLine <- parseLineInfo(path, srcAnnotate)
            annotation <- functionAnnotate(parseLine$fcnName, 
                                           path[length(path)], path,
                                           srcAnnotate, parseLine$fileName, 
                                           parseLine$lineNumber, "hotPaths", 
                                           NULL)
            if(!is.null(fileName))
                cat(paste('<p id="fileName">Filename: ', fileName, '</p>'))
            else if(!is.null(parseLine$fileName))
                cat(paste('<p id="fileName">Filename: ', parseLine$fileName, '</p>'))
        }
    })
    output$plot <- renderPlot({
        if(nchar(input$fcnName)){
            path <- rev(unlist(strsplit(input$fcnName, ",", fixed = TRUE)))
            parseLine <- parseLineInfo(path[length(path)], srcAnnotate)
            filtered <- filterProfileData(pd,parseLine$fcnName,focus=T)
            if(input$plotType == 'plotCallgraph')
                plotProfileCallGraph(filtered, style = google.style)
            else if(input$plotType == 'plotTreemap')
                calleeTreeMap(filtered)
            else if(input$plotType == 'plotFlamegraph')
                flameGraph(filtered, order="hot")
            else if(input$plotType == 'plotTimegraph')
                flameGraph(filtered, order="time")
        }
        else if(input$plotType == 'plotCallgraph')
            plotProfileCallGraph(pd, style = google.style)
        else if(input$plotType == 'plotTreemap')
            calleeTreeMap(pd)
        else if(input$plotType == 'plotFlamegraph')
            flameGraph(pd, order="hot")
        else if(input$plotType == 'plotTimegraph')
            flameGraph(pd, order="time")
  })    

}
# Always keep an empty final line or annotateSource will break
