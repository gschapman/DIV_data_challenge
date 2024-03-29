# Define UI
ui <- fluidPage(
  
  # Application title
  titlePanel("Data Challenge - DIV Percent Cover by Species, Over Time"),
  
  sidebarLayout(
    
    # Sidebar with a slider input
    sidebarPanel(
      width = 2,
      
      div(
        style = "color: dimgrey; margin-bottom: 15px;",
        strong("To initiate Portal download, select a Domain and Site:")
      ),
      
      selectInput("domain", "Domain:", c("")),
      
      selectInput("site", "Site:", c("")),
      
      div(
        style = "color: dimgrey; margin-bottom: 15px;",
        strong("To display data, select a plot ID after the Portal download has completed.")
      ),
      
      selectInput("plot", "Plot:", c("")),
      
    ),
    
    # Show a plot of the generated distribution
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