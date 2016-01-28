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
  

})

