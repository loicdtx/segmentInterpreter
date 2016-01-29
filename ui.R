library(shiny)


shinyUI(fluidPage(
  # Custom css for status dots
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
  ),
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
           textInput('dbPath', 'Path to input database',
                     value = '/home/dutri001/git/resilience/data/SR_ee_samples_amazon.sqlite'),
           uiOutput("dbTableSelect"),
           textInput('dbOutPath', "Path to output database",
                     value = '/home/dutri001/git/resilience/data/trainingSamples.sqlite'),
           textInput('dbOutTable', "Output database table name",
                     'training'),
           actionButton("dbConnect", "Connect to (or create) output database"),
           numericInput("nbFeatures", 'Number of features to sample from data base', value = 200, min = 2),
           actionButton("nextTimeSeries", "Next time-series"),
           actionButton("writeToDb", "Write to db")),
    column(width = 4,
           selectInput('formula',
                       label = 'Formula',
                       choices = list('trend',
                                      'trend + harmon',
                                      'harmon'),
                       selected = 'trend + harmon'),
           numericInput("order", label = 'Harmonic order', value = 3)),
    
    column(width = 4,
           sliderInput('h', label = 'minimal segment size', min = 0, max = 1, value = 0.20, step = 0.01)
           # htmlOutput("dbStatus")
           )
  )
))
