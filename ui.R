library(shiny)


shinyUI(fluidPage(
  # Custom css for status dots
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
  ),
  fluidRow(
    column(width = 3,
           h3("Segment classes"),
           uiOutput("inSelect")),
    column(width = 9,
           tabsetPanel(
             tabPanel('plot', plotOutput("bpPlot")),
             tabPanel('table', tableOutput('statTable'))
           ))
  ),
  fluidRow(
    column(width = 3,
           h3("Time-series control"),
           actionButton("nextTimeSeries", "Next time-series"),
           actionButton("writeToDb", "Write to db"),
           numericInput("nbFeatures", 'Number of features to sample from data base', value = 200, min = 2)),
    
    column(width = 3,
           h3("breakpoints parameters"),
           tags$i("Select these on application startup and don't change them during the interpretation"),
           selectInput('formula',
                       label = 'Formula',
                       choices = list('trend',
                                      'trend + harmon',
                                      'harmon'),
                       selected = 'trend + harmon'),
           numericInput("order", label = 'Harmonic order', value = 3),
           sliderInput('h', label = 'minimal segment size', min = 0, max = 1, value = 0.20, step = 0.01)),
    
    column(width = 3,
           h3("Databases connections"),
           tags$i("Don't forget to connect to the output database by clicking on the button"),
           textInput('dbPath', 'Path to input database',
                     value = '/home/dutri001/git/resilience/data/SR_ee_samples_amazon.sqlite'),
           uiOutput("dbTableSelect"),
           textInput('dbOutPath', "Path to output database",
                     value = '/home/dutri001/git/resilience/data/trainingSamples.sqlite'),
           textInput('dbOutTable', "Output database table name",
                     'training'),
           actionButton("dbConnect", "Connect to (or create) output database")),
    
    column(width = 3,
          leafletOutput("plotLocation")     
    #        # htmlOutput("dbStatus")
          )
  )
))
