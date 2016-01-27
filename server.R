library(shiny)
library(dplyr)
library(RSQLite)
library(spectralResilience)

source('R/utils.R') # cloudShadow(), getLandsatDate()

shinyServer(function(input, output) {
  
  # Establish connection with db (not sure where it should go)
  # dbFile <- input$dbFile
  # if(is.null(dbFile))
  #   return(NULL)
  dbFile <- '/home/dutri001/git/resilience/data/SR_ee_samples_amazon.sqlite'
  con <- src_sqlite(dbFile)
  
  # Create/connect to output db
  con_out <- src_sqlite('/home/dutri001/sandbox/test_df.sqlite', create = TRUE)
  
  # List tables and send output to UI
  # TODO
  dbTables <- src_tbls(con)
  
  # Get from UI the name of the table we want to work with
  # TODO
  dfRemote <- tbl(con, dbTables)
  
  
  # UI asks how many features to sample
  # TODO
  nSamples <- input$nSamples
  
  # Extract vector of featureID unique values and sample from it
  uniqueFeatures <- dfRemote %>%
    select(featureID) %>%
    distinct() %>%
    collect()
  
  # Sample from feature vector
  featuresSample <- sample(featuresVector$featureID, nSamples)
  
  # Reactive that runs breakpoints()
  breakpts <- reactive({
    
    # Get the "next" feature
    id <- featuresSample[featureID_index]
    
    # Read df compute required fields and filter clouds and shadows
    df <- dfRemote %>%
      filter(featureID %in% id) %>%
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
  
  # Manage the time-series number using a reactiveValue and an observer
  featureID_index <- reactiveValues(i = 1)
  observe({
    input$update
    featureID_index$i <- isolate(featureID_index$i) + 1
  })
  
  # Reactive that holds the dataframe with predictors and interpreted classes
  trainingDf <- reactive({
    if (is.null(breakpts())) {
      return(NULL)
    }
    
    nbSegments <- breakpts()@nbSegments
    
    segmentClasses <- sapply(1:nbSegments, function(i) {
      input[[paste0("Class", i)]]
    })
    
    classes <- as.data.frame(segmentClasses)
    return(cbind(classes, breakpts()@statsDf))
  })
  
  # Build a dataframe and write it to db

  newEntry <- observe({
    if(input$update > 0) { # When button is pressed in UI
      # Update database
      db_insert_into(con = con_out$con, table = "rf_training", values = trainingDf())
    }
  })
  output$table1 <- renderTable({values$df})

})
