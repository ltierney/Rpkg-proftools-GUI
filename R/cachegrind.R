cacheGrind <- function(pd) {
    getCmd <- function(name)
        tryCatch(system2("which", name, stdout = TRUE),
                 warning = function(w) NULL)
    cmd <- getCmd("kcachegrind")
    if (! is.character(cmd))
        cmd <- getCmd("qcachegrind")
    if (! is.character(cmd))
        stop("neither 'kcachegrind' nor 'qcachecrind' is available")
    fname <- tempfile()
    writeCallgrindFile(pd, file = fname)
    system2(cmd, fname, wait = FALSE)
    Sys.sleep(1)
    unlink(fname)
}

cacheGrindRStudio <- function() {
    pd <- readRStudioProfileCacheData()
    if (is.null(pd))
        stop("no profile data available in the RStudio profile cache")
    cacheGrind(pd)
}
