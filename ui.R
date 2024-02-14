# Define UI
ui <- fluidPage(
  
  # Application title
  titlePanel("Data Challenge - DIV Percent Cover by Species, Over Time"),
  
  sidebarLayout(
    
    # Sidebar with a slider input
    sidebarPanel(
      width = 2,
      
      selectInput("domain", "Domain:", c("")),
      
      selectInput("site", "Site:", c("")),
      
      selectInput("plot", "Plot:", c("")),
      
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
      width = 10,
      
      # Summary table
      fluidRow(
        div(
          style = "max-height: 45vh; padding-right: 17px; overflow-x: auto; overflow-y: auto;",
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