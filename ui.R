library(shiny)


shinyUI(fluidPage(
  fluidRow(
    column(width = 3,
           uiOutput("inSelect")),
    column(width = 8, offset = 1,
           tabsetPanel(
             tabPanel('plot', plotOutput("bpPlot")),
             tabPanel('table', tableOutput('statTable'))
           ))
  ),
  fluidRow(
    column(width = 4,
           textInput('dbPath', 'Path to Data base',
                     value = '/home/dutri001/git/resilience/data/SR_ee_samples_amazon.sqlite'),
           uiOutput("dbTableSelect"),
           numericInput("nbFeatures", 'Number of features to sample from data base', value = 200, min = 2),
           actionButton("nextTimeSeries", "Write to db / Next time-series")),
    column(width = 4,
           selectInput('formula',
                       label = 'Formula',
                       choices = list('trend',
                                      'trend + harmon',
                                      'harmon'),
                       selected = 'trend + harmon'),
           numericInput("order", label = 'Harmonic order', value = 3)),
    
    column(width = 4,
           sliderInput('h', label = 'minimal segment size', min = 0, max = 1, value = 0.20, step = 0.01))
  )
))
