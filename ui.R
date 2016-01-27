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
           actionButton("update", "Write to db / Next time-series")),
    column(width = 4,
           selectInput('formula',
                       label = 'Formula',
                       choices = list('trend',
                                      'trend + harmon',
                                      'harmon'),
                       selected = 'trend + harmon'),
           numericInput("order", label = 'Harmonic order', value = 3)),
    
    column(width = 4,
           sliderInput('h', label = 'minimal segment size', min = 0, max = 1, value = 0.20, step = 0.01),
           # TOD: add db file input here
           numericInput("nSamples", "Number of Samples", value = 200, min = 2))
  )
))
