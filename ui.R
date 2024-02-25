# Define UI
ui <- fluidPage(
  
  # Application title
  titlePanel("DIV, Summed 1m2 Percent Cover, Over Time"),
  
  ## DL Button style
  tags$style(
    paste(".btn {vertical-align: top; border: 1px solid #BFB1AC; box-shadow: 3px 3px 0px #75615A;}")
  ),
  
  sidebarLayout(
    
    # Sidebar with a slider input
    sidebarPanel(
      width = 2,
      
      div(
        style = "color: dimgrey; margin-bottom: 15px; text-align: justify;",
        strong("To initiate Portal data download, select a Domain and Site:")
      ),
      
      # Select domain
      selectInput("domain", "Domain:", c("")),
      
      # Select site
      selectInput("site", "Site:", c("")),
      
      # Select bout; first bout is selected by default
      selectInput("bout", "Bout Number:", c("")),
      
      # Select data type
      selectInput(
        "portal_data_type", "Data Type:", choices = c("Plant Taxa", "Other Variables", "Nativity Status")
      ),
      
      div(
        style = "color: dimgrey; margin-bottom: 15px; text-align: justify;",
        strong("To display data, select a plot ID after the Portal download has completed:")
      ),
      
      # Select plot
      selectInput("plot", "Plot:", c("")),
      
      div(
        style = "color: dimgrey; margin-bottom: 10px; font-size: 90%; text-align: justify;",
        "Transforming the time series plot to display values on a log scale can help expand clustered 'low' values:"
      ),
      
      # Transform plotted y-values to log2 if selected, which expands visibility of small values
      radioButtons(
        "transform_y", "Transform Y Axis:", choices = c("Linear", "Log (Base 2)"), inline = T
      ),
      
      div(
        style = "color: dimgrey; margin-bottom: 10px; font-size: 90%; text-align: justify;",
        "Selecting rows in the data table will filter what is displayed in the time series plot.",
        "Use the button below to de-select all rows, and plot all available values:"
      ),
      
      # De-select all rows button
      actionButton("spp_plot_summary_ds_all", "De-select All Rows", width = "100%")
      
    ),
    
    # Show table and plot of selected data
    mainPanel(
      width = 10,
      
      # Summary table
      fluidRow(
        div(
          style = "max-height: 50vh; padding-right: 17px; margin-bottom: 25px; overflow-x: auto; overflow-y: auto;",
          DTOutput("spp_plot_summary")
        )
      ),
      
      # Time series plot
      fluidRow(
        div(
          style = "max-height: 45vh; padding-right: 17px; overflow-x: auto; overflow-y: auto;",
          plotlyOutput("spp_plot_plotly")
        )
      )
      
    ) # End main panel
  )
)