library(shiny)


shinyServer(function(input, output, session) {
    
#    fcnName <- reactive({  
#        input$fcnName
#    })
    # observe({
      # session$sendCustomMessage(type = 'testmessage',
                                # message = list(a = 1, b = 'text',
                                               # type = value))
    # })

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
})
