# Define UI
ui <- fluidPage(
  
  tags$head(HTML("<title>DIV: Summed 1m2 Percent Cover, Over Time</title>")),
  
  ## DL Button style
  tags$style(
    paste(".btn {vertical-align: top; border: 1px solid #BFB1AC; box-shadow: 3px 3px 0px #75615A;}")
  ),
  
  sidebarLayout(
    
    # Sidebar with a slider input
    sidebarPanel(
      style = "margin-top: 15px;",
      width = 2,
      
      div(
        style = "color: dimgrey; margin-bottom: 15px; text-align: justify;",
        strong("To initiate the Portal data download, select a Domain and Site:")
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
      
      # Transform plotted y-values to log2 if selected, which expands visibility of small values
      hr(style = "height: 0.5px; border:none; background-color: silver; margin: 10px 0 10px 0;"),
      
      div(
        style = "color: dimgrey; margin-bottom: 5px; font-size: 90%; text-align: justify;",
        "Transforming the time series plot to display values on a log scale can help expand visibility of clustered 'low' values:"
      ),
      
      radioButtons(
        "transform_y", "Transform Time Series Plot:", choices = c("Linear", "Log (Base 2)"), inline = T
      ),
      
      # De-select all rows button
      hr(style = "height: 0.5px; border:none; background-color: silver; margin: 0 0 10px 0;"),
      
      div(
        style = "color: dimgrey; margin: 10px 0 10px 0; font-size: 90%; text-align: justify;",
        strong("Selecting rows in the data table will filter what is displayed in the time series plot."),
        "Use the button below to de-select all rows, and plot all available values:"
      ),
      
      actionButton("spp_plot_summary_ds_all", "De-select All Rows", width = "100%")
      
    ),
    
    # Show table and plot of selected data
    mainPanel(
      width = 10,
      
      # Application Title
      fluidRow(
        div(
          style = "margin: 10px 0 10px 0; font-size: 175%; text-align: center;",
          strong("Plant Diversity:"), "Summed", HTML(paste0("1m", tags$sup("2"))), "Percent Cover, Over Time"
        )
      ),
      
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