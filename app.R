library(shiny)
source ("db_extract.R")
# Define UI for data download app ----
ui <- fluidPage(
    
    # App title ----
    titlePanel("The River Ouse Project: extract species frequencies and counts from the 
               meadows database"),
    
    # Sidebar layout with input and output definitions ----
    sidebarLayout(
        
        # Sidebar panel for inputs ----
        sidebarPanel(
            p("Please wait while the raw data extract is displayed - takes a few seconds."),
            p(),
            p("You can download all the raw data in a single .csv file, but note this downloads
              approximately 1.5 Mb data, a little over 21000 rows in Excel."),
            downloadButton("downloadAll", "Download all"),
            p(),
            p("Or, you can download smaller datasets for which species frequencies have 
              already been calculated."),
            p("Select from the choices below; a preview of the data is displayed in 
            the table. If you want to keep it, press the Download button. 
            A file will be saved in your Downloads folder in .csv format, which can 
            be opened by most spreadsheets."),
            
            # Input: Choose dataset ----
            selectInput("dataset", "Choose a dataset:",
                        choices = c("None",
                                    "Gross species frequencies", 
                                    "Species frequencies by community", 
                                    "Species frequencies by assembly",
                                    "Species counts by community",
                                    "Species counts by assembly")),
            
            # Button
            downloadButton("downloadData", "Download digest"),
            p("Explanation of non-obvious columns:"),
            tags$ul(
              tags$li("hits: number of times species has been found"), 
              tags$li("trials: number of quadrats (samples) that it could have been found in"), 
              tags$li("freq: hits/trials, mean frequency"),
              tags$li("CrI5: 5% quantile of the underlying distribution"),
              tags$li("median: 50% quantile of the underlying distribution"),
              tags$li("CrI95: 95% quantile of the underlying distribution"),
            ),
            p(),
            p("You may download the R code for the data extract and digests here:"),
            a(href="db_extract.R", "db_extract.R", download=NA, target="_blank")
        ), # End of sidebar panel layout
        
        # Main panel for displaying outputs; just has the table in it.
        mainPanel(
            shinycssloaders::withSpinner(
                tableOutput("table")
            )
        )
        
    )
)

# Define server logic to display and download selected file ----
server <- function(input, output) {
    the_data <- GetTheData()
    # Table of all the data ----
    output$table <- renderTable({
      datasetInput()
    })
    # Downloadable csv of all data ----
    output$downloadAll <- downloadHandler(
      filename = function() {
        paste("species_frequencies", ".csv", sep = "")
      },
      content = function(file) {
        write.csv(GetTheData(), file, row.names = FALSE)
      }
    )
    
    # Reactive value for selected dataset ----
    datasetInput <- reactive({
        switch(input$dataset,
               # "None" ={},
               "None" = AllTheData(the_data),
               "Gross species frequencies" = GrossFrequency(the_data),
               "Species frequencies by community" = FrequencyByCommunity(the_data),
               "Species frequencies by assembly" = FrequencyByAssembly(the_data),
               "Species counts by community" = CommunitySpeciesCounts(the_data),
               "Species counts by assembly" =  AssemblySpeciesCounts(the_data))     
    })
 
      
    # Table of selected dataset ----
    output$table <- renderTable({
        datasetInput()
    })
    
    # Downloadable csv of selected dataset ----
    output$downloadData <- downloadHandler(
      file = function() {
          paste(input$dataset, ".csv", sep = "")
        },
        content = function(file) {
            write.csv(datasetInput(), file, row.names = FALSE)
        }
    )
    
 dbDisconnectAll() # Ensure all handles closed on exit  
}

# Create Shiny app ----
shinyApp(ui, server)