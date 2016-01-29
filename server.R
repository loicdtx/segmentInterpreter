library(shiny)
library(dplyr)
library(RSQLite)
library(spectralResilience)
library(magrittr)
library(stringr)

source('R/utils.R') # cloudShadow(), getLandsatDate()

dbConOut <- NULL

shinyServer(function(input, output) {
  
  # FOr time-series number
  counter <- reactiveValues(i = 1)
  
  # Connect to databases
  dbCon <- reactive({
    dbFile <- input$dbPath
    con <- src_sqlite(dbFile)
    return(con)
  })
  
  
  # Reactive that lists the tables of the db
  dbTables <- reactive({
    return(src_tbls(dbCon()))
  })
    
  # Send list of tables to UI
  output$dbTableSelect <- renderUI({
    if(is.null(dbTables())) {
      return(NULL)
    }
    selectInput('dbTableSelect', label = "Input database table",  choices = dbTables())
  })
  
  # Reactive that connects to db table
  dfRemote <- reactive({
    return(tbl(dbCon(), dbTables()))
  })
  
  # Create/connect to output db when button is pressed
  observe({
    if(input$dbConnect > 0) {
      dbConOut <<- src_sqlite(input$dbOutPath, create = TRUE)
    }
  })
  
  # Get status of output db connection
  # dbConOut_status <- reactive({
  #   if(is.null(dbConOut)) {
  #     return('dbStatusFalse')
  #   } else {
  #     return('dbStatusTrue')
  #   }
  # })
  # 
  # output$dbStatus <- renderUI({
  #   div(id = dbConOut_status())
  # })
  
  # Reactive that generates a vector of random featureID
  featuresSample <- reactive({
    # Get number of features to be sampled from UI
    nbFeatures <- input$nbFeatures
    
    # Get vector of unique features
    uniqueFeatures <- dfRemote() %>%
      dplyr::select(featureID) %>%
      distinct() %>%
      collect()
    
    # Sample from this vector
    featuresSample <- sample(uniqueFeatures$featureID, nbFeatures)
    return(featuresSample)
  })
  
  
  # Reactive that runs breakpoints()
  breakpts <- reactive({
    
    # featureID
    id <- featuresSample()[counter$i]
    
    # Read df compute required fields and filter clouds and shadows
    df <- dfRemote() %>%
      filter(featureID == id) %>%
      collect() %>%
      mutate(time = getLandsatDate(sceneID)) %>%
      mutate(NDMI = (B4 - B5)/(B4 + B5)) %>%
      mutate(NDVI = (B4 - B3)/(B4 + B3)) %>%
      mutate(NDSI = (B2 - B5)/(B2 + B5)) %>%
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
  
  # Observer that writes to db when "nextTimeSeries" button is pressed
  observe({
    if(input$writeToDb > 0) { # When button is pressed in UI
      # Update database
      db_insert_into(con = dbConOut$con, table = input$dbOutTable, values = trainingDf())
    }
  })
  
  # Observer to go to next time-series when button is pressed
  observe({
    if(input$nextTimeSeries > 0) {
      counter$i <- isolate(counter$i) + 1
    }
  })

})

