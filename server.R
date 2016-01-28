library(shiny)
library(dplyr)
library(RSQLite)
library(spectralResilience)
library(magrittr)
library(stringr)

source('R/utils.R') # cloudShadow(), getLandsatDate()

# Load data
dfIn <- readRDS('data/matoGrosso.rds')

shinyServer(function(input, output) {
  
  # Reactive that runs breakpoints()
  breakpts <- reactive({
    
    # Get the "next" feature
    
    # Read df compute required fields and filter clouds and shadows
    df <- dfIn %>%
      mutate(time = getLandsatDate(sceneID)) %>%
      rowwise() %>%
      mutate(mask = cloudShadow(B1, B3, B4, B7, NDSI, NDVI)) %>% # TODO: Shadow threshold too restrictive for oregon
      filter(mask == 'land') %>%
      data.frame()
    
    formula <- switch(input$formula,
                      'trend' = response ~ trend,
                      'trend + harmon' = response ~ trend + harmon,
                      'harmon' = response ~ harmon)
    
    order <- input$order
    
    h <- input$h
    
    # Compute SR object
    out <- initSR(df, formula = formula, h = h, order = order) %>%
      makePP('NDMI') %>%
      makeSegmentNumberVector() %>%
      makeStatsDf()
      
    return(out)
  })

  # First output (plot)  
  output$bpPlot <- renderPlot({  
    # plot results
    if(is.null(breakpts())) {
      print("No Data")
    } else {
      gplot(breakpts())
    }       
  })
  
  # Dynamically control UI
  # dynamic select (link to uiOutput("inSelect") in UI)
  output$inSelect <- renderUI({
    if (is.null(breakpts())) {
      return(NULL)
    }
    nbSegments <- breakpts()@nbSegments
    lapply(1:nbSegments, function(i) {
      selectInput(paste0("Class", i), label = paste("Segment_", i),  choices = c('Stable', 'Decline', 'Regrowth', 'Transition', 'Other'), selected = 'Stable')
    })
  })
  
  ## Reactive that builds a dataframe from output of breakpts() and interpreted classes
  trainingDf <- reactive({
    if (is.null(breakpts())) {
      return(NULL)
    }
    
    regressorsDf <- breakpts()@statsDf
    nbSegments <- breakpts()@nbSegments
    segmentClassVector <- sapply(1:nbSegments, function(i) {
      input[[paste0("Class", i)]]
    })
    
    regressorsDf$class <- segmentClassVector
    return(regressorsDf)
  })
  
  # Display the training df produced in the other tab of UI
  output$statTable <- renderTable({trainingDf()})

})

